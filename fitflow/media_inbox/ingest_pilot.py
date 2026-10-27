"""Temporary, deterministic pilot export; not part of the Flutter app.

Only crop, uniform Lanczos resize, neutral padding and WebP encoding.
No generation, retouching, anatomy changes, or source-file modification.
"""
from pathlib import Path
from PIL import Image, ImageOps, ImageDraw
import hashlib
import json

ROOT = Path(__file__).resolve().parent.parent
INBOX = ROOT / 'media_inbox'
REVIEW = INBOX / 'review'
REVIEW.mkdir(exist_ok=True)

# Explicit decisions after reviewing each source and the existing catalog.
# Square boxes are in original 1448x1086 source coordinates. Out-of-bounds
# areas for the two wide floor poses use only a flat dark neutral border.
EXPORTS = [
    ('pushup_wall', 'ChatGPT Image Oct 16, 2026, 10_09_36 PM-1.png', (130, 0, 1216, 1086)),
    ('pushup_standard', 'ChatGPT Image Oct 16, 2026, 10_09_47 PM-2.png', (55, -130, 1375, 1190)),
    ('squat_bodyweight', 'ChatGPT Image Oct 16, 2026, 10_10_02 PM-3.png', (300, 90, 1220, 1010)),
    ('lunge_reverse', 'ChatGPT Image Oct 16, 2026, 10_10_12 PM-4.png', (210, 20, 1230, 1040)),
    ('plank_forearm', 'ChatGPT Image Oct 16, 2026, 10_10_24 PM-5.png', (65, -130, 1385, 1190)),
    ('arm_circles', 'ChatGPT Image Oct 16, 2026, 10_10_28 PM-6.png', (160, 0, 1246, 1086)),
]

def safe_square(source, box):
    left, top, right, bottom = box
    assert right-left == bottom-top
    clipped = (max(0,left), max(0,top), min(source.width,right), min(source.height,bottom))
    canvas = Image.new('RGB', (right-left, bottom-top), '#0B1210')
    canvas.paste(source.crop(clipped), (clipped[0]-left, clipped[1]-top))
    return canvas

def digest(path):
    return hashlib.sha256(path.read_bytes()).hexdigest()

manifest = []
for exercise_id, filename, box in EXPORTS:
    src = INBOX / filename
    original_digest = digest(src)
    with Image.open(src) as opened:
        source = ImageOps.exif_transpose(opened).convert('RGB')
        assert source.size == (1448, 1086)
        variants = [
            ('hero', source.resize((960,720), Image.Resampling.LANCZOS), 93),
            ('thumb', safe_square(source,box).resize((256,256), Image.Resampling.LANCZOS), 95),
        ]
        for variant, raster, quality in variants:
            path = ROOT / 'assets/images/exercises' / variant / f'{exercise_id}.webp'
            path.parent.mkdir(parents=True, exist_ok=True)
            if path.exists():
                raise RuntimeError(f'Refusing to overwrite existing output: {path}')
            raster.save(path, 'WEBP', quality=quality, method=6)
            with Image.open(path) as result:
                result.load()
                assert result.format == 'WEBP' and result.size == raster.size
                assert getattr(result,'n_frames',1) == 1
            manifest.append(dict(id=exercise_id, source=filename, source_sha256=original_digest,
                variant=variant, path=path.relative_to(ROOT).as_posix(), width=raster.width,
                height=raster.height, bytes=path.stat().st_size, sha256=digest(path),
                crop=[0,0,1448,1086] if variant=='hero' else list(box), quality=quality))
    assert digest(src) == original_digest

(REVIEW / 'export-manifest.json').write_text(json.dumps(manifest,indent=2)+'\n',encoding='utf-8')

# Review-only labeled sheet; labels are never embedded in production assets.
sheet = Image.new('RGB',(3*360,2*350),'#0B1210')
draw = ImageDraw.Draw(sheet)
for index,(exercise_id,_,_) in enumerate(EXPORTS):
    x,y=(index%3)*360,(index//3)*350
    with Image.open(ROOT/'assets/images/exercises/thumb'/f'{exercise_id}.webp') as thumb:
        sheet.paste(thumb,(x+8,y+28))
        sheet.paste(thumb.resize((72,72),Image.Resampling.LANCZOS),(x+278,y+28))
        sheet.paste(thumb.resize((64,64),Image.Resampling.LANCZOS),(x+278,y+116))
    draw.text((x+8,y+8),exercise_id,fill='white')
    draw.text((x+278,y+102),'72px',fill='white')
    draw.text((x+278,y+182),'64px',fill='white')
sheet.save(REVIEW/'thumbnail-review.png')
print(json.dumps(manifest,indent=2))
print('TOTAL_BYTES',sum(item['bytes'] for item in manifest))
