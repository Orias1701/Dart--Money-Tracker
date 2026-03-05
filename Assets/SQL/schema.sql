-- 1. Xóa các bảng cũ (nếu có) để làm mới hoàn toàn
drop table if exists public.transaction_tags cascade;
drop table if exists public.transactions cascade;
drop table if exists public.tags cascade;
drop table if exists public.debts_loans cascade;
drop table if exists public.recurring_transactions cascade;
drop table if exists public.budgets cascade;
drop table if exists public.categories cascade;
drop table if exists public.accounts cascade;
drop table if exists public.users cascade;

-- 2. TẠO BẢNG USERS (Người dùng)
create table public.users (
  id uuid references auth.users on delete cascade primary key,
  full_name text,
  avatar_url text,
  is_premium boolean default false,
  role text check (role in ('admin', 'user')) default 'user', -- Gộp cột role trực tiếp vào bảng
  created_at timestamp with time zone default timezone('utc'::text, now()) not null
);

-- 3. TẠO BẢNG ACCOUNTS (Tài khoản/Ví/Thẻ)
create table public.accounts (
  id uuid default uuid_generate_v4() primary key,
  user_id uuid references public.users(id) on delete cascade not null,
  name text not null,
  account_type text check (account_type in ('asset', 'liability')) not null default 'asset',
  balance numeric default 0 not null,
  credit_limit numeric default 0, -- Dành cho thẻ tín dụng (liability)
  statement_date integer check (statement_date between 1 and 31),
  payment_date integer check (payment_date between 1 and 31),
  include_in_total boolean default true,
  currency text default 'VND' not null,
  created_at timestamp with time zone default timezone('utc'::text, now()) not null,
  updated_at timestamp with time zone default timezone('utc'::text, now()) not null
);

-- 4. TẠO BẢNG CATEGORIES (Danh mục)
create table public.categories (
  id uuid default uuid_generate_v4() primary key,
  user_id uuid references public.users(id) on delete cascade, -- Null = Hệ thống mặc định
  parent_id uuid references public.categories(id) on delete cascade, -- Cho phép tạo danh mục con
  name text not null,
  type text check (type in ('income', 'expense')) not null,
  icon_name text not null,
  color_hex text not null, -- Bắt buộc để vẽ biểu đồ
  is_default boolean default false,
  order_index integer default 0,
  is_active boolean default true,
  created_at timestamp with time zone default timezone('utc'::text, now()) not null
);

-- 5. TẠO BẢNG TRANSACTIONS (Giao dịch)
create table public.transactions (
  id uuid default uuid_generate_v4() primary key,
  user_id uuid references public.users(id) on delete cascade not null,
  account_id uuid references public.accounts(id) on delete cascade not null,
  to_account_id uuid references public.accounts(id) on delete cascade, -- Dành cho chuyển khoản
  category_id uuid references public.categories(id) on delete set null,
  type text check (type in ('income', 'expense', 'transfer')) not null,
  amount numeric not null check (amount > 0), -- Luôn lưu số dương
  fee_amount numeric default 0 check (fee_amount >= 0), -- Phí chuyển khoản
  transaction_date timestamp with time zone not null,
  note text,
  image_url text, -- Ảnh hóa đơn
  payee text, -- Người nhận/Người gửi
  status text check (status in ('cleared', 'pending')) default 'cleared',
  created_at timestamp with time zone default timezone('utc'::text, now()) not null,
  updated_at timestamp with time zone default timezone('utc'::text, now()) not null
);

-- 6. TẠO BẢNG TAGS (Nhãn)
create table public.tags (
  id uuid default uuid_generate_v4() primary key,
  user_id uuid references public.users(id) on delete cascade not null,
  name text not null,
  color_hex text not null,
  created_at timestamp with time zone default timezone('utc'::text, now()) not null
);

-- 7. TẠO BẢNG TRANSACTION_TAGS (Liên kết Transactions - Tags)
create table public.transaction_tags (
  transaction_id uuid references public.transactions(id) on delete cascade,
  tag_id uuid references public.tags(id) on delete cascade,
  primary key (transaction_id, tag_id)
);

-- 8. TẠO BẢNG BUDGETS (Ngân sách)
create table public.budgets (
  id uuid default uuid_generate_v4() primary key,
  user_id uuid references public.users(id) on delete cascade not null,
  category_id uuid references public.categories(id) on delete cascade not null,
  amount numeric not null check (amount > 0),
  period text check (period in ('weekly', 'monthly', 'yearly', 'custom')) not null,
  start_date date not null,
  end_date date not null,
  created_at timestamp with time zone default timezone('utc'::text, now()) not null
);

