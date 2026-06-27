#!/usr/bin/env python3
"""Generate PixelWorld placeholder pixel assets.

The script is deterministic, uses only Pillow drawing primitives, and
overwrites generated PNG files under art/generated/. No third-party art is
downloaded or embedded.
"""

from __future__ import annotations

import math
import sys
from dataclasses import dataclass
from pathlib import Path
from typing import Iterable

try:
    from PIL import Image, ImageDraw
except ImportError:
    print("Pillow is required. Install it with: pip install pillow")
    sys.exit(1)


ROOT = Path(__file__).resolve().parents[1]
OUT = ROOT / "art" / "generated"
SCRIPT_RES = "res://tools/generate_pixel_assets.py"
MANIFEST = ROOT / "ASSET_MANIFEST.md"


Color = tuple[int, int, int]
RGBA = tuple[int, int, int, int]


@dataclass
class AssetRecord:
    path: str
    size: str
    asset_type: str
    purpose: str
    animated: bool
    frames: int
    placeholder: bool = True
    script: str = SCRIPT_RES


ASSETS: list[AssetRecord] = []


def rgba(color: Color | RGBA, alpha: int = 255) -> RGBA:
    if len(color) == 4:
        return color  # type: ignore[return-value]
    return (color[0], color[1], color[2], alpha)


def canvas(w: int, h: int, bg: RGBA = (0, 0, 0, 0)) -> Image.Image:
    return Image.new("RGBA", (w, h), bg)


def save_asset(
    img: Image.Image,
    rel: str,
    asset_type: str,
    purpose: str,
    animated: bool = False,
    frames: int = 1,
) -> None:
    path = OUT / rel
    path.parent.mkdir(parents=True, exist_ok=True)
    img.save(path)
    ASSETS.append(
        AssetRecord(
            path="res://" + str(path.relative_to(ROOT)).replace("\\", "/"),
            size=f"{img.size[0]}x{img.size[1]}",
            asset_type=asset_type,
            purpose=purpose,
            animated=animated,
            frames=frames,
        )
    )
    print(f"generated {path.relative_to(ROOT)}")


def draw_outline_rect(d: ImageDraw.ImageDraw, xy: list[int], fill: Color, outline: Color = (22, 24, 32)) -> None:
    d.rectangle(xy, fill=rgba(outline))
    if xy[2] - xy[0] > 2 and xy[3] - xy[1] > 2:
        d.rectangle([xy[0] + 1, xy[1] + 1, xy[2] - 1, xy[3] - 1], fill=rgba(fill))


def draw_humanoid(
    d: ImageDraw.ImageDraw,
    ox: int,
    oy: int,
    body: Color,
    trim: Color,
    skin: Color = (229, 178, 118),
    hair: Color = (38, 28, 24),
    facing: str = "down",
    pose: int = 0,
) -> None:
    outline = (24, 28, 42)
    d.rectangle([ox + 12, oy + 4, ox + 20, oy + 12], fill=rgba(outline))
    d.rectangle([ox + 13, oy + 5, ox + 19, oy + 11], fill=rgba(skin))
    if facing == "up":
        d.rectangle([ox + 12, oy + 4, ox + 20, oy + 9], fill=rgba(hair))
    elif facing == "left":
        d.rectangle([ox + 12, oy + 4, ox + 17, oy + 11], fill=rgba(hair))
        d.rectangle([ox + 14, oy + 8, ox + 15, oy + 9], fill=rgba(outline))
    elif facing == "right":
        d.rectangle([ox + 15, oy + 4, ox + 20, oy + 11], fill=rgba(hair))
        d.rectangle([ox + 17, oy + 8, ox + 18, oy + 9], fill=rgba(outline))
    else:
        d.rectangle([ox + 12, oy + 4, ox + 20, oy + 6], fill=rgba(hair))
        d.rectangle([ox + 14, oy + 8, ox + 15, oy + 9], fill=rgba(outline))
        d.rectangle([ox + 18, oy + 8, ox + 19, oy + 9], fill=rgba(outline))
    d.rectangle([ox + 9, oy + 12, ox + 23, oy + 24], fill=rgba(outline))
    d.rectangle([ox + 11, oy + 13, ox + 21, oy + 23], fill=rgba(body))
    arm_shift = [-1, 0, 1, 0][pose % 4]
    d.rectangle([ox + 8, oy + 15 + arm_shift, ox + 11, oy + 22 + arm_shift], fill=rgba(trim))
    d.rectangle([ox + 21, oy + 15 - arm_shift, ox + 24, oy + 22 - arm_shift], fill=rgba(trim))
    leg_shift = [-1, 1, -1, 1][pose % 4]
    d.rectangle([ox + 11 + leg_shift, oy + 24, ox + 15 + leg_shift, oy + 29], fill=rgba(outline))
    d.rectangle([ox + 17 - leg_shift, oy + 24, ox + 21 - leg_shift, oy + 29], fill=rgba(outline))


def player_frame(facing: str = "down", pose: int = 0, attack: bool = False, hurt: bool = False, dead: bool = False) -> Image.Image:
    img = canvas(32, 32)
    d = ImageDraw.Draw(img)
    if dead:
        d.rectangle([7, 20, 25, 26], fill=rgba((22, 24, 32)))
        d.rectangle([9, 18, 23, 24], fill=rgba((44, 112, 220)))
        d.rectangle([11, 15, 17, 19], fill=rgba((229, 178, 118)))
        d.rectangle([19, 16, 23, 20], fill=rgba((25, 52, 135)))
        return img
    body = (44, 112, 220) if not hurt else (190, 80, 92)
    trim = (25, 52, 135)
    draw_humanoid(d, 0, 0, body, trim, facing=facing, pose=pose)
    if attack:
        blade = (210, 226, 232)
        shadow = (96, 118, 136)
        if facing == "left":
            d.rectangle([1, 14, 10, 16], fill=rgba(blade))
            d.rectangle([2, 17, 10, 18], fill=rgba(shadow))
        elif facing == "right":
            d.rectangle([22, 14, 31, 16], fill=rgba(blade))
            d.rectangle([22, 17, 30, 18], fill=rgba(shadow))
        elif facing == "up":
            d.rectangle([14, 0, 16, 10], fill=rgba(blade))
            d.rectangle([17, 1, 18, 10], fill=rgba(shadow))
        else:
            d.rectangle([14, 22, 16, 31], fill=rgba(blade))
            d.rectangle([17, 22, 18, 30], fill=rgba(shadow))
    return img


def sheet(frames: Iterable[Image.Image]) -> Image.Image:
    frames = list(frames)
    w, h = frames[0].size
    out = canvas(w * len(frames), h)
    for i, frame in enumerate(frames):
        out.paste(frame, (i * w, 0), frame)
    return out


