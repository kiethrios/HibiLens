#!/usr/bin/env python3
"""Download or read, verify, and install the Hibi Lens SigLIP model."""

from __future__ import annotations

import argparse
import contextlib
import hashlib
import json
import os
import re
import shutil
import stat
import sys
import tempfile
import unicodedata
import urllib.error
import urllib.request
import zipfile
from pathlib import Path, PurePosixPath
from typing import Any, Sequence
from urllib.parse import urlparse


EXPECTED_DESTINATION = (
    "JapCapture/Models/SigLIP/siglip_base_patch16_224_image.mlpackage"
)
EXPECTED_MODEL_ROOT = "siglip_base_patch16_224_image.mlpackage"
EXPECTED_MODEL_ID = "google/siglip-base-patch16-224"
EXPECTED_LICENSE = "Apache-2.0"
EXPECTED_CONVERTER = {
    "torch": "2.5.0",
    "transformers": "5.8.0",
    "coremltools": "8.3.0",
}
EXPECTED_MANIFEST_KEYS = {
    "schemaVersion",
    "assetURL",
    "archiveSHA256",
    "archiveBytes",
    "destination",
    "modelID",
    "modelRevision",
    "license",
    "converter",
}
SHA256_PATTERN = re.compile(r"[0-9a-f]{64}\Z")
REVISION_PATTERN = re.compile(r"[0-9a-f]{40}\Z")
DRIVE_PATTERN = re.compile(r"[A-Za-z]:")
DOWNLOAD_CHUNK_BYTES = 1024 * 1024
MAX_ARCHIVE_BYTES = 8 * 1024 * 1024 * 1024
MAX_ZIP_ENTRIES = 4096
MAX_UNCOMPRESSED_BYTES = 16 * 1024 * 1024 * 1024
MAX_FILE_BYTES = 8 * 1024 * 1024 * 1024
MAX_COMPRESSION_RATIO = 200
MAX_PACKAGE_MANIFEST_BYTES = 1024 * 1024


class ModelPreparationError(RuntimeError):
    """Raised when a public model asset cannot be installed safely."""


class _JSONObject(dict[str, Any]):
    def __init__(self, pairs: list[tuple[str, Any]]) -> None:
        super().__init__(pairs)
        counts: dict[str, int] = {}
        for key, _value in pairs:
            counts[key] = counts.get(key, 0) + 1
        self.duplicate_keys = sorted(key for key, count in counts.items() if count > 1)


def _load_manifest(path: Path) -> dict[str, Any]:
    try:
        payload = json.loads(
            path.read_text(encoding="utf-8"), object_pairs_hook=_JSONObject
        )
    except (OSError, UnicodeError, json.JSONDecodeError) as error:
        raise ModelPreparationError(
            f"cannot load model manifest {path}: {error}"
        ) from error
    if not isinstance(payload, _JSONObject):
        raise ModelPreparationError("model manifest root must be an object")
    errors: list[str] = []
    if payload.duplicate_keys:
        errors.append("duplicate fields: " + ", ".join(payload.duplicate_keys))
    missing = sorted(EXPECTED_MANIFEST_KEYS - set(payload))
    unexpected = sorted(set(payload) - EXPECTED_MANIFEST_KEYS)
    if missing:
        errors.append("missing fields: " + ", ".join(missing))
    if unexpected:
        errors.append("unexpected fields: " + ", ".join(unexpected))

    if type(payload.get("schemaVersion")) is not int or payload.get("schemaVersion") != 1:
        errors.append("schemaVersion must be the integer 1")
    asset_url = payload.get("assetURL")
    if not isinstance(asset_url, str) or not asset_url:
        errors.append("assetURL must be a non-empty URL")
    else:
        parsed = urlparse(asset_url)
        if parsed.scheme not in {"https", "http", "file"}:
            errors.append("assetURL must use https, http, or file")
        elif parsed.scheme in {"https", "http"} and not parsed.netloc:
            errors.append("assetURL must be absolute")
        elif parsed.scheme == "file" and not parsed.path.startswith("/"):
            errors.append("file assetURL must be absolute")
    digest = payload.get("archiveSHA256")
    if not isinstance(digest, str) or SHA256_PATTERN.fullmatch(digest) is None:
        errors.append("archiveSHA256 must be 64 lowercase hexadecimal characters")
    byte_count = payload.get("archiveBytes")
    if type(byte_count) is not int or byte_count < 0:
        errors.append("archiveBytes must be a nonnegative integer")
    elif byte_count > MAX_ARCHIVE_BYTES:
        errors.append("archiveBytes exceeds the supported limit")
    if payload.get("destination") != EXPECTED_DESTINATION:
        errors.append(f"destination must be exactly {EXPECTED_DESTINATION}")
    if payload.get("modelID") != EXPECTED_MODEL_ID:
        errors.append(f"modelID must be exactly {EXPECTED_MODEL_ID}")
    revision = payload.get("modelRevision")
    if not isinstance(revision, str) or REVISION_PATTERN.fullmatch(revision) is None:
        errors.append("modelRevision must be 40 lowercase hexadecimal characters")
    if payload.get("license") != EXPECTED_LICENSE:
        errors.append(f"license must be exactly {EXPECTED_LICENSE}")
    converter = payload.get("converter")
    if converter != EXPECTED_CONVERTER:
        errors.append("converter versions do not match the supported release contract")
    if isinstance(converter, _JSONObject) and converter.duplicate_keys:
        errors.append(
            "converter has duplicate fields: " + ", ".join(converter.duplicate_keys)
        )
    if errors:
        raise ModelPreparationError("invalid model manifest: " + "; ".join(sorted(errors)))
    return dict(payload)


