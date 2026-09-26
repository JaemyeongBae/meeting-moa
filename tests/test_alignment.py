import sys, unittest
from pathlib import Path
sys.path.insert(0,str(Path(__file__).resolve().parents[1]/'worker'))
from engine import align_segments, speaker_at

class AlignmentTests(unittest.TestCase):
    def test_zero_duration_words_are_not_lost(self):
        data=[{'text':' 네, 제가 하겠습니다.', 'offsets':{'from':1000,'to':2000},'tokens':[
            {'text':'[_BEG_]','offsets':{'from':1000,'to':1000}},
            {'text':' 네, 제가','offsets':{'from':1000,'to':1000}},
            {'text':' 하겠습니다.','offsets':{'from':1000,'to':2000}}]}]
        r=align_segments(data,[{'start':1,'end':2,'speaker':'a'}],3)
        self.assertEqual(r[0]['text'],'네, 제가 하겠습니다.')
    def test_split_one_sentence_at_speaker_change(self):
        data=[{'text':' Hello. Yes.', 'offsets':{'from':0,'to':3000},'tokens':[
            {'text':' Hello.','offsets':{'from':0,'to':1000}},
            {'text':' Yes.','offsets':{'from':2000,'to':3000}}]}]
        r=align_segments(data,[{'start':0,'end':1,'speaker':'a'},{'start':2,'end':3,'speaker':'b'}],3)
        self.assertEqual([(s['speaker'],s['text']) for s in r],[('a','Hello.'),('b','Yes.')])
    def test_unknown_gap_is_not_invented_speaker(self):
        self.assertEqual(speaker_at(4,5,[{'start':0,'end':1,'speaker':'a'}]),'unknown')
    def test_bad_token_decoding_preserves_full_segment(self):
        r=align_segments([{'text':'안녕하세요','offsets':{'from':0,'to':1000},'tokens':[{'text':'잘못된 토큰','offsets':{'from':0,'to':1000}}]}],[{'start':0,'end':1,'speaker':'a'}],1)
        self.assertEqual(r[0]['text'],'안녕하세요')
if __name__=='__main__':unittest.main()