def npc_image(body: Color, trim: Color, feature: str = "", skin: Color = (229, 178, 118)) -> Image.Image:
    img = canvas(32, 32)
    d = ImageDraw.Draw(img)
    draw_humanoid(d, 0, 0, body, trim, skin=skin, facing="down", pose=0)
    outline = (24, 28, 42)
    if feature == "hat":
        d.rectangle([10, 3, 22, 6], fill=rgba(outline))
        d.rectangle([11, 2, 21, 4], fill=rgba(trim))
    elif feature == "hammer":
        d.rectangle([22, 8, 25, 16], fill=rgba((92, 58, 34)))
        d.rectangle([20, 6, 27, 9], fill=rgba((120, 122, 126)))
    elif feature == "pack":
        d.rectangle([6, 12, 10, 22], fill=rgba(outline))
        d.rectangle([7, 13, 9, 21], fill=rgba((180, 130, 66)))
    elif feature == "shield":
        d.rectangle([5, 14, 10, 22], fill=rgba(outline))
        d.rectangle([6, 15, 9, 21], fill=rgba((72, 100, 150)))
    elif feature == "staff":
        d.rectangle([24, 5, 25, 26], fill=rgba((95, 64, 38)))
        d.rectangle([22, 4, 27, 7], fill=rgba(trim))
    elif feature == "glasses":
        d.rectangle([13, 8, 15, 9], fill=rgba(outline))
        d.rectangle([18, 8, 20, 9], fill=rgba(outline))
    elif feature == "mask":
        d.rectangle([12, 7, 20, 10], fill=rgba((58, 58, 68)))
    elif feature == "hood":
        d.rectangle([10, 3, 22, 13], fill=rgba(outline))
        d.rectangle([12, 5, 20, 12], fill=rgba(body))
    elif feature == "cyber":
        d.rectangle([19, 7, 21, 10], fill=rgba((48, 230, 224)))
        d.rectangle([22, 14, 24, 20], fill=rgba((48, 230, 224)))
    elif feature == "wasteland":
        d.rectangle([9, 3, 23, 5], fill=rgba((120, 90, 48)))
        d.rectangle([20, 13, 24, 23], fill=rgba((76, 78, 68)))
    return img


def slime(color: Color, accent: Color) -> Image.Image:
    img = canvas(32, 32)
    d = ImageDraw.Draw(img)
    outline = (18, 42, 30)
    d.rectangle([7, 16, 25, 25], fill=rgba(outline))
    d.rectangle([9, 12, 23, 25], fill=rgba(outline))
    d.rectangle([10, 14, 22, 23], fill=rgba(color))
    d.rectangle([13, 18, 14, 19], fill=rgba((7, 18, 18)))
    d.rectangle([18, 18, 19, 19], fill=rgba((7, 18, 18)))
    d.rectangle([11, 14, 13, 15], fill=rgba(accent))
    return img


def beast(kind: str, color: Color, accent: Color) -> Image.Image:
    img = canvas(32, 32)
    d = ImageDraw.Draw(img)
    outline = (28, 28, 34)
    if kind in {"wolf", "elite_wolf"}:
        d.rectangle([7, 15, 24, 23], fill=rgba(outline))
        d.rectangle([9, 13, 22, 21], fill=rgba(color))
        d.rectangle([6, 11, 11, 16], fill=rgba(outline))
        d.rectangle([8, 12, 12, 16], fill=rgba(color))
        d.rectangle([20, 10, 25, 15], fill=rgba(outline))
        d.rectangle([22, 11, 25, 15], fill=rgba(accent))
        if kind == "elite_wolf":
            d.rectangle([12, 9, 19, 11], fill=rgba((200, 52, 52)))
    elif kind == "boar":
        d.rectangle([6, 15, 25, 24], fill=rgba(outline))
        d.rectangle([8, 13, 23, 22], fill=rgba(color))
        d.rectangle([5, 17, 8, 20], fill=rgba(accent))
        d.rectangle([21, 12, 23, 14], fill=rgba(outline))
    elif kind == "snake":
        d.rectangle([5, 20, 24, 23], fill=rgba(outline))
        d.rectangle([7, 18, 25, 21], fill=rgba(color))
        d.rectangle([23, 16, 28, 20], fill=rgba(color))
        d.rectangle([26, 17, 27, 18], fill=rgba((220, 40, 40)))
    elif kind == "spider":
        d.rectangle([11, 12, 21, 22], fill=rgba(outline))
        d.rectangle([13, 14, 19, 20], fill=rgba(color))
        for y in [13, 16, 19]:
            d.rectangle([4, y, 11, y + 1], fill=rgba(outline))
            d.rectangle([21, y, 28, y + 1], fill=rgba(outline))
    elif kind == "bat":
        d.rectangle([13, 12, 19, 20], fill=rgba(outline))
        d.rectangle([14, 13, 18, 19], fill=rgba(color))
        d.polygon([(13, 14), (4, 9), (8, 20)], fill=rgba(accent))
        d.polygon([(19, 14), (28, 9), (24, 20)], fill=rgba(accent))
    return img


def humanoid_enemy(kind: str, body: Color, trim: Color) -> Image.Image:
    img = npc_image(body, trim, feature="hood" if "bandit" in kind else "")
    d = ImageDraw.Draw(img)
    if kind == "knife":
        d.rectangle([23, 14, 29, 16], fill=rgba((210, 220, 220)))
    elif kind == "bow":
        d.arc([22, 9, 30, 23], 270, 90, fill=rgba((130, 82, 38)), width=1)
        d.rectangle([23, 16, 30, 16], fill=rgba((220, 220, 190)))
    elif kind == "skeleton":
        d.rectangle([13, 5, 19, 11], fill=rgba((218, 218, 190)))
        d.rectangle([11, 14, 21, 23], fill=rgba((218, 218, 190)))
        d.rectangle([14, 7, 15, 8], fill=rgba((20, 20, 20)))
        d.rectangle([18, 7, 19, 8], fill=rgba((20, 20, 20)))
    elif kind == "zombie":
        d.rectangle([13, 5, 19, 11], fill=rgba((108, 150, 82)))
        d.rectangle([9, 18, 23, 21], fill=rgba((88, 68, 52)))
    elif kind == "leader":
        d.rectangle([10, 3, 22, 6], fill=rgba((150, 40, 30)))
        d.rectangle([23, 12, 30, 14], fill=rgba((235, 210, 90)))
    elif kind == "demon":
        d.rectangle([10, 4, 12, 8], fill=rgba((170, 42, 88)))
        d.rectangle([20, 4, 22, 8], fill=rgba((170, 42, 88)))
        d.rectangle([14, 17, 18, 20], fill=rgba((235, 60, 110)))
    return img


