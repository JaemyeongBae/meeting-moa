import json,sys,unittest
from pathlib import Path
from unittest.mock import patch
sys.path.insert(0,str(Path(__file__).resolve().parents[1]/'worker'))
from engine import parse_claude_response,intelligence,claude_environment
class ProviderTests(unittest.TestCase):
    def test_structured_claude_success(self):
        self.assertEqual(parse_claude_response(json.dumps({'is_error':False,'structured_output':{'answer':'ok'}})),{'answer':'ok'})
    def test_provider_error_is_not_a_success(self):
        with self.assertRaisesRegex(RuntimeError,'Claude 요청 실패'):
            parse_claude_response(json.dumps({'is_error':True,'result':'Usage limit reached'}))
    def test_missing_structured_output_is_rejected(self):
        with self.assertRaises(RuntimeError):parse_claude_response('{"result":"not a meeting"}')
    def test_unknown_provider_never_silently_falls_back(self):
        with self.assertRaisesRegex(RuntimeError,'지원하지 않는'):
            intelligence('invalid','prompt',{})
    def test_official_claude_auth_methods_remain_available(self):
        with patch.dict('os.environ',{'ANTHROPIC_API_KEY':'example-for-test','CLAUDECODE':'1'}):  # pragma: allowlist secret — synthetic test sentinel
            env=claude_environment()
            self.assertEqual(env['ANTHROPIC_API_KEY'],'example-for-test')
            self.assertNotIn('CLAUDECODE',env)
if __name__=='__main__':unittest.main()
