# Build APK đã ký ngay trên máy rồi đưa lên mục Releases của GitHub.
#
#   .\scripts\release.ps1 v1.2.0
#   .\scripts\release.ps1 v1.2.0 -SkipTests      # đã chạy test rồi
#   .\scripts\release.ps1 v1.2.0 -DryRun         # chỉ build + kiểm chữ ký
#
# Thay cho việc build trên GitHub Actions (chậm). Ký bằng keystore trên máy:
# android/moneybook-release.jks + android/key.properties.
#
# Thứ tự: kiểm tra → test → build → kiểm chữ ký → gắn thẻ + đẩy thẻ → tạo bản
# phát hành kèm APK. Hỏng ở bước nào thì dừng ở bước đó, chưa có gì lên GitHub
# cho tới bước gắn thẻ.

param(
    [Parameter(Mandatory = $true, Position = 0)]
    [string]$Version,
    [switch]$SkipTests,
    [switch]$DryRun
)

$ErrorActionPreference = 'Stop'
Set-Location (Split-Path $PSScriptRoot -Parent)

function Fail([string]$msg) {
    Write-Host "LỖI: $msg" -ForegroundColor Red
    exit 1
}

function Step([string]$msg) {
    Write-Host ""
    Write-Host "==> $msg" -ForegroundColor Cyan
}

function Run([string]$exe, [string[]]$arguments) {
    & $exe @arguments
    if ($LASTEXITCODE -ne 0) { Fail "$exe $($arguments -join ' ') thất bại (mã $LASTEXITCODE)" }
}

# ---- Kiểm tra trước ---------------------------------------------------------

if ($Version -notmatch '^v(\d+)\.(\d+)\.(\d+)$') {
    Fail "Số phiên bản phải có dạng v1.2.3, nhận được '$Version'"
}
$major = [int]$Matches[1]; $minor = [int]$Matches[2]; $patch = [int]$Matches[3]
if ($minor -gt 99 -or $patch -gt 99) { Fail 'minor và patch phải nhỏ hơn 100' }
$buildName = $Version.Substring(1)

# versionCode của Android phải tăng dần, nếu không điện thoại từ chối cài đè.
# Suy thẳng từ số phiên bản để khỏi phải nhớ số nào đã dùng: v1.2.3 → 10203.
# Các bản build trên GitHub trước đây dùng số lần chạy (tới 11), nhỏ hơn hẳn.
$buildNumber = $major * 10000 + $minor * 100 + $patch

if (-not (Test-Path 'android/key.properties') -or -not (Test-Path 'android/moneybook-release.jks')) {
    Fail 'Thiếu android/key.properties hoặc android/moneybook-release.jks — không ký được bản release'
}

if (-not $DryRun) {
    if (-not (Get-Command gh -ErrorAction SilentlyContinue)) { Fail 'Chưa cài GitHub CLI (gh)' }
    & gh auth status *> $null
    if ($LASTEXITCODE -ne 0) { Fail 'gh chưa đăng nhập. Chạy: gh auth login' }

    # Chỉ xét file đã theo dõi: file lạ chưa add (như .claude/) không ảnh hưởng bản build.
    $dirty = git status --porcelain --untracked-files=no
    if ($dirty) { Fail "Còn thay đổi chưa commit, bản phát hành sẽ không khớp với thẻ:`n$dirty" }

    # Bản phát hành phải nằm trên main ở GitHub, không thì thẻ trỏ vào một
    # commit mà main không có (lỡ chạy trên nhánh khác, hoặc quên push).
    Run git @('fetch', '--quiet', 'origin', 'main')
    & git merge-base --is-ancestor HEAD origin/main
    if ($LASTEXITCODE -ne 0) {
        Fail 'Commit hiện tại chưa nằm trên origin/main. Merge / push lên main trước rồi chạy lại'
    }

    if (git tag --list $Version) { Fail "Thẻ $Version đã có trên máy" }
    $remoteTag = git ls-remote --tags origin "refs/tags/$Version"
    if ($remoteTag) { Fail "Thẻ $Version đã có trên GitHub" }
}