def tile_icon(kind: str, base: Color, detail: Color) -> Image.Image:
    img = Image.new("RGBA", (16, 16), rgba(base))
    d = ImageDraw.Draw(img)
    dark = (36, 34, 38)
    if "bamboo" in kind:
        for x in [4, 8, 12]:
            d.rectangle([x, 2, x + 1, 14], fill=rgba(detail))
            d.point((x + 2, 5), fill=rgba((110, 210, 86)))
    elif "spirit_grass" in kind:
        d.rectangle([7, 5, 8, 14], fill=rgba((42, 102, 44)))
        d.rectangle([4, 8, 7, 10], fill=rgba(detail))
        d.rectangle([8, 4, 12, 7], fill=rgba((118, 236, 140)))
    elif "stone" in kind or "rock" in kind or "ore" in kind:
        d.rectangle([3, 7, 12, 13], fill=rgba(dark))
        d.rectangle([4, 6, 11, 12], fill=rgba(detail))
    elif "step" in kind or "floor" in kind or "road" in kind:
        d.rectangle([0, 5, 15, 7], fill=rgba(detail))
        d.rectangle([0, 11, 15, 12], fill=rgba(detail))
        d.rectangle([7, 0, 8, 15], fill=rgba(detail))
    elif "wall" in kind or "fence" in kind:
        for y in [2, 6, 10, 14]:
            d.rectangle([0, y, 15, y + 1], fill=rgba(detail))
        for x in [4, 10]:
            d.rectangle([x, 0, x + 1, 15], fill=rgba(dark))
    elif "gate" in kind:
        d.rectangle([2, 2, 5, 14], fill=rgba(dark))
        d.rectangle([10, 2, 13, 14], fill=rgba(dark))
        d.rectangle([3, 3, 12, 6], fill=rgba(detail))
    elif "bridge" in kind:
        d.rectangle([0, 6, 15, 10], fill=rgba((126, 78, 38)))
        for x in [2, 6, 10, 14]:
            d.rectangle([x, 4, x, 12], fill=rgba(detail))
    elif "river" in kind:
        d.rectangle([0, 0, 6, 15], fill=rgba((42, 92, 178)))
        d.rectangle([7, 0, 9, 15], fill=rgba(detail))
    elif "cliff" in kind:
        d.polygon([(0, 15), (8, 3), (15, 15)], fill=rgba(detail))
        d.rectangle([6, 7, 8, 9], fill=rgba(dark))
    elif "blood" in kind:
        d.rectangle([4, 7, 11, 10], fill=rgba((130, 24, 28)))
        d.point((12, 11), fill=rgba((130, 24, 28)))
    elif "scrap" in kind:
        d.rectangle([3, 10, 13, 13], fill=rgba(dark))
        d.rectangle([5, 6, 8, 10], fill=rgba(detail))
        d.rectangle([10, 5, 12, 9], fill=rgba((120, 122, 126)))
    elif "car" in kind:
        d.rectangle([2, 7, 14, 12], fill=rgba(detail))
        d.rectangle([4, 5, 10, 8], fill=rgba(dark))
        d.point((4, 13), fill=rgba(dark))
        d.point((12, 13), fill=rgba(dark))
    elif "pipe" in kind:
        d.rectangle([0, 6, 15, 9], fill=rgba(detail))
        d.rectangle([5, 4, 7, 11], fill=rgba(dark))
    elif "terminal" in kind or "panel" in kind:
        d.rectangle([3, 3, 13, 13], fill=rgba(dark))
        d.rectangle([5, 5, 11, 8], fill=rgba((40, 230, 220)))
        d.point((6, 11), fill=rgba(detail))
        d.point((9, 11), fill=rgba(detail))
    elif "core" in kind or "lantern" in kind:
        d.rectangle([5, 5, 11, 11], fill=rgba(dark))
        d.rectangle([6, 6, 10, 10], fill=rgba(detail))
        d.point((8, 3), fill=rgba(detail))
    elif "flower" in kind:
        d.rectangle([7, 8, 8, 14], fill=rgba((42, 120, 44)))
        d.rectangle([5, 5, 10, 8], fill=rgba(detail))
        d.rectangle([7, 3, 8, 10], fill=rgba(detail))
    elif "barrel" in kind:
        d.rectangle([4, 4, 12, 14], fill=rgba(dark))
        d.rectangle([5, 5, 11, 13], fill=rgba(detail))
        d.rectangle([4, 7, 12, 8], fill=rgba((80, 50, 30)))
    elif "crate" in kind:
        d.rectangle([3, 4, 13, 14], fill=rgba(dark))
        d.rectangle([4, 5, 12, 13], fill=rgba(detail))
        d.line([4, 5, 12, 13], fill=rgba(dark))
        d.line([12, 5, 4, 13], fill=rgba(dark))
    elif "sign" in kind:
        d.rectangle([3, 4, 13, 9], fill=rgba(detail))
        d.rectangle([7, 9, 8, 15], fill=rgba(dark))
    elif "well" in kind:
        d.rectangle([4, 7, 12, 14], fill=rgba(dark))
        d.rectangle([5, 8, 11, 13], fill=rgba(detail))
        d.rectangle([3, 4, 13, 6], fill=rgba((92, 60, 38)))
    else:
        d.rectangle([3, 3, 12, 12], fill=rgba(detail))
    return img


