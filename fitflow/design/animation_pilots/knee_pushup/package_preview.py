"""Package Flutter-rendered vector frames as a looping review GIF."""
from pathlib import Path
from PIL import Image
ROOT=Path(__file__).resolve().parents[3]
source=ROOT/'.dart_tool/knee_pushup_frames'
frames=[Image.open(source/f'frame_{i:03d}.png').convert('RGB') for i in range(100)]
# One shared palette keeps colors stable across the loop.
samples=Image.new('RGB',(480*3,480))
for n,i in enumerate([0,25,50]):samples.paste(frames[i],(480*n,0))
palette=samples.quantize(colors=256)
encoded=[f.quantize(palette=palette,dither=Image.Dither.NONE) for f in frames]
output=Path(__file__).parent/'preview.gif'
encoded[0].save(output,save_all=True,append_images=encoded[1:],duration=40,loop=0,optimize=False,disposal=2)
print(output,output.stat().st_size)
