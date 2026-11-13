"""Collects the text for translation (CLAUDE.md: translate all text for the player).

It reads the GDScript code, the scenes, and the data files. It writes the
template project/locale/messages.pot. Then it updates each project/locale/*.po
file: it keeps the translations that it can use, adds new text without a
translation, and removes old text.

The text is:
- the literal argument of tr("...") in GDScript;
- each constant whose name ends with _TEXT: a string, a triple-quoted string,
  a dictionary of strings, or an array of strings;
- the "text" property of a scene node;
- the data keys "name", "text", and keys that end with "_name".

The text player (project/tools) and the tests (project/tests) are not for the
player, so the tool skips them.

Run it from the repository root: task i18n
With --check, it changes nothing and fails if a file is not up to date.

It fails when zh_TW.po uses a word of mainland China from
tools/i18n/zh_tw_avoid.json (SPEC Section 4.1).
"""

import json
import re
import sys
from pathlib import Path

PROJECT = Path("project")
LOCALE = PROJECT / "locale"
POT = LOCALE / "messages.pot"
AVOID = Path("tools/i18n/zh_tw_avoid.json")
SKIP_DIRS = {"tests", "tools", ".godot", "addons"}
DATA_KEYS = {"name", "text"}

TR_CALL = re.compile(r'\btr\(\s*"((?:[^"\\]|\\.)*)"\s*\)')
CONST_TEXT = re.compile(r"^const [A-Z0-9_]+_TEXT\b[^=]*:?=\s*(.*)$")
STRING = re.compile(r'"((?:[^"\\]|\\.)*)"')
SCENE_TEXT = re.compile(r'^text = "((?:[^"\\]|\\.)*)"', re.M)


class Catalog:
    def __init__(self):
        self.ids = []
        self.sources = {}

    def add(self, text, source):
        if not text.strip():
            return
        if text not in self.sources:
            self.ids.append(text)
            self.sources[text] = []
        if source not in self.sources[text]:
            self.sources[text].append(source)


def unescape(s):
    out, i = [], 0
    while i < len(s):
        ch = s[i]
        if ch == "\\" and i + 1 < len(s):
            nxt = s[i + 1]
            out.append({"n": "\n", "t": "\t"}.get(nxt, nxt))
            i += 2
            continue
        out.append(ch)
        i += 1
    return "".join(out)


def skipped(path):
    return any(part in SKIP_DIRS for part in path.relative_to(PROJECT).parts)


def collect_gd(cat, path):
    src = path.read_text(encoding="utf-8")
    rel = path.as_posix()
    for m in TR_CALL.finditer(src):
        cat.add(unescape(m.group(1)), rel)
    lines = src.split("\n")
    i = 0
    while i < len(lines):
        m = CONST_TEXT.match(lines[i])
        if not m:
            i += 1
            continue
        value = m.group(1).strip()
        if value.startswith('"""'):
            body = value[3:]
            while '"""' not in body and i + 1 < len(lines):
                i += 1
                body += "\n" + lines[i]
            cat.add(body.split('"""')[0], rel)
        elif value.startswith("{") or value.startswith("["):
            closing = "}" if value.startswith("{") else "]"
            block = value
            while not block.rstrip().endswith(closing) and i + 1 < len(lines):
                i += 1
                block += "\n" + lines[i]
            # In a dictionary, take the values only: the text after each ":".
            for part in re.finditer(r'(?::\s*|[\[,]\s*|^\s*)"((?:[^"\\]|\\.)*)"', block, re.M):
                key_like = block[part.end():].lstrip().startswith(":")
                if not key_like:
                    cat.add(unescape(part.group(1)), rel)
        else:
            s = STRING.match(value)
            if s:
                cat.add(unescape(s.group(1)), rel)
        i += 1


def collect_scene(cat, path):
    for m in SCENE_TEXT.finditer(path.read_text(encoding="utf-8")):
        cat.add(unescape(m.group(1)), path.as_posix())