def item_icon(kind: str, color: Color) -> Image.Image:
    img = canvas(16, 16)
    d = ImageDraw.Draw(img)
    dark = (34, 30, 32)
    if "potion" in kind or "antidote" in kind:
        d.rectangle([6, 2, 10, 5], fill=rgba(dark))
        d.rectangle([4, 5, 12, 13], fill=rgba(dark))
        d.rectangle([5, 7, 11, 12], fill=rgba(color))
    elif "sword" in kind or "dagger" in kind or "blade" in kind:
        d.rectangle([3, 12, 5, 14], fill=rgba((92, 58, 36)))
        d.rectangle([5, 10, 7, 12], fill=rgba(dark))
        d.rectangle([7, 3, 12, 10], fill=rgba(color))
    elif "bow" in kind:
        d.arc([3, 2, 13, 14], 260, 100, fill=rgba(color), width=2)
        d.rectangle([4, 8, 13, 8], fill=rgba((220, 220, 190)))
    elif "staff" in kind:
        d.rectangle([6, 4, 7, 14], fill=rgba((92, 58, 36)))
        d.rectangle([4, 2, 9, 6], fill=rgba(color))
    elif "letter" in kind or "scroll" in kind:
        d.rectangle([3, 4, 13, 12], fill=rgba(dark))
        d.rectangle([4, 5, 12, 11], fill=rgba((224, 212, 170)))
        d.line([4, 5, 12, 11], fill=rgba(color))
    elif "key" in kind:
        d.rectangle([3, 7, 10, 9], fill=rgba(color))
        d.rectangle([9, 5, 13, 10], fill=rgba(dark))
        d.rectangle([10, 6, 12, 9], fill=(0, 0, 0, 0))
    elif "chip" in kind or "circuit" in kind:
        d.rectangle([3, 3, 13, 13], fill=rgba(dark))
        d.rectangle([5, 5, 11, 11], fill=rgba(color))
        for x in [2, 14]:
            for y in [5, 8, 11]:
                d.point((x, y), fill=rgba(color))
    elif "orb" in kind or "core" in kind or "crystal" in kind:
        d.rectangle([5, 4, 11, 12], fill=rgba(dark))
        d.rectangle([6, 5, 10, 11], fill=rgba(color))
        d.point((8, 3), fill=rgba((245, 245, 255)))
    elif "bone" in kind:
        d.rectangle([4, 7, 12, 9], fill=rgba(color))
        d.rectangle([2, 6, 5, 10], fill=rgba(color))
        d.rectangle([11, 6, 14, 10], fill=rgba(color))
    elif "meat" in kind or "bun" in kind or "food" in kind:
        d.rectangle([4, 5, 12, 12], fill=rgba(dark))
        d.rectangle([5, 6, 11, 11], fill=rgba(color))
    else:
        d.rectangle([4, 4, 12, 12], fill=rgba(dark))
        d.rectangle([5, 5, 11, 11], fill=rgba(color))
    return img


def ui_icon(kind: str, color: Color) -> Image.Image:
    img = canvas(16, 16)
    d = ImageDraw.Draw(img)
    dark = (34, 30, 40)
    if kind in {"hp", "heart"}:
        d.rectangle([3, 4, 6, 7], fill=rgba(dark))
        d.rectangle([10, 4, 13, 7], fill=rgba(dark))
        d.rectangle([2, 7, 14, 10], fill=rgba(dark))
        d.rectangle([4, 10, 12, 12], fill=rgba(dark))
        d.rectangle([5, 5, 12, 10], fill=rgba(color))
    elif kind == "mp":
        d.rectangle([5, 2, 11, 13], fill=rgba(dark))
        d.rectangle([6, 4, 10, 12], fill=rgba(color))
    elif kind == "inventory":
        d.rectangle([3, 5, 13, 13], fill=rgba(dark))
        d.rectangle([4, 6, 12, 12], fill=rgba(color))
        d.rectangle([6, 3, 10, 5], fill=rgba(dark))
    elif kind == "map":
        d.rectangle([3, 4, 13, 12], fill=rgba((220, 205, 140)))
        d.line([6, 4, 6, 12], fill=rgba(dark))
        d.line([10, 4, 10, 12], fill=rgba(dark))
    elif kind == "quest":
        d.rectangle([4, 3, 12, 13], fill=rgba(dark))
        d.rectangle([6, 5, 10, 6], fill=rgba(color))
        d.rectangle([6, 8, 10, 9], fill=rgba(color))
    elif kind == "settings":
        d.rectangle([6, 2, 9, 14], fill=rgba(color))
        d.rectangle([2, 6, 14, 9], fill=rgba(color))
        d.rectangle([6, 6, 9, 9], fill=rgba(dark))
    elif kind == "dialogue":
        d.rectangle([3, 4, 13, 11], fill=rgba(dark))
        d.rectangle([4, 5, 12, 10], fill=rgba(color))
        d.rectangle([6, 11, 8, 13], fill=rgba(dark))
    elif kind == "warning":
        d.polygon([(8, 2), (14, 13), (2, 13)], fill=rgba(color))
        d.rectangle([7, 6, 8, 10], fill=rgba(dark))
    elif kind in {"save", "load"}:
        d.rectangle([3, 3, 13, 13], fill=rgba(dark))
        d.rectangle([5, 4, 11, 7], fill=rgba(color))
        if kind == "load":
            d.rectangle([7, 9, 9, 12], fill=rgba(color))
            d.rectangle([6, 11, 10, 12], fill=rgba(color))
    elif kind in {"attack", "defense", "speed", "interact"}:
        d.rectangle([4, 4, 12, 12], fill=rgba(dark))
        d.rectangle([6, 6, 10, 10], fill=rgba(color))
    else:
        d.rectangle([4, 4, 12, 12], fill=rgba(dark))
        d.rectangle([5, 5, 11, 11], fill=rgba(color))
    return img


def panel_image(w: int, h: int, base: Color, border: Color, inset: Color) -> Image.Image:
    img = canvas(w, h)
    d = ImageDraw.Draw(img)
    d.rectangle([0, 0, w - 1, h - 1], fill=rgba(border))
    d.rectangle([2, 2, w - 3, h - 3], fill=rgba(base))
    d.rectangle([4, 4, w - 5, h - 5], outline=rgba(inset))
    return img


def effect(kind: str, color: Color, frames: int = 4) -> Image.Image:
    frames_img: list[Image.Image] = []
    for i in range(frames):
        img = canvas(32, 32)
        d = ImageDraw.Draw(img)
        c = rgba(color)
        if "slash_down" in kind:
            d.rectangle([14 - i, 12, 16 + i, 28], fill=c)
            d.rectangle([17 + i, 16, 18 + i, 24], fill=rgba((240, 240, 220)))
        elif "slash_up" in kind:
            d.rectangle([14 - i, 4, 16 + i, 20], fill=c)
            d.rectangle([17 + i, 8, 18 + i, 16], fill=rgba((240, 240, 220)))
        elif "slash_left" in kind:
            d.rectangle([3, 14 - i, 19, 16 + i], fill=c)
            d.rectangle([7, 17 + i, 15, 18 + i], fill=rgba((240, 240, 220)))
        elif "slash_right" in kind:
            d.rectangle([13, 14 - i, 29, 16 + i], fill=c)
            d.rectangle([17, 17 + i, 25, 18 + i], fill=rgba((240, 240, 220)))
        elif "hit" in kind:
            radius = 2 + i * 2
            d.rectangle([16 - radius, 16 - radius, 16 + radius, 16 + radius], fill=c)
            d.rectangle([15, 4, 17, 9 + i], fill=rgba((255, 220, 90)))
            d.rectangle([15, 23 - i, 17, 28], fill=rgba((255, 220, 90)))
        elif "heal" in kind:
            d.rectangle([15, 6 - i, 16, 24 + i], fill=c)
            d.rectangle([8 + i, 15, 24 - i, 16], fill=rgba((200, 255, 210)))
            d.rectangle([10, 22 - i, 22, 23 - i], fill=c)
        elif "fireball" in kind:
            d.rectangle([8 + i, 12 - i, 22 + i, 20 + i], fill=rgba((130, 40, 20)))
            d.rectangle([11 + i, 14 - i, 20 + i, 18 + i], fill=c)
        elif "lightning" in kind:
            d.polygon([(16, 3), (10 + i, 15), (16, 15), (12, 29), (24 - i, 12), (17, 12)], fill=c)
        elif "poison" in kind:
            d.rectangle([10 - i, 16 - i, 22 + i, 23 + i], fill=rgba((50, 90, 36)))
            d.rectangle([12, 13 - i, 20, 20], fill=c)
        else:
            d.rectangle([12 - i, 12 - i, 20 + i, 20 + i], fill=c)
        frames_img.append(img)
    return sheet(frames_img)


