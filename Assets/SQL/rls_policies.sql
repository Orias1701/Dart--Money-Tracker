-- Chạy file này trong Supabase Dashboard → SQL Editor nếu gặp lỗi 403 (Forbidden) khi thêm tài khoản / giao dịch.
-- Row Level Security (RLS) chặn mọi thao tác nếu không có policy.

-- Bảng users: user chỉ xem/sửa chính mình
alter table public.users enable row level security;

drop policy if exists "Users can view own profile" on public.users;
create policy "Users can view own profile"
  on public.users for select using (auth.uid() = id);

drop policy if exists "Users can update own profile" on public.users;
create policy "Users can update own profile"
  on public.users for update using (auth.uid() = id);

-- Trigger handle_new_user cần insert vào users (chạy với security definer) nên không cần policy insert cho user.

-- Bảng accounts: user chỉ thao tác với tài khoản của mình
alter table public.accounts enable row level security;

drop policy if exists "Users can manage own accounts" on public.accounts;
create policy "Users can manage own accounts"
  on public.accounts for all using (auth.uid() = user_id);

-- Bảng categories: select hệ thống + của mình; insert/update/delete chỉ của mình
alter table public.categories enable row level security;

drop policy if exists "Users can view categories" on public.categories;
create policy "Users can view categories"
  on public.categories for select using (user_id is null or auth.uid() = user_id);

drop policy if exists "Users can manage own categories" on public.categories;
create policy "Users can manage own categories"
  on public.categories for all using (auth.uid() = user_id);

-- Bảng transactions
alter table public.transactions enable row level security;

drop policy if exists "Users can manage own transactions" on public.transactions;
create policy "Users can manage own transactions"
  on public.transactions for all using (auth.uid() = user_id);

-- Các bảng còn lại (tags, budgets, recurring_transactions, debts_loans, transaction_tags) nếu cần dùng sau
alter table public.tags enable row level security;
drop policy if exists "Users can manage own tags" on public.tags;
create policy "Users can manage own tags" on public.tags for all using (auth.uid() = user_id);

alter table public.budgets enable row level security;
drop policy if exists "Users can manage own budgets" on public.budgets;
create policy "Users can manage own budgets" on public.budgets for all using (auth.uid() = user_id);

alter table public.recurring_transactions enable row level security;
drop policy if exists "Users can manage own recurring" on public.recurring_transactions;
create policy "Users can manage own recurring" on public.recurring_transactions for all using (auth.uid() = user_id);

alter table public.debts_loans enable row level security;
drop policy if exists "Users can manage own debts" on public.debts_loans;
create policy "Users can manage own debts" on public.debts_loans for all using (auth.uid() = user_id);

alter table public.transaction_tags enable row level security;
drop policy if exists "Users can manage transaction_tags" on public.transaction_tags;
create policy "Users can manage transaction_tags" on public.transaction_tags for all
  using (exists (select 1 from public.transactions t where t.id = transaction_id and t.user_id = auth.uid()));
