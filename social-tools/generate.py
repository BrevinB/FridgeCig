#!/usr/bin/env python3
"""Render a batch of social post images from HTML templates.

Usage:
    python3 generate.py batches/week1.json

For each post in the batch this fills the named template's {{PLACEHOLDERS}},
screenshots it with headless Chrome at the right platform size, and writes:

    output/<batch-name>/<slug>.png     the post image
    output/<batch-name>/captions.md    copy-paste captions + hashtags, in order

Add a new week by copying a batch file and editing the JSON — no code changes.
Template fields not set by a post fall back to DEFAULTS below.
"""

import html
import json
import subprocess
import sys
from pathlib import Path

CHROME = "/Applications/Google Chrome.app/Contents/MacOS/Google Chrome"
ROOT = Path(__file__).resolve().parent

# (width, height) per platform placement
SIZES = {
    "feed": (1080, 1350),    # IG feed portrait (also fine for TikTok photo posts)
    "square": (1080, 1080),  # IG feed square / carousel slide
    "story": (1080, 1920),   # IG story / Reel cover / TikTok cover
}

DEFAULTS = {
    "EYEBROW": "FridgeCig",
    "SUBTITLE": "",
    "UNIT": "",
    "TITLE_SIZE": "88",
    "FOOTER": "FridgeCig — free on the App Store",
}


def build_items(items):
    """Turn [{"title": ..., "desc": ...}] into list-card <li> markup."""
    return "\n".join(
        f'<li><span class="num">{i + 1}</span><div>'
        f'<b>{html.escape(item["title"])}</b>'
        f'<p>{html.escape(item.get("desc", ""))}</p></div></li>'
        for i, item in enumerate(items)
    )


def main():
    if len(sys.argv) != 2:
        sys.exit(__doc__)

    batch_path = Path(sys.argv[1])
    posts = json.loads(batch_path.read_text())
    out_dir = ROOT / "output" / batch_path.stem
    out_dir.mkdir(parents=True, exist_ok=True)

    captions = [f"# {batch_path.stem} — captions\n"]
    for post in posts:
        template = (ROOT / "templates" / f"{post['template']}.html").read_text()
        fields = {**DEFAULTS, **post.get("fields", {})}
        if isinstance(fields.get("ITEMS"), list):
            fields["ITEMS"] = build_items(fields["ITEMS"])
        for key, value in fields.items():
            template = template.replace("{{%s}}" % key, str(value))

        page = out_dir / f"{post['slug']}.html"
        page.write_text(template)
        width, height = SIZES[post.get("size", "feed")]
        png = out_dir / f"{post['slug']}.png"
        subprocess.run(
            [
                CHROME, "--headless=new", "--disable-gpu", "--hide-scrollbars",
                f"--screenshot={png}", f"--window-size={width},{height}",
                "--force-device-scale-factor=1", page.as_uri(),
            ],
            check=True, capture_output=True,
        )
        page.unlink()

        captions.append(
            f"## {post['slug']} ({post.get('platforms', 'IG + TikTok')})\n\n"
            f"{post['caption']}\n\n{post['hashtags']}\n"
        )
        print(f"  rendered {png.relative_to(ROOT)}")

    (out_dir / "captions.md").write_text("\n".join(captions))
    print(f"\n{len(posts)} posts -> {out_dir.relative_to(ROOT)}/ (see captions.md)")


if __name__ == "__main__":
    main()