def generate_legacy_assets() -> None:
    save_asset(player_frame("down"), "characters/player_idle.png", "character", "v0.2.0 玩家待机")
    save_asset(sheet(player_frame("down", i) for i in range(4)), "characters/player_walk_sheet.png", "character", "v0.2.0 玩家行走", True, 4)
    save_asset(sheet(player_frame("right", i, attack=True) for i in range(3)), "characters/player_attack_sheet.png", "character", "v0.2.0 玩家攻击", True, 3)
    save_asset(npc_image((198, 146, 55), (105, 68, 34)), "characters/npc_villager.png", "npc", "v0.2.0 普通村民")
    save_asset(npc_image((80, 160, 88), (235, 235, 220), "staff"), "characters/npc_doctor.png", "npc", "v0.2.0 药师")
    save_asset(npc_image((122, 72, 168), (96, 58, 36), "staff"), "characters/npc_chief.png", "npc", "v0.2.0 村长")
    save_asset(slime((57, 188, 83), (120, 240, 126)), "enemies/enemy_slime.png", "enemy", "v0.2.0 史莱姆")
    save_asset(beast("wolf", (112, 116, 126), (150, 150, 160)), "enemies/enemy_wolf.png", "enemy", "v0.2.0 妖狼")
    save_asset(humanoid_enemy("knife", (139, 48, 35), (78, 39, 28)), "enemies/enemy_bandit.png", "enemy", "v0.2.0 山贼")

    tile_specs = [
        ("tile_grass.png", "grass", (58, 134, 49), (94, 174, 62), "草地瓦片"),
        ("tile_road.png", "road", (139, 112, 74), (178, 145, 92), "道路瓦片"),
        ("tile_tree.png", "bamboo", (48, 126, 50), (36, 120, 44), "树木瓦片"),
        ("tile_water.png", "river_edge", (42, 92, 178), (82, 142, 220), "水面瓦片"),
        ("tile_house.png", "crate", (168, 112, 64), (180, 95, 55), "房屋瓦片"),
        ("tile_mountain.png", "cliff", (90, 90, 92), (124, 124, 124), "山体瓦片"),
        ("tile_cave.png", "gate", (50, 38, 30), (72, 54, 38), "洞口瓦片"),
        ("tile_sect_floor.png", "floor", (176, 166, 126), (126, 112, 78), "宗门地面"),
        ("tile_herb.png", "spirit_grass", (58, 134, 49), (94, 210, 78), "草药资源点"),
        ("tile_chest.png", "crate", (58, 134, 49), (158, 91, 39), "宝箱资源点"),
    ]
    for filename, kind, base, detail, purpose in tile_specs:
        save_asset(tile_icon(kind, base, detail), f"tiles/{filename}", "tile", f"v0.2.0 {purpose}")

    for name, color in [
        ("herb", (78, 205, 82)),
        ("potion", (205, 70, 210)),
        ("wood", (139, 82, 38)),
        ("stone", (128, 130, 136)),
        ("coin", (229, 183, 43)),
        ("sword", (190, 205, 212)),
    ]:
        save_asset(item_icon(name, color), f"items/item_{name}.png", "item", f"v0.2.0 {name} 图标")

    for kind, filename, color in [
        ("heart", "ui_heart.png", (220, 50, 72)),
        ("heart", "ui_empty_heart.png", (80, 72, 80)),
        ("stamina", "ui_stamina.png", (77, 210, 88)),
        ("attack", "ui_attack.png", (205, 216, 220)),
        ("interact", "ui_interact.png", (232, 232, 120)),
        ("save", "ui_save.png", (220, 224, 230)),
    ]:
        save_asset(ui_icon(kind, color), f"ui/{filename}", "ui", f"v0.2.0 {filename}")

    save_asset(effect("hit", (235, 54, 42)), "effects/effect_hit_sheet.png", "effect", "v0.2.0 命中特效", True, 4)
    save_asset(effect("heal", (74, 220, 132)), "effects/effect_heal_sheet.png", "effect", "v0.2.0 治疗特效", True, 4)


