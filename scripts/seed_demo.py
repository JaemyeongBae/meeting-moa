"""Create fictional screenshot data in the separate demo store; no personal files are read."""
import json, shutil
from datetime import datetime, timezone
from pathlib import Path
root = Path.home() / 'Library/Application Support/MoaMeetingDemo/meetings/synthetic-demo'
root.mkdir(parents=True, exist_ok=True)
lines = [
    (0,7.02,'speaker_1','오늘은 미팅모아의 첫 번째 회의입니다. 이번 주에는 맥 버전의 녹음 기능과 회의록 요약을 먼저 완성하겠습니다.'),
    (8.32,15.56,'speaker_2','네, 제가 녹음 기능을 맡겠습니다. 금요일까지 테스트를 마치고 결과를 공유하겠습니다.'),
    (17.54,26.46,'speaker_1','좋습니다. 아이폰 버전은 다음 단계로 미루겠습니다. 회의록은 한국어로 작성하고, 결정 사항과 할 일을 구분해주세요.'),
    (27.66,36.08,'speaker_2','발화자 이름을 수정하는 기능도 넣겠습니다. 다만 출시 날짜는 아직 결정하지 않았습니다.'),
]
meeting = dict(id='synthetic-demo',title='미팅모아 제품 회의 · 데모',createdAt=datetime(2026,9,25,5,0,tzinfo=timezone.utc).timestamp()-978307200,
    audioFile='demo.wav',duration=37.90675,speakers={'speaker_1':'기획 담당','speaker_2':'개발 담당'},interrupted=False,
    segments=[dict(id=str(i),start=a,end=b,speaker=s,text=t) for i,(a,b,s,t) in enumerate(lines)],
    minutes=dict(title='미팅모아 제품 회의',overview='이번 주에는 Mac 버전의 녹음과 회의록 요약을 완성합니다. iPhone 버전은 다음 단계로 진행하며, 출시 날짜는 미정입니다.',
        keyPoints=['Mac 버전 녹음 기능과 회의록 요약을 우선 개발합니다. [00:00]','회의록은 한국어로 작성하고 결정과 할 일을 구분합니다. [00:17]'],
        decisions=['iPhone 버전은 다음 단계로 미룹니다. [00:17]','출시 날짜는 아직 결정하지 않았습니다. [00:27]'],
        actionItems=[dict(task='녹음 기능 테스트 후 결과 공유',owner='개발 담당',due='금요일',evidence='[00:08]'),dict(task='발화자 이름 수정 기능 추가',owner='개발 담당',due='미정',evidence='[00:27]')]),
    messages=[dict(id='demo-question',role='user',text='누가 언제까지 녹음 기능을 테스트하기로 했어?'),
              dict(id='demo-answer',role='assistant',text='개발 담당이 금요일까지 녹음 기능 테스트를 마치고 결과를 공유하기로 했습니다. [00:08]\n\n출시 날짜는 아직 정해지지 않았습니다. 테스트 기한과 출시일은 구분해서 보시면 됩니다. [00:27]')])
(root/'meeting.json').write_text(json.dumps(meeting,ensure_ascii=False,indent=2))
print('Fictional demo store prepared. Start with --demo --demo-home.')
