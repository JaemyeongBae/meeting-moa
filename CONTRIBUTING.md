# Contributing

버그 수정, 한국어 인식 개선, 접근성, 테스트와 문서 기여를 환영합니다.

1. 이슈에서 구체적인 문제와 재현 절차를 설명합니다. 실제 회의나 개인정보 대신 합성 자료를 사용하세요.
2. 브랜치를 만들고 변경합니다. SwiftUI 앱은 `Sources/MoaMeeting/`, 음성·AI 처리는 `worker/engine.py`입니다.
3. `swift build -c release`와 `python3 -m unittest discover -s tests -v`를 실행합니다.
4. UI 변경에는 데모 모드 스크린샷을 첨부합니다. 기기별 절대 경로, 토큰, 로그인 화면을 포함하지 마세요.
5. 변경 이유, 검증 방법, 남은 한계를 PR에 적습니다.

기여한 코드는 프로젝트 MIT 라이선스로 제공하는 것으로 간주합니다. 외부 코드·모델을 추가하면 출처와 해당 라이선스를 함께 명시하세요.

녹음 파일·모델·런타임·빌드 결과는 커밋하지 않습니다. 커밋 전 `git diff --cached`와 `python3 scripts/audit_public_tree.py`를 확인하세요.
