"""Prepare face-filter PNG assets with transparency from reference images."""
from __future__ import annotations

import os
from pathlib import Path

from PIL import Image, ImageFilter

OUT = Path(__file__).resolve().parents[1] / "assets" / "filters"
DOWNLOADS = Path(r"C:\Users\ajcru\Downloads")


def near_white(r: int, g: int, b: int, threshold: int = 235) -> bool:
    return r >= threshold and g >= threshold and b >= threshold


def near_black(r: int, g: int, b: int, threshold: int = 28) -> bool:
    return r <= threshold and g <= threshold and b <= threshold


def near_blue_bg(r: int, g: int, b: int) -> bool:
    # Light blue sheet behind the accessory stack
    return b > 170 and g > 150 and r > 130 and b >= r and abs(r - g) < 40


def make_transparent(
    img: Image.Image,
    *,
    remove_white: bool = False,
    remove_black: bool = False,
    remove_blue: bool = False,
    white_thr: int = 235,
    black_thr: int = 28,
) -> Image.Image:
    rgba = img.convert("RGBA")
    pixels = rgba.load()
    w, h = rgba.size
    for y in range(h):
        for x in range(w):
            r, g, b, a = pixels[x, y]
            if remove_white and near_white(r, g, b, white_thr):
                pixels[x, y] = (r, g, b, 0)
            elif remove_black and near_black(r, g, b, black_thr):
                pixels[x, y] = (r, g, b, 0)
            elif remove_blue and near_blue_bg(r, g, b):
                pixels[x, y] = (r, g, b, 0)
    return rgba


def trim_alpha(img: Image.Image, padding: int = 4) -> Image.Image:
    bbox = img.getbbox()
    if not bbox:
        return img
    left, top, right, bottom = bbox
    left = max(0, left - padding)
    top = max(0, top - padding)
    right = min(img.width, right + padding)
    bottom = min(img.height, bottom + padding)
    return img.crop((left, top, right, bottom))


def soft_edge(img: Image.Image) -> Image.Image:
    """Slight blur on alpha only to reduce harsh cutouts."""
    r, g, b, a = img.split()
    a = a.filter(ImageFilter.GaussianBlur(radius=0.6))
    return Image.merge("RGBA", (r, g, b, a))


def save(img: Image.Image, name: str) -> None:
    OUT.mkdir(parents=True, exist_ok=True)
    path = OUT / name
    img = soft_edge(trim_alpha(img))
    img.save(path, "PNG")
    print(f"Wrote {path} ({img.size[0]}x{img.size[1]})")


def split_stack(path: Path) -> None:
    img = Image.open(path).convert("RGBA")
    w, h = img.size
    # Four roughly equal vertical bands: hair, glasses, mustache, beard
    bands = [
        ("hair.png", 0.00, 0.26),
        ("glasses.png", 0.26, 0.48),
        ("mustache.png", 0.48, 0.68),
        ("beard.png", 0.68, 1.00),
    ]
    for name, y0, y1 in bands:
        crop = img.crop((0, int(h * y0), w, int(h * y1)))
        transparent = make_transparent(crop, remove_blue=True, remove_white=True)
        save(transparent, name)


def process_hat(path: Path, out_name: str) -> None:
    img = Image.open(path)
    transparent = make_transparent(img, remove_white=True, white_thr=230)
    save(transparent, out_name)


def process_santa(path: Path, out_name: str) -> None:
    img = Image.open(path)
    transparent = make_transparent(img, remove_black=True, black_thr=35)
    save(transparent, out_name)


def process_picture(path: Path) -> None:
    try:
        img = Image.open(path)
    except Exception as e:
        print(f"Skipping picture.avif: {e}")
        return
    print(f"picture.avif size={img.size} mode={img.mode}")
    # Heuristic: treat near-white/near-black corners as background
    sample = img.convert("RGB").resize((1, 1)).getpixel((0, 0))
    print(f"corner sample approx via resize: {sample}")
    rgba = make_transparent(img, remove_white=True, remove_black=True)
    save(rgba, "accessory.png")


def main() -> None:
    print("OUT=", OUT)
    split_stack(DOWNLOADS / "WhatsApp Image 2026-10-19 at 10.19.44 AM.jpeg")
    process_hat(DOWNLOADS / "WhatsApp Image 2026-10-19 at 10.21.18 AM.jpeg", "sun_hat.png")
    process_santa(DOWNLOADS / "WhatsApp Image 2026-10-19 at 10.23.36 AM.jpeg", "santa_hat.png")
    process_picture(DOWNLOADS / "picture.avif")
    print("Done. Assets:", sorted(p.name for p in OUT.glob("*.png")))


if __name__ == "__main__":
    main()
