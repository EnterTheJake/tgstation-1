"""
Generates the scope optics assets as BYOND .dmi files:
  * scope_fisheye.dmi  - a displacement (normal) map for the "displace" filter.
  * scope_vignette.dmi - a soft black edge-darkening overlay.

Both share INNER so the flat centre of the lens, the start of the vignette, and
(via the code) the rim blur all line up on the same boundary.

Displacement: BYOND's "displace" filter reads the red channel as X offset and the
green channel as Y offset, 128 being neutral; the pixel offset scales with the
filter's `size`. The centre is left flat, then past INNER the sample point is
pushed outward along the radius (smoothstepped in, no seam), squeezing distant
content into the rim like a lens edge while the middle stays untouched.

Vignette: an actual scope tube rather than soft darkened corners - transparent
inside VIGNETTE_INNER, then climbing fast (VIGNETTE_POWER < 1) to fully opaque
black, so the field of view reads as a hard circle with nothing outside it.
"""

import math
import struct
import zlib
from pathlib import Path

WIDTH = 480          # 15 tiles * 32px, matches FULLSCREEN_OVERLAY_RESOLUTION
HEIGHT = 480
INNER = 0.55           # displacement: fraction of the radius that stays perfectly flat
STRENGTH = 0.04        # peak displacement as a fraction of the radius, reached at the rim
VIGNETTE_INNER = 0.47  # tube: radius fraction where the field of view starts closing in
VIGNETTE_ALPHA = 240   # peak darkness at the corners; short of opaque so the rim isn't a hard wall
VIGNETTE_POWER = 0.8   # < 1 climbs faster than linear, but gently enough to avoid tunnel vision

ICON_DIR = (
    Path(__file__).resolve().parents[2]
    / "code/modules/antagonists/traitor/contractor/icons"
)


def smoothstep(t: float) -> float:
    t = max(0.0, min(t, 1.0))
    return t * t * (3.0 - 2.0 * t)


def build_displacement():
    """Returns (rows, max_offset_px). rows are RGBA bytearrays."""
    cx = (WIDTH - 1) / 2.0
    cy = (HEIGHT - 1) / 2.0
    radius = min(WIDTH, HEIGHT) / 2.0
    max_offset = STRENGTH * radius

    rows = []
    for y in range(HEIGHT):
        row = bytearray()
        dy = y - cy
        for x in range(WIDTH):
            dx = x - cx
            r = math.hypot(dx, dy)
            u = r / radius
            if r < 1e-6 or u <= INNER:
                off_x = off_y = 0.0
            else:
                delta = max_offset * smoothstep((u - INNER) / (1.0 - INNER))
                off_x = delta * (dx / r)
                off_y = delta * (dy / r)

            # Encode to 0..255 with 128 = neutral. Image rows run top-down but BYOND's
            # +y points up, so the green channel is negated.
            red = round(128.0 + (off_x / max_offset) * 127.0)
            green = round(128.0 - (off_y / max_offset) * 127.0)
            row += bytes((max(0, min(255, red)), max(0, min(255, green)), 128, 255))
        rows.append(row)
    return rows, max_offset


def build_vignette():
    """Returns rows of RGBA bytes: black, opening out from VIGNETTE_INNER to a solid rim."""
    cx = (WIDTH - 1) / 2.0
    cy = (HEIGHT - 1) / 2.0
    radius = min(WIDTH, HEIGHT) / 2.0

    rows = []
    for y in range(HEIGHT):
        row = bytearray()
        dy = y - cy
        for x in range(WIDTH):
            dx = x - cx
            u = math.hypot(dx, dy) / radius
            ramp = smoothstep((u - VIGNETTE_INNER) / (1.0 - VIGNETTE_INNER)) ** VIGNETTE_POWER
            alpha = round(VIGNETTE_ALPHA * ramp)
            row += bytes((0, 0, 0, max(0, min(255, alpha))))
        rows.append(row)
    return rows


def chunk(tag: bytes, data: bytes) -> bytes:
    return (
        struct.pack(">I", len(data))
        + tag
        + data
        + struct.pack(">I", zlib.crc32(tag + data) & 0xFFFFFFFF)
    )


def dmi_metadata(state_name: str) -> bytes:
    text = (
        "# BEGIN DMI\n"
        "version = 4.0\n"
        f"\twidth = {WIDTH}\n"
        f"\theight = {HEIGHT}\n"
        f'state = "{state_name}"\n'
        "\tdirs = 1\n"
        "\tframes = 1\n"
        "# END DMI\n"
    )
    # zTXt: keyword \0 compression-method compressed-text
    return b"Description\x00\x00" + zlib.compress(text.encode("ascii"))


def write_dmi(rows, state_name: str, path: Path):
    raw = bytearray()
    for row in rows:
        raw.append(0)  # filter type 0 (None) per scanline
        raw += row

    png = bytearray(b"\x89PNG\r\n\x1a\n")
    png += chunk(b"IHDR", struct.pack(">IIBBBBB", WIDTH, HEIGHT, 8, 6, 0, 0, 0))
    png += chunk(b"zTXt", dmi_metadata(state_name))
    png += chunk(b"IDAT", zlib.compress(bytes(raw), 9))
    png += chunk(b"IEND", b"")
    path.write_bytes(bytes(png))


if __name__ == "__main__":
    disp_rows, max_offset = build_displacement()
    write_dmi(disp_rows, "fisheye", ICON_DIR / "scope_fisheye.dmi")
    print(f"wrote scope_fisheye.dmi ({WIDTH}x{HEIGHT}, state 'fisheye')")
    print(f"  displace filter size to use: {max_offset:.2f}  -> round to {round(max_offset)}")

    write_dmi(build_vignette(), "vignette", ICON_DIR / "scope_vignette.dmi")
    print(f"wrote scope_vignette.dmi ({WIDTH}x{HEIGHT}, state 'vignette')")
