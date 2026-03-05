-- Xóa danh mục cũ (nếu có) để seed lại bộ mới tinh
delete from public.categories where user_id is null;

-- HỆ THỐNG DANH MỤC CHI TIÊU (Expense)
INSERT INTO public.categories (name, type, icon_name, color_hex, is_default, order_index) VALUES
  ('Food & Dining', 'expense', 'restaurant', '#FFD700', true, 1),
  ('Health', 'expense', 'medical_services', '#4169E1', true, 2),
  ('Beauty', 'expense', 'face', '#FF69B4', true, 3),
  ('Job', 'expense', 'work', '#32CD32', true, 4),
  ('Shopping', 'expense', 'shopping_cart', '#FFA500', true, 5),
  ('Transportation', 'expense', 'directions_car', '#8A2BE2', true, 6),
  ('Housing', 'expense', 'home', '#20B2AA', true, 7),
  ('Entertainment', 'expense', 'sports_esports', '#FF4500', true, 8),
  ('Education', 'expense', 'school', '#4682B4', true, 9),
  ('Sports', 'expense', 'pool', '#00FA9A', true, 10),
  ('Social', 'expense', 'people', '#FF8C00', true, 11),
  ('Clothing', 'expense', 'checkroom', '#DDA0DD', true, 12),
  ('Car', 'expense', 'directions_car_filled', '#708090', true, 13),
  ('Electronics', 'expense', 'devices', '#696969', true, 14),
  ('Travel', 'expense', 'flight_takeoff', '#00BFFF', true, 15),
  ('Pets', 'expense', 'pets', '#8B4513', true, 16),
  ('Gifts', 'expense', 'card_giftcard', '#FF1493', true, 17),
  ('Donations', 'expense', 'volunteer_activism', '#FF6347', true, 18),
  ('Family', 'expense', 'family_restroom', '#2E8B57', true, 19);

-- HỆ THỐNG DANH MỤC THU NHẬP (Income)
INSERT INTO public.categories (name, type, icon_name, color_hex, is_default, order_index) VALUES
  ('Salary', 'income', 'payments', '#00FA9A', true, 1),
  ('Bonus', 'income', 'military_tech', '#FFD700', true, 2),
  ('Investment', 'income', 'trending_up', '#9370DB', true, 3),
  ('Freelance', 'income', 'laptop_mac', '#1E90FF', true, 4),
  ('Gifts Received', 'income', 'redeem', '#FF69B4', true, 5),
  ('Others', 'income', 'account_balance_wallet', '#A9A9A9', true, 6);