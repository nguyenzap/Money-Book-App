# MoneyBook — App quản lý chi tiêu cá nhân

App Android offline, dùng riêng. Mọi nhập liệu thủ công. Dữ liệu nằm hoàn toàn
trong máy, không server, không tài khoản.

## Chạy và build

```powershell
flutter run -d <device>                 # dev, hot reload bằng phím r
flutter test                            # 281 test, chạy trong ~2 giây
flutter analyze
dart run build_runner build             # BẮT BUỘC sau khi sửa lib/core/db/tables.dart
flutter build apk --release --target-platform android-arm64
adb install -r build\app\outputs\flutter-apk\app-release.apk
```

Toolchain đã cấu hình sẵn: Flutter 3.41.2, JDK 17 tại `C:\Users\Admin\.jdks\jdk-17.0.20.1+1`
(trỏ bằng `flutter config --jdk-dir`, vì JDK 23 mặc định của máy quá mới cho Gradle),
Android SDK 36 + cmdline-tools.

## Quy tắc bất di bất dịch

**Số tiền là `int` = số đồng VND.** Không bao giờ dùng `double`.

**`amount` trong DB luôn dương.** Dấu suy ra từ `kind`. Không được lưu số âm —
làm vậy sẽ có hai nguồn sự thật và sổ sách sẽ lệch.

**Số dư ví tính bằng đúng một công thức, không rẽ nhánh theo loại giao dịch:**

```
số dư = initial_balance
      + tổng amount của giao dịch có wallet_to_id   = ví này
      - tổng amount của giao dịch có wallet_from_id = ví này
      (chỉ tính deleted_at IS NULL)
```

Tuyệt đối không viết `if (kind == expense) balance -= amount` ở bất kỳ đâu.

**`lib/core/domain/tx_kind.dart` là nguồn sự thật duy nhất** về dấu tiền, về việc
loại nào cần danh mục / cần người / cần chân ví nào. Thêm loại giao dịch mới thì
chỉ sửa file này; màn hình `tx_editor_screen.dart` tự dựng form theo các cờ đó.

**Công nợ dùng cột `debt_delta` lưu sẵn**, không suy ra lúc truy vấn. Dương =
người đó nợ mình, âm = mình nợ họ. Nhờ vậy sổ nợ chỉ là một phép SUM, và xử lý
được cả trường hợp xoá nợ (không có dòng tiền nên không suy ngược được từ ví).

**`day_key` / `month_key` tính sẵn ở Dart theo giờ địa phương.** Không dùng
`strftime` của SQLite — nó quy về UTC, làm giao dịch lúc 23h30 ngày cuối tháng
bị xếp nhầm sang tháng sau.

**Thống kê chỉ tính `income` và `expense`.** Chuyển ví không phải chi tiêu; vay
mượn là dòng nợ; điều chỉnh số dư càng không.

**SQLite mặc định TẮT khoá ngoại** — `PRAGMA foreign_keys = ON` được bật trong
`beforeOpen`. Bỏ đi là mọi `references(...)` thành vô nghĩa.

## Cấu trúc

```
lib/core/
  domain/tx_kind.dart      ★ enum 8 loại + logic dấu tiền
  db/tables.dart           định nghĩa bảng (sửa xong PHẢI chạy build_runner)
  db/database.dart         migration, PRAGMA, dữ liệu gieo sẵn
  db/repository.dart       toàn bộ truy vấn — không viết SQL ở tầng UI
  format/money.dart        int đồng <-> chuỗi có dấu chấm, TextInputFormatter
  format/dates.dart        dayKey/monthKey, nhãn tiếng Việt
  providers.dart           Riverpod, đều là StreamProvider nên UI tự cập nhật
lib/features/<tính năng>/  mỗi thư mục một miền nghiệp vụ
```

## Ràng buộc nghiệp vụ đã cài

- Ví có giao dịch: không xoá được, chỉ lưu trữ (`is_archived`).
- Người còn dư nợ khác 0: không xoá được, phải tất toán trước.
- Xoá danh mục: giao dịch giữ nguyên, chỉ thành "Chưa phân loại".
- Xoá giao dịch là xoá mềm (`deleted_at`) để hoàn tác được.
- Trả dùm sinh 2 giao dịch cùng `group_id`; xoá thì hỏi để xoá cả cặp.

