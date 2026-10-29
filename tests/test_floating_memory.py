import pathlib, shutil, subprocess, tempfile, unittest
ROOT=pathlib.Path(__file__).resolve().parents[1]
class FloatingMemoryTests(unittest.TestCase):
    @unittest.skipUnless(shutil.which('lua'), 'Lua interpreter unavailable')
    def test_persistence_and_bounds(self):
        with tempfile.TemporaryDirectory() as temp:
            subprocess.run(['lua', str(ROOT/'tests/floating_memory.lua'), str(pathlib.Path(temp)/'windows.tsv'), str(ROOT/'home/.config/hypr/floating-window-memory.lua')],check=True)
