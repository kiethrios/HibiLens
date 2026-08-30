# Third-party notices

The items below keep their respective licenses. The repository's source code
license does not replace these terms.

## EDRDG and JMdict

The Japanese vocabulary data in
`Data/ObjectVocabulary/object_vocabulary_source.csv` and the generated
`JapCapture/Resources/object-vocabulary.json` include material derived from
JMdict. JMdict is maintained by the Electronic Dictionary Research and
Development Group (EDRDG) and is available under CC BY-SA 4.0.

Copyright (c) James William Breen and The Electronic Dictionary Research and Development Group.

- Project: https://www.edrdg.org/jmdict/j_jmdict.html
- License and attribution: https://www.edrdg.org/edrdg/licence.html
- Local license copy: [LICENSES/CC-BY-SA-4.0.txt](LICENSES/CC-BY-SA-4.0.txt)

Changes made for Hibi Lens include selecting entries, matching object labels,
and adding application-specific fields. Those changes do not alter the JMdict
license boundary.

## Open Images

`openimages-boxable-classes.csv` contains Open Images class descriptions
published by Google LLC. Its labels are used to select vocabulary concepts.
Open Images annotations and class descriptions are available under CC BY 4.0.
This repository does not include Open Images photos.

- Dataset page: https://storage.googleapis.com/openimages/web/download_v7.html
- Class-description source: https://storage.googleapis.com/openimages/v5/class-descriptions-boxable.csv
- Local license copy: [LICENSES/CC-BY-4.0.txt](LICENSES/CC-BY-4.0.txt)

## Google SigLIP

Hibi Lens uses Google SigLIP model `google/siglip-base-patch16-224`, pinned to
revision `7fd15f0689c79d79e38b1c2e2e2370a7bf2761ed`. The model and the derived
Core ML image encoder and text-embedding assets are covered by Apache 2.0.

- Pinned model source: https://huggingface.co/google/siglip-base-patch16-224/tree/7fd15f0689c79d79e38b1c2e2e2370a7bf2761ed
- Local license copy: [LICENSES/Apache-2.0.txt](LICENSES/Apache-2.0.txt)

The Hibi Lens source build downloads the Core ML package separately. See the
README model-preparation section before building the app.
