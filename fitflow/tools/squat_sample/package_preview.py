"""Package rendered vector frames for review; does not modify app assets."""
from pathlib import Path
from PIL import Image, ImageDraw, ImageFont

out = Path(__file__).resolve().parents[2] / 'build/squat-sample'
font = ImageFont.truetype('C:/Windows/Fonts/arial.ttf', 26)
frames = []
for i in range(60):
    canvas = Image.new('RGB', (1200, 660), '#f5f6fa')
    draw = ImageDraw.Draw(canvas)
    for x, label, key in [(0, 'Original push-up', 'reference'),
                          (600, 'Squat — original character parts', 'squat')]:
        frame = Image.open(out / f'{key}_{i}.png').convert('RGB')
        canvas.paste(frame, (x, 60))
        draw.text((x + 24, 18), label, font=font, fill='#182238')
    frames.append(canvas)
frames[0].save(out / 'squat-comparison-v4.gif', save_all=True,
               append_images=frames[1:], duration=67, loop=0, optimize=False)
sheet = Image.new('RGB', (1200, 600), 'white')
for j, i in enumerate([0, 7, 15, 22, 30, 37, 45, 52]):
    frame = Image.open(out / f'squat_{i}.png').convert('RGB').resize((300, 300))
    sheet.paste(frame, (j % 4 * 300, j // 4 * 300))
sheet.save(out / 'review-v4.jpg')
