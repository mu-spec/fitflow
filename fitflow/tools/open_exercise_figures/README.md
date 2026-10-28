# Locally authored and adapted exercise figures

The JSON files contain the key poses for figures authored or adapted for Home Workout using the Open Exercise Figures mannequin renderer. Adapted upstream figures are CC0 1.0; its `render.py` code is MIT-0. The upstream author did not review or endorse the changes. `assets/animations/open_exercise_figures/NOTICE.md` lists each source and adaptation.

These files and the Python script are **authoring tools**, not application runtime dependencies. The rendered WebPs are bundled by Flutter and work offline.

To regenerate the local loops, obtain the files below from the pinned commit `a0574d54baaf23f5784dfdebd5c65f6a87fd5194`:

```sh
curl -L https://raw.githubusercontent.com/AbanoubAmir/open-exercise-figures/a0574d54baaf23f5784dfdebd5c65f6a87fd5194/render.py -o /tmp/oef-render.py
curl -L https://raw.githubusercontent.com/AbanoubAmir/open-exercise-figures/a0574d54baaf23f5784dfdebd5c65f6a87fd5194/animations/3533.webp -o /tmp/oef-squat.webp
python3 -m pip install pillow numpy
python3 tools/open_exercise_figures/build_demos.py \
  --renderer /tmp/oef-render.py \
  --squat-source /tmp/oef-squat.webp \
  --output assets/animations/open_exercise_figures
```

The script builds the locally authored/adapted files only; unchanged upstream clips are identified in the notice. It checks authored and interpolated poses for below-floor joints and performs a few movement-specific contact checks. **Those checks do not establish biomechanical correctness.** Have a fitness professional review the demonstrations, including intermediate poses, before release.
