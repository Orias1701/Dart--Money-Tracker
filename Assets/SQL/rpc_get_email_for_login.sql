-- Chạy trong Supabase SQL Editor nếu muốn đăng nhập bằng "email hoặc tên hiển thị".
-- RPC trả về email để client gọi signInWithPassword. Nếu login_id chứa '@' thì trả về chính nó, ngược lại tìm email từ public.users.full_name.

create or replace function public.get_email_for_login(login_id text)
returns text
language plpgsql
security definer
set search_path = public
as $$
declare
  result text;
begin
  login_id := trim(login_id);
  if login_id = '' then
    return null;
  end if;
  if position('@' in login_id) > 0 then
    return login_id;
  end if;
  select u.email into result
  from auth.users u
  inner join public.users p on p.id = u.id
  where p.full_name = login_id
  limit 1;
  return result;
end;
$$;

-- Cho phép role anon gọi (user chưa đăng nhập).
grant execute on function public.get_email_for_login(text) to anon;
