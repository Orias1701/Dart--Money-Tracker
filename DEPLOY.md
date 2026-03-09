# Deploy – SpendSync

Sau khi chạy `flutter build web` và/hoặc `flutter build apk`, dùng hướng dẫn dưới đây để deploy.

---

## 1. Build (đã chạy)

- **Web:** `flutter build web` → thư mục **`build/web`**
- **Android APK:** `flutter build apk` → file **`build/app/outputs/flutter-apk/app-release.apk`** (~52MB)

---

## 2. Deploy Web (build/web)

Upload toàn bộ nội dung thư mục **`build/web`** lên host tĩnh. Một số cách thường dùng:

### Vercel

```bash
# Cài Vercel CLI (một lần): npm i -g vercel
cd build/web
vercel --prod
```

Hoặc kéo thả thư mục `build/web` vào [vercel.com](https://vercel.com) (Import Project → upload).

### Netlify

- Trên [netlify.com](https://netlify.com): **Sites → Add new site → Deploy manually** → kéo thả thư mục `build/web`.
- Hoặc dùng Netlify CLI: `netlify deploy --prod --dir=build/web`

### Firebase Hosting

```bash
firebase init hosting   # chọn build/web làm public directory
firebase deploy
```

### Supabase Storage (static site)

- Tạo bucket public, upload nội dung `build/web` (có thể dùng Dashboard hoặc API). Cấu hình index.html làm trang mặc định nếu host hỗ trợ.

### GitHub Pages

- Đẩy nội dung `build/web` lên nhánh `gh-pages` hoặc dùng GitHub Actions build Flutter web rồi deploy vào `gh-pages`.

**Lưu ý:** App dùng Supabase với URL/Key trong `.env`. Khi deploy web, cần cấu hình biến môi trường build (ví dụ Vercel/Netlify: thêm `SUPABASE_URL`, `SUPABASE_ANON_KEY`) hoặc dùng file env tại build time (flutter_dotenv đọc lúc build). Nếu build đã chạy trên máy có `.env` đúng thì `build/web` đã nhúng sẵn giá trị đó.

---

## 3. Android APK

- File: **`build/app/outputs/flutter-apk/app-release.apk`**
- Có thể gửi file này cho người dùng cài trực tiếp (sideload) hoặc đăng lên Google Play (thường dùng AAB: `flutter build appbundle`).

---

## 4. Build lại khi cần

```bash
flutter build web          # Web
flutter build apk          # Android APK
flutter build appbundle     # Android AAB (cho Play Store)
```
