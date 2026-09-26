#!/bin/bash
set -euo pipefail
project_dir="$(cd "$(dirname "$0")/.." && pwd)"
moa_runtime="$HOME/Library/Application Support/MoaMeeting/runtime"
export PATH="/opt/homebrew/bin:/usr/local/bin:$HOME/.local/bin:$PATH"
for required in uv ffmpeg whisper-cli; do
  if ! command -v "$required" >/dev/null; then
    echo "Missing $required. See README.md for installation." >&2
    exit 1
  fi
done
if [ ! -x "$moa_runtime/bin/python" ]; then
  uv venv --python 3.11 "$moa_runtime"
fi
uv pip install --python "$moa_runtime/bin/python" -r "$project_dir/worker/requirements.txt"
"$moa_runtime/bin/python" "$project_dir/scripts/download_models.py"
echo 'Ready. Run ./scripts/build.sh'