## Về biểu đồ

Cơ cấu chi theo danh mục dùng **thanh ngang một tông, đậm dần**, không dùng biểu
đồ tròn nhiều màu. Lý do đã kiểm chứng bằng công cụ validate màu: quá 3-4 màu thì
các lát bánh không còn phân biệt được, nhất là với người mù màu. Ở dạng thanh,
danh tính đến từ nhãn chữ nên số lượng danh mục không bị giới hạn.

## Tự động build

`.github/workflows/ci.yml` chạy analyze + test mỗi lần push. Workflow
`release.yml` build APK đã ký và tạo bản phát hành khi đẩy thẻ `v1.2.3`:

```powershell
git tag v1.0.1
git push origin v1.0.1
```

Số phiên bản lấy từ tên thẻ qua `--build-name`, nên không phải sửa `pubspec.yaml`.
Keystore nạp từ GitHub Secrets (xem `.github/README.md`), và có một bước chạy
`apksigner` chặn lại nếu APK lỡ bị ký bằng debug key.

## Chữ ký release

`android/moneybook-release.jks` + `android/key.properties` **không commit** nhưng
phải sao lưu riêng. Mất chúng thì không cài đè bản mới lên app đang dùng được
nữa, buộc phải gỡ app — mất toàn bộ dữ liệu chi tiêu.

## Trả dùm

Nằm trong luồng ghi Chi tiêu bằng một công tắc, không phải màn hình riêng, vì
bản chất nó là một khoản chi. `Repository.addSplitBill` sinh ra một `expense`
đúng bằng phần của mình cộng nhiều `lend` cho từng người, tất cả cùng một
`groupId`.

Đây là lý do cả thống kê lẫn ngân sách đều chỉ đếm `expense`: một bữa 200k chia
bốn người làm ví trừ đủ 200k nhưng chỉ 50k vào chi tiêu, nên trả dùm không bao
giờ làm vượt hạn mức oan. Chia lẻ thì phần dư dồn vào mình để tổng khớp hoá đơn.

## Ngân sách và tiền thật

Hạn mức chỉ đếm chi tiêu của đúng danh mục đó, nên tiêu lố ở mục khác thì hạn
mức vẫn báo "còn nhiều" trong khi ví đã cạn. Vì vậy với tháng hiện tại,
`budgetsProvider` chặn phần còn tiêu được bằng `spendableAssets` qua
`capBudgetsByCash` (nhiều hạn mức thì chia theo tỉ lệ phần còn lại).
`remaining` vẫn là số của hạn mức; mọi con số "mỗi ngày được tiêu" dùng
`spendable`. Tháng đã qua không bị chặn.

Tiền ngân sách tiêu không hết KHÔNG chia lại cho những ngày sau mà thành tiền
tự do: `BudgetProgress.reserved` = `remaining` − `unusedBeforeToday` (phần
những ngày trước tiêu dưới nhịp đều, tính dồn cả tháng nên tiết kiệm lấp chỗ
hụt của ngày lố trước, lấp đủ mới nhả). Cần `spentToday` (lấy trong
`watchBudgets`, null nếu không phải tháng này — khi đó không nhả gì). Tiêu lố
thì mốc vẫn tự hạ như cũ; `recoveryLimit` / `daysToRecover` (bớt 25% mức
thường ngày, `kRecoveryCut`) chỉ là gợi ý, không phải mốc.

Mọi thứ phụ thuộc "hôm nay" phải xem `todayProvider` (tự đổi qua nửa đêm và khi
app quay lại từ nền), không gọi `DateTime.now()` lúc dựng provider — provider
không bị dựng lại nên app để nền qua đêm sẽ tính theo ngày hôm qua.

## Tiền tự do

