# Tự động build và phát hành

Hai quy trình chạy trên GitHub Actions:

| File | Chạy khi nào | Làm gì |
|---|---|---|
| `workflows/ci.yml` | Mỗi lần push lên `main` hoặc mở pull request | Phân tích tĩnh, kiểm tra mã sinh tự động còn khớp, chạy toàn bộ test |
| `workflows/release.yml` | Khi đẩy một thẻ dạng `v1.2.3` | Chạy test, build APK đã ký, tạo bản phát hành kèm file APK |

## Cài đặt một lần

Workflow phát hành cần chữ ký release. Keystore **không nằm trong repo** nên
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

## Phát hành một bản mới

```powershell
git tag v1.0.1
git push origin v1.0.1
```

Chờ vài phút, APK sẽ nằm ở tab **Releases** của repo. Tải về điện thoại rồi
cài đè lên bản cũ — dữ liệu giữ nguyên.

Muốn build thử mà chưa gắn thẻ thì vào tab **Actions** → **Phát hành** →
**Run workflow** và gõ số phiên bản.

## Vì sao phải ký đúng keystore

Android chỉ cho cài đè khi chữ ký trùng với bản đã cài. Ký bằng chữ ký khác thì
điện thoại báo "App not installed", buộc phải gỡ app ra cài lại — **mất toàn bộ
dữ liệu chi tiêu**.

Workflow có một bước kiểm tra chữ ký sau khi build: nếu vì lý do gì đó APK bị ký
bằng debug key, nó dừng lại và báo lỗi thay vì phát hành một bản không cài được.

## Giữ keystore ở đâu

Secrets trên GitHub chỉ là bản sao để build. File gốc
`android/moneybook-release.jks` và `android/key.properties` vẫn phải được cất
riêng ở chỗ an toàn. Mất cả hai nơi thì không bao giờ cập nhật được app nữa.