@contextlib.contextmanager
def _open_regular_archive(path: Path):
    flags = os.O_RDONLY
    if hasattr(os, "O_NOFOLLOW"):
        flags |= os.O_NOFOLLOW
    if hasattr(os, "O_NONBLOCK"):
        flags |= os.O_NONBLOCK
    try:
        descriptor = os.open(path, flags)
    except OSError as error:
        raise ModelPreparationError(f"cannot read model archive: {error}") from error
    try:
        status = os.fstat(descriptor)
        if not stat.S_ISREG(status.st_mode):
            raise ModelPreparationError("model archive must be a regular file")
        with os.fdopen(descriptor, "rb") as stream:
            descriptor = -1
            yield stream
    finally:
        if descriptor >= 0:
            os.close(descriptor)


def _verify_archive(stream, manifest: dict[str, Any]) -> str:
    digest = hashlib.sha256()
    byte_count = 0
    try:
        stream.seek(0)
        while True:
            chunk = stream.read(DOWNLOAD_CHUNK_BYTES)
            if not chunk:
                break
            byte_count += len(chunk)
            if byte_count > MAX_ARCHIVE_BYTES:
                raise ModelPreparationError("model archive exceeds the supported limit")
            digest.update(chunk)
        stream.seek(0)
    except OSError as error:
        raise ModelPreparationError(f"cannot read model archive: {error}") from error
    rendered_digest = digest.hexdigest()
    if byte_count != manifest["archiveBytes"]:
        raise ModelPreparationError(
            "model archive byte count does not match manifest"
        )
    if rendered_digest != manifest["archiveSHA256"]:
        raise ModelPreparationError("model archive SHA-256 does not match manifest")
    return rendered_digest


def _download_archive(asset_url: str, expected_bytes: int) -> Path:
    file_descriptor, temporary_name = tempfile.mkstemp(
        prefix="hibi-lens-siglip-", suffix=".zip"
    )
    os.close(file_descriptor)
    temporary = Path(temporary_name)
    try:
        request = urllib.request.Request(
            asset_url,
            headers={"User-Agent": "HibiLens-model-preparer/1"},
        )
        with urllib.request.urlopen(request, timeout=30) as response, temporary.open(
            "wb"
        ) as output:
            byte_count = 0
            while True:
                chunk = response.read(DOWNLOAD_CHUNK_BYTES)
                if not chunk:
                    break
                byte_count += len(chunk)
                if byte_count > expected_bytes or byte_count > MAX_ARCHIVE_BYTES:
                    raise ModelPreparationError(
                        "downloaded model archive byte count exceeds manifest"
                    )
                output.write(chunk)
        return temporary
    except (OSError, urllib.error.URLError, ValueError) as error:
        temporary.unlink(missing_ok=True)
        raise ModelPreparationError("cannot download model archive") from error
    except BaseException:
        temporary.unlink(missing_ok=True)
        raise


def _printable_name(name: str) -> bool:
    return bool(name) and all(
        character.isprintable()
        and not (0xD800 <= ord(character) <= 0xDFFF)
        for character in name
    )


def _zip_path(name: str) -> PurePosixPath:
    if not _printable_name(name):
        raise ModelPreparationError("ZIP entry has an empty or non-printable name")
    if "\\" in name:
        raise ModelPreparationError("ZIP entry uses an unsafe backslash path")
    if name.startswith(("/", "//")) or DRIVE_PATTERN.match(name):
        raise ModelPreparationError("ZIP entry uses an absolute or drive path")
    if name.endswith("/"):
        raise ModelPreparationError("ZIP directory entries are not accepted")
    parts = name.split("/")
    if any(part in {"", ".", ".."} for part in parts):
        raise ModelPreparationError("ZIP entry has an unsafe or ambiguous path")
    return PurePosixPath(*parts)


def _platform_key(path: PurePosixPath) -> str:
    return unicodedata.normalize("NFD", path.as_posix()).casefold()


def _validate_zip(archive: zipfile.ZipFile) -> list[tuple[zipfile.ZipInfo, PurePosixPath]]:
    infos = archive.infolist()
    if not infos:
        raise ModelPreparationError("model package ZIP is empty")
    if len(infos) > MAX_ZIP_ENTRIES:
        raise ModelPreparationError("model package ZIP contains too many entries")
    checked: list[tuple[zipfile.ZipInfo, PurePosixPath]] = []
    seen_exact: set[str] = set()
    seen_platform: dict[str, str] = {}
    total_size = 0
    for info in infos:
        path = _zip_path(info.filename)
        rendered = path.as_posix()
        if rendered in seen_exact:
            raise ModelPreparationError("ZIP contains duplicate entries")
        seen_exact.add(rendered)
        platform_key = _platform_key(path)
        previous = seen_platform.get(platform_key)
        if previous is not None:
            raise ModelPreparationError(
                "ZIP contains platform-colliding entries"
            )
        seen_platform[platform_key] = rendered
        if info.flag_bits & 0x1:
            raise ModelPreparationError("ZIP contains an encrypted entry")
        if info.create_system == 3:
            file_type = stat.S_IFMT(info.external_attr >> 16)
            if file_type not in (0, stat.S_IFREG):
                raise ModelPreparationError("ZIP contains a symlink or special entry")
        if info.file_size < 0 or info.file_size > MAX_FILE_BYTES:
            raise ModelPreparationError("ZIP entry exceeds the supported size")
        if info.compress_size < 0:
            raise ModelPreparationError("ZIP entry has an invalid compressed size")
        if info.file_size and info.compress_size == 0:
            raise ModelPreparationError("ZIP entry has an excessive compression ratio")
        if info.compress_size and info.file_size / info.compress_size > MAX_COMPRESSION_RATIO:
            raise ModelPreparationError("ZIP entry has an excessive compression ratio")
        total_size += info.file_size
        if total_size > MAX_UNCOMPRESSED_BYTES:
            raise ModelPreparationError("ZIP expands beyond the supported size")
        if not path.parts or path.parts[0] != EXPECTED_MODEL_ROOT:
            raise ModelPreparationError(
                "model package ZIP must contain exactly the expected .mlpackage root"
            )
        checked.append((info, path))

    for rendered, platform_key in (
        (path.as_posix(), _platform_key(path)) for _info, path in checked
    ):
        components = platform_key.split("/")
        for length in range(1, len(components)):
            ancestor = "/".join(components[:length])
            if ancestor in seen_platform:
                raise ModelPreparationError(
                    "ZIP file entry collides with an ancestor path"
                )

    relative_paths = {
        PurePosixPath(*path.parts[1:]).as_posix(): info
        for info, path in checked
    }
    unexpected = sorted(
        path
        for path in relative_paths
        if path.split("/", 1)[0] not in {"Manifest.json", "Data"}
    )
    if unexpected:
        raise ModelPreparationError(
            "model package has unexpected root contents: " + ", ".join(unexpected)
        )
    required_model = "Data/com.apple.CoreML/model.mlmodel"
    if "Manifest.json" not in relative_paths or required_model not in relative_paths:
        raise ModelPreparationError(
            "model package must contain Manifest.json and " + required_model
        )
    if relative_paths["Manifest.json"].file_size > MAX_PACKAGE_MANIFEST_BYTES:
        raise ModelPreparationError("model package Manifest.json is too large")
    unexpected_data = sorted(
        path
        for path in relative_paths
        if path.startswith("Data/")
        and not path.startswith("Data/com.apple.CoreML/")
    )
    if unexpected_data:
        raise ModelPreparationError(
            "model package has unexpected Data contents: " + ", ".join(unexpected_data)
        )
    try:
        model_manifest = json.loads(
            archive.read(relative_paths["Manifest.json"]).decode("utf-8")
        )
    except (KeyError, UnicodeError, json.JSONDecodeError, RuntimeError, zipfile.BadZipFile) as error:
        raise ModelPreparationError("model package Manifest.json is invalid") from error
    if not isinstance(model_manifest, dict):
        raise ModelPreparationError("model package Manifest.json root is invalid")
    if not isinstance(model_manifest.get("rootModelIdentifier"), str):
        raise ModelPreparationError(
            "model package Manifest.json is missing rootModelIdentifier"
        )
    if not isinstance(model_manifest.get("itemInfoEntries"), dict):
        raise ModelPreparationError(
            "model package Manifest.json is missing itemInfoEntries"
        )
    return sorted(checked, key=lambda item: item[1].as_posix())