`lib/core/domain/free_money.dart`. Tiền tự do = tiền tiêu được − phần hạn mức
còn lại của mọi ngân sách tháng này. Nợ mình phải trả đã trừ sẵn trong tiền
tiêu được (`watchSpendableAssets` = ví − quỹ − `watchTotalOwed`, cộng nợ theo
từng người, người khác nợ mình không bù vào), nên `FreeMoney.owed` chỉ để hiển
thị — trừ lần nữa là đếm nợ hai lần. Trừ nợ để vay/trả nợ không làm con số
nhảy (tiền và nợ đi cùng nhau). Mốc hôm nay chia đều tới hết
tháng, cùng cách với ngân sách từng mục (cộng lại phần đã tiêu hôm nay rồi mới
chia). "Đã tiêu tự do hôm nay" = chi vào mục không có hạn mức + cho mượn, không
tính chi từ quỹ (`watchSpentOutsideBudgetsOnDay`).

`FreeMoney.preview` cho biết một khoản chi sắp ghi lấy từ hạn mức, từ tiền tự
do, hay lấn vào tiền đã giữ — hiện ở màn ghi giao dịch trước khi bấm Ghi.

## Quỹ

Tiền đã dành sẵn cho khoản biết trước. **Không phải ví ảo** mà là nhãn dán lên
tiền đang nằm trong ví thật — người dùng chuyển tiền sang một ngân hàng ít dùng
cho khỏi tiêu nhầm, nên số dư ví phải luôn khớp với app ngân hàng.

Không có loại giao dịch riêng: nạp quỹ là `transfer` có `fund_id`, chi từ quỹ là
`expense` có `fund_id`. Công thức số dư ví vì thế không phải rẽ nhánh thêm.

**Quỹ dùng cột `fund_delta` lưu sẵn**, giống `debt_delta`: số quỹ chỉ là
`SUM(fund_delta)` (`Repository._fundSavedExpr`). Chiều tính lúc ghi bằng
`fundDeltaOf` (`lib/core/domain/fund_delta.dart`), xét theo **ví đang giữ quỹ**:
tiền vào ví đó thì quỹ tăng, ra thì giảm. Không suy ra lúc truy vấn được, vì
nạp / rút **ngay trong ví giữ quỹ** (tiền đã nằm sẵn đó, chỉ dán hoặc gỡ nhãn)
có hai chân trùng nhau — vế vào và vế ra triệt tiêu, không còn biết chiều. Khi
đó `addTransaction(intoFund: ...)` quyết định; sửa giao dịch thì giữ chiều cũ;
nhập sao lưu tính lại từ chân ví và chỉ lấy dấu trong file cho trường hợp này.

Tiền quỹ và nợ phải trả trừ khỏi `watchSpendableAssets` nhưng vẫn trong
`watchTotalAssets`.

## Mẫu chi tiêu

Bảng `expense_templates`, tách khỏi `recurring_templates` vì mẫu không có lịch:
chỉ chạy khi bấm, thời điểm luôn là lúc bấm. Cố định được ghi chú (cũng là
nhãn; trống thì lấy tên danh mục), số tiền, ví và danh mục — trường nào cũng
để trống được. Đủ cả bốn (`TemplateView.isOneTap`) thì bấm là ghi luôn kèm
Hoàn tác; thiếu thì mở màn ghi điền sẵn phần đã có. Ví đã lưu trữ coi như
thiếu ví.

`Repository.recordFromTemplate` đọc lại mẫu từ DB chứ không tin bản trên màn
hình. Xoá ví / danh mục thì mẫu chỉ mất trường đó (`deleteWallet`,
`deleteCategory` gỡ trước, nếu không khoá ngoại chặn). Nút ghi nhanh ở màn
Tổng quan (giữ để sửa) và đầu bảng nút cộng; màn ghi chi tiêu có nút "Lưu làm
mẫu".

## Sao lưu

`BackupService` xuất JSON đầy đủ (khôi phục được) và CSV phẳng (mở bằng Excel,
**phải có BOM** nếu không tiếng Việt vỡ trên Windows).

Khi nhập, id trong file được ánh xạ sang id mới chứ không dùng lại — chế độ gộp
gần như chắc chắn đụng id. `dayKey`/`monthKey`/`debtDelta` tính lại từ dữ liệu
gốc chứ không tin file, phòng bản sao lưu đến từ máy khác múi giờ. Toàn bộ chạy
trong một `db.transaction()`.

## Chưa làm

Giao dịch định kỳ + nhắc nhở (bảng `recurring_templates` đã có sẵn), bộ lọc danh
sách giao dịch, dark mode toggle thủ công, icon app riêng.
