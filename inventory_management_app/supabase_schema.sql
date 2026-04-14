-- SQL Script to run in Supabase SQL Editor to match the Carta local SQLite database (MULTI-TENANT SECURE)

-- Stores Table
create table public.stores (
  id bigint not null,
  user_id uuid not null default auth.uid() references auth.users(id) on delete cascade,
  name text not null,
  address text not null,
  phone text,
  created_at timestamp with time zone not null default now(),
  primary key (id, user_id)
);

-- Categories Table
create table public.categories (
  id bigint not null,
  user_id uuid not null default auth.uid() references auth.users(id) on delete cascade,
  store_id bigint not null,
  name text not null,
  description text,
  primary key (id, user_id),
  foreign key (store_id, user_id) references public.stores(id, user_id) on delete cascade
);

-- Products Table
create table public.products (
  id bigint not null,
  user_id uuid not null default auth.uid() references auth.users(id) on delete cascade,
  store_id bigint not null,
  category_id bigint not null,
  name text not null,
  brand text not null,
  barcode text,
  quantity integer not null default 0,
  restock_threshold integer not null default 10,
  price double precision not null default 0.0,
  verified integer not null default 0,
  last_updated timestamp with time zone not null default now(),
  supplier text,
  last_delivery_date timestamp with time zone,
  low_stock_flagged integer not null default 0,
  reorder_interval_days integer not null default 7,
  primary key (id, user_id),
  foreign key (store_id, user_id) references public.stores(id, user_id) on delete cascade,
  foreign key (category_id, user_id) references public.categories(id, user_id) on delete cascade
);

-- Purchase Orders Table
create table public.purchase_orders (
  id bigint not null,
  user_id uuid not null default auth.uid() references auth.users(id) on delete cascade,
  store_id bigint not null,
  product_id bigint not null,
  product_name text not null,
  supplier text not null,
  quantity integer not null,
  order_date timestamp with time zone not null,
  delivery_date timestamp with time zone,
  delivered integer not null default 0,
  notes text,
  primary key (id, user_id),
  foreign key (store_id, user_id) references public.stores(id, user_id) on delete cascade,
  foreign key (product_id, user_id) references public.products(id, user_id) on delete cascade
);

-- Enable Row Level Security (RLS) - Secure Policies isolating Users
alter table stores enable row level security;
alter table categories enable row level security;
alter table products enable row level security;
alter table purchase_orders enable row level security;

create policy "Users can only see and edit their own stores" on stores for all using (user_id = auth.uid());
create policy "Users can only see and edit their own categories" on categories for all using (user_id = auth.uid());
create policy "Users can only see and edit their own products" on products for all using (user_id = auth.uid());
create policy "Users can only see and edit their own purchase_orders" on purchase_orders for all using (user_id = auth.uid());
