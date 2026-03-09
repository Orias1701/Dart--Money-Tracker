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
- **Windows – đặt JAVA_HOME vĩnh viễn (tránh lỗi "supplied javaHome seems to be invalid"):**  
  `JAVA_HOME` phải trỏ tới **thư mục JDK có chứa `bin\java.exe`** (ví dụ `E:\_Compliers\JavaJDK\JavaJDK21`, không phải `E:\_Compliers\JavaJDK`). Trong PowerShell (chạy một lần):
  ```powershell
  [System.Environment]::SetEnvironmentVariable("JAVA_HOME", "E:\_Compliers\JavaJDK\JavaJDK21", "User")
  ```
  Sau đó **đóng hết Cursor rồi mở lại** để extension Gradle nhận biến mới.

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
   - `Assets/SQL/migration_groups_rls_rpc.sql` (**bắt buộc** – tránh lỗi 500 khi load nhóm, giao dịch, tạo nhóm, tham gia nhóm)
   - `Assets/SQL/seed.sql` (nếu cần dữ liệu mẫu)
   
   **Nếu gặp lỗi 500** khi vào Me, Records, Charts hoặc khi tạo giao dịch: chạy `Assets/SQL/migration_groups_rls_rpc.sql` trong SQL Editor.

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

### 6.5. Chạy trên Web – lỗi Hot Restart (CanvasKit)

Khi chạy **Flutter Web** (`flutter run -d chrome` hoặc chọn Chrome), **Hot Restart** đôi khi gây lỗi:

```text
LateInitializationError: Field '_handledContextLostEvent' has not been initialized.
```

Đây là **lỗi đã biết** của Flutter (CanvasKit/WebGL), không phải do code dự án.

**Cách xử lý:**

1. **Dùng Full Restart thay vì Hot Restart:** Dừng app (Stop) rồi chạy lại `flutter run -d chrome` (hoặc nút Run). Hot **Reload** (r) thường vẫn dùng được.
2. **Dùng HTML renderer (tránh CanvasKit):** Chạy với `--web-renderer html`:
   ```bash
   flutter run -d chrome --web-renderer html
   ```
   Renderer HTML ít gặp lỗi context loss khi restart hơn, nhưng có thể chậm hơn CanvasKit trên một số giao diện.

---

## 7. Kiểm tra nhanh

- **Flutter & SDK:**  
  `flutter doctor -v`
- **Android SDK:**  
  Đã set `ANDROID_HOME` và (nếu dùng) `sdk.dir` trong `android/local.properties` (hoặc để script trong `settings.gradle.kts` tự ghi từ `ANDROID_HOME`).
- **Env:**  
  File `.env` tồn tại, có `SUPABASE_URL` và `SUPABASE_ANON_KEY` đúng.

---

## 8. Lỗi thường gặp (Troubleshooting)

### LicenceNotAcceptedException (NDK / Android SDK)

- **Triệu chứng:** Build báo `LicenceNotAcceptedException`, thiếu `ndk;28.2.x` hoặc SDK packages.
- **Cách 1:** Chạy và chấp nhận giấy phép (gõ `y` khi được hỏi). **Lưu ý:** đường dẫn phải có **ký tự ổ đĩa** (ví dụ `E:`).
  ```powershell
  # PowerShell – thay E: bằng ổ đĩa của bạn nếu khác
  & "E:\_DevTools\Android\sdk\cmdline-tools\latest\bin\sdkmanager.bat" --licenses
  ```
  Hoặc nếu đã set `ANDROID_HOME`:
  ```powershell
  & "$env:ANDROID_HOME\cmdline-tools\latest\bin\sdkmanager.bat" --licenses
  ```
- **Cách 2:** Đã tạo sẵn thư mục `licenses` và một số file trong SDK; nếu vẫn lỗi, dùng Cách 1 hoặc Android Studio → SDK Manager → cài NDK và chấp nhận license.

### JavaVersion / IllegalArgumentException: 25.0.1

- **Triệu chứng:** Gradle báo `IllegalArgumentException: 25.0.1` khi build Android (Kotlin không nhận Java 25).
- **Cách xử lý:** Dùng **JDK 17 hoặc 21** cho Android build:
  - Đặt `JAVA_HOME` trỏ tới JDK 17/21, hoặc
  - Trong `android/gradle.properties` bỏ comment và sửa đường dẫn:
    ```properties
    org.gradle.java.home=C:\\Program Files\\Java\\jdk-17
    ```
  Sau đó chạy lại `flutter build apk` hoặc `./gradlew assembleDebug`.

---

## 9. Tài liệu tham khảo trong repo

- **README.md** – Tổng quan và hướng dẫn nhanh.
- **STRUCTURE.md** – Kiến trúc thư mục và database.
- **.env.example** – Mẫu biến môi trường.