def _safe_destination(root: Path) -> tuple[Path, Path]:
    try:
        root_status = root.lstat()
    except OSError as error:
        raise ModelPreparationError(f"cannot inspect repository root: {error}") from error
    if stat.S_ISLNK(root_status.st_mode):
        raise ModelPreparationError("repository root must not be a symlink")
    if not stat.S_ISDIR(root_status.st_mode):
        raise ModelPreparationError("repository root must be a directory")
    resolved_root = root.resolve(strict=True)
    destination_relative = PurePosixPath(EXPECTED_DESTINATION)
    if destination_relative.is_absolute() or ".." in destination_relative.parts:
        raise ModelPreparationError("model destination is unsafe")
    destination = resolved_root.joinpath(*destination_relative.parts)
    try:
        destination.relative_to(resolved_root)
    except ValueError as error:
        raise ModelPreparationError("model destination escapes repository root") from error

    current = resolved_root
    for component in destination_relative.parts[:-1]:
        current = current / component
        try:
            status = current.lstat()
        except FileNotFoundError:
            try:
                current.mkdir(mode=0o755)
            except OSError as error:
                raise ModelPreparationError(
                    f"cannot create model destination parent: {error}"
                ) from error
            status = current.lstat()
        except OSError as error:
            raise ModelPreparationError(
                f"cannot inspect model destination parent: {error}"
            ) from error
        if stat.S_ISLNK(status.st_mode):
            raise ModelPreparationError("model destination has a symlink ancestor")
        if not stat.S_ISDIR(status.st_mode):
            raise ModelPreparationError("model destination ancestor is not a directory")
    try:
        destination_status = destination.lstat()
    except FileNotFoundError:
        pass
    except OSError as error:
        raise ModelPreparationError(f"cannot inspect model destination: {error}") from error
    else:
        if stat.S_ISLNK(destination_status.st_mode):
            raise ModelPreparationError("model destination must not be a symlink")
        if not stat.S_ISDIR(destination_status.st_mode):
            raise ModelPreparationError("model destination must be a directory")
    return resolved_root, destination


