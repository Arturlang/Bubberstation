#!/usr/bin/env python3
"""Compare two skin state dumps produced by the "Dump Skin State" debug verb.

The dumps record what each engine reported through winget() for every skin element.
This script normalises the values that are formatted differently but mean the same
thing, then reports what genuinely differs.

    python tools/winget_parity/compare_skin_dumps.py \
        data/winget_parity_byond.json data/winget_parity_opendream.json

Exit status is 1 when any difference survives normalisation, so it can gate CI.
"""

from __future__ import annotations

import argparse
import json
import re
import sys
from typing import Any

# Params whose value is conceptually a boolean. BYOND and OpenDream disagree on
# whether to spell these "true"/"false" or "1"/"0".
BOOL_PARAMS = {
    "is-visible", "is-disabled", "is-pane", "is-maximized", "is-minimized",
    "can-resize", "titlebar", "statusbar", "show-splitter", "is-vert",
    "is-flat", "is-checked", "is-multi-line", "no-command", "letterbox",
    "is-list", "show-lines", "is-slider", "auto-format", "show-history",
}

# Params holding one or more numbers, e.g. "640x480", "12,34", "0,0".
VECTOR_PARAMS = {
    "pos", "size", "anchor1", "anchor2", "inner-size", "outer-size",
    "view-size", "icon-size",
}

# Params holding a single number.
NUMERIC_PARAMS = {"splitter", "zoom", "value", "width", "max-lines", "dir", "current-tab"}

COLOR_PARAMS = {"background-color", "tab-text-color", "highlight-color"}

# Differences here are environmental rather than skin bugs.
IGNORED_TOP_LEVEL = {"engine", "byond_version", "dm_version", "dpi"}

NUMBER_RE = re.compile(r"-?\d+(?:\.\d+)?")


def normalise(param: str, raw: Any) -> Any:
    """Reduce a winget value to a form comparable across engines."""
    if raw is None:
        return None

    text = str(raw).strip()

    if param in BOOL_PARAMS:
        lowered = text.lower()
        if lowered in ("true", "1"):
            return True
        if lowered in ("false", "0", ""):
            return False
        return lowered

    if param in COLOR_PARAMS:
        lowered = text.lower()
        if lowered in ("", "none", "null"):
            return None
        if re.fullmatch(r"#[0-9a-f]{3}", lowered):  # #rgb -> #rrggbb
            return "#" + "".join(ch * 2 for ch in lowered[1:])
        return lowered

    if param in VECTOR_PARAMS or param in NUMERIC_PARAMS:
        numbers = [round(float(n), 3) for n in NUMBER_RE.findall(text)]
        if not numbers:
            return text.lower() or None
        # Trailing zeroes are meaningless: "640x480" == "640x480.0".
        return numbers

    if text == "":
        return None

    return text


def compare_elements(left: dict, right: dict, left_name: str, right_name: str) -> list[str]:
    findings: list[str] = []

    left_elements = left.get("elements", {})
    right_elements = right.get("elements", {})

    only_left = sorted(set(left_elements) - set(right_elements))
    only_right = sorted(set(right_elements) - set(left_elements))

    for element_id in only_left:
        findings.append(f"[missing element] {element_id!r} present in {left_name}, absent in {right_name}")
    for element_id in only_right:
        findings.append(f"[extra element]   {element_id!r} present in {right_name}, absent in {left_name}")

    for element_id in sorted(set(left_elements) & set(right_elements)):
        left_params = left_elements[element_id] or {}
        right_params = right_elements[element_id] or {}

        for param in sorted(set(left_params) | set(right_params)):
            left_value = normalise(param, left_params.get(param))
            right_value = normalise(param, right_params.get(param))

            if left_value == right_value:
                continue

            findings.append(
                f"[{element_id}] {param}: "
                f"{left_name}={left_params.get(param)!r} ({left_value!r})  "
                f"{right_name}={right_params.get(param)!r} ({right_value!r})"
            )

    return findings


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__,
                                     formatter_class=argparse.RawDescriptionHelpFormatter)
    parser.add_argument("left", help="first dump (conventionally the BYOND one)")
    parser.add_argument("right", help="second dump (conventionally the OpenDream one)")
    parser.add_argument("--allow-size-mismatch", action="store_true",
                        help="compare even if the dumps were taken at different window sizes")
    args = parser.parse_args()

    with open(args.left, encoding="utf-8") as handle:
        left = json.load(handle)
    with open(args.right, encoding="utf-8") as handle:
        right = json.load(handle)

    left_name = left.get("engine", "left")
    right_name = right.get("engine", "right")

    print(f"Comparing {left_name} ({args.left}) against {right_name} ({args.right})")
    for key in sorted(IGNORED_TOP_LEVEL):
        if key in left or key in right:
            print(f"  {key}: {left.get(key)!r} vs {right.get(key)!r}")

    # Anchoring makes almost every value size-dependent, so comparing dumps taken at
    # different window sizes produces differences that mean nothing.
    left_size = normalise("size", left.get("reference_window_size"))
    right_size = normalise("size", right.get("reference_window_size"))
    if left_size != right_size:
        message = (f"reference window size differs: {left.get('reference_window_size')!r} "
                   f"vs {right.get('reference_window_size')!r}")
        if not args.allow_size_mismatch:
            print(f"\nRefusing to compare: {message}.")
            print("Re-take both dumps at the same window size, or pass --allow-size-mismatch.")
            return 2
        print(f"\nWARNING: {message} - geometry differences below are probably not real.")

    findings = compare_elements(left, right, left_name, right_name)

    element_count = len(set(left.get("elements", {})) | set(right.get("elements", {})))
    print(f"\n{element_count} elements compared, {len(findings)} difference(s)\n")

    for finding in findings:
        print(finding)

    return 1 if findings else 0


if __name__ == "__main__":
    sys.exit(main())