-- 9. TẠO BẢNG RECURRING TRANSACTIONS (Giao dịch định kỳ)
create table public.recurring_transactions (
  id uuid default uuid_generate_v4() primary key,
  user_id uuid references public.users(id) on delete cascade not null,
  account_id uuid references public.accounts(id) on delete cascade not null,
  category_id uuid references public.categories(id) on delete set null,
  type text check (type in ('income', 'expense')) not null,
  amount numeric not null check (amount > 0),
  note text,
  frequency text check (frequency in ('daily', 'weekly', 'monthly', 'yearly')) not null,
  next_date date not null,
  is_active boolean default true,
  created_at timestamp with time zone default timezone('utc'::text, now()) not null
);

-- 10. TẠO BẢNG DEBTS & LOANS (Vay mượn/Sổ nợ)
create table public.debts_loans (
  id uuid default uuid_generate_v4() primary key,
  user_id uuid references public.users(id) on delete cascade not null,
  person_name text not null,
  type text check (type in ('debt', 'loan')) not null,
  amount numeric not null check (amount > 0),
  remaining_amount numeric not null check (remaining_amount >= 0),
  due_date date,
  status text check (status in ('active', 'paid')) default 'active',
  created_at timestamp with time zone default timezone('utc'::text, now()) not null
);

-- --------------------------------------------------------
-- PHẦN CỰC QUAN TRỌNG: TRIGGER CẬP NHẬT TỰ ĐỘNG SỐ DƯ VÍ
-- --------------------------------------------------------
create or replace function update_account_balance()
returns trigger as $$
begin
  -- KHI THÊM GIAO DỊCH MỚI (INSERT)
  if tg_op = 'INSERT' then
    if new.type = 'expense' then
      update public.accounts set balance = balance - new.amount where id = new.account_id;
    elsif new.type = 'income' then
      update public.accounts set balance = balance + new.amount where id = new.account_id;
    elsif new.type = 'transfer' then
      update public.accounts set balance = balance - (new.amount + new.fee_amount) where id = new.account_id;
      if new.to_account_id is not null then
        update public.accounts set balance = balance + new.amount where id = new.to_account_id;
      end if;
    end if;
    return new;
  end if;

  -- KHI XÓA GIAO DỊCH (DELETE)
  if tg_op = 'DELETE' then
    if old.type = 'expense' then
      update public.accounts set balance = balance + old.amount where id = old.account_id;
    elsif old.type = 'income' then
      update public.accounts set balance = balance - old.amount where id = old.account_id;
    elsif old.type = 'transfer' then
      update public.accounts set balance = balance + (old.amount + old.fee_amount) where id = old.account_id;
      if old.to_account_id is not null then
        update public.accounts set balance = balance - old.amount where id = old.to_account_id;
      end if;
    end if;
    return old;
  end if;
  return null;
end;
$$ language plpgsql security definer;

drop trigger if exists on_transaction_inserted on public.transactions;
create trigger on_transaction_inserted
  after insert on public.transactions
  for each row execute function update_account_balance();

drop trigger if exists on_transaction_deleted on public.transactions;
create trigger on_transaction_deleted
  after delete on public.transactions
  for each row execute function update_account_balance();

-- Trigger tự động tạo User profile khi đăng ký + tự động tạo ví mặc định
create or replace function public.handle_new_user()
returns trigger as $$
begin
  -- Tạo profile người dùng vào bảng users
  insert into public.users (id, full_name, avatar_url, role)
  values (new.id, new.raw_user_meta_data->>'full_name', new.raw_user_meta_data->>'avatar_url', 'user');

  -- TỰ ĐỘNG TẠO VÍ MẶC ĐỊNH CHO NGƯỜI DÙNG MỚI (Trải nghiệm UX tuyệt đỉnh)
  insert into public.accounts (user_id, name, account_type, balance, currency)
  values 
    (new.id, 'Tiền mặt', 'asset', 0, 'VND'),
    (new.id, 'Tài khoản Ngân hàng', 'asset', 0, 'VND');

  return new;
end;
$$ language plpgsql security definer;

drop trigger if exists on_auth_user_created on auth.users;
create trigger on_auth_user_created
  after insert on auth.users
  for each row execute procedure public.handle_new_user();