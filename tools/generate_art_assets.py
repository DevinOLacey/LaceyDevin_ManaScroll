from __future__ import annotations

from pathlib import Path
from random import Random
from typing import Iterable

from PIL import Image, ImageChops, ImageDraw, ImageFilter


ROOT = Path(__file__).resolve().parents[1]
CARD_SIZE = (1024, 1024)
ENEMY_SIZE = (260, 280)
RNG = Random(7)


def rgba(color: tuple[int, int, int], alpha: int = 255) -> tuple[int, int, int, int]:
	return color + (alpha,)


def lerp(a: float, b: float, t: float) -> float:
	return a + (b - a) * t


def lerp_color(start: tuple[int, int, int], end: tuple[int, int, int], t: float) -> tuple[int, int, int]:
	return tuple(int(lerp(start[index], end[index], t)) for index in range(3))


def make_vertical_gradient(size: tuple[int, int], top: tuple[int, int, int], bottom: tuple[int, int, int]) -> Image.Image:
	width, height = size
	gradient = Image.new("RGBA", size)
	draw = ImageDraw.Draw(gradient)
	for y in range(height):
		color = lerp_color(top, bottom, y / max(height - 1, 1))
		draw.line((0, y, width, y), fill=rgba(color))
	return gradient


def add_vignette(image: Image.Image, strength: int = 180) -> Image.Image:
	width, height = image.size
	mask = Image.new("L", image.size, 0)
	mask_draw = ImageDraw.Draw(mask)
	mask_draw.ellipse((-width * 0.08, -height * 0.05, width * 1.08, height * 1.05), fill=255)
	mask = mask.filter(ImageFilter.GaussianBlur(radius=min(width, height) // 5))
	darkness = Image.new("RGBA", image.size, (0, 0, 0, strength))
	darkness.putalpha(ImageChops.invert(mask))
	return Image.alpha_composite(image, darkness)


def glow_ellipse(layer: Image.Image, bbox: tuple[float, float, float, float], color: tuple[int, int, int], alpha: int, blur: int) -> None:
	glow = Image.new("RGBA", layer.size, (0, 0, 0, 0))
	draw = ImageDraw.Draw(glow)
	draw.ellipse(bbox, fill=rgba(color, alpha))
	layer.alpha_composite(glow.filter(ImageFilter.GaussianBlur(blur)))


def glow_polygon(layer: Image.Image, points: Iterable[tuple[float, float]], color: tuple[int, int, int], alpha: int, blur: int) -> None:
	glow = Image.new("RGBA", layer.size, (0, 0, 0, 0))
	draw = ImageDraw.Draw(glow)
	draw.polygon(list(points), fill=rgba(color, alpha))
	layer.alpha_composite(glow.filter(ImageFilter.GaussianBlur(blur)))


def add_motes(layer: Image.Image, color: tuple[int, int, int], count: int, region: tuple[int, int, int, int], size_range: tuple[int, int], blur: int = 0) -> None:
	specks = Image.new("RGBA", layer.size, (0, 0, 0, 0))
	draw = ImageDraw.Draw(specks)
	left, top, right, bottom = region
	for _ in range(count):
		size = RNG.randint(size_range[0], size_range[1])
		x = RNG.randint(left, right)
		y = RNG.randint(top, bottom)
		alpha = RNG.randint(70, 220)
		draw.ellipse((x - size, y - size, x + size, y + size), fill=rgba(color, alpha))
	if blur > 0:
		specks = specks.filter(ImageFilter.GaussianBlur(blur))
	layer.alpha_composite(specks)


def make_canvas(size: tuple[int, int], top: tuple[int, int, int], bottom: tuple[int, int, int]) -> Image.Image:
	canvas = make_vertical_gradient(size, top, bottom)
	return add_vignette(canvas)


def save(image: Image.Image, relative_path: str) -> None:
	path = ROOT / relative_path
	path.parent.mkdir(parents=True, exist_ok=True)
	image.save(path)


def draw_bramble_husk_enemy() -> Image.Image:
	image = make_canvas(ENEMY_SIZE, (12, 24, 18), (5, 10, 8))
	glow_ellipse(image, (60, 30, 210, 180), (82, 163, 102), 90, 18)
	add_motes(image, (138, 211, 125), 24, (28, 12, 228, 186), (1, 4), 1)

	body = Image.new("RGBA", image.size, (0, 0, 0, 0))
	draw = ImageDraw.Draw(body)
	draw.polygon([(130, 34), (88, 72), (72, 120), (82, 178), (130, 226), (182, 180), (190, 116), (170, 64)], fill=rgba((68, 47, 28)))
	draw.polygon([(130, 58), (102, 82), (90, 124), (98, 160), (130, 188), (164, 158), (170, 118), (156, 82)], fill=rgba((36, 85, 41)))
	draw.ellipse((112, 110, 148, 144), fill=rgba((173, 239, 150), 240))
	draw.line((130, 42, 130, 208), fill=rgba((101, 72, 44)), width=7)
	draw.line((96, 92, 164, 146), fill=rgba((101, 72, 44)), width=5)
	draw.line((166, 84, 210, 64), fill=rgba((90, 63, 38)), width=9)
	draw.line((176, 104, 230, 122), fill=rgba((90, 63, 38)), width=8)
	draw.line((92, 88, 52, 56), fill=rgba((90, 63, 38)), width=9)
	draw.line((80, 120, 34, 136), fill=rgba((90, 63, 38)), width=8)
	draw.line((116, 200, 92, 260), fill=rgba((96, 68, 39)), width=10)
	draw.line((148, 198, 164, 260), fill=rgba((96, 68, 39)), width=10)
	for thorn in [
		[(48, 48), (60, 52), (40, 68)],
		[(212, 56), (225, 44), (220, 70)],
		[(28, 138), (44, 130), (40, 154)],
		[(224, 120), (242, 116), (230, 138)],
		[(94, 248), (102, 228), (116, 252)],
		[(160, 246), (146, 230), (176, 248)],
	]:
		draw.polygon(thorn, fill=rgba((131, 180, 112)))
	body = body.filter(ImageFilter.GaussianBlur(0.4))
	image.alpha_composite(body)
	glow_ellipse(image, (110, 108, 150, 146), (173, 239, 150), 160, 12)
	return image


def draw_bramble_snap() -> Image.Image:
	image = make_canvas(CARD_SIZE, (28, 49, 36), (7, 12, 10))
	add_motes(image, (126, 197, 110), 55, (120, 120, 900, 920), (2, 8), 2)
	glow_ellipse(image, (140, 140, 880, 880), (72, 148, 76), 55, 60)
	layer = Image.new("RGBA", CARD_SIZE, (0, 0, 0, 0))
	draw = ImageDraw.Draw(layer)
	for offset in [0, 38, 78]:
		points = [(170, 760 - offset), (360, 610 - offset), (542, 510 - offset), (708, 390 - offset), (884, 242 - offset)]
		for index in range(len(points) - 1):
			draw.line(points[index] + points[index + 1], fill=rgba((77, 51, 32)), width=28 - (index * 3))
		for x, y in points[1:-1]:
			draw.polygon([(x, y), (x - 28, y - 62), (x + 18, y - 18)], fill=rgba((189, 230, 172)))
			draw.polygon([(x, y), (x + 52, y + 6), (x + 12, y + 24)], fill=rgba((189, 230, 172)))
	glow_polygon(layer, [(168, 760), (356, 614), (544, 510), (708, 390), (884, 242), (860, 300), (680, 442), (516, 558), (344, 682)], (164, 227, 149), 110, 24)
	image.alpha_composite(layer)
	return image


def draw_thick_bark() -> Image.Image:
	image = make_canvas(CARD_SIZE, (62, 39, 22), (13, 10, 6))
	glow_ellipse(image, (170, 148, 854, 880), (162, 115, 69), 75, 58)
	layer = Image.new("RGBA", CARD_SIZE, (0, 0, 0, 0))
	draw = ImageDraw.Draw(layer)
	for inset, color in [(0, (72, 47, 28)), (40, (96, 66, 41)), (84, (124, 90, 60))]:
		draw.rounded_rectangle((252 + inset, 156 + inset, 772 - inset, 874 - inset), radius=180 - inset // 2, fill=rgba(color), outline=rgba((196, 157, 107)), width=10)
	draw.ellipse((392, 362, 632, 602), fill=rgba((206, 167, 111), 110))
	draw.line((420, 260, 604, 776), fill=rgba((163, 121, 77)), width=18)
	draw.line((320, 474, 706, 548), fill=rgba((163, 121, 77)), width=14)
	for x in [346, 430, 594, 676]:
		draw.line((x, 286, x - 46, 742), fill=rgba((82, 56, 35)), width=8)
	image.alpha_composite(layer.filter(ImageFilter.GaussianBlur(0.6)))
	add_motes(image, (241, 211, 164), 18, (220, 180, 804, 858), (4, 10), 1)
	return image


def draw_sap_mend() -> Image.Image:
	image = make_canvas(CARD_SIZE, (46, 28, 14), (8, 12, 8))
	glow_ellipse(image, (236, 186, 790, 868), (255, 177, 88), 92, 70)
	layer = Image.new("RGBA", CARD_SIZE, (0, 0, 0, 0))
	draw = ImageDraw.Draw(layer)
	heart = [(512, 226), (322, 330), (290, 546), (512, 804), (734, 546), (702, 330)]
	draw.polygon(heart, fill=rgba((101, 67, 40)))
	draw.line((512, 246, 512, 776), fill=rgba((67, 41, 24)), width=16)
	draw.line((374, 366, 648, 632), fill=rgba((67, 41, 24)), width=12)
	for crack in [
		(442, 292, 402, 422, 462, 518, 418, 650),
		(588, 306, 620, 404, 566, 522, 622, 642),
	]:
		draw.line(crack, fill=rgba((31, 18, 10)), width=12, joint="curve")
	for stream in [
		(454, 288, 432, 418, 476, 536, 446, 664),
		(568, 300, 592, 408, 548, 522, 590, 646),
	]:
		draw.line(stream, fill=rgba((255, 183, 76), 210), width=16, joint="curve")
	draw.ellipse((448, 432, 578, 562), fill=rgba((255, 222, 140), 160))
	glow_ellipse(layer, (428, 412, 598, 582), (255, 200, 118), 190, 24)
	image.alpha_composite(layer)
	add_motes(image, (255, 207, 132), 30, (240, 200, 792, 860), (2, 7), 2)
	return image


def draw_flame_bolt() -> Image.Image:
	image = make_canvas(CARD_SIZE, (84, 19, 10), (10, 4, 8))
	glow_ellipse(image, (150, 150, 894, 914), (255, 112, 38), 82, 75)
	layer = Image.new("RGBA", CARD_SIZE, (0, 0, 0, 0))
	draw = ImageDraw.Draw(layer)
	bolt = [(256, 744), (470, 544), (424, 516), (678, 238), (570, 470), (628, 494)]
	glow_polygon(layer, bolt, (255, 127, 46), 185, 42)
	draw.polygon(bolt, fill=rgba((255, 184, 95)))
	draw.polygon([(278, 740), (466, 564), (446, 536), (638, 310), (552, 468), (584, 482)], fill=rgba((255, 241, 186)))
	for ring in [(250, 694, 424, 868), (344, 596, 502, 754), (544, 316, 722, 494)]:
		draw.arc(ring, start=18, end=320, fill=rgba((255, 134, 53), 180), width=14)
	image.alpha_composite(layer)
	add_motes(image, (255, 186, 116), 36, (184, 160, 868, 900), (3, 10), 2)
	return image


def draw_ember_shield() -> Image.Image:
	image = make_canvas(CARD_SIZE, (78, 26, 10), (12, 8, 12))
	glow_ellipse(image, (182, 168, 842, 884), (255, 142, 74), 76, 72)
	layer = Image.new("RGBA", CARD_SIZE, (0, 0, 0, 0))
	draw = ImageDraw.Draw(layer)
	glow_polygon(layer, [(512, 196), (314, 304), (332, 654), (512, 840), (694, 654), (710, 304)], (255, 126, 66), 170, 36)
	draw.polygon([(512, 196), (314, 304), (332, 654), (512, 840), (694, 654), (710, 304)], fill=rgba((122, 42, 24)))
	draw.polygon([(512, 252), (370, 334), (382, 626), (512, 766), (642, 626), (654, 334)], fill=rgba((242, 132, 76), 180))
	draw.ellipse((424, 400, 600, 576), fill=rgba((255, 220, 176), 124))
	for arc_box in [(272, 250, 752, 836), (334, 308, 690, 760)]:
		draw.arc(arc_box, start=210, end=330, fill=rgba((255, 197, 120), 210), width=16)
		draw.arc(arc_box, start=24, end=146, fill=rgba((255, 197, 120), 210), width=16)
	add_motes(layer, (255, 171, 94), 26, (254, 178, 780, 880), (3, 9), 2)
	image.alpha_composite(layer)
	return image


def draw_ice_bolt() -> Image.Image:
	image = make_canvas(CARD_SIZE, (30, 66, 108), (6, 14, 28))
	glow_ellipse(image, (136, 126, 882, 892), (111, 212, 255), 82, 74)
	layer = Image.new("RGBA", CARD_SIZE, (0, 0, 0, 0))
	draw = ImageDraw.Draw(layer)
	main_shard = [(510, 172), (646, 414), (594, 820), (446, 820), (384, 436)]
	side_shards = [
		[(318, 446), (426, 516), (362, 702), (258, 634)],
		[(706, 440), (786, 608), (692, 692), (620, 540)],
	]
	for shard in [main_shard] + side_shards:
		glow_polygon(layer, shard, (141, 229, 255), 160, 28)
		draw.polygon(shard, fill=rgba((179, 244, 255), 230), outline=rgba((235, 252, 255), 250))
	for line in [
		(512, 208, 546, 784),
		(512, 208, 444, 612),
		(512, 208, 618, 516),
	]:
		draw.line(line, fill=rgba((255, 255, 255), 200), width=6)
	add_motes(layer, (212, 248, 255), 34, (184, 146, 846, 872), (2, 7), 1)
	image.alpha_composite(layer)
	return image


def draw_frost_armor() -> Image.Image:
	image = make_canvas(CARD_SIZE, (38, 84, 110), (8, 14, 24))
	glow_ellipse(image, (176, 144, 844, 900), (133, 224, 255), 76, 76)
	layer = Image.new("RGBA", CARD_SIZE, (0, 0, 0, 0))
	draw = ImageDraw.Draw(layer)
	armor = [(512, 184), (346, 290), (360, 632), (512, 826), (664, 632), (678, 290)]
	glow_polygon(layer, armor, (122, 224, 255), 160, 30)
	draw.polygon(armor, fill=rgba((76, 150, 183), 220), outline=rgba((221, 248, 255), 245))
	draw.polygon([(512, 250), (410, 314), (424, 606), (512, 716), (600, 606), (614, 314)], fill=rgba((203, 242, 255), 125))
	draw.line((420, 328, 604, 328), fill=rgba((236, 252, 255), 220), width=10)
	draw.line((512, 254, 512, 714), fill=rgba((236, 252, 255), 200), width=8)
	for shard in [
		[(344, 626), (284, 770), (392, 708)],
		[(678, 626), (632, 718), (738, 768)],
		[(510, 814), (456, 934), (564, 904)],
	]:
		draw.polygon(shard, fill=rgba((191, 243, 255), 230), outline=rgba((245, 253, 255), 220))
	add_motes(layer, (224, 249, 255), 28, (186, 154, 836, 920), (2, 8), 2)
	image.alpha_composite(layer)
	return image


def draw_accelerate_mana_gates() -> Image.Image:
	image = make_canvas(CARD_SIZE, (36, 32, 84), (8, 10, 24))
	glow_ellipse(image, (120, 120, 904, 904), (108, 182, 255), 84, 78)
	layer = Image.new("RGBA", CARD_SIZE, (0, 0, 0, 0))
	draw = ImageDraw.Draw(layer)
	for left, right, top, bottom in [(238, 430, 250, 814), (586, 778, 250, 814)]:
		glow_ellipse(layer, (left - 32, top - 24, right + 32, bottom + 24), (105, 201, 255), 120, 28)
		draw.rounded_rectangle((left, top, right, bottom), radius=44, outline=rgba((155, 228, 255), 245), width=18, fill=rgba((37, 58, 113), 150))
		for y in [330, 450, 570, 690]:
			draw.line((left + 24, y, right - 24, y), fill=rgba((178, 238, 255), 160), width=8)
	for arc_box in [(210, 202, 806, 870), (278, 236, 738, 834)]:
		draw.arc(arc_box, start=212, end=330, fill=rgba((146, 228, 255), 220), width=16)
		draw.arc(arc_box, start=28, end=148, fill=rgba((146, 228, 255), 220), width=16)
	for x in [428, 512, 596]:
		draw.line((x, 314, x, 742), fill=rgba((255, 253, 212), 210), width=8)
	add_motes(layer, (185, 238, 255), 42, (168, 156, 856, 882), (2, 8), 2)
	image.alpha_composite(layer)
	return image


def draw_unstable_discharge() -> Image.Image:
	image = make_canvas(CARD_SIZE, (60, 22, 92), (8, 10, 28))
	glow_ellipse(image, (166, 156, 854, 868), (150, 103, 255), 86, 80)
	layer = Image.new("RGBA", CARD_SIZE, (0, 0, 0, 0))
	draw = ImageDraw.Draw(layer)
	core_box = (392, 378, 632, 618)
	glow_ellipse(layer, (352, 338, 672, 658), (171, 124, 255), 190, 36)
	draw.ellipse(core_box, fill=rgba((105, 60, 188), 240), outline=rgba((232, 214, 255), 245), width=10)
	draw.ellipse((438, 424, 586, 572), fill=rgba((227, 244, 255), 170))
	arcs = [
		[(504, 404), (382, 276), (322, 156)],
		[(544, 420), (694, 286), (776, 170)],
		[(432, 520), (280, 586), (186, 744)],
		[(592, 506), (738, 566), (850, 710)],
		[(512, 596), (498, 760), (412, 914)],
	]
	for arc in arcs:
		for width, color in [(22, (147, 110, 255)), (10, (228, 245, 255))]:
			draw.line(arc, fill=rgba(color, 215), width=width, joint="curve")
	for x, y in [(322, 156), (776, 170), (186, 744), (850, 710), (412, 914)]:
		draw.ellipse((x - 24, y - 24, x + 24, y + 24), fill=rgba((198, 234, 255), 210))
	add_motes(layer, (197, 219, 255), 48, (168, 142, 872, 934), (2, 9), 2)
	image.alpha_composite(layer)
	return image


def main() -> None:
	assets = {
		"battle/art/actors/bramble_husk.png": draw_bramble_husk_enemy(),
		"cards/art/Bramble Snap.png": draw_bramble_snap(),
		"cards/art/Thick Bark.png": draw_thick_bark(),
		"cards/art/Sap Mend.png": draw_sap_mend(),
		"cards/art/Flame Bolt.png": draw_flame_bolt(),
		"cards/art/Ember Shield.png": draw_ember_shield(),
		"cards/art/Ice Bolt.png": draw_ice_bolt(),
		"cards/art/Frost Armor.png": draw_frost_armor(),
		"cards/art/Accelerate Mana Gates.png": draw_accelerate_mana_gates(),
		"cards/art/Unstable Discharge.png": draw_unstable_discharge(),
	}

	for relative_path, image in assets.items():
		save(image, relative_path)
		print(f"generated {relative_path}")


if __name__ == "__main__":
	main()
