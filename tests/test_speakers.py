import importlib.util, sys, unittest
from pathlib import Path
sys.path.insert(0,str(Path(__file__).resolve().parents[1]/'worker'))
from engine import merge_speakers

class FakeExtractor:
    """Returns a fixed voice vector per second of audio; samples hold the voice id."""
    def __init__(self, voices): self.voices=voices
    def create_stream(self): return self
    def accept_waveform(self, sr, chunk): self.voice=int(chunk[0])
    def input_finished(self): pass
    def compute(self, stream): return self.voices[stream.voice]

@unittest.skipUnless(importlib.util.find_spec('numpy'), 'numpy is installed with the worker runtime')
class SpeakerMergeTests(unittest.TestCase):
    def run_merge(self, voices_by_second, turns, vectors):
        return [t['speaker'] for t in merge_speakers(turns, voices_by_second, 1, FakeExtractor(vectors))]
    def test_fragments_of_one_voice_are_merged(self):
        audio=[0]*40+[1]*40+[0]*20+[1]*3
        turns=[{'start':0,'end':40,'speaker':'a'},{'start':40,'end':80,'speaker':'b'},
               {'start':80,'end':100,'speaker':'c'},{'start':100,'end':103,'speaker':'d'}]
        labels=self.run_merge(audio,turns,{0:[1,0,0],1:[0,1,0]})
        self.assertEqual(labels,['a','b','a','b'])
    def test_distinct_voices_stay_apart(self):
        audio=[0]*30+[1]*30+[2]*30
        turns=[{'start':0,'end':30,'speaker':'a'},{'start':30,'end':60,'speaker':'b'},{'start':60,'end':90,'speaker':'c'}]
        self.assertEqual(self.run_merge(audio,turns,{0:[1,0,0],1:[0,1,0],2:[0,0,1]}),['a','b','c'])
    def test_turns_too_short_to_embed_are_kept(self):
        self.assertEqual(self.run_merge([0],[{'start':0,'end':.5,'speaker':'a'}],{0:[1,0,0]}),['a'])
if __name__=='__main__':unittest.main()
