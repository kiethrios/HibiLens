#!/usr/bin/env python3
import csv
import json
import sys
from collections import defaultdict
from pathlib import Path

REQUIRED_COLUMNS = [
    "concept_id",
    "domain",
    "canonical_label",
    "aliases",
    "jmdict_seq",
    "japanese",
    "kana",
    "romaji",
    "english",
    "zh_hans",
    "part_of_speech",
    "concept_priority",
    "candidate_priority",
    "source_notes",
]


def normalize_label(value):
    return " ".join(value.strip().lower().replace("_", " ").split())


def parse_priority(value, row_number, column):
    try:
        return int(value)
    except ValueError as error:
        raise ValueError(f"row {row_number}: {column} must be an integer") from error


def read_rows(source_path):
    with source_path.open(newline="", encoding="utf-8") as handle:
        reader = csv.DictReader(handle)
        missing = [column for column in REQUIRED_COLUMNS if column not in (reader.fieldnames or [])]
        if missing:
            raise ValueError(f"missing required columns: {', '.join(missing)}")

        rows = []
        for row_number, row in enumerate(reader, start=2):
            for column in REQUIRED_COLUMNS:
                if column == "zh_hans":
                    continue
                if not row[column].strip():
                    raise ValueError(f"row {row_number}: {column} is required")
            if not row["jmdict_seq"].isdigit():
                raise ValueError(f"row {row_number}: jmdict_seq must be numeric")
            rows.append((row_number, row))
        return rows


def build_resource(rows):
    concepts_by_id = {}
    aliases = defaultdict(list)
    seen_aliases = {}

    for row_number, row in rows:
        concept_id = row["concept_id"].strip()
        canonical_label = normalize_label(row["canonical_label"])
        concept_priority = parse_priority(row["concept_priority"], row_number, "concept_priority")
        candidate_priority = parse_priority(row["candidate_priority"], row_number, "candidate_priority")

        concept = concepts_by_id.setdefault(
            concept_id,
            {
                "id": concept_id,
                "domain": row["domain"].strip(),
                "canonicalLabel": canonical_label,
                "priority": concept_priority,
                "candidates": [],
            },
        )

        candidate = {
            "jmdictSeq": row["jmdict_seq"].strip(),
            "japanese": row["japanese"].strip(),
            "kana": row["kana"].strip(),
            "romaji": row["romaji"].strip(),
            "english": row["english"].strip(),
            "zhHans": row["zh_hans"].strip(),
            "partOfSpeech": [part.strip() for part in row["part_of_speech"].split("|") if part.strip()],
            "priority": candidate_priority,
        }
        concept["candidates"].append(candidate)

        alias_values = [canonical_label]
        alias_values.extend(normalize_label(value) for value in row["aliases"].split(",") if value.strip())
        for alias in sorted(set(alias_values)):
            existing = seen_aliases.get((alias, concept_id))
            if existing is not None:
                raise ValueError(f"row {row_number}: duplicate alias '{alias}' for concept '{concept_id}'")
            seen_aliases[(alias, concept_id)] = row_number
            if concept_id not in aliases[alias]:
                aliases[alias].append(concept_id)

    return {
        "version": 1,
        "sources": [
            {
                "name": "JMdict",
                "license": "CC-BY-SA-4.0",
                "url": "https://www.edrdg.org/",
            },
            {
                "name": "Open Images V7 class descriptions",
                "license": "CC-BY-4.0",
                "url": "https://storage.googleapis.com/openimages/web/download_v7.html",
            },
        ],
        "aliases": dict(sorted(aliases.items())),
        "concepts": sorted(concepts_by_id.values(), key=lambda item: (-item["priority"], item["id"])),
    }


def main(argv):
    if len(argv) != 3:
        print("usage: generate_object_vocabulary.py SOURCE_CSV OUTPUT_JSON", file=sys.stderr)
        return 2

    source_path = Path(argv[1])
    output_path = Path(argv[2])
    resource = build_resource(read_rows(source_path))
    output_path.parent.mkdir(parents=True, exist_ok=True)
    output_path.write_text(
        json.dumps(resource, ensure_ascii=False, indent=2, sort_keys=True) + "\n",
        encoding="utf-8",
    )
    return 0


if __name__ == "__main__":
    raise SystemExit(main(sys.argv))
