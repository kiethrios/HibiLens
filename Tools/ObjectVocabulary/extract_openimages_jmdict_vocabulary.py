#!/usr/bin/env python3
import argparse
import csv
import gzip
import re
import xml.etree.ElementTree as ET
from pathlib import Path

FIELDNAMES = [
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

BROAD_OR_LOW_VALUE_LABELS = {
    "animal",
    "auto part",
    "bathroom accessory",
    "baked goods",
    "building",
    "clothing",
    "dairy product",
    "dessert",
    "drink",
    "fashion accessory",
    "food",
    "fruit",
    "furniture",
    "kitchenware",
    "man",
    "musical instrument",
    "office supplies",
    "person",
    "personal care",
    "plant",
    "sports equipment",
    "tableware",
    "vehicle",
    "vegetable",
    "weapon",
    "woman",
}

DOMAIN_KEYWORDS = [
    ("animals", {"alpaca", "ant", "bear", "bee", "bird", "cat", "dog", "fish", "horse", "zebra"}),
    ("food", {"apple", "banana", "bread", "cake", "cheese", "pizza", "sandwich", "zucchini"}),
    ("vehicles", {"aircraft", "ambulance", "barge", "bicycle", "boat", "bus", "car", "train", "truck"}),
    ("electronics", {"camera", "computer", "keyboard", "laptop", "phone", "remote", "tablet", "television"}),
    ("home", {"bed", "chair", "clock", "door", "lamp", "mirror", "pillow", "sofa", "table", "window"}),
    ("kitchen", {"bottle", "bowl", "cup", "fork", "knife", "mug", "plate", "spoon", "wine"}),
    ("tools", {"axe", "drill", "hammer", "ladder", "saw", "screwdriver", "wrench"}),
    ("clothing", {"belt", "boot", "dress", "glove", "hat", "helmet", "shirt", "shoe", "sock"}),
    ("sports", {"ball", "bat", "racket", "skateboard", "ski", "surfboard"}),
]

COMMON_PRIORITY_PREFIXES = ("ichi", "news", "spec", "gai", "nf")

PREFERRED_JMDICT_SEQ_BY_TERM = {
    "ball": "1123550",
    "bed": "1119650",
    "belt": "1120070",
    "box": "1585650",
    "cake": "1047860",
    "coin": "1280530",
    "cosmetics": "1187110",
    "crown": "1181450",
    "crutch": "1349960",
    "dress": "1089280",
    "drill": "1089070",
    "fork": "1110110",
    "lamp": "1140360",
    "pen": "1121380",
    "table": "1078630",
    "tie": "1092820",
}

HIRAGANA_ROMAJI = {
    "あ": "a", "い": "i", "う": "u", "え": "e", "お": "o",
    "か": "ka", "き": "ki", "く": "ku", "け": "ke", "こ": "ko",
    "さ": "sa", "し": "shi", "す": "su", "せ": "se", "そ": "so",
    "た": "ta", "ち": "chi", "つ": "tsu", "て": "te", "と": "to",
    "な": "na", "に": "ni", "ぬ": "nu", "ね": "ne", "の": "no",
    "は": "ha", "ひ": "hi", "ふ": "fu", "へ": "he", "ほ": "ho",
    "ま": "ma", "み": "mi", "む": "mu", "め": "me", "も": "mo",
    "や": "ya", "ゆ": "yu", "よ": "yo",
    "ら": "ra", "り": "ri", "る": "ru", "れ": "re", "ろ": "ro",
    "わ": "wa", "を": "o", "ん": "n",
    "が": "ga", "ぎ": "gi", "ぐ": "gu", "げ": "ge", "ご": "go",
    "ざ": "za", "じ": "ji", "ず": "zu", "ぜ": "ze", "ぞ": "zo",
    "だ": "da", "ぢ": "ji", "づ": "zu", "で": "de", "ど": "do",
    "ば": "ba", "び": "bi", "ぶ": "bu", "べ": "be", "ぼ": "bo",
    "ぱ": "pa", "ぴ": "pi", "ぷ": "pu", "ぺ": "pe", "ぽ": "po",
    "ぁ": "a", "ぃ": "i", "ぅ": "u", "ぇ": "e", "ぉ": "o",
}

DIGRAPHS = {
    "きゃ": "kya", "きゅ": "kyu", "きょ": "kyo",
    "しゃ": "sha", "しゅ": "shu", "しょ": "sho",
    "ちゃ": "cha", "ちゅ": "chu", "ちょ": "cho",
    "にゃ": "nya", "にゅ": "nyu", "にょ": "nyo",
    "ひゃ": "hya", "ひゅ": "hyu", "ひょ": "hyo",
    "みゃ": "mya", "みゅ": "myu", "みょ": "myo",
    "りゃ": "rya", "りゅ": "ryu", "りょ": "ryo",
    "ぎゃ": "gya", "ぎゅ": "gyu", "ぎょ": "gyo",
    "じゃ": "ja", "じゅ": "ju", "じょ": "jo",
    "びゃ": "bya", "びゅ": "byu", "びょ": "byo",
    "ぴゃ": "pya", "ぴゅ": "pyu", "ぴょ": "pyo",
    "ふぁ": "fa", "ふぃ": "fi", "ふぇ": "fe", "ふぉ": "fo",
    "てぃ": "ti", "でぃ": "di", "うぃ": "wi", "うぇ": "we", "うぉ": "wo",
}


def normalize_label(value):
    value = re.sub(r"\s*\([^)]*\)", "", value.strip())
    value = value.replace("&", " and ")
    return " ".join(value.lower().split())


def singularize(label):
    if label.endswith("ies"):
        return label[:-3] + "y"
    if label.endswith(("ses", "xes", "ches", "shes")):
        return label[:-2]
    if label.endswith("s") and not label.endswith("ss"):
        return label[:-1]
    return label


def concept_id_for(label):
    return re.sub(r"[^a-z0-9]+", "_", normalize_label(label)).strip("_")


def domain_for(label):
    tokens = set(normalize_label(label).split())
    for domain, keywords in DOMAIN_KEYWORDS:
        if tokens & keywords:
            return domain
    return "objects"


def katakana_to_hiragana(text):
    chars = []
    for char in text:
        code = ord(char)
        if 0x30A1 <= code <= 0x30F6:
            chars.append(chr(code - 0x60))
        else:
            chars.append(char)
    return "".join(chars)


def romanize(kana):
    text = katakana_to_hiragana(kana)
    output = []
    index = 0
    double_next = False
    while index < len(text):
        char = text[index]
        pair = text[index:index + 2]
        if char == "っ":
            double_next = True
            index += 1
            continue
        if char == "ー":
            if output:
                output[-1] += output[-1][-1]
            index += 1
            continue
        if pair in DIGRAPHS:
            value = DIGRAPHS[pair]
            index += 2
        else:
            value = HIRAGANA_ROMAJI.get(char, "")
            index += 1
        if value:
            if double_next:
                value = value[0] + value
                double_next = False
            output.append(value)
    return "".join(output)


def normalized_gloss_parts(glosses):
    parts = []
    for gloss in glosses:
        cleaned = normalize_label(gloss)
        parts.extend(normalize_label(part) for part in re.split(r"[;,/]", cleaned) if normalize_label(part))
    return parts


def has_noun_pos(pos_values):
    return any("noun" in value for value in pos_values)


def priority_score(priority_values):
    score = 0
    for value in priority_values:
        if value.startswith("ichi"):
            score += 80
        elif value.startswith("news"):
            score += 70
        elif value.startswith("spec"):
            score += 50
        elif value.startswith("gai"):
            score += 30
        elif value.startswith("nf"):
            score += 20
    return score


def parse_openimages(path):
    labels = []
    with path.open(newline="", encoding="utf-8") as handle:
        for row in csv.DictReader(handle):
            canonical = normalize_label(row["DisplayName"])
            if not canonical or canonical in BROAD_OR_LOW_VALUE_LABELS or canonical.startswith("human "):
                continue
            labels.append({
                "display": row["DisplayName"],
                "canonical": canonical,
                "singular": singularize(canonical),
            })
    return labels


def parse_existing_source(path):
    if not path.exists():
        return {}
    with path.open(newline="", encoding="utf-8") as handle:
        return {row["concept_id"]: row for row in csv.DictReader(handle)}


def collect_jmdict_matches(path, terms):
    matches = {term: [] for term in terms}
    with gzip.open(path, "rb") as handle:
        for _, entry in ET.iterparse(handle, events=("end",)):
            if entry.tag != "entry":
                continue

            seq = entry.findtext("ent_seq") or ""
            kebs = [element.findtext("keb") for element in entry.findall("k_ele") if element.findtext("keb")]
            rebs = [element.findtext("reb") for element in entry.findall("r_ele") if element.findtext("reb")]
            priorities = [element.text for element in entry.findall(".//ke_pri") + entry.findall(".//re_pri") if element.text]
            japanese = (kebs or rebs or [""])[0]
            kana = (rebs or [japanese])[0]

            for sense in entry.findall("sense"):
                pos_values = [element.text or "" for element in sense.findall("pos")]
                if not has_noun_pos(pos_values):
                    continue

                glosses = [element.text for element in sense.findall("gloss") if element.text]
                gloss_parts = normalized_gloss_parts(glosses)
                for term in set(gloss_parts) & terms:
                    matches[term].append({
                        "seq": seq,
                        "japanese": japanese,
                        "kana": kana,
                        "glosses": gloss_parts,
                        "priorityScore": priority_score(priorities),
                    })

            entry.clear()
    return matches


def candidate_sort_key(term, candidate):
    glosses = candidate["glosses"]
    try:
        exact_gloss_index = glosses.index(term)
    except ValueError:
        exact_gloss_index = 99
    native_script = 1 if any("\u4e00" <= char <= "\u9fff" for char in candidate["japanese"]) else 0
    return (
        0 if candidate["seq"] == PREFERRED_JMDICT_SEQ_BY_TERM.get(term) else 1,
        exact_gloss_index,
        -candidate["priorityScore"],
        -native_script,
        len(candidate["japanese"]),
        candidate["seq"],
    )


def make_aliases(canonical):
    aliases = {canonical}
    singular = singularize(canonical)
    aliases.add(singular)
    tokens = canonical.split()
    if len(tokens) > 1:
        aliases.add(tokens[-1])
    return ",".join(sorted(aliases))


def build_rows(openimages_labels, existing_rows, matches):
    rows = list(existing_rows.values())
    seen_concepts = set(existing_rows.keys())

    for label in openimages_labels:
        concept_id = concept_id_for(label["canonical"])
        if concept_id in seen_concepts:
            continue
        seen_concepts.add(concept_id)

        term = label["canonical"] if matches.get(label["canonical"]) else label["singular"]
        candidates = matches.get(term, [])
        if not candidates:
            continue

        best = sorted(candidates, key=lambda candidate: candidate_sort_key(term, candidate))[0]
        priority = max(45, min(89, 70 + best["priorityScore"] // 10))
        english = label["canonical"]
        rows.append({
            "concept_id": concept_id,
            "domain": domain_for(english),
            "canonical_label": english,
            "aliases": make_aliases(english),
            "jmdict_seq": best["seq"],
            "japanese": best["japanese"],
            "kana": best["kana"],
            "romaji": romanize(best["kana"]),
            "english": english,
            "zh_hans": "",
            "part_of_speech": "noun",
            "concept_priority": str(priority),
            "candidate_priority": str(priority),
            "source_notes": "auto_openimages_jmdict_exact_gloss_zh_pending",
        })

    return sorted(rows, key=lambda row: (-int(row["concept_priority"]), row["concept_id"]))


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--openimages", type=Path, required=True)
    parser.add_argument("--jmdict", type=Path, required=True)
    parser.add_argument("--existing-source", type=Path)
    parser.add_argument("--output", type=Path, required=True)
    args = parser.parse_args()

    openimages_labels = parse_openimages(args.openimages)
    existing_rows = parse_existing_source(args.existing_source) if args.existing_source else {}
    terms = {label["canonical"] for label in openimages_labels} | {label["singular"] for label in openimages_labels}
    matches = collect_jmdict_matches(args.jmdict, terms)
    rows = build_rows(openimages_labels, existing_rows, matches)

    args.output.parent.mkdir(parents=True, exist_ok=True)
    with args.output.open("w", newline="", encoding="utf-8") as handle:
        writer = csv.DictWriter(handle, fieldnames=FIELDNAMES)
        writer.writeheader()
        writer.writerows(rows)

    print(f"openimages_labels={len(openimages_labels)}")
    print(f"source_rows={len(rows)}")


if __name__ == "__main__":
    main()