def generate_v021_assets() -> None:
    for folder in [
        "characters/player",
        "characters/npc",
        "enemies/slime",
        "enemies/beast",
        "enemies/humanoid",
        "tiles/xianxia",
        "tiles/apocalypse",
        "tiles/cyberpunk",
        "items/materials",
        "items/consumables",
        "items/weapons",
        "ui/icons",
        "ui/panels",
        "effects/combat",
        "effects/magic",
        "previews",
    ]:
        (OUT / folder).mkdir(parents=True, exist_ok=True)

    for facing in ["down", "up", "left", "right"]:
        save_asset(sheet(player_frame(facing, i) for i in range(4)), f"characters/player/player_idle_{facing}_sheet.png", "character", f"玩家 {facing} 待机动画", True, 4)
        save_asset(sheet(player_frame(facing, i) for i in range(4)), f"characters/player/player_walk_{facing}_sheet.png", "character", f"玩家 {facing} 行走动画", True, 4)
        save_asset(sheet(player_frame(facing, i, attack=True) for i in range(3)), f"characters/player/player_attack_{facing}_sheet.png", "character", f"玩家 {facing} 攻击动画", True, 3)
    save_asset(player_frame("down", hurt=True), "characters/player/player_hurt.png", "character", "玩家受伤帧")
    save_asset(player_frame("down", dead=True), "characters/player/player_dead.png", "character", "玩家死亡帧")

    npc_specs = [
        ("npc_farmer.png", (142, 96, 44), (80, 150, 52), "hat", "农夫"),
        ("npc_blacksmith.png", (88, 88, 92), (190, 92, 42), "hammer", "铁匠"),
        ("npc_merchant.png", (195, 126, 58), (94, 54, 34), "pack", "商人"),
        ("npc_guard.png", (66, 108, 144), (182, 190, 180), "shield", "守卫"),
        ("npc_sect_disciple.png", (86, 142, 202), (236, 236, 210), "staff", "宗门弟子"),
        ("npc_elder.png", (126, 96, 168), (218, 218, 196), "staff", "长者"),
        ("npc_child.png", (230, 178, 76), (86, 150, 196), "", "孩童"),
        ("npc_innkeeper.png", (160, 86, 52), (235, 210, 120), "hat", "客栈老板"),
        ("npc_mysterious_old_man.png", (76, 70, 90), (185, 185, 210), "hood", "神秘老人"),
        ("npc_bandit_spy.png", (92, 58, 48), (170, 44, 38), "mask", "山贼探子"),
        ("npc_cyber_doctor.png", (56, 88, 110), (48, 230, 224), "cyber", "赛博医生"),
        ("npc_wasteland_survivor.png", (126, 100, 64), (76, 78, 68), "wasteland", "废土幸存者"),
    ]
    for filename, body, trim, feature, purpose in npc_specs:
        save_asset(npc_image(body, trim, feature), f"characters/npc/{filename}", "npc", purpose)

    slime_specs = [
        ("enemy_slime_green.png", (57, 188, 83), (120, 240, 126), "绿色史莱姆"),
        ("enemy_slime_blue.png", (54, 140, 220), (115, 210, 250), "蓝色史莱姆"),
        ("enemy_slime_poison.png", (108, 184, 54), (188, 235, 54), "毒史莱姆"),
        ("enemy_slime_fire.png", (220, 84, 42), (255, 190, 64), "火史莱姆"),
    ]
    for filename, color, accent, purpose in slime_specs:
        save_asset(slime(color, accent), f"enemies/slime/{filename}", "enemy", purpose)

    beast_specs = [
        ("enemy_wolf_gray.png", "wolf", (112, 116, 126), (150, 150, 160), "灰狼"),
        ("enemy_wolf_black.png", "wolf", (44, 46, 56), (86, 90, 104), "黑狼"),
        ("enemy_boar.png", "boar", (126, 76, 52), (218, 190, 150), "野猪"),
        ("enemy_snake.png", "snake", (62, 150, 68), (176, 220, 64), "蛇"),
        ("enemy_spider.png", "spider", (78, 54, 88), (130, 80, 150), "蜘蛛"),
        ("enemy_bat.png", "bat", (68, 64, 86), (112, 96, 150), "蝙蝠"),
        ("enemy_elite_wolf.png", "elite_wolf", (92, 104, 130), (180, 190, 220), "精英妖狼"),
    ]
    for filename, kind, color, accent, purpose in beast_specs:
        save_asset(beast(kind, color, accent), f"enemies/beast/{filename}", "enemy", purpose)

    humanoid_specs = [
        ("enemy_bandit_knife.png", "knife", (139, 48, 35), (78, 39, 28), "持刀山贼"),
        ("enemy_bandit_bow.png", "bow", (128, 72, 36), (86, 52, 32), "弓箭山贼"),
        ("enemy_rogue_cultivator.png", "staff", (92, 48, 132), (190, 180, 72), "散修敌人"),
        ("enemy_skeleton.png", "skeleton", (190, 190, 170), (120, 120, 110), "骷髅"),
        ("enemy_zombie.png", "zombie", (84, 112, 72), (92, 64, 48), "僵尸"),
        ("enemy_bandit_leader.png", "leader", (150, 48, 40), (210, 150, 58), "山贼头目"),
        ("enemy_demon_seed.png", "demon", (82, 36, 80), (210, 54, 110), "魔种"),
    ]
    for filename, kind, body, trim, purpose in humanoid_specs:
        save_asset(humanoid_enemy(kind, body, trim), f"enemies/humanoid/{filename}", "enemy", purpose)

    tile_groups = {
        "tiles/xianxia": [
            ("tile_bamboo.png", "bamboo", (56, 128, 54), (104, 196, 78), "竹林"),
            ("tile_spirit_grass.png", "spirit_grass", (50, 130, 52), (92, 230, 120), "灵草"),
            ("tile_spirit_stone.png", "spirit_stone", (82, 88, 96), (110, 220, 230), "灵石"),
            ("tile_stone_step.png", "stone_step", (120, 116, 108), (160, 156, 140), "石阶"),
            ("tile_sect_wall.png", "sect_wall", (126, 114, 90), (84, 74, 58), "宗门墙"),
            ("tile_sect_gate.png", "sect_gate", (118, 82, 58), (190, 154, 80), "宗门门"),
            ("tile_wood_bridge.png", "wood_bridge", (74, 100, 134), (170, 110, 54), "木桥"),
            ("tile_river_edge.png", "river_edge", (58, 126, 70), (92, 170, 150), "河岸"),
            ("tile_cliff.png", "cliff", (90, 86, 82), (130, 124, 112), "悬崖"),
            ("tile_talisman_floor.png", "floor", (170, 150, 102), (220, 190, 84), "符文地面"),
        ],
        "tiles/apocalypse": [
            ("tile_cracked_road.png", "road", (70, 70, 70), (120, 110, 96), "破裂道路"),
            ("tile_ruin_floor.png", "floor", (84, 78, 70), (124, 110, 94), "废墟地面"),
            ("tile_blood_stain.png", "blood", (78, 68, 60), (130, 24, 28), "血迹"),
            ("tile_scrap_pile.png", "scrap", (72, 70, 68), (148, 132, 98), "废料堆"),
            ("tile_barricade.png", "fence", (76, 62, 52), (142, 82, 40), "路障"),
            ("tile_abandoned_car.png", "car", (72, 74, 74), (124, 76, 58), "废车"),
            ("tile_infected_ground.png", "spirit_grass", (72, 82, 58), (114, 160, 64), "感染地面"),
            ("tile_metal_fence.png", "fence", (66, 68, 72), (142, 150, 154), "金属栅栏"),
        ],
        "tiles/cyberpunk": [
            ("tile_metal_floor.png", "floor", (52, 58, 70), (96, 110, 128), "金属地面"),
            ("tile_neon_road.png", "road", (38, 42, 58), (42, 220, 230), "霓虹道路"),
            ("tile_pipe.png", "pipe", (42, 48, 58), (120, 132, 150), "管道"),
            ("tile_terminal.png", "terminal", (36, 42, 56), (40, 230, 220), "终端"),
            ("tile_data_panel.png", "panel", (34, 40, 54), (210, 68, 240), "数据面板"),
            ("tile_cyber_wall.png", "wall", (46, 50, 66), (80, 92, 130), "赛博墙"),
            ("tile_warning_floor.png", "floor", (54, 48, 42), (230, 190, 40), "警示地面"),
            ("tile_energy_core.png", "core", (36, 42, 58), (72, 240, 220), "能量核心"),
        ],
        "tiles": [
            ("tile_flower_red.png", "flower", (58, 134, 49), (220, 70, 76), "红花"),
            ("tile_flower_blue.png", "flower", (58, 134, 49), (70, 120, 230), "蓝花"),
            ("tile_small_rock.png", "rock", (58, 134, 49), (132, 132, 128), "小石头"),
            ("tile_big_rock.png", "rock", (58, 134, 49), (108, 108, 104), "大石头"),
            ("tile_barrel.png", "barrel", (58, 134, 49), (150, 88, 42), "木桶"),
            ("tile_crate.png", "crate", (58, 134, 49), (166, 106, 58), "木箱"),
            ("tile_sign.png", "sign", (58, 134, 49), (170, 112, 54), "告示牌"),
            ("tile_lantern.png", "lantern", (58, 134, 49), (236, 174, 62), "灯笼"),
            ("tile_well.png", "well", (58, 134, 49), (120, 118, 110), "水井"),
            ("tile_fence.png", "fence", (58, 134, 49), (150, 92, 46), "栅栏"),
        ],
    }
    for folder, specs in tile_groups.items():
        for filename, kind, base, detail, purpose in specs:
            save_asset(tile_icon(kind, base, detail), f"{folder}/{filename}", "tile", purpose)

    material_specs = [
        ("item_spirit_grass.png", "grass", (92, 230, 120), "灵草"),
        ("item_beast_bone.png", "bone", (220, 214, 184), "兽骨"),
        ("item_beast_core.png", "core", (220, 80, 84), "兽核"),
        ("item_iron_ore.png", "ore", (134, 136, 142), "铁矿"),
        ("item_wood_log.png", "wood", (146, 88, 42), "原木"),
        ("item_cloth.png", "cloth", (206, 188, 142), "布料"),
        ("item_scrap_metal.png", "scrap", (126, 132, 138), "废金属"),
        ("item_circuit.png", "circuit", (54, 220, 205), "电路"),
        ("item_crystal.png", "crystal", (120, 210, 240), "晶体"),
        ("item_monster_meat.png", "meat", (194, 74, 70), "妖兽肉"),
    ]
    for filename, kind, color, purpose in material_specs:
        save_asset(item_icon(kind, color), f"items/materials/{filename}", "item", purpose)

    consumable_specs = [
        ("item_small_potion.png", "potion", (220, 72, 86), "小药水"),
        ("item_medium_potion.png", "potion", (196, 62, 190), "中药水"),
        ("item_big_potion.png", "potion", (96, 96, 230), "大药水"),
        ("item_stamina_potion.png", "potion", (72, 210, 84), "体力药水"),
        ("item_antidote.png", "antidote", (116, 220, 72), "解毒剂"),
        ("item_food_bun.png", "bun", (230, 205, 150), "包子"),
        ("item_cooked_meat.png", "meat", (176, 88, 48), "熟肉"),
    ]
    for filename, kind, color, purpose in consumable_specs:
        save_asset(item_icon(kind, color), f"items/consumables/{filename}", "item", purpose)

    weapon_specs = [
        ("item_wood_sword.png", "sword", (150, 92, 46), "木剑"),
        ("item_iron_sword.png", "sword", (190, 205, 212), "铁剑"),
        ("item_dagger.png", "dagger", (210, 214, 220), "匕首"),
        ("item_bow.png", "bow", (168, 108, 52), "弓"),
        ("item_staff.png", "staff", (138, 92, 46), "法杖"),
        ("item_talisman.png", "scroll", (230, 200, 72), "符箓"),
        ("item_cyber_blade.png", "blade", (52, 230, 220), "赛博刃"),
        ("item_letter.png", "letter", (210, 82, 72), "信件"),
        ("item_key.png", "key", (230, 190, 54), "钥匙"),
        ("item_map_scroll.png", "scroll", (170, 120, 60), "地图卷轴"),
        ("item_sect_token.png", "token", (80, 150, 220), "宗门令牌"),
        ("item_data_chip.png", "chip", (64, 220, 210), "数据芯片"),
        ("item_mysterious_orb.png", "orb", (180, 80, 220), "神秘宝珠"),
    ]
    for filename, kind, color, purpose in weapon_specs:
        folder = "items/weapons" if filename in {
            "item_wood_sword.png", "item_iron_sword.png", "item_dagger.png", "item_bow.png", "item_staff.png", "item_talisman.png", "item_cyber_blade.png"
        } else "items"
        save_asset(item_icon(kind, color), f"{folder}/{filename}", "item", purpose)

    ui_specs = [
        ("ui_hp.png", "hp", (220, 50, 72), "生命图标"),
        ("ui_mp.png", "mp", (80, 120, 230), "法力图标"),
        ("ui_stamina_icon.png", "stamina", (77, 210, 88), "体力图标"),
        ("ui_inventory.png", "inventory", (190, 130, 70), "背包图标"),
        ("ui_map.png", "map", (220, 205, 140), "地图图标"),
        ("ui_quest.png", "quest", (230, 190, 70), "任务图标"),
        ("ui_settings.png", "settings", (160, 170, 180), "设置图标"),
        ("ui_dialogue.png", "dialogue", (210, 210, 160), "对话图标"),
        ("ui_warning.png", "warning", (230, 188, 42), "警告图标"),
        ("ui_gold.png", "coin", (230, 190, 54), "金币图标"),
        ("ui_exp.png", "orb", (100, 220, 120), "经验图标"),
        ("ui_level.png", "quest", (130, 180, 230), "等级图标"),
        ("ui_save_icon.png", "save", (220, 224, 230), "保存图标"),
        ("ui_load_icon.png", "load", (120, 190, 230), "读取图标"),
        ("ui_attack_icon.png", "attack", (220, 80, 70), "攻击图标"),
        ("ui_defense_icon.png", "defense", (110, 150, 220), "防御图标"),
        ("ui_speed_icon.png", "speed", (90, 220, 130), "速度图标"),
        ("ui_interact_icon.png", "interact", (232, 232, 120), "交互图标"),
    ]
    for filename, kind, color, purpose in ui_specs:
        save_asset(ui_icon(kind, color), f"ui/icons/{filename}", "ui", purpose)

    panel_specs = [
        ("panel_dialogue.png", 160, 48, "对话面板"),
        ("panel_inventory.png", 160, 96, "背包面板"),
        ("panel_status.png", 120, 48, "状态面板"),
        ("panel_log.png", 180, 80, "日志面板"),
        ("button_normal.png", 64, 24, "普通按钮"),
        ("button_hover.png", 64, 24, "悬停按钮"),
        ("button_pressed.png", 64, 24, "按下按钮"),
    ]
    for i, (filename, w, h, purpose) in enumerate(panel_specs):
        save_asset(panel_image(w, h, (42 + i * 4, 46 + i * 3, 58 + i * 2), (18, 20, 30), (86, 96, 120)), f"ui/panels/{filename}", "ui", purpose)

    combat_effects = [
        ("effect_slash_down_sheet.png", "slash_down", (215, 220, 225), "向下斩击"),
        ("effect_slash_up_sheet.png", "slash_up", (215, 220, 225), "向上斩击"),
        ("effect_slash_left_sheet.png", "slash_left", (215, 220, 225), "向左斩击"),
        ("effect_slash_right_sheet.png", "slash_right", (215, 220, 225), "向右斩击"),
        ("effect_hit_small_sheet.png", "hit_small", (235, 80, 58), "小命中特效"),
        ("effect_hit_big_sheet.png", "hit_big", (245, 60, 42), "大命中特效"),
    ]
    for filename, kind, color, purpose in combat_effects:
        save_asset(effect(kind, color), f"effects/combat/{filename}", "effect", purpose, True, 4)

    magic_effects = [
        ("effect_heal_green_sheet.png", "heal", (74, 220, 132), "绿色治疗"),
        ("effect_spirit_blue_sheet.png", "spirit", (70, 150, 240), "蓝色灵气"),
        ("effect_fireball_sheet.png", "fireball", (245, 120, 36), "火球"),
        ("effect_lightning_sheet.png", "lightning", (240, 230, 70), "闪电"),
        ("effect_poison_sheet.png", "poison", (116, 220, 72), "毒雾"),
    ]
    for filename, kind, color, purpose in magic_effects:
        save_asset(effect(kind, color), f"effects/magic/{filename}", "effect", purpose, True, 4)


