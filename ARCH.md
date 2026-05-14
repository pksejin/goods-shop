# ARCH.md — 잔재미코딩 굿즈샵 아키텍처

## DB 테이블 구조 (ERD)

```
auth.users (Supabase 내장)
    │
    ├─── profiles
    │       id (FK → auth.users)
    │       is_admin (boolean)
    │       created_at
    │
    └─── orders
            id
            user_id (FK → auth.users)
            total_amount
            status          'pending' | 'paid' | 'failed'
            toss_order_id   (Toss 결제창에 넘기는 고유 주문 ID)
            toss_payment_key (결제 완료 후 Toss가 발급하는 키)
            created_at
                │
                └─── order_items
                        id
                        order_id (FK → orders)
                        product_id (FK → products)
                        product_name  ← 주문 시점 스냅샷
                        price         ← 주문 시점 스냅샷
                        quantity

products
    id
    name / description / price
    image_url
    stock
    is_active
    created_at
```

## RLS(Row Level Security) 정책 요약

| 테이블 | 일반 유저 | 관리자 |
|---|---|---|
| `products` | SELECT 전체 (공개) | — |
| `profiles` | 본인만 SELECT·UPDATE | 전체 SELECT |
| `orders` | 본인만 SELECT·INSERT·UPDATE | 전체 SELECT |
| `order_items` | 본인 주문 것만 SELECT·INSERT | 전체 SELECT |

관리자 판단 기준: `profiles.is_admin = true` (서버 RLS에서 직접 확인)

## 결제 플로우

```
[cart.html]
  사용자가 "결제하기" 클릭
      │
      ▼
  로그인 확인 → 미로그인이면 login.html?redirect=cart.html
      │
      ▼
  Supabase에 orders INSERT (status: 'pending')
  Supabase에 order_items INSERT
      │
      ▼
  TossPayments.payment.requestPayment() 호출
      │
  ┌───┴───┐
  │ 성공  │ 실패
  ▼       ▼
[success.html]   [cart.html]
  paymentKey,
  orderId,
  amount를
  URL params로 수신
      │
      ▼
  orders UPDATE
    status → 'paid'
    toss_payment_key 저장
      │
      ▼
  localStorage 장바구니 비우기
  주문 완료 화면 표시
```

> **주의**: success.html에서의 결제 확인은 클라이언트 사이드입니다.
> 실제 서비스에서는 Supabase Edge Function 또는 서버에서
> Toss API(`POST /v1/payments/confirm`)를 호출해 검증해야 합니다.

## 장바구니 구조

`localStorage` 키: `'cart'`

```js
// 저장 형태
{
  "uuid-of-product-1": 2,  // productId: quantity
  "uuid-of-product-2": 1
}
```

- 상품 추가: `index.html`의 "장바구니 담기" 버튼
- 수량 변경·삭제: `cart.html`
- 장바구니 비우기: `success.html` 결제 완료 후 `localStorage.removeItem('cart')`

## 인증 흐름

```
회원가입(signup.html)
  supabase.auth.signUp() → profiles 트리거 자동 생성
      ↓
로그인(login.html)
  supabase.auth.signInWithPassword()
  → ?redirect 파라미터가 있으면 해당 페이지로, 없으면 index.html
      ↓
세션 확인 (각 페이지 init()에서)
  supabase.auth.getUser()
  → null이면 login.html로 redirect (보호된 페이지만)
```

이메일 인증: **비활성화** (`mailer_autoconfirm: true` — Supabase 설정 완료)

## GitHub Pages 배포 절차

1. 이 폴더에서 git 초기화: `git init`
2. GitHub에 새 저장소(repository) 생성
3. 파일 push:
   ```bash
   git add .
   git commit -m "init: 굿즈샵 초기 구조"
   git remote add origin https://github.com/<username>/<repo>.git
   git push -u origin main
   ```
4. GitHub 저장소 → Settings → Pages → Source: `main` 브랜치 루트 선택
5. 배포 URL: `https://<username>.github.io/<repo>/`
6. `config.js`의 Toss `successUrl` 확인 — `success.html` 절대경로가 GitHub Pages URL과 일치해야 함
   (현재 `cart.html`에서 `location.origin + ... + 'success.html'`로 동적 계산하므로 자동 처리됨)

## 관리자 계정

- 이메일: `admin@admin.com`
- 비밀번호: `superadmin`
- Supabase Auth에 실제 계정으로 생성됨
- `profiles.is_admin = true` 설정 완료
- 로그인 후 `admin.html` 접근 가능
