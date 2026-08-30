#!/usr/bin/env python3
import argparse
import json
import shutil
from pathlib import Path

import numpy as np
import torch
from transformers import AutoModel, AutoProcessor


REPO_ROOT = Path(__file__).resolve().parents[2]
DEFAULT_MODEL_REVISION = "main"


def log(message: str) -> None:
    print(f"[SigLIPExport] {message}", flush=True)


def load_object_vocabulary_labels(path: str) -> list[str]:
    vocabulary_path = Path(path).expanduser()
    resource = json.loads(vocabulary_path.read_text(encoding="utf-8"))
    concepts = resource.get("concepts", [])
    labels = []
    seen = set()
    for concept in concepts:
        label = concept.get("canonicalLabel", "").strip()
        if label and label not in seen:
            seen.add(label)
            labels.append(label)
    if not labels:
        raise ValueError(f"No canonical labels found in object vocabulary: {vocabulary_path}")
    return labels


def prompts_for(label: str) -> list[str]:
    return [
        f"A photo of a {label}",
        f"A close-up photo of a {label}",
        f"A picture of a {label}",
    ]


def normalize(vector: torch.Tensor) -> torch.Tensor:
    return vector / vector.norm(dim=-1, keepdim=True).clamp_min(1e-12)


def pooled_features(output) -> torch.Tensor:
    if isinstance(output, torch.Tensor):
        return output
    if hasattr(output, "pooler_output") and output.pooler_output is not None:
        return output.pooler_output
    if hasattr(output, "image_embeds") and output.image_embeds is not None:
        return output.image_embeds
    if hasattr(output, "text_embeds") and output.text_embeds is not None:
        return output.text_embeds
    raise TypeError(f"Unsupported SigLIP feature output: {type(output).__name__}")


def patch_coremltools_torch_cast() -> None:
    import coremltools.converters.mil.frontend.torch.ops as torch_ops

    original_cast = torch_ops._cast

    def patched_cast(context, node, dtype, dtype_name):
        inputs = torch_ops._get_inputs(context, node, expected=1)
        x = inputs[0]
        if not (len(x.shape) == 0 or np.all([d == 1 for d in x.shape])):
            raise ValueError("input to cast must be either a scalar or a length 1 tensor")

        if x.can_be_folded_to_const():
            value = x.val
            if isinstance(value, dtype):
                res = x
            else:
                array_value = np.asarray(value)
                if array_value.size == 1:
                    res = torch_ops.mb.const(val=dtype(array_value.item()), name=node.name)
                else:
                    target_dtype = np.bool_ if dtype is bool else np.int32
                    res = torch_ops.mb.const(val=array_value.astype(target_dtype), name=node.name)
        elif len(x.shape) > 0:
            x = torch_ops.mb.squeeze(x=x, name=node.name + "_item")
            res = torch_ops.mb.cast(x=x, dtype=dtype_name, name=node.name)
        else:
            res = torch_ops.mb.cast(x=x, dtype=dtype_name, name=node.name)
        context.add(res, node.name)

    torch_ops._cast = patched_cast
    log(f"patched coremltools torch cast: {original_cast.__name__}")


def export_image_encoder(model, output_path: str) -> None:
    import coremltools as ct

    patch_coremltools_torch_cast()
    log("tracing image encoder")

    class ImageEncoder(torch.nn.Module):
        def __init__(self, wrapped):
            super().__init__()
            self.wrapped = wrapped

        def forward(self, pixel_values):
            features = pooled_features(self.wrapped.get_image_features(pixel_values=pixel_values))
            return normalize(features)

    wrapped = ImageEncoder(model).eval()
    example = torch.zeros(1, 3, 224, 224)
    traced = torch.jit.trace(wrapped, example)

    output = Path(output_path).expanduser()
    output.parent.mkdir(parents=True, exist_ok=True)
    if output.exists():
        if output.is_dir():
            shutil.rmtree(output)
        else:
            output.unlink()
    log("converting image encoder to Core ML")
    mlmodel = ct.convert(
        traced,
        inputs=[ct.TensorType(name="pixel_values", shape=example.shape)],
        outputs=[ct.TensorType(name="image_embeds")],
        convert_to="mlprogram",
        minimum_deployment_target=ct.target.iOS17,
    )
    mlmodel.save(str(output))
    log(f"wrote image model: {output}")


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("--model-id", default="google/siglip-base-patch16-224")
    parser.add_argument(
        "--revision",
        default=DEFAULT_MODEL_REVISION,
        help="Hugging Face model revision or commit hash.",
    )
    parser.add_argument(
        "--output-json",
        default=str(REPO_ROOT / "JapCapture/Resources/siglip-object-vocabulary-text-embeddings.json"),
    )
    parser.add_argument(
        "--object-vocabulary",
        default=str(REPO_ROOT / "JapCapture/Resources/object-vocabulary.json"),
        help="App object-vocabulary JSON containing concepts[].canonicalLabel.",
    )
    parser.add_argument(
        "--output-image-model",
        default=str(REPO_ROOT / "JapCapture/Models/SigLIP/siglip_base_patch16_224_image.mlpackage"),
    )
    args = parser.parse_args()

    labels = load_object_vocabulary_labels(args.object_vocabulary)
    log(f"loaded {len(labels)} object vocabulary labels")
    log(f"loading processor: {args.model_id}@{args.revision}")
    processor = AutoProcessor.from_pretrained(args.model_id, revision=args.revision)
    log(f"loading model: {args.model_id}@{args.revision}")
    model = AutoModel.from_pretrained(
        args.model_id,
        revision=args.revision,
        attn_implementation="eager",
    ).eval()
    log("computing text embeddings")

    items = []
    with torch.no_grad():
        for label in labels:
            prompts = prompts_for(label)
            inputs = processor(text=prompts, padding="max_length", return_tensors="pt")
            text_features = pooled_features(model.get_text_features(**inputs))
            text_features = normalize(text_features)
            averaged = normalize(text_features.mean(dim=0, keepdim=True))[0]
            items.append({
                "label": label,
                "prompts": prompts,
                "embedding": [float(value) for value in averaged.cpu().tolist()],
            })

    output = {
        "modelID": args.model_id,
        "modelRevision": args.revision,
        "license": "apache-2.0",
        "embeddingDimension": len(items[0]["embedding"]),
        "items": items,
    }

    output_path = Path(args.output_json).expanduser()
    output_path.parent.mkdir(parents=True, exist_ok=True)
    output_path.write_text(json.dumps(output, indent=2, ensure_ascii=False) + "\n", encoding="utf-8")
    log(f"wrote text embeddings: {output_path}")

    export_image_encoder(model, args.output_image_model)


if __name__ == "__main__":
    main()