def load_image_for_preview(path: str) -> Image.Image:
    local = ROOT / path.replace("res://", "")
    img = Image.open(local).convert("RGBA")
    return img


def preview(records: list[AssetRecord], rel: str, cell_padding: int = 2, columns: int = 12) -> None:
    if not records:
        return
    thumbs: list[Image.Image] = []
    for record in records:
        img = load_image_for_preview(record.path)
        if record.animated and img.size[0] > 32:
            img = img.crop((0, 0, 32, img.size[1]))
        thumbs.append(img)
    cell_w = max(img.size[0] for img in thumbs) + cell_padding
    cell_h = max(img.size[1] for img in thumbs) + cell_padding
    rows = math.ceil(len(thumbs) / columns)
    out = canvas(columns * cell_w + cell_padding, rows * cell_h + cell_padding, (38, 38, 42, 255))
    for i, img in enumerate(thumbs):
        x = cell_padding + (i % columns) * cell_w
        y = cell_padding + (i // columns) * cell_h
        out.paste(img, (x, y), img)
    save_asset(out, rel, "preview", rel.split("/")[-1], False, 1)


def generate_previews() -> None:
    non_preview = [a for a in ASSETS if a.asset_type != "preview"]
    preview([a for a in non_preview if a.asset_type in {"character", "npc"}], "previews/character_preview.png")
    preview([a for a in non_preview if a.asset_type == "enemy"], "previews/enemy_preview.png")
    preview([a for a in non_preview if a.asset_type == "tile"], "previews/tile_preview.png", columns=16)
    preview([a for a in non_preview if a.asset_type == "item"], "previews/item_preview.png", columns=16)
    preview([a for a in non_preview if a.asset_type == "ui"], "previews/ui_preview.png", columns=10)
    preview([a for a in non_preview if a.asset_type == "effect"], "previews/effect_preview.png")
    preview(non_preview, "previews/all_assets_preview.png", columns=16)


def write_manifest() -> None:
    counts = {
        "character": sum(1 for a in ASSETS if a.asset_type == "character"),
        "npc": sum(1 for a in ASSETS if a.asset_type == "npc"),
        "enemy": sum(1 for a in ASSETS if a.asset_type == "enemy"),
        "tile": sum(1 for a in ASSETS if a.asset_type == "tile"),
        "item": sum(1 for a in ASSETS if a.asset_type == "item"),
        "ui": sum(1 for a in ASSETS if a.asset_type == "ui"),
        "effect": sum(1 for a in ASSETS if a.asset_type == "effect"),
        "preview": sum(1 for a in ASSETS if a.asset_type == "preview"),
    }
    lines = [
        "# ASSET_MANIFEST.md — PixelWorld v0.2.1 占位像素素材清单",
        "",
        "所有素材均为项目脚本自制的占位像素素材，由 `res://tools/generate_pixel_assets.py` 使用 Python + Pillow 生成。素材可重复生成，重新运行脚本会覆盖 `res://art/generated/` 下的 PNG 文件。",
        "",
        "## 资产列表",
        "",
        "| 文件路径 | 尺寸 | 类型 | 用途 | 是否动画 | 帧数 | 是否占位素材 | 生成脚本 |",
        "|---|---:|---|---|---|---:|---|---|",
    ]
    for asset in ASSETS:
        lines.append(
            f"| `{asset.path}` | {asset.size} | {asset.asset_type} | {asset.purpose} | "
            f"{'是' if asset.animated else '否'} | {asset.frames} | {'是' if asset.placeholder else '否'} | `{asset.script}` |"
        )
    lines.extend(
        [
            "",
            "## 统计",
            "",
            f"* 角色素材数量: {counts['character']}",
            f"* NPC 素材数量: {counts['npc']}",
            f"* 敌人素材数量: {counts['enemy']}",
            f"* 地图瓦片数量: {counts['tile']}",
            f"* 物品图标数量: {counts['item']}",
            f"* UI 素材数量: {counts['ui']}",
            f"* 特效素材数量: {counts['effect']}",
            f"* 预览图数量: {counts['preview']}",
            f"* 总素材数量: {len(ASSETS)}",
            "",
            "## 后续替换计划",
            "",
            "* v0.2.1 素材仅用于系统开发、地图测试、战斗测试和 UI 布局测试。",
            "* 后续正式像素美术建议使用 Aseprite / LibreSprite / Piskel 按同名路径逐步替换。",
        ]
    )
    MANIFEST.write_text("\n".join(lines) + "\n", encoding="utf-8")


def print_summary() -> None:
    counts: dict[str, int] = {}
    for asset in ASSETS:
        counts[asset.asset_type] = counts.get(asset.asset_type, 0) + 1
    print("")
    print("PixelWorld asset generation summary")
    for key in ["character", "npc", "enemy", "tile", "item", "ui", "effect", "preview"]:
        print(f"  {key}: {counts.get(key, 0)}")
    print(f"  total: {len(ASSETS)}")


def main() -> None:
    ASSETS.clear()
    generate_legacy_assets()
    generate_v021_assets()
    generate_previews()
    write_manifest()
    print_summary()


if __name__ == "__main__":
    main()
