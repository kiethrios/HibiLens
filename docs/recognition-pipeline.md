# Local recognition pipeline

Hibi Lens recognizes objects on the device. Photos and image embeddings do not
need to leave the device for this flow.

## Vocabulary sources

The public vocabulary starts with two reviewed source files:

- `openimages-boxable-classes.csv` supplies Open Images object labels.
- `Data/ObjectVocabulary/object_vocabulary_source.csv` contains the selected
  concepts and their JMdict-backed Japanese entries.

`Tools/ObjectVocabulary/extract_openimages_jmdict_vocabulary.py` can rebuild the
review CSV from an Open Images class-description file and a JMdict XML archive.
The JMdict archive is an external input and is not stored in this repository.

`Tools/ObjectVocabulary/generate_object_vocabulary.py` validates the reviewed
CSV and writes `JapCapture/Resources/object-vocabulary.json`, which the app uses
for Japanese terms and aliases.

## SigLIP assets

The classifier uses `google/siglip-base-patch16-224` at revision
`7fd15f0689c79d79e38b1c2e2e2370a7bf2761ed`.

The public repository includes
`JapCapture/Resources/siglip-object-vocabulary-text-embeddings.json`. It is the
text index for the object vocabulary. The large Core ML image encoder is kept
outside Git history. Install it before opening the Xcode project:

```bash
python3 scripts/prepare_siglip_model.py
```

The script installs the checked package at
`JapCapture/Models/SigLIP/siglip_base_patch16_224_image.mlpackage`.

Maintainers can regenerate the text index and Core ML model with
`Tools/SigLIP/export_siglip_assets.py` and the pinned Python dependencies in
`Tools/SigLIP/requirements.txt`.

## Runtime flow

The app normalizes a captured or selected image, runs the Core ML SigLIP image
encoder, and compares the resulting vector with the bundled text embeddings.
The best matching label is resolved through `object-vocabulary.json` and used
to create the Japanese vocabulary card. Recognition, saved cards, and study
progress remain on the device.

## Licenses

- JMdict-derived vocabulary material is CC BY-SA 4.0.
- Open Images class-description material is CC BY 4.0.
- SigLIP and its derived model assets are Apache 2.0.

Source links, attribution, and local license copies are in
[`THIRD_PARTY_NOTICES.md`](../THIRD_PARTY_NOTICES.md).