Write-Host "Phiên bản $buildName (versionCode $buildNumber), commit $(git rev-parse --short HEAD)"

# ---- Test -------------------------------------------------------------------

if (-not $SkipTests) {
    Step 'Chạy test'
    Run flutter @('test')
}

# ---- Build ------------------------------------------------------------------

Step 'Build APK'
# Chỉ arm64: mọi điện thoại Android đời gần đây đều dùng kiến trúc này, bản gộp
# cả ba kiến trúc nặng gấp hơn hai lần.
Run flutter @(
    'build', 'apk', '--release',
    '--target-platform', 'android-arm64',
    '--build-name', $buildName,
    '--build-number', "$buildNumber"
)

New-Item -ItemType Directory -Force 'build/release' | Out-Null
$apk = "build/release/QuanLyChiTieu-$Version.apk"
Copy-Item 'build/app/outputs/flutter-apk/app-release.apk' $apk -Force

# ---- Kiểm chữ ký ------------------------------------------------------------

Step 'Kiểm tra chữ ký'
# Keystore hỏng hay thiếu thì Gradle lặng lẽ ký bằng debug key, và bản đó không
# cài đè được lên app đang dùng — buộc gỡ app, mất toàn bộ dữ liệu.
$sdk = $env:ANDROID_HOME
if (-not $sdk) { $sdk = $env:ANDROID_SDK_ROOT }
if (-not $sdk -and (Test-Path 'android/local.properties')) {
    $line = Select-String -Path 'android/local.properties' -Pattern '^sdk\.dir=(.*)$' | Select-Object -First 1
    if ($line) { $sdk = $line.Matches[0].Groups[1].Value -replace '\\\\', '\' -replace '\\:', ':' }
}
if (-not $sdk) { $sdk = Join-Path $env:LOCALAPPDATA 'Android\Sdk' }

$apksigner = Get-ChildItem (Join-Path $sdk 'build-tools') -Directory -ErrorAction SilentlyContinue |
    Sort-Object { [version]($_.Name -replace '[^\d\.].*$', '') } -Descending |
    ForEach-Object { Join-Path $_.FullName 'apksigner.bat' } |
    Where-Object { Test-Path $_ } |
    Select-Object -First 1
if (-not $apksigner) { Fail "Không tìm thấy apksigner trong $sdk\build-tools" }

$certs = & $apksigner verify --print-certs $apk 2>&1 | Out-String
if ($LASTEXITCODE -ne 0) { Fail "apksigner verify thất bại:`n$certs" }
Write-Host $certs
if ($certs -match 'CN=Android Debug') {
    Fail 'APK đang bị ký bằng debug key, không cài đè được lên bản đang dùng'
}

$sizeMb = [math]::Round((Get-Item $apk).Length / 1MB, 1)
Write-Host "APK: $apk ($sizeMb MB)" -ForegroundColor Green

if ($DryRun) {
    Write-Host ''
    Write-Host 'DryRun: dừng ở đây, không gắn thẻ và không đẩy gì lên GitHub.' -ForegroundColor Yellow
    exit 0
}

# ---- Phát hành --------------------------------------------------------------

Step "Gắn thẻ $Version và đẩy lên GitHub"
Run git @('tag', $Version)
Run git @('push', 'origin', $Version)

Step 'Tạo bản phát hành'
$notes = @'
Tải file `.apk` bên dưới về điện thoại rồi mở ra cài.

Cài đè lên bản cũ được, dữ liệu chi tiêu giữ nguyên — APK này ký
bằng đúng chữ ký của các bản trước.

Trước khi cập nhật nên vào **Cài đặt → Sao lưu → Sao lưu đầy đủ**
và gửi file JSON cho chính mình, phòng khi cần khôi phục.
'@
Run gh @(
    'release', 'create', $Version, $apk,
    '--title', $Version,
    '--notes', $notes,
    '--generate-notes',
    '--verify-tag'
)

Write-Host ''
Write-Host "Xong: $Version đã lên mục Releases." -ForegroundColor Green
