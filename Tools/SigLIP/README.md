# SigLIP Asset Export

This tool generates the bundled object-vocabulary text-embedding resource and
Core ML image encoder model for the SigLIP classifier.

Initial target model:

- `google/siglip-base-patch16-224`
- license shown on Hugging Face: `apache-2.0`

Run from the repository root:

```bash
python3.12 -m venv .venv
./.venv/bin/pip install -r Tools/SigLIP/requirements.txt
./.venv/bin/python Tools/SigLIP/export_siglip_assets.py
```

The default output path is resolved from the repository root, so the script can
also be run from another working directory.

The first run downloads the Hugging Face model and Python wheels. Keep the
requirements file pinned when regenerating bundled embeddings so the generated
JSON is reproducible.

For fully reproducible assets, pass a Hugging Face commit hash instead of the
default branch name:

```bash
./.venv/bin/python Tools/SigLIP/export_siglip_assets.py --revision <commit-sha>
```

The script writes:

```text
JapCapture/Resources/siglip-object-vocabulary-text-embeddings.json
JapCapture/Models/SigLIP/siglip_base_patch16_224_image.mlpackage
```

Core ML conversion requires `coremltools` and may take time because it traces
the image encoder and can download model files on the first run.

The exporter pins `torch==2.5.0` because `coremltools==8.3.0` lists it as the
latest tested Torch release. Newer Torch releases may install successfully but
can produce converter graph errors for SigLIP's vision attention-pooling head.

Useful overrides:

```bash
./.venv/bin/python Tools/SigLIP/export_siglip_assets.py \
  --model-id google/siglip-base-patch16-224 \
  --revision main \
  --object-vocabulary JapCapture/Resources/object-vocabulary.json \
  --output-json JapCapture/Resources/siglip-object-vocabulary-text-embeddings.json \
  --output-image-model JapCapture/Models/SigLIP/siglip_base_patch16_224_image.mlpackage
```
