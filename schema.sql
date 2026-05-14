-- =====================================================
-- 잔재미코딩 굿즈샵 DB 스키마
-- Supabase SQL Editor에 붙여넣고 실행하세요
-- =====================================================

-- 기존 테이블 제거
drop table if exists order_items cascade;
drop table if exists orders cascade;
drop table if exists profiles cascade;
drop table if exists products cascade;
drop function if exists handle_new_user cascade;

-- 상품
create table products (
  id uuid default gen_random_uuid() primary key,
  name text not null,
  description text,
  price integer not null,
  image_url text,
  stock integer default 0,
  is_active boolean default true,
  created_at timestamptz default now()
);

-- 프로필 (is_admin 포함)
create table profiles (
  id uuid references auth.users primary key,
  is_admin boolean default false,
  created_at timestamptz default now()
);

-- 주문 헤더
create table orders (
  id uuid default gen_random_uuid() primary key,
  user_id uuid references auth.users not null,
  total_amount integer not null,
  status text not null default 'pending', -- pending | paid | failed
  toss_order_id text unique,
  toss_payment_key text,
  created_at timestamptz default now()
);

-- 주문 상세 (상품별 행)
create table order_items (
  id uuid default gen_random_uuid() primary key,
  order_id uuid references orders on delete cascade not null,
  product_id uuid references products not null,
  product_name text not null,  -- 주문 시점 상품명 스냅샷
  price integer not null,      -- 주문 시점 가격 스냅샷
  quantity integer not null
);

-- RLS 활성화
alter table products enable row level security;
alter table profiles enable row level security;
alter table orders enable row level security;
alter table order_items enable row level security;

-- products: 누구나 조회 가능 (공개 상품 목록)
create policy "products_public_select" on products for select using (true);

-- profiles: 본인만 조회/수정
create policy "profiles_own_select" on profiles for select using (auth.uid() = id);
create policy "profiles_own_update" on profiles for update using (auth.uid() = id);
-- profiles: 관리자는 전체 조회
create policy "profiles_admin_select" on profiles for select using (
  exists (select 1 from profiles p where p.id = auth.uid() and p.is_admin = true)
);

-- orders: 본인 CRUD
create policy "orders_own_select" on orders for select using (auth.uid() = user_id);
create policy "orders_own_insert" on orders for insert with check (auth.uid() = user_id);
create policy "orders_own_update" on orders for update using (auth.uid() = user_id);
-- orders: 관리자는 전체 조회
create policy "orders_admin_select" on orders for select using (
  exists (select 1 from profiles p where p.id = auth.uid() and p.is_admin = true)
);

-- order_items: 본인 주문 것만
create policy "order_items_own_select" on order_items for select using (
  exists (select 1 from orders o where o.id = order_items.order_id and o.user_id = auth.uid())
);
create policy "order_items_own_insert" on order_items for insert with check (
  exists (select 1 from orders o where o.id = order_items.order_id and o.user_id = auth.uid())
);
-- order_items: 관리자는 전체 조회
create policy "order_items_admin_select" on order_items for select using (
  exists (select 1 from profiles p where p.id = auth.uid() and p.is_admin = true)
);

-- 신규 가입 시 profiles 자동 생성 트리거
create or replace function handle_new_user()
returns trigger as $$
begin
  insert into profiles (id) values (new.id);
  return new;
end;
$$ language plpgsql security definer;

create trigger on_auth_user_created
  after insert on auth.users
  for each row execute function handle_new_user();

-- 관리자 계정 등록 (admin@admin.com, UUID는 실제 생성된 값)
insert into profiles (id, is_admin)
values ('6a80bc9c-40d8-409a-b2a7-7cfab847a97d', true)
on conflict (id) do update set is_admin = true;

-- 샘플 굿즈
insert into products (name, description, price, image_url, stock) values
  ('잔재미코딩 티셔츠', '잔재미코딩 로고가 새겨진 고품질 면 티셔츠. 일상에서도 편하게 입을 수 있어요.', 29000, 'https://placehold.co/400x400/3b82f6/ffffff?text=T-Shirt', 50),
  ('잔재미코딩 스티커 팩', '귀여운 캐릭터 스티커 10종 세트. 노트북, 텀블러 등에 붙여보세요!', 5000, 'https://placehold.co/400x400/10b981/ffffff?text=Stickers', 200),
  ('잔재미코딩 에코백', '튼튼한 캔버스 소재 에코백. 쇼핑백 대신 매일 사용하세요.', 15000, 'https://placehold.co/400x400/f59e0b/ffffff?text=Eco+Bag', 30);
