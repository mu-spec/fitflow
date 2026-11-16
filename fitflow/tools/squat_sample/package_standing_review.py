"""Package standing review animations; leave installed app assets unchanged."""
from pathlib import Path
from PIL import Image, ImageDraw, ImageFont

OUT = Path(__file__).resolve().parents[2] / 'build/standing-pair-review'
font = ImageFont.truetype('C:/Windows/Fonts/seguisb.ttf', 21)
small = ImageFont.truetype('C:/Windows/Fonts/segoeui.ttf', 16)
for name, title, count, subtitle, poses in [
    ('march_in_place', 'March in Place', 48, 'Alternating steps and opposite arm swing', [0, 12, 24, 36]),
    ('calf_raise', 'Calf Raise', 60, 'Heel lift, brief hold, controlled lower', [0, 18, 28, 45]),
]:
    frames = []
    for frame in range(count):
        canvas = Image.new('RGB', (420, 482), '#f5f5f5')
        draw = ImageDraw.Draw(canvas)
        draw.rectangle((0, 0, 420, 61), fill='white')
        draw.text((18, 8), title, font=font, fill='#202124')
        draw.text((18, 36), subtitle, font=small, fill='#66717b')
        with Image.open(OUT / 'frames' / f'{name}_{frame}.png') as im:
            canvas.paste(im.convert('RGB'), (0, 62))
        frames.append(canvas)
    frames[0].save(OUT / f'{name}-review.gif', save_all=True,
                   append_images=frames[1:], duration=[80, 80, 90] * (count // 3),
                   loop=0, disposal=2)
    sheet = Image.new('RGB', (840, 884), '#f5f5f5')
    for slot, frame in enumerate(poses):
        x, y = slot % 2 * 420, slot // 2 * 442
        with Image.open(OUT / 'frames' / f'{name}_{frame}.png') as im:
            sheet.paste(im.convert('RGB'), (x, y + 22))
        ImageDraw.Draw(sheet).text((x + 14, y), f'{frame / 12:.1f} seconds', font=small, fill='#202124')
    sheet.save(OUT / f'{name}-poses.png')
    print(OUT / f'{name}-review.gif')
