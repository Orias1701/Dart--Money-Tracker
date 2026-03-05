# Hướng dẫn cài đặt môi trường – SpendSync

Tài liệu này liệt kê SDK, công cụ, extension và các bước cần thiết để build và chạy dự án Flutter SpendSync (Money Tracker) trên máy của bạn.

---

## 1. SDK bắt buộc

### 1.1. Flutter SDK

- **Yêu cầu:** Flutter SDK tương thích Dart **^3.11.0** (xem `pubspec.yaml`).
- **Cài đặt:**
  - Tải: [https://docs.flutter.dev/get-started/install](https://docs.flutter.dev/get-started/install)
  - Hoặc: `winget install Flutter.Flutter` (Windows) / `choco install flutter`
- **Kiểm tra:**  
  `flutter doctor`

### 1.2. Android SDK (để build/chạy Android)

- **Yêu cầu:** Android SDK (thường đi kèm Android Studio hoặc cài Command-line tools).
- **Cài đặt:**
  - Cách 1: Cài [Android Studio](https://developer.android.com/studio) → SDK Manager cài Android SDK.
  - Cách 2: Chỉ cài [Command Line Tools](https://developer.android.com/studio#command-tools).
- **Cấu hình:** Đặt biến môi trường **`ANDROID_HOME`** trỏ tới thư mục SDK (ví dụ: `C:\Users\<user>\AppData\Local\Android\Sdk` trên Windows).
- **Kiểm tra:**  
  `flutter doctor -v` (phần Android toolchain).

### 1.3. Java (JDK) – dùng cho Gradle (Android build)

- **Yêu cầu:** JDK 17 trở lên (khuyến nghị 17 hoặc 21; tránh Java 25 nếu Kotlin/Gradle báo lỗi tương thích).
- **Cài đặt:** [Adoptium](https://adoptium.net/) hoặc Oracle JDK, sau đó set **`JAVA_HOME`**.
- **Kiểm tra:**  
  `java -version`

---

## 2. SDK / nền tảng tùy chọn

| Nền tảng   | Yêu cầu                                      |
|-----------|-----------------------------------------------|
| **iOS**   | macOS + Xcode (và CocoaPods)                  |
| **Windows** | Windows 10/11, Visual Studio 2022 (Desktop C++) |
| **Web**   | Chỉ cần Flutter, không cần thêm SDK đặc biệt  |
| **macOS** | macOS + Xcode                                 |

Chạy `flutter doctor -v` để xem nền tảng nào đã sẵn sàng.

---

## 3. Công cụ (Tools)

| Công cụ   | Mục đích                          |
|-----------|------------------------------------|
| **Git**   | Clone repo, quản lý mã nguồn      |
| **IDE**   | VS Code, Cursor hoặc Android Studio để code và chạy Flutter |

- **Gradle:** Dự án dùng **Gradle Wrapper** (`android/gradlew` / `gradlew.bat`), không bắt buộc cài Gradle toàn cục. Nếu muốn dùng lệnh `gradle` ở mọi nơi thì có thể cài thêm (ví dụ `choco install gradle` với quyền Admin).

---

## 4. Extension (VS Code / Cursor)

Cài các extension sau để code và debug Flutter/Dart thoải mái:

| Extension        | ID / Tên gợi ý        | Mục đích                |
|------------------|------------------------|--------------------------|
| **Dart**         | `Dart-Code.dart`       | Hỗ trợ ngôn ngữ Dart     |
| **Flutter**      | `Dart-Code.flutter`   | Run/debug Flutter, hot reload |
| **Flutter Riverpod Snippets** | (tùy chọn) | Snippet Riverpod |
| **Error Lens**   | (tùy chọn)            | Hiển thị lỗi ngay trên dòng code |

Trong Cursor/VS Code: **Extensions** (Ctrl+Shift+X) → tìm "Dart" và "Flutter" → Install.

---

## 5. Tài khoản và dịch vụ

- **Supabase:** Dự án dùng Supabase (Auth, PostgreSQL). Cần tạo project tại [https://supabase.com](https://supabase.com) và lấy:
  - **Project URL** → `SUPABASE_URL`
  - **anon/public key** → `SUPABASE_ANON_KEY`  
  (Supabase Dashboard → Settings → API.)

---

## 6. Các bước chạy dự án

### 6.1. Clone và cài dependency

```bash
git clone <url-repo>
cd Dart--Money-Tracker
flutter pub get
```

### 6.2. Cấu hình biến môi trường (.env)

- Copy file mẫu:  
  `copy .env.example .env` (Windows) hoặc `cp .env.example .env` (macOS/Linux).
- Mở `.env` và điền:

```env
SUPABASE_URL=https://your-project.supabase.co
SUPABASE_ANON_KEY=your-anon-key-here
```

- **Không commit file `.env`** (đã nằm trong `.gitignore`).

### 6.3. Supabase: Auth và Database

1. **Email đăng ký không bắt buộc xác thực:**  
   Supabase Dashboard → **Authentication** → **Providers** → **Email** → tắt **Confirm email** (nếu muốn đăng nhập ngay sau đăng ký).

2. **Bật RLS và policy:**  
   Mở **SQL Editor**, chạy lần lượt:
   - `Assets/SQL/schema.sql` (tạo bảng nếu chưa có)
   - `Assets/SQL/rls_policies.sql` (tránh lỗi 403 khi thêm tài khoản/giao dịch)
   - `Assets/SQL/rpc_get_email_for_login.sql` (nếu cần đăng nhập bằng email hoặc tên)
   - `Assets/SQL/seed.sql` (nếu cần dữ liệu mẫu)

### 6.4. Chạy ứng dụng

```bash
# Chọn thiết bị (hoặc trình giả lập)
flutter devices

# Chạy (mặc định debug)
flutter run
```

Build release (ví dụ Android APK):

```bash
flutter build apk
```

---

## 7. Kiểm tra nhanh

- **Flutter & SDK:**  
  `flutter doctor -v`
- **Android SDK:**  
  Đã set `ANDROID_HOME` và (nếu dùng) `sdk.dir` trong `android/local.properties` (hoặc để script trong `settings.gradle.kts` tự ghi từ `ANDROID_HOME`).
- **Env:**  
  File `.env` tồn tại, có `SUPABASE_URL` và `SUPABASE_ANON_KEY` đúng.

---

## 8. Tài liệu tham khảo trong repo

- **README.md** – Tổng quan và hướng dẫn nhanh.
- **STRUCTURE.md** – Kiến trúc thư mục và database.
- **.env.example** – Mẫu biến môi trường.

Nếu gặp lỗi build (ví dụ Kotlin/Java version), kiểm tra JDK đang dùng (`java -version`) và khuyến nghị dùng JDK 17 hoặc 21 cho Android build.
