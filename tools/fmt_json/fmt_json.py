"""Formats the JSON data files in project/data, as gdformat does for GDScript.

The format: tab indentation, as the Godot editor writes JSON. An array that has
only numbers, strings, or short arrays of them stays on one line when it fits in
LINE_LIMIT characters, for example a shape [[0, 0], [1, 0]]. The key order does
not change. Non-ASCII text stays as it is.

Run it from the repository root: task fmt
With --check, it changes nothing and fails if a file is not formatted.
"""

import json
import sys
from pathlib import Path

DATA = Path("project/data")
LINE_LIMIT = 80


def scalar(v):
    return not isinstance(v, (dict, list))


def inline(v):
    """Returns the one-line text of a value, or None if it must not be on one line."""
    if scalar(v):
        return json.dumps(v, ensure_ascii=False)
    if isinstance(v, list) and all(scalar(x) or (isinstance(x, list) and all(scalar(y) for y in x)) for x in v):
        return json.dumps(v, ensure_ascii=False, separators=(", ", ": "))
    return None


def render(v, depth=0):
    pad = "\t" * (depth + 1)
    end = "\t" * depth
    one = inline(v)
    # A number or a string is always on one line, also when it is long.
    if scalar(v) or (one is not None and len(one) + depth * 4 <= LINE_LIMIT):
        return one
    if isinstance(v, dict):
        if not v:
            return "{}"
        items = [f"{pad}{json.dumps(k, ensure_ascii=False)}: {render(x, depth + 1)}" for k, x in v.items()]
        return "{\n" + ",\n".join(items) + "\n" + end + "}"
    if not v:
        return "[]"
    items = [pad + render(x, depth + 1) for x in v]
    return "[\n" + ",\n".join(items) + "\n" + end + "]"


def main():
    check = "--check" in sys.argv
    stale = []
    for path in sorted(DATA.rglob("*.json")):
        old = path.read_text(encoding="utf-8")
        new = render(json.loads(old)) + "\n"
        if old == new:
            continue
        if check:
            stale.append(path)
            continue
        path.write_text(new, encoding="utf-8")
        print(f"fmt_json: wrote {path}")
    for path in stale:
        print(f"fmt_json: {path} is not formatted. Run: task fmt", file=sys.stderr)
    sys.exit(1 if stale else 0)


if __name__ == "__main__":
    main()
