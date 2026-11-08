# Tự động build và phát hành

| Cách | Chạy khi nào | Làm gì |
|---|---|---|
| `workflows/ci.yml` | Mỗi lần push lên `main` hoặc mở pull request | Phân tích tĩnh, kiểm tra mã sinh tự động còn khớp, chạy toàn bộ test |
| `scripts/release.ps1` | Chạy tay trên máy — **cách phát hành chính** | Chạy test, build APK đã ký trên máy, kiểm chữ ký, gắn thẻ, đưa APK lên Releases |
| `workflows/release.yml` | Chỉ khi bấm tay ở tab Actions — **dự phòng** | Như trên nhưng build trên GitHub (chậm) |

## Phát hành một bản mới

```powershell
.\scripts\release.ps1 v1.2.0
```

Script dừng lại trước khi đụng tới GitHub nếu: còn thay đổi chưa commit, thẻ
đã có, test hỏng, hoặc APK bị ký bằng debug key. Cần `gh` đã đăng nhập
(`gh auth login`). Muốn build thử mà không đẩy gì lên thì thêm `-DryRun`; đã
chạy test rồi thì thêm `-SkipTests`.

`versionCode` suy từ số phiên bản: `v1.2.3` → `10203` (minor, patch < 100).
Workflow dự phòng dùng đúng công thức này, nên đổi qua lại giữa hai cách
không bao giờ ra số lùi — số lùi thì điện thoại từ chối cài đè.

APK nằm ở `build/release/QuanLyChiTieu-v1.2.0.apk` và ở tab **Releases** của
repo. Tải về điện thoại rồi cài đè lên bản cũ — dữ liệu giữ nguyên.

## Cài đặt một lần cho workflow dự phòng

Script trên máy ký bằng `android/moneybook-release.jks` sẵn có, không cần gì
thêm. Riêng workflow dự phòng cần chữ ký release. Keystore **không nằm trong repo** nên
phải nạp qua GitHub Secrets.

### 1. Chuyển keystore thành chuỗi base64

Chạy trên máy, trong thư mục dự án:

```powershell
[Convert]::ToBase64String([IO.File]::ReadAllBytes("android\moneybook-release.jks")) | Set-Clipboard
```

Chuỗi đã nằm trong clipboard.

### 2. Thêm bốn secret

Vào repo trên GitHub → **Settings** → **Secrets and variables** → **Actions** →
**New repository secret**. Thêm lần lượt:

| Tên secret | Giá trị |
|---|---|
| `KEYSTORE_BASE64` | Chuỗi vừa chép ở bước 1 |
| `KEYSTORE_STORE_PASSWORD` | Dòng `storePassword` trong `android/key.properties` |
| `KEYSTORE_KEY_PASSWORD` | Dòng `keyPassword` |
| `KEYSTORE_KEY_ALIAS` | Dòng `keyAlias` |

Xem lại `android/key.properties` nếu quên:

```powershell
Get-Content android\key.properties
```

## Chạy workflow dự phòng

Tab **Actions** → **Phát hành** → **Run workflow**, gõ số phiên bản. Đừng
đẩy thẻ bằng tay rồi chờ — workflow không còn chạy theo thẻ nữa.

## Vì sao phải ký đúng keystore

Android chỉ cho cài đè khi chữ ký trùng với bản đã cài. Ký bằng chữ ký khác thì
điện thoại báo "App not installed", buộc phải gỡ app ra cài lại — **mất toàn bộ
dữ liệu chi tiêu**.

Cả script lẫn workflow đều có bước kiểm tra chữ ký sau khi build: nếu vì lý do gì đó APK bị ký
bằng debug key, nó dừng lại và báo lỗi thay vì phát hành một bản không cài được.

## Giữ keystore ở đâu

Secrets trên GitHub chỉ là bản sao để build. File gốc
`android/moneybook-release.jks` và `android/key.properties` vẫn phải được cất
riêng ở chỗ an toàn. Mất cả hai nơi thì không bao giờ cập nhật được app nữa.
