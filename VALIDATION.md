# Validation — 2026-09-26

Environment: Apple M4 Pro, 24 GB unified memory, macOS 26.5.2, Swift 6.2.3,
Codex CLI 0.156.1 signed in with ChatGPT.

- Swift release build and application bundle signing succeeded.
- Four regression tests passed: zero-duration words preserved; speaker changes split inside a sentence; unassigned gaps stay unknown; malformed token text falls back to complete segment text.
- Generated a 37.90675-second Korean fixture with macOS Yuna and Eddy voices. This is synthetic test data, not a real meeting.
- Offline Whisper + sherpa-onnx pipeline returned four turns and two speakers. The application repeated the pipeline with automatic speaker counting and also found two speakers.
- Token alignment originally dropped zero-duration words (such as “네, 제가”). This was corrected and the real audio run was repeated.
- A transcription error remains in the synthetic fixture: “출시 날짜” was recognized as “출신할 차”. The summary marked that phrase as unclear instead of inventing its meaning. Real meeting accuracy has not been benchmarked.
- A real Codex request returned schema-conforming JSON using the existing ChatGPT login.
- The app created and saved the summary after transcription. The summary included decisions and action items with timestamps.
- The chat worker answered the question about the recording test owner and deadline: speaker 2, Friday, [00:08].
- Native UI was launched and inspected. Empty state, imported meeting, progress, and speaker transcript were observed. Audio playback state was observed.
- Input audio was imported via the app's `--import` startup route, which invokes the same importURL method as the file picker. Automated interaction with the macOS Go to Folder sheet was unreliable, so completing that sheet was not claimed as verified.
- Microphone recording code is included, but physical microphone capture has not been exercised. The first recording requires the user's macOS microphone permission.
- System audio capture, real-time transcription, iPhone support, public distribution/notarization, and multi-hour stress tests are outside this preview.

Developer output lives in ignored `artifacts/`. The sample meeting in the app is intentionally retained so the user can try playback, editing, summary, and follow-up questions immediately.

## v0.2

- Renamed the visible app, window and bundle to 미팅모아 (MeetingMoa), retaining the existing data folder and bundle identifier for upgrades.
- Added a persistent Codex / Claude Code selector and connection checks.
- Tested real Claude Code structured summary and transcript Q&A using synthetic audio-derived text. CLI authentication was owned by the user's existing subscription login; no token extraction or direct backend calls were used.
- Claude's own configured API-key and supported-provider authentication methods remain available. API credentials may change how usage is billed.
- Nine regression tests passed, covering alignment, malformed/error Claude responses, unknown-provider rejection, and preservation of official authentication choices.
- Captured five UI screenshots using a dedicated demo store. Screenshot content is fictional, authored presentation data, not an accuracy benchmark.
- Microphone permission and capture should be checked on each user's Mac; the public documentation does not include personal microphone tests.
