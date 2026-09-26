# AI 연결 방식

최종 확인: 2026-09-26. 제공자 문서는 바뀔 수 있으므로 배포 전 원문을 확인하세요.

## 미팅모아가 하는 일

앱은 사용자가 별도로 설치한 공식 CLI를 로컬 자식 프로세스로 실행합니다. 미팅모아 서버를 경유하지 않습니다. 토큰 추출, 브라우저 쿠키 복사, 자체 OAuth 클라이언트, 제공자 비공개 엔드포인트 직접 호출은 구현하지 않습니다.

| 연결 | 실행 | 인증 주체 | 결과 |
| --- | --- | --- | --- |
| Codex | `codex exec` | 공식 Codex CLI의 기존 ChatGPT 로그인 | JSON Schema에 맞춘 응답 |
| Claude Code | `claude -p` | 수정되지 않은 공식 Claude Code CLI | `structured_output` 응답 |

요약 요청은 구간별 요약 후 통합할 수 있습니다. 질의응답에는 대화록과 최근 채팅 맥락을 제공합니다. 사용자 선택을 다른 제공자로 자동 전환하지 않습니다. 제공자 오류와 사용 한도 초과는 앱에 표시합니다.

## Claude는 공식 지원인가요?

**공식 CLI의 프로그램 방식 실행은 문서화되어 있습니다. 미팅모아 자체가 Anthropic이 승인한 제품이라는 뜻은 아닙니다.**

[Claude Code 자동화 문서](https://code.claude.com/docs/en/headless)는 `-p`와 JSON Schema 응답을 설명합니다.

[Legal and compliance](https://code.claude.com/docs/en/legal-and-compliance#can-customers-offer-claude-code-in-their-products)는 제품에서 Claude Code를 실행하는 경우 Commercial Terms 및 명시된 조건 준수를 요구합니다. 주요 조건은 다음과 같습니다.

- 공식 Claude Code 바이너리를 수정하지 않고 사용합니다.
- CLI가 제공하는 인증 방법을 제거·비활성화·제한하지 않습니다.
- 최종 사용자가 자기 구독, API 키 또는 지원 제공자의 자격 증명으로 직접 인증합니다.
- 운영자가 사용자 대신 이용료를 지불·재판매·중개하는 구조를 제공하지 않습니다.
- Anthropic이 제품을 제작·보증·제휴한다고 오해하게 표시하지 않습니다.

같은 문서는 **제3자 앱의 자체 Claude.ai 로그인, 자격 증명·세션 토큰 수집 및 중개**를 제한하면서, 최종 사용자가 수정되지 않은 공식 Claude Code에 자기 구독으로 로그인하는 경우를 구분합니다. MIT 라이선스가 이러한 제공자 조건을 대체하지 않습니다. 이 저장소를 서비스나 제품으로 배포하는 운영자는 해당 조건을 검토해야 합니다.

미팅모아의 Claude 어댑터는 CLI의 기존 인증 설정을 유지합니다. `ANTHROPIC_API_KEY`나 외부 제공자 설정이 있으면 **구독 대신 API·제공자 과금**이 적용될 수 있습니다. 설정의 연결 상태는 인증 유형을 보여주지만 실제 청구액이나 남은 한도를 보장하지 않습니다.

참고: [Pro/Max와 Claude Code](https://support.claude.com/en/articles/11145838-use-claude-code-with-your-pro-or-max-plan)

## Codex

[비대화형 실행 문서](https://learn.chatgpt.com/docs/non-interactive-mode)와 [인증 문서](https://learn.chatgpt.com/docs/auth)를 참고합니다.

현재 Codex 어댑터는 ChatGPT 로그인만 사용하며, API 환경 변수를 제거하고 로그인 방식을 확인합니다. `--ignore-user-config`, `--ephemeral`, 읽기 전용 모드로 실행하고 셸·웹검색·앱·플러그인 도구를 끕니다. Codex의 현재 정책과 구독 사용 한도가 적용됩니다.

## 도구와 데이터

Claude는 `--tools ""`, `--strict-mcp-config`, 빈 MCP 설정, 훅 비활성화, 세션 비영속화 옵션으로 호출합니다. 인증은 공식 CLI에 맡깁니다. 기본 사용자 설정과 관리자가 정한 설정은 CLI의 동작·데이터 정책에 영향을 줄 수 있습니다. 앱 자체는 음성 파일을 제공자에게 보내지 않지만, 대화록 텍스트는 요약·질문 요청에 포함됩니다.
