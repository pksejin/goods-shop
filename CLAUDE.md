# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## 프로젝트 개요

**잔재미코딩 굿즈샵** — 굿즈를 판매하는 소형 쇼핑몰.
GitHub Pages(정적 HTML) + Supabase(인증·DB) + 토스페이먼츠(결제 테스트 모드)로 구성.

## 기술 스택

| 역할 | 기술 |
|---|---|
| 호스팅 | GitHub Pages |
| 인증·DB | Supabase (프로젝트 ID: `iubpepagzzqoebpiella`) |
| 결제 | 토스페이먼츠 테스트 모드 |
| 프론트엔드 | 순수 HTML/CSS/JS (빌드 도구 없음, 외부 CSS 파일 없음) |

## 파일 구조

| 파일 | 역할 |
|---|---|
| `config.js` | Supabase URL·키, Toss 클라이언트 키 |
| `index.html` | 상품 목록 (메인 페이지) |
| `login.html` | 로그인 |
| `signup.html` | 회원가입 |
| `cart.html` | 장바구니 + 결제 시작 |
| `success.html` | 토스 결제 완료 콜백 |
| `orders.html` | 내 결제 내역 |
| `admin.html` | 관리자 대시보드 |
| `schema.sql` | Supabase DB 스키마 전체 |
| `ARCH.md` | 세부 아키텍처 문서 |

## 로컬 실행

빌드 단계 없음. 아무 정적 서버로 서빙하면 됩니다.

```bash
# VS Code Live Server 확장 사용 (권장)
# 또는
npx serve .
```

> `file://` 프로토콜로 직접 열면 Supabase JS가 차단될 수 있으므로 로컬 서버를 사용하세요.

## 주요 설정값

- **Supabase URL·키**: `config.js` 상단
- **Toss 클라이언트 키**: `config.js`의 `TOSS_CLIENT_KEY` — 현재 플레이스홀더. 토스 개발자 콘솔에서 `test_ck_...` 키를 발급받아 교체 필요
- **관리자 계정**: `admin@admin.com` / `superadmin` (Supabase에 실제 계정으로 생성 완료, `profiles.is_admin = true`)

## 코드 작성 규칙

- 코드는 가능한 단순하게 유지
- 요청하지 않은 추가 기능은 임의로 넣지 않음
- 모든 CSS·JS는 각 HTML 파일 안에 인라인으로 작성 (외부 파일 금지)
- 장바구니 상태는 `localStorage`에 `{productId: quantity}` 형태로 보관
