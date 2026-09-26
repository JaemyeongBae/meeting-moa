"""Fail if the staged/public tree contains likely private or generated material.
This is a focused repository check, not a guarantee that all secrets are detected.
"""
import getpass, re, struct, subprocess, sys
from pathlib import PurePosixPath

paths = subprocess.check_output(['git','ls-files','-z']).decode().split('\0')
errors=[]
blocked_parts={'.venv','.build','dist','artifacts','models','runtime','meetings','jobs','__pycache__'}
blocked_ext={'.wav','.aiff','.m4a','.mp3','.mp4','.onnx','.pt','.bin','.sqlite','.db','.pem','.key','.p12','.log'}
patterns={
    'absolute personal home path':re.compile(r'/Users/[A-Za-z0-9._-]+/'),
    'email address':re.compile(r'\b[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}\b'),
    'OpenAI/Anthropic-style key':re.compile(r'\bsk-(?:ant-)?[A-Za-z0-9_-]{24,}\b'),
    'GitHub token':re.compile(r'\b(?:gh[pousr]_[A-Za-z0-9]{30,}|github_pat_[A-Za-z0-9_]{30,})\b'),
    'private key':re.compile(r'-----BEGIN (?:RSA |EC |OPENSSH )?PRIVATE KEY-----'),
}
for name in filter(None,paths):
    path=PurePosixPath(name)
    if blocked_parts.intersection(path.parts) or path.suffix.lower() in blocked_ext or path.name in {'auth.json','credentials.json','runtime.json'} or path.name.startswith('.env'):
        errors.append(f'{name}: private/generated file type');continue
    data=subprocess.check_output(['git','show',':'+name])
    if path.suffix.lower()=='.png':
        if not name.startswith('docs/screenshots/'):
            errors.append(f'{name}: image outside reviewed screenshot directory')
        offset=8
        while offset+12<=len(data):
            length=struct.unpack('>I',data[offset:offset+4])[0];kind=data[offset+4:offset+8]
            if kind in {b'eXIf',b'tEXt',b'iTXt',b'zTXt'}:errors.append(f'{name}: metadata chunk {kind.decode()}')
            offset+=length+12
        continue
    if name=='scripts/Moa.icns':continue
    try:text=data.decode('utf-8')
    except UnicodeDecodeError:
        errors.append(f'{name}: unexpected binary file');continue
    for label,pattern in patterns.items():
        if pattern.search(text):errors.append(f'{name}: {label}')
    # Only flag a non-generic local account name, without logging its value.
    user=getpass.getuser()
    if user not in {'runner','root','user','admin'} and re.search(r'(?<![\w])'+re.escape(user)+r'(?![\w])',text,re.I):
        errors.append(f'{name}: local account name')
if errors:
    print('\n'.join(errors));sys.exit(1)
print(f'Public-tree check passed: {len(list(filter(None,paths)))} tracked files. Images still require visual review.')
