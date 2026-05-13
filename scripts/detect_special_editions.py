#!/usr/bin/env python3
"""Detect new Diet Coke special editions via the Anthropic API + web search.

Run from the GitHub Action. Reads the current SpecialEdition enum from
Badge.swift, asks Claude (with the web_search tool) for any recently-launched
editions not in that list, and patches Badge.swift to add the new cases.
Writes a PR body fragment to a known path so the workflow can pass it to
peter-evans/create-pull-request.

Exits 0 in all "normal" outcomes (including "no candidates"). Exits non-zero
only on hard errors (auth, parse, malformed Claude response).
"""

from __future__ import annotations

import json
import os
import re
import subprocess
import sys
from pathlib import Path

import anthropic

REPO_ROOT = Path(__file__).resolve().parent.parent
BADGE_SWIFT = REPO_ROOT / "DietCokeTracker" / "Models" / "Badge.swift"
PROMPT_FILE = Path(__file__).parent / "prompts" / "detect_editions.md"
PR_BODY_PATH = REPO_ROOT / ".detected_editions_pr_body.md"
PR_TITLE_PATH = REPO_ROOT / ".detected_editions_pr_title.txt"
CANDIDATES_JSON_PATH = REPO_ROOT / ".detected_editions_candidates.json"

ALLOWED_CATEGORIES = {"limited", "dietCokeFlavors", "cokeCreations"}
ALLOWED_RARITIES = {"common", "uncommon", "rare", "epic", "legendary"}
MODEL = "claude-sonnet-4-6"


def parse_known_editions(badge_swift: str) -> list[dict]:
    enum_match = re.search(
        r"enum SpecialEdition:[^{]*\{(.*?)var id: String",
        badge_swift,
        re.DOTALL,
    )
    if not enum_match:
        raise RuntimeError("Could not locate SpecialEdition enum body in Badge.swift")
    body = enum_match.group(1)
    cases = re.findall(r'case (\w+)\s*=\s*"([^"]+)"', body)
    if not cases:
        raise RuntimeError("Parsed enum body but found no cases")
    return [{"swiftCase": s, "rawValue": r} for s, r in cases]


def get_open_pr_raw_values() -> set[str]:
    """Return rawValues already present in open detection PRs."""
    try:
        result = subprocess.run(
            ["gh", "pr", "list", "--label", "edition-detection",
             "--state", "open", "--json", "title", "--limit", "50"],
            capture_output=True, text=True, check=True,
        )
        titles = [pr["title"] for pr in json.loads(result.stdout)]
    except (subprocess.CalledProcessError, json.JSONDecodeError, FileNotFoundError):
        return set()
    raw_values: set[str] = set()
    for title in titles:
        m = re.search(r'"([^"]+)"', title)
        if m:
            raw_values.add(m.group(1))
    return raw_values


def query_claude(known_raw_values: list[str]) -> list[dict]:
    api_key = os.environ.get("ANTHROPIC_API_KEY")
    if not api_key:
        raise RuntimeError("ANTHROPIC_API_KEY is not set")
    client = anthropic.Anthropic(api_key=api_key)
    prompt = PROMPT_FILE.read_text().replace(
        "{{KNOWN_EDITIONS}}",
        "\n".join(f"- {v}" for v in sorted(known_raw_values)),
    )
    response = client.messages.create(
        model=MODEL,
        max_tokens=4096,
        tools=[{"type": "web_search_20250305", "name": "web_search", "max_uses": 5}],
        messages=[{"role": "user", "content": prompt}],
    )
    text = "".join(
        getattr(block, "text", "")
        for block in response.content
        if getattr(block, "type", None) == "text"
    ).strip()
    if not text:
        return []

    fenced = re.search(r"```(?:json)?\s*(\[.*?\])\s*```", text, re.DOTALL)
    if fenced:
        text = fenced.group(1)
    else:
        bare = re.search(r"(\[.*\])", text, re.DOTALL)
        if bare:
            text = bare.group(1)

    parsed = json.loads(text)
    if not isinstance(parsed, list):
        raise RuntimeError(f"Expected JSON array from Claude, got: {type(parsed).__name__}")
    return parsed


def validate_candidates(
    raw: list[dict], known_raw_values: set[str], already_open_raw_values: set[str]
) -> list[dict]:
    valid: list[dict] = []
    for c in raw:
        if not isinstance(c, dict):
            continue
        required = ("rawValue", "swiftCase", "category", "icon", "description", "rarity", "sources")
        if any(k not in c for k in required):
            print(f"skip: missing fields in {c!r}", file=sys.stderr)
            continue
        if c["category"] not in ALLOWED_CATEGORIES:
            print(f"skip: bad category {c['category']!r}", file=sys.stderr)
            continue
        if c["rarity"] not in ALLOWED_RARITIES:
            print(f"skip: bad rarity {c['rarity']!r}", file=sys.stderr)
            continue
        if not re.match(r"^[a-z][A-Za-z0-9]*$", c["swiftCase"]):
            print(f"skip: invalid swiftCase {c['swiftCase']!r}", file=sys.stderr)
            continue
        if not isinstance(c["sources"], list) or not c["sources"]:
            print(f"skip: empty sources for {c['rawValue']!r}", file=sys.stderr)
            continue
        if c["rawValue"] in known_raw_values:
            print(f"skip: already in enum: {c['rawValue']!r}", file=sys.stderr)
            continue
        if c["rawValue"] in already_open_raw_values:
            print(f"skip: already in open PR: {c['rawValue']!r}", file=sys.stderr)
            continue
        valid.append(c)
    return valid


