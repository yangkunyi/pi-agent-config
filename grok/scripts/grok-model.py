#!/usr/bin/env python3
"""Switch grok CLI backend between the official grok.com subscription and the
slb-v1.api.fan relay for grok-4.6.

Usage:
    grok-model            # show current backend
    grok-model fan        # point grok-4.6 at https://slb-v1.api.fan/v1
    grok-model official   # restore official grok.com endpoint (remove override)
"""
import re
import sys
from pathlib import Path

CONFIG = Path.home() / ".grok" / "config.toml"
KEY_FILE = Path.home() / ".grok" / "fan-api.key"
FAN_BASE = "https://slb-v1.api.fan/v1"
MODEL_KEY = '[model."grok-4.6"]'
# The override block is always written by this script with this exact shape,
# so it can be located and removed reliably.
FAN_BLOCK_TMPL = """\
[model."grok-4.6"]
base_url = "{base}"
api_key = "{key}"
api_backend = "responses"
supports_backend_search = false
context_window = 500000

"""


def read_config() -> str:
    return CONFIG.read_text()


def write_config(text: str) -> None:
    CONFIG.write_text(text)


def remove_block(text: str) -> str:
    lines = text.splitlines(keepends=True)
    out = []
    i = 0
    while i < len(lines):
        line = lines[i]
        if line.strip() == MODEL_KEY:
            # skip until next top-level section header or EOF
            i += 1
            while i < len(lines) and not lines[i].startswith("["):
                i += 1
            continue
        out.append(line)
        i += 1
    return "".join(out)


def status() -> int:
    text = read_config()
    m = re.search(rf"{re.escape(MODEL_KEY)}.*?base_url = \"([^\"]+)\"", text, re.S)
    if m:
        backend = "fan (relay)" if m.group(1) == FAN_BASE else f"custom ({m.group(1)})"
        print(f"grok-4.6 -> {backend}")
    else:
        print("grok-4.6 -> official (grok.com subscription)")
    return 0


def set_fan() -> int:
    if not KEY_FILE.exists():
        print(f"error: {KEY_FILE} not found; store the fan API key there (chmod 600)")
        return 1
    key = KEY_FILE.read_text().strip()
    if not key:
        print(f"error: {KEY_FILE} is empty")
        return 1
    text = remove_block(read_config())
    write_config(text + "\n" + FAN_BLOCK_TMPL.format(base=FAN_BASE, key=key))
    print(f"grok-4.6 -> fan relay ({FAN_BASE})")
    return 0


def set_official() -> int:
    write_config(remove_block(read_config()))
    print("grok-4.6 -> official (grok.com subscription)")
    return 0


def main() -> int:
    if len(sys.argv) > 1:
        arg = sys.argv[1].lower()
        if arg in ("status", "show", "current"):
            return status()
        if arg in ("fan", "relay", "proxy"):
            return set_fan()
        if arg in ("official", "grok", "off"):
            return set_official()
        print(f"unknown backend: {sys.argv[1]}", file=sys.stderr)
        return 2
    return status()


if __name__ == "__main__":
    sys.exit(main())