def collect_data(cat, path):
    rel = path.as_posix()

    def walk(value, key=""):
        if isinstance(value, dict):
            for k in sorted(value):
                walk(value[k], k)
        elif isinstance(value, list):
            for v in value:
                walk(v, key)
        elif isinstance(value, str) and (key in DATA_KEYS or key.endswith("_name")):
            cat.add(value, rel)

    walk(json.loads(path.read_text(encoding="utf-8")))


def quote(s):
    return '"' + s.replace("\\", "\\\\").replace('"', '\\"').replace("\n", "\\n").replace("\t", "\\t") + '"'


def write_string(out, keyword, s):
    if "\n" not in s or s == "\n":
        out.append(f"{keyword} {quote(s)}")
        return
    out.append(f'{keyword} ""')
    for part in s.splitlines(keepends=True):
        out.append(quote(part))


def render(cat, lang, po):
    out = ["# Payload Protocol translation" + ("" if lang else " template. Do not edit. Run: task i18n")]
    out.append('msgid ""')
    out.append('msgstr ""')
    out.append('"Content-Type: text/plain; charset=UTF-8\\n"')
    if lang:
        out.append(f'"Language: {lang}\\n"')
    for text in cat.ids:
        out.append("")
        for src in cat.sources[text][:3]:
            out.append(f"#: {src}")
        write_string(out, "msgid", text)
        write_string(out, "msgstr", po.get(text, ""))
    return "\n".join(out) + "\n"


def parse_po(text):
    result, current, mid, mstr = {}, None, None, None

    def flush():
        if mid is not None and mstr is not None and mid != "":
            result[mid] = mstr

    for raw in text.split("\n"):
        line = raw.strip()
        if line.startswith("msgid "):
            flush()
            mid, mstr, current = "", None, "id"
            line = line[6:]
        elif line.startswith("msgstr "):
            mstr, current = "", "str"
            line = line[7:]
        elif not line.startswith('"'):
            continue
        value = unescape(line[1:-1]) if line.startswith('"') else ""
        if current == "id":
            mid += value
        elif current == "str":
            mstr += value
    flush()
    return result


def main():
    check = "--check" in sys.argv
    cat = Catalog()
    for path in sorted(PROJECT.rglob("*.gd")):
        if not skipped(path):
            collect_gd(cat, path)
    for path in sorted(PROJECT.rglob("*.tscn")):
        if not skipped(path):
            collect_scene(cat, path)
    for path in sorted((PROJECT / "data").rglob("*.json")):
        collect_data(cat, path)
    files = {POT: render(cat, "", {})}
    for po_path in sorted(LOCALE.glob("*.po")):
        files[po_path] = render(cat, po_path.stem, parse_po(po_path.read_text(encoding="utf-8")))
    stale = False
    for path, text in files.items():
        old = path.read_text(encoding="utf-8") if path.exists() else ""
        if old == text:
            continue
        if check:
            print(f"i18n: {path} is not up to date. Run: task i18n", file=sys.stderr)
            stale = True
            continue
        path.write_text(text, encoding="utf-8")
        print(f"i18n: wrote {path}")
    for path, text in files.items():
        if path == POT:
            continue
        po = parse_po(text)
        missing = [t for t in cat.ids if not po.get(t)]
        if missing:
            print(f"i18n: {path}: {len(missing)} of {len(cat.ids)} entries have no translation")
            if check:
                stale = True
    if avoid_words(files):
        stale = True
    sys.exit(1 if stale else 0)


def avoid_words(files):
    """Prints each word of mainland China in zh_TW.po. Returns True if it finds one."""
    avoid = json.loads(AVOID.read_text(encoding="utf-8"))
    found = False
    for path, text in files.items():
        if path.stem != "zh_TW":
            continue
        for msgid, msgstr in parse_po(text).items():
            for word, use in avoid.items():
                if word in msgstr:
                    found = True
                    print(f"i18n: {path}: {word} is a word of mainland China. Use {use}: {msgid!r}")
    return found


if __name__ == "__main__":
    main()