def _write_zip_entry(
    path: Path, archive: zipfile.ZipFile, info: zipfile.ZipInfo
) -> None:
    path.parent.mkdir(parents=True, exist_ok=True, mode=0o755)
    flags = os.O_WRONLY | os.O_CREAT | os.O_EXCL
    if hasattr(os, "O_NOFOLLOW"):
        flags |= os.O_NOFOLLOW
    descriptor = os.open(path, flags, 0o644)
    try:
        with os.fdopen(descriptor, "wb") as stream:
            byte_count = 0
            with archive.open(info, "r") as source:
                while True:
                    chunk = source.read(DOWNLOAD_CHUNK_BYTES)
                    if not chunk:
                        break
                    byte_count += len(chunk)
                    if byte_count > info.file_size:
                        raise ModelPreparationError(
                            "ZIP entry expands beyond its declared size"
                        )
                    stream.write(chunk)
            if byte_count != info.file_size:
                raise ModelPreparationError("ZIP entry size changed while reading")
    except BaseException:
        path.unlink(missing_ok=True)
        raise


def _install_archive(archive_stream, root: Path) -> Path:
    _resolved_root, destination = _safe_destination(root)
    parent = destination.parent
    staging = Path(tempfile.mkdtemp(prefix=".siglip-install-", dir=parent))
    staged_model = staging / EXPECTED_MODEL_ROOT
    backup: Path | None = None
    try:
        try:
            with zipfile.ZipFile(archive_stream) as archive:
                checked = _validate_zip(archive)
                for info, relative in checked:
                    target = staging.joinpath(*relative.parts)
                    try:
                        _write_zip_entry(target, archive, info)
                    except (OSError, RuntimeError, zipfile.BadZipFile) as error:
                        raise ModelPreparationError(
                            "cannot read verified model package ZIP entry"
                        ) from error
        except (OSError, zipfile.BadZipFile) as error:
            raise ModelPreparationError("cannot read model package ZIP") from error

        if not staged_model.is_dir():
            raise ModelPreparationError("model package staging root is missing")
        if destination.exists():
            backup_container = Path(
                tempfile.mkdtemp(prefix=".siglip-backup-", dir=parent)
            )
            backup_container.rmdir()
            backup = backup_container
            os.replace(destination, backup)
        try:
            os.replace(staged_model, destination)
        except BaseException:
            if backup is not None and backup.exists() and not destination.exists():
                os.replace(backup, destination)
                backup = None
            raise
        if backup is not None:
            shutil.rmtree(backup)
            backup = None
        return destination
    finally:
        if backup is not None and backup.exists() and not destination.exists():
            os.replace(backup, destination)
        if staging.exists():
            shutil.rmtree(staging)


def prepare_model(
    manifest_path: Path,
    archive_override: Path | None,
    root: Path,
) -> tuple[Path, str]:
    manifest = _load_manifest(manifest_path)
    downloaded: Path | None = None
    archive = archive_override
    if archive is None:
        downloaded = _download_archive(manifest["assetURL"], manifest["archiveBytes"])
        archive = downloaded
    try:
        with _open_regular_archive(archive) as archive_stream:
            digest = _verify_archive(archive_stream, manifest)
            installed = _install_archive(archive_stream, root)
            return installed, digest
    finally:
        if downloaded is not None:
            downloaded.unlink(missing_ok=True)


def _parser() -> argparse.ArgumentParser:
    default_root = Path(__file__).resolve().parents[1]
    parser = argparse.ArgumentParser(
        description="Verify and install the Hibi Lens SigLIP Core ML model."
    )
    parser.add_argument(
        "--manifest",
        type=Path,
        default=Path("ModelAssets/siglip-base-patch16-224-coreml.json"),
    )
    parser.add_argument("--archive", type=Path)
    parser.add_argument("--root", type=Path, default=default_root)
    return parser


def main(argv: Sequence[str] | None = None) -> int:
    arguments = _parser().parse_args(argv)
    manifest = arguments.manifest
    if not manifest.is_absolute():
        manifest = arguments.root / manifest
    try:
        installed, digest = prepare_model(manifest, arguments.archive, arguments.root)
    except (ModelPreparationError, OSError) as error:
        print(f"model preparation error: {error}", file=sys.stderr)
        return 1
    print(f"installed {installed} sha256={digest}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
