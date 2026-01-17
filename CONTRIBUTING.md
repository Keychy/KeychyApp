# 🛠️ Keychy Contribution Guide

`Keychy 프로젝트` 에 기여해주셔서 감사합니다.  
아래 가이드는 일관된 협업과 깔끔한 히스토리를 위한 최소한의 규칙입니다.


## Branch Strategy

`release` ← `develop` ← `feature/feat-name`

- `release`: 앱스토어 배포 / 프로덕션 브랜치
- `develop`: 개발 통합 브랜치
- `feature 브랜치`: 기능 단위 작업 브랜치

---

## Branch Naming Rules

- 소문자만 사용
- 타입 뒤에는 /
- 단어 구분은 -

Examples:
- feature/keyring-voice-memo
- bugfix/collection-crash

---

## Branch Types

| Type | Description | Example |
|------|------------|---------|
| release | 프로덕션 / 배포 | - |
| develop | 개발 통합 | - |
| feature/ | 새로운 기능 개발 | feature/keyring-maker |
| bugfix/ | 버그 수정 | bugfix/keyring-crash |
| chore/ | 빌드, 설정, 환경 변경 | chore/setup-ci |
| docs/ | 문서 작업 | docs/readme-update |
| refactor/ | 코드 리팩토링 | refactor/keyring-model |
| style/ | UI/UX 스타일링 | style/button-design |
| perf/ | 성능 최적화 | perf/image-loading |

---

## Commit Convention

커밋 메시지는 아래 형식을 따릅니다.

### Commit Types

| Type | Description | Example |
|------|------------|---------|
| feat | 새로운 기능 추가 | feat: 키링에 음성 메모 기능 추가 |
| fix | 버그 수정 | fix: 컬렉션 화면 크래시 버그 수정 |
| chore | 빌드, 설정 변경 | chore: 의존성 업데이트 |
| docs | 문서 작업 | docs: API 가이드 추가 |
| refactor | 코드 리팩토링 | refactor: KeyringManager 구조 개선 |
| style | UI/UX 스타일 변경 | style: 메인 화면 버튼 디자인 개선 |
| perf | 성능 최적화 | perf: 이미지 로딩 속도 개선 |

---

## Pull Request Rules

- 모든 작업은 `feature` 브랜치에서 진행합니다.
- PR 대상 브랜치는 `develop` 입니다.
- PR 제목은 커밋 컨벤션을 따릅니다.
- 최소 1명 이상 승인 후 merge 합니다.
- Merge 방식은 Merge Commit 을 사용합니다.
