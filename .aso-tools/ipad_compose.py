#!/usr/bin/env python3
"""
iPad App Store Screenshot Composer (companion to the iPhone skill's compose.py).

Builds a deterministic iPad-dimension scaffold: solid brand-colour canvas,
bold headline (auto-fit), and the iPad screenshot composited into a rounded
"screen" on a thin dark bezel, top-aligned and bleeding off the bottom edge.

The scaffold is then handed to Nano Banana Pro, which turns the placeholder
bezel into a photorealistic iPad frame and matches the iPhone set's style.

Default canvas = 2048x2732 (iPad 12.9"/13", accepted by App Store Connect).
Pass --width/--height for the 13" 2064x2752 variant if needed.
"""

import argparse
from PIL import Image, ImageDraw, ImageFont

FONT_PATH = "/Library/Fonts/SF-Pro-Display-Black.otf"


def hex_to_rgb(h):
    h = h.lstrip("#")
    return tuple(int(h[i:i + 2], 16) for i in (0, 2, 4))


def word_wrap(draw, text, font, max_w):
    words, lines, cur = text.split(), [], ""
    for w in words:
        test = f"{cur} {w}".strip()
        if draw.textlength(test, font=font) <= max_w:
            cur = test
        else:
            if cur:
                lines.append(cur)
            cur = w
    if cur:
        lines.append(cur)
    return lines


def fit_font(text, max_w, size_max, size_min):
    dummy = ImageDraw.Draw(Image.new("RGBA", (1, 1)))
    for size in range(size_max, size_min - 1, -4):
        font = ImageFont.truetype(FONT_PATH, size)
        bbox = dummy.textbbox((0, 0), text, font=font)
        if (bbox[2] - bbox[0]) <= max_w:
            return font
    return ImageFont.truetype(FONT_PATH, size_min)


def draw_centered(draw, cx, y, text, font, line_gap, max_w=None):
    lines = word_wrap(draw, text, font, max_w) if max_w else [text]
    for line in lines:
        bbox = draw.textbbox((0, 0), line, font=font)
        h = bbox[3] - bbox[1]
        draw.text((cx, y - bbox[1]), line, fill="white", font=font, anchor="mt")
        y += h + line_gap
    return y


def compose(bg_hex, verb, desc, screenshot_path, output_path, W, H):
    bg = hex_to_rgb(bg_hex)
    canvas = Image.new("RGBA", (W, H), (*bg, 255))
    draw = ImageDraw.Draw(canvas)
    cx = W // 2

    # Typography scaled to the wider iPad canvas
    verb_max = int(W * 0.185)      # ~380 at 2048
    verb_min = int(W * 0.115)
    desc_size = int(W * 0.085)     # ~174 at 2048
    line_gap = int(H * 0.009)
    max_text_w = int(W * 0.90)

    verb_font = fit_font(verb.upper(), max_text_w, verb_max, verb_min)
    desc_font = ImageFont.truetype(FONT_PATH, desc_size)

    text_top = int(H * 0.05)
    y = draw_centered(draw, cx, text_top, verb.upper(), verb_font, line_gap)
    y += int(H * 0.008)
    y = draw_centered(draw, cx, y, desc.upper(), desc_font, line_gap, max_w=max_text_w)

    # Device: top-aligned below the headline, bleeding off the bottom edge
    bezel = max(10, int(W * 0.010))
    corner_r = int(W * 0.035)
    device_w = int(W * 0.82)
    screen_w = device_w - 2 * bezel
    device_x = (W - device_w) // 2
    device_y = int(y + H * 0.045)
    screen_x = device_x + bezel
    screen_y = device_y + bezel

    shot = Image.open(screenshot_path).convert("RGBA")
    scale = screen_w / shot.width
    shot = shot.resize((screen_w, int(shot.height * scale)), Image.LANCZOS)
    screen_h = H - screen_y + 400  # overflow past the bottom

    # Dark bezel (placeholder iPad body Nano Banana will make photorealistic)
    bezel_layer = Image.new("RGBA", canvas.size, (0, 0, 0, 0))
    ImageDraw.Draw(bezel_layer).rounded_rectangle(
        [device_x, device_y, device_x + device_w, device_y + screen_h + 2 * bezel],
        radius=corner_r + bezel, fill=(26, 26, 28, 255),
    )
    canvas = Image.alpha_composite(canvas, bezel_layer)

    # Black screen + screenshot, rounded-rect masked
    mask = Image.new("L", canvas.size, 0)
    ImageDraw.Draw(mask).rounded_rectangle(
        [screen_x, screen_y, screen_x + screen_w, screen_y + screen_h],
        radius=corner_r, fill=255,
    )
    scr = Image.new("RGBA", canvas.size, (0, 0, 0, 0))
    ImageDraw.Draw(scr).rounded_rectangle(
        [screen_x, screen_y, screen_x + screen_w, screen_y + screen_h],
        radius=corner_r, fill=(0, 0, 0, 255),
    )
    scr.paste(shot, (screen_x, screen_y))
    scr.putalpha(mask)
    canvas = Image.alpha_composite(canvas, scr)

    canvas.convert("RGB").save(output_path, "PNG")
    print(f"✓ {output_path} ({W}×{H})")


def main():
    p = argparse.ArgumentParser(description="Compose iPad App Store screenshot scaffold")
    p.add_argument("--bg", required=True)
    p.add_argument("--verb", required=True)
    p.add_argument("--desc", required=True)
    p.add_argument("--screenshot", required=True)
    p.add_argument("--output", required=True)
    p.add_argument("--width", type=int, default=2048)
    p.add_argument("--height", type=int, default=2732)
    args = p.parse_args()
    compose(args.bg, args.verb, args.desc, args.screenshot, args.output, args.width, args.height)


if __name__ == "__main__":
    main()
