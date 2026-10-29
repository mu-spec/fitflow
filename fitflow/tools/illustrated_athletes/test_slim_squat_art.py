"""Small reproducible checks for the offline slim-squat authoring step."""
import unittest
from PIL import Image, ImageDraw

from slim_squat_art import slim_squat_frame


class SlimSquatArtTest(unittest.TestCase):
    def test_head_and_feet_are_unchanged_while_the_middle_is_narrower(self):
        source = Image.new('RGBA', (160, 160), (0, 0, 0, 0))
        draw = ImageDraw.Draw(source)
        draw.rectangle((68, 10, 92, 30), fill=(220, 180, 155, 255))
        draw.rectangle((55, 31, 105, 115), fill=(230, 100, 40, 255))
        draw.rectangle((40, 140, 120, 149), fill=(34, 34, 34, 255))
        result = slim_squat_frame(source)
        self.assertEqual(result.size, source.size)
        self.assertEqual(result.crop((0, 10, 160, 20)).tobytes(),
                         source.crop((0, 10, 160, 20)).tobytes())
        self.assertEqual(result.crop((0, 140, 160, 150)).tobytes(),
                         source.crop((0, 140, 160, 150)).tobytes())
        self.assertLess(result.crop((0, 70, 160, 71)).getchannel('A').getbbox()[2]
                        - result.crop((0, 70, 160, 71)).getchannel('A').getbbox()[0], 51)

    def test_rejects_opaque_frame_or_invalid_factor(self):
        with self.assertRaises(ValueError):
            slim_squat_frame(Image.new('RGB', (10, 10), 'white'))
        with self.assertRaises(ValueError):
            slim_squat_frame(Image.new('RGBA', (10, 10)), width=.2)


if __name__ == '__main__':
    unittest.main()
