"""Package Flutter-rendered review frames; does not modify app assets."""
from pathlib import Path
from PIL import Image, ImageDraw, ImageFont

ROOT = Path(__file__).resolve().parents[2]
OUT = ROOT / 'build/front-squat-review'
FONT = ImageFont.truetype('C:/Windows/Fonts/segoeui.ttf', 17)

frames = []
for index in range(24):
    canvas = Image.new('RGB', (720, 402), '#f5f5f5')
    draw = ImageDraw.Draw(canvas)
    draw.rectangle((0, 0, 720, 41), fill='white')
    draw.text((16, 10), 'Approved Jumping Jacks artwork', font=FONT, fill='#202124')
    draw.text((376, 10), 'Squat adaptation — review only', font=FONT, fill='#202124')
    for col, name in enumerate(['reference', 'squat']):
        with Image.open(OUT / 'frames' / f'{name}_{index}.png') as frame:
            canvas.paste(frame.convert('RGB'), (col*360, 42))
    draw.line((360, 0, 360, 402), fill='#dddddd')
    frames.append(canvas)
frames[0].save(OUT / 'squat-artwork-comparison.gif', save_all=True,
               append_images=frames[1:], duration=167, loop=0, disposal=2)

sheet = Image.new('RGB', (1080, 760), '#f5f5f5')
for slot, index in enumerate([0, 4, 8, 12, 16, 20]):
    x, y = (slot % 3)*360, (slot // 3)*380
    with Image.open(OUT / 'frames' / f'squat_{index}.png') as frame:
        sheet.paste(frame.convert('RGB'), (x, y+20))
    ImageDraw.Draw(sheet).text((x+12, y), f'{index/6:.1f}s', font=FONT, fill='#202124')
sheet.save(OUT / 'squat-motion-check.png')
print(OUT / 'squat-artwork-comparison.gif')