def escape_swift_string(s: str) -> str:
    return s.replace("\\", "\\\\").replace('"', '\\"')


def patch_badge_swift(content: str, candidate: dict) -> str:
    sc = candidate["swiftCase"]
    rv = escape_swift_string(candidate["rawValue"])
    cat = candidate["category"]
    icon = escape_swift_string(candidate["icon"])
    desc = escape_swift_string(candidate["description"])
    rar = candidate["rarity"]

    enum_anchor = "    var id: String { rawValue }"
    if enum_anchor not in content:
        raise RuntimeError("Enum anchor not found in Badge.swift")
    content = content.replace(
        enum_anchor,
        f'    case {sc} = "{rv}"\n\n{enum_anchor}',
        1,
    )

    category_anchor = "        }\n    }\n\n    static func editions"
    if category_anchor not in content:
        raise RuntimeError("var category switch anchor not found")
    content = content.replace(
        category_anchor,
        f"        case .{sc}:\n            return .{cat}\n{category_anchor}",
        1,
    )

    icon_anchor = "        }\n    }\n\n    var badgeDescription"
    if icon_anchor not in content:
        raise RuntimeError("var icon switch anchor not found")
    content = content.replace(
        icon_anchor,
        f'        case .{sc}: return "{icon}"\n{icon_anchor}',
        1,
    )

    desc_anchor = "        }\n    }\n\n    var rarity"
    if desc_anchor not in content:
        raise RuntimeError("var badgeDescription switch anchor not found")
    content = content.replace(
        desc_anchor,
        f'        case .{sc}:\n            return "{desc}"\n{desc_anchor}',
        1,
    )

    rarity_anchor = "        }\n    }\n\n    func toBadge"
    if rarity_anchor not in content:
        raise RuntimeError("var rarity switch anchor not found")
    content = content.replace(
        rarity_anchor,
        f"        case .{sc}:\n            return .{rar}\n{rarity_anchor}",
        1,
    )

    return content


def render_pr_body(candidates: list[dict]) -> str:
    lines = [
        "## Detected new Diet Coke special edition" + ("s" if len(candidates) > 1 else ""),
        "",
        "This PR was opened automatically by `.github/workflows/detect-special-editions.yml`. "
        "Claude searched the web for newly-launched editions not already in the `SpecialEdition` enum.",
        "",
        "## Reviewer checklist",
        "",
        "- [ ] `rawValue` matches the official marketing name **exactly** — once merged and a user logs a drink with this edition, changing the rawValue will orphan that entry's data.",
        "- [ ] `icon` is a real SF Symbol that visually fits the theme.",
        "- [ ] `description` matches the playful house tone (see `Badge.swift` for examples).",
        "- [ ] `category` and `rarity` look right.",
        "- [ ] Sources are real and the edition is officially launched (not rumored).",
        "- [ ] The new case was added in **all 5 places**: enum body, `var category`, `var icon`, `var badgeDescription`, `var rarity` (the script does this — verify the diff).",
        "",
        "## Candidates",
        "",
    ]
    for c in candidates:
        lines.extend([
            f"### {c['rawValue']}",
            "",
            f"- **Swift case**: `{c['swiftCase']}`",
            f"- **Category**: `{c['category']}`",
            f"- **Rarity**: `{c['rarity']}`",
            f"- **Icon**: `{c['icon']}`",
            f"- **Description**: {c['description']}",
            "- **Sources**:",
        ])
        for src in c["sources"]:
            lines.append(f"  - {src}")
        lines.append("")
    lines.append("---")
    lines.append("")
    lines.append("Mark as ready for review once you've verified everything above.")
    return "\n".join(lines)


def render_pr_title(candidates: list[dict]) -> str:
    if len(candidates) == 1:
        return f'Add special edition: "{candidates[0]["rawValue"]}"'
    return f'Add {len(candidates)} new special editions: ' + ", ".join(
        f'"{c["rawValue"]}"' for c in candidates
    )


def main() -> int:
    badge_swift = BADGE_SWIFT.read_text()
    known = parse_known_editions(badge_swift)
    known_raw_values = {k["rawValue"] for k in known}
    print(f"Found {len(known)} existing editions in Badge.swift", file=sys.stderr)

    already_open = get_open_pr_raw_values()
    if already_open:
        print(f"{len(already_open)} edition(s) already in open PRs: {sorted(already_open)}", file=sys.stderr)

    raw_candidates = query_claude(sorted(known_raw_values))
    print(f"Claude returned {len(raw_candidates)} raw candidate(s)", file=sys.stderr)

    candidates = validate_candidates(raw_candidates, known_raw_values, already_open)
    if not candidates:
        print("No new editions detected.", file=sys.stderr)
        return 0

    patched = badge_swift
    for c in candidates:
        patched = patch_badge_swift(patched, c)
    BADGE_SWIFT.write_text(patched)

    PR_BODY_PATH.write_text(render_pr_body(candidates))
    PR_TITLE_PATH.write_text(render_pr_title(candidates))
    CANDIDATES_JSON_PATH.write_text(json.dumps(candidates, indent=2))
    print(f"Patched Badge.swift with {len(candidates)} new edition(s).", file=sys.stderr)
    return 0


if __name__ == "__main__":
    sys.exit(main())
