#!/bin/bash
set -euo pipefail
project_dir="$(cd "$(dirname "$0")/.." && pwd)"
moa_runtime="$HOME/Library/Application Support/MoaMeeting/runtime"
app_dir="$project_dir/dist/미팅모아.app"
swift build --package-path "$project_dir" -c release
mkdir -p "$app_dir/Contents/MacOS" "$app_dir/Contents/Resources"
cp "$project_dir/.build/release/MoaMeeting" "$app_dir/Contents/MacOS/MoaMeeting"
cp "$project_dir/scripts/Moa.icns" "$app_dir/Contents/Resources/Moa.icns"
cp "$project_dir/worker/engine.py" "$app_dir/Contents/Resources/engine.py"
/usr/bin/python3 - "$app_dir" "$moa_runtime/bin/python" <<'PY'
import plistlib,json,sys
from pathlib import Path
app=Path(sys.argv[1])
info=dict(CFBundleExecutable='MoaMeeting',CFBundleIdentifier='kr.moa.meeting.preview',CFBundleName='미팅모아',CFBundleIconFile='Moa.icns',CFBundleDisplayName='미팅모아',CFBundlePackageType='APPL',CFBundleShortVersionString='0.2.0',CFBundleVersion='2',LSMinimumSystemVersion='14.0',NSHighResolutionCapable=True,NSMicrophoneUsageDescription='회의를 녹음하고 대화록을 만들기 위해 마이크를 사용합니다.',NSHumanReadableCopyright='Moa Meeting · Personal preview')
(app/'Contents/Info.plist').write_bytes(plistlib.dumps(info))
(app/'Contents/Resources/runtime.json').write_text(json.dumps({'python':sys.argv[2]}))
PY
codesign --force --sign - --identifier kr.moa.meeting.preview "$app_dir"
echo "$app_dir"
