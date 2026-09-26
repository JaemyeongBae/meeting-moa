from pathlib import Path
import urllib.request, tarfile, shutil, concurrent.futures
ROOT = Path.home() / 'Library/Application Support/MoaMeeting/models'
ROOT.mkdir(parents=True, exist_ok=True)
ASSETS = {
 'ggml-large-v3-turbo-q5_0.bin': 'https://huggingface.co/ggerganov/whisper.cpp/resolve/main/ggml-large-v3-turbo-q5_0.bin',
 'segmentation.tar.bz2': 'https://github.com/k2-fsa/sherpa-onnx/releases/download/speaker-segmentation-models/sherpa-onnx-pyannote-segmentation-3-0.tar.bz2',
 'embedding.onnx': 'https://github.com/k2-fsa/sherpa-onnx/releases/download/speaker-recongition-models/3dspeaker_speech_eres2net_base_sv_zh-cn_3dspeaker_16k.onnx',
}
def get(item):
 name, url = item
 target = ROOT / name
 if target.exists(): return
 print('Downloading '+name, flush=True)
 with urllib.request.urlopen(url, timeout=60) as r, target.with_suffix('.part').open('wb') as out:
  shutil.copyfileobj(r, out)
 target.with_suffix('.part').replace(target)
 print('Ready '+name, flush=True)
with concurrent.futures.ThreadPoolExecutor(max_workers=3) as pool:
 list(pool.map(get, ASSETS.items()))
with tarfile.open(ROOT/'segmentation.tar.bz2') as archive:
 member = next(m for m in archive.getmembers() if m.name.endswith('/model.onnx'))
 with archive.extractfile(member) as src, (ROOT/'segmentation.onnx').open('wb') as dst: shutil.copyfileobj(src,dst)
print('Models installed at '+str(ROOT), flush=True)
