from pathlib import Path
import subprocess, wave, json
root=Path(__file__).resolve().parents[1]/'artifacts'
root.mkdir(exist_ok=True)
lines=[
 ('Yuna','오늘은 모아 앱의 첫 번째 회의입니다. 이번 주에는 맥 버전의 녹음 기능과 회의록 요약을 먼저 완성하겠습니다.'),
 ('Eddy (한국어(한국))','네, 제가 녹음 기능을 맡겠습니다. 금요일까지 테스트를 마치고 결과를 공유하겠습니다.'),
 ('Yuna','좋습니다. 아이폰 버전은 다음 단계로 미루겠습니다. 회의록은 한국어로 작성하고, 결정 사항과 할 일을 구분해주세요.'),
 ('Eddy (한국어(한국))','발화자 이름을 수정하는 기능도 넣겠습니다. 다만 출시 날짜는 아직 결정하지 않았습니다.'),
]
parts=[]
for i,(voice,text) in enumerate(lines):
 a=root/f'voice-{i}.aiff';w=root/f'voice-{i}.wav'
 subprocess.run(['say','-v',voice,'-r','165','-o',str(a),text],check=True)
 subprocess.run(['ffmpeg','-loglevel','error','-y','-i',str(a),'-ar','16000','-ac','1','-c:a','pcm_s16le',str(w)],check=True)
 with wave.open(str(w),'rb') as f: parts.append(f.readframes(f.getnframes()))
with wave.open(str(root/'모아 테스트 회의.wav'),'wb') as out:
 out.setnchannels(1);out.setsampwidth(2);out.setframerate(16000)
 for p in parts:out.writeframes(p+b'\0'*32000)
job=root/'transcription-job';job.mkdir(exist_ok=True)
(job/'request.json').write_text(json.dumps({'mode':'transcribe','audio':str(root/'모아 테스트 회의.wav'),'language':'ko','speakerCount':2}))
print(root/'모아 테스트 회의.wav')
