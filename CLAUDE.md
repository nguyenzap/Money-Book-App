# MoneyBook — App quản lý chi tiêu cá nhân

App Android offline, dùng riêng. Mọi nhập liệu thủ công. Dữ liệu nằm hoàn toàn
trong máy, không server, không tài khoản.

## Chạy và build

```powershell
flutter run -d <device>                 # dev, hot reload bằng phím r
flutter test                            # 469 test, chạy trong ~10 giây
flutter analyze
dart run build_runner build             # BẮT BUỘC sau khi sửa lib/core/db/tables.dart
flutter build apk --release --target-platform android-arm64
adb install -r build\app\outputs\flutter-apk\app-release.apk
```

Toolchain đã cấu hình sẵn: Flutter 3.41.2, JDK 17 tại `C:\Users\Admin\.jdks\jdk-17.0.20.1+1`
(trỏ bằng `flutter config --jdk-dir`, vì JDK 23 mặc định của máy quá mới cho Gradle),
Android SDK 36 + cmdline-tools.

Máy Linux (Ubuntu) cũng có toolchain từ 2026-11-27: Flutter 3.41.2 ở
`~/development/flutter`, JDK 17 (`/usr/lib/jvm/java-17-openjdk-amd64`, Java
mặc định của máy là 25, quá mới cho Gradle), Android SDK ở `~/Android/Sdk`.
Chỉ build được bản `--debug`: khoá ký release chỉ nằm trên máy Windows.

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
chỉ sửa file này; màn hình `tx_editor_screen.dart` tự dựng form theo các cờ đó
(quy tắc của form nằm ở `TxForm`, `tx_form_rules.dart`; không so sánh
`kind == TxKind.x` trong màn hình).

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
  domain/tx_kind.dart      ★ enum 8 loại + logic dấu tiền + cờ cho màn ghi
  domain/category_flow.dart  enum chiều danh mục (chi / thu), lưu bằng tên;
                           tx_kind.dart export lại
  domain/tx_rules.dart     kiểm tra chung cho mọi đường ghi giao dịch (kể cả
                           nhập sao lưu): trả dùm không kèm ví, hoá đơn khớp tổng
  domain/budget_progress.dart  nhịp độ ngân sách, capBudgetsByCash (thuần Dart)
  domain/debt_allocation.dart  phân bổ phần nợ còn lại theo FIFO (thuần Dart)
  db/tables.dart           định nghĩa bảng (sửa xong PHẢI chạy build_runner)
  db/database.dart         migration, PRAGMA, dữ liệu gieo sẵn
  db/repository.dart       class Repository + biểu thức SQL dùng chung
                           (_walletBalanceExpr, _txViewSelect, _fundSavedExpr…)
  db/repository_<miền>.dart  truy vấn từng miền, là `part` + `extension … on
                           Repository` nên nơi gọi vẫn viết repo.method();
                           file gọi method phải import repository.dart
  db/repository_models.dart  TxView, WalletWithBalance… (repository.dart export)
  format/money.dart        int đồng <-> chuỗi có dấu chấm, TextInputFormatter
  format/dates.dart        dayKey/monthKey, nhãn tiếng Việt
  providers.dart           Riverpod, đều là StreamProvider nên UI tự cập nhật
lib/features/<tính năng>/  mỗi thư mục một miền nghiệp vụ
```

## Ràng buộc nghiệp vụ đã cài

- Ví có giao dịch: không xoá được, chỉ lưu trữ (`is_archived`).
- Ví đang giữ quỹ: không xoá, không lưu trữ được (`archiveWallet` ném
  `ArgumentError`). Ví lưu trữ rời tổng tài sản mà quỹ vẫn bị trừ khỏi tiền
  tiêu được, nên quỹ sẽ bị trừ vào ví khác.
- Quỹ không đổi được ví giữ quỹ (`updateFund` ném `ArgumentError`, màn sửa
  khoá ô chọn ví): giao dịch nạp / rút cũ vẫn trỏ vào ví cũ. Muốn chuyển thì
  lập quỹ mới ở ví mới, chuyển tiền sang, rồi xoá quỹ cũ.
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

`.github/workflows/ci.yml` chạy analyze + test mỗi lần push. Phát hành thì
build **trên máy** (GitHub Actions quá chậm) rồi chỉ đẩy APK lên Releases:

```powershell
.\scripts\release.ps1 v1.2.0          # -DryRun: chỉ build + kiểm chữ ký
```

Script: test → build arm64 → `apksigner` chặn nếu ký bằng debug key → gắn thẻ,
đẩy thẻ → `gh release create` kèm APK. Số phiên bản lấy từ tên thẻ qua
`--build-name`, nên không phải sửa `pubspec.yaml`; `versionCode` = `v1.2.3` →
`10203`. `release.yml` chỉ còn là dự phòng, chạy tay ở tab Actions (KHÔNG chạy
theo thẻ, nếu không nó build lại và đụng bản script vừa tạo), dùng cùng công
thức versionCode và keystore từ GitHub Secrets (xem `.github/README.md`).

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

## Người khác trả dùm

Chiều ngược của trả dùm: bạn trả thay mình, mình chỉ ghi phần của mình. Mở qua
mục "Ghi nợ" trong bảng ghi nhanh (`QuickActionSheet`, không phải công tắc trong
màn ghi Chi tiêu; màn ghi mở với `initialPaidByOther: true`, ẩn thanh chọn loại
và ví). Ghi **đúng một** `expense` **không có chân ví nào**, có `person_id` —
không tách thành "vay rồi chi" vì mình chưa hề cầm số tiền đó.

- Số dư ví đúng sẵn nhờ công thức chung: không chân ví thì không đụng ví nào.
- Thống kê, ngân sách đếm nó như mọi khoản chi.
- Nợ: `TxKind.debtDelta(amount, hasPerson: true)` cho `expense` ra `-amount`.
  Mọi chỗ ghi `debt_delta` (add, update, nhập sao lưu) truyền
  `hasPerson: personId != null`. Khoản chi thường vì thế KHÔNG được mang
  `person_id` — màn ghi chỉ gửi người khi đang ở chế độ Ghi nợ
  (`TxForm.isPaidByOther`).
- Tiền tiêu được giảm ngay qua `watchTotalOwed`, dù ví không đổi.
- `addTransaction` / `updateTransaction` ném `ArgumentError` nếu khoản chi có
  người mà lại có ví hoặc quỹ (đếm hai lần). Trả lại thì ghi `repay` thường.
- `TxView.isPaidByOther`; `signedAmount` vẫn âm dù không có ví.

## Tất toán từng khoản

Cột `transactions.settles_tx_id` (`Transactions.settlesTxId`, nullable, tham chiếu
`transactions.id`, `ON DELETE SET NULL`, từ schema v7) nối một giao dịch tất toán
(`collect` / `repay`, có ví hoặc xoá nợ `is_writeoff`) với đúng một khoản nợ gốc.

- Một khoản nợ là giao dịch có `debt_delta != 0` và `settles_tx_id IS NULL`.
- Phần còn lại (`TxView.debtRemaining`, tính ở tầng `Repository` qua hàm thuần
  `allocateDebts` trong `lib/core/domain/debt_allocation.dart`) được phân bổ
  theo từng người, theo thứ tự thời gian `(occurred_at, id)` (FIFO), không rẽ
  nhánh theo `kind`:
  - Dòng có `settles_tx_id` trừ vào khoản đích trước (tối đa phần còn mở của
    đích); nếu dư thì phần dư xử lý như dòng không gắn đích.
  - Dòng không gắn đích (tất toán cả sổ, xoá nợ, cho mượn, vay, trả dùm…) trừ
    lần lượt vào các khoản đang mở **ngược dấu**, cũ nhất trước; phần còn lại
    mở một khoản mới theo chiều của chính dòng đó.
  - Tổng các phần còn mở có dấu luôn bằng dư nợ ròng của người đó (`netDebtOf`).
  - Dòng có `settles_tx_id != null` luôn có `debtRemaining == null`.
- `Repository.addTransaction(settlesTxId: ...)` kiểm tra khoản đích tồn tại, chưa
  xoá, là khoản nợ, và `amount <= remaining` (theo đúng phân bổ FIFO); sai thì
  ném `ArgumentError`.
- Sao lưu JSON v7 xuất `settlesTxId` và ánh xạ lại theo bảng đổi id giao dịch
  sau khi chèn xong toàn bộ giao dịch (không phụ thuộc thứ tự trong file).

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

## Hoá đơn chi tiết

Bảng `bill_items` (tên món, số lượng, đơn giá, `is_discount`), gắn vào một
khoản chi. Có hoá đơn thì **số tiền khoản chi chính là tổng hoá đơn**
(`billTotal`, `lib/core/domain/bill.dart`): màn ghi ẩn ô số tiền, và
`addTransaction` / `updateTransaction` ném `ArgumentError` nếu hai số lệch
nhau. Đơn giá luôn dương, giảm giá là cờ `is_discount` — cùng tinh thần với
`amount`. Món không ảnh hưởng thống kê hay ngân sách, chúng vẫn chỉ thấy một
khoản chi.

`updateTransaction(bill: null)` giữ nguyên hoá đơn, `bill: []` là bỏ. Xoá mềm
để nguyên các dòng (hoàn tác được), xoá hẳn thì `ON DELETE CASCADE` dọn theo.
Không đi cùng trả dùm (trả dùm tách hoá đơn thành nhiều giao dịch). CSV chưa
xuất các món, JSON thì có (`billItems`, có từ định dạng sao lưu v5; tự động ghi thêm ở v6).

## Sao lưu

`BackupService` xuất JSON đầy đủ (khôi phục được) và CSV phẳng (mở bằng Excel,
**phải có BOM** nếu không tiếng Việt vỡ trên Windows).

Khi nhập, id trong file được ánh xạ sang id mới chứ không dùng lại — chế độ gộp
gần như chắc chắn đụng id. `groupId` cũng vậy: gộp một file hai lần thì hai cặp
trả dùm không được dính thành một nhóm. Mọi dòng giao dịch được kiểm tra TRƯỚC
khi đụng DB (số tiền dương, loại hợp lệ, hoá đơn khớp tổng) và báo
`BackupException`. Khoản chi vừa có ví vừa có người là dữ liệu kiểu cũ: nhập
vào thì bỏ người, không đẻ nợ. `dayKey`/`monthKey`/`debtDelta` tính lại từ dữ liệu
gốc chứ không tin file, phòng bản sao lưu đến từ máy khác múi giờ. Toàn bộ chạy
trong một `db.transaction()`.

## Tự động ghi từ thông báo ngân hàng

Kế hoạch đầy đủ: `finance-app-plan.md`. Đọc thông báo của app BIDV và Eximbank,
ghi thành giao dịch qua đúng `Repository.addTransaction` như nhập tay, rồi
phân loại trong máy. Không mạng, không quyền `INTERNET`.

**Đường đi:** `AutoTrackListenerService.kt` (lọc theo gói ở dòng đầu, chỉ chép
chữ vào hộp thư SQLite riêng phía Android) → MethodChannel `moneybook/autotrack`
→ `AutoTrackService.sync()` (chạy khi mở app, khi quay lại từ nền, khi có tin
lúc app đang mở) → `notification_events` → parser → `addTransaction`. Kotlin
không bao giờ ghi vào DB của Drift, không chạy Flutter ngầm, không foreground
service. Hộp thư Android chỉ được xoá (`ackInbox`) SAU khi Dart đã lưu xong.

**Parser viết tay trong mã nguồn** (`lib/core/domain/autotrack/parsers/`), mỗi
ngân hàng một lớp `LabeledLinesParser`: dòng đầu khớp `header` VÀ có dòng số
tiền thì mới là giao dịch, OTP/khuyến mãi tự rơi vào `unmatched`. Nhãn và dòng
đầu so ở dạng `foldVi` (không dấu) vì Dart không có NFC. Số tiền qua
`parseVnd`, bắt buộc có dấu `+`/`-`, không bao giờ qua `double`. Thông báo đẩy
thật của BIDV có tiêu đề `Thông báo BIDV` (chính là dòng đầu); Eximbank có
dòng đầu `Eximbank <chi nhánh>: dd/MM/yyyy HH:mm` trong thân.

Ngân hàng đổi câu chữ: chép tin "đã che" ở Nhật ký thông báo, thêm vào
`test/fixtures/autotrack/<id>/` (dòng `# expect:`, `# title:`), sửa parser,
**tăng `version`**, phát hành. Tin `unmatched`/`failed` được giữ 30 ngày và
đọc lại tự động khi `parserVersion` cũ hơn. Mẫu thật trong fixtures phải che
số tài khoản và thay tên người.

**Chống trùng hai lớp:** `dedupeHash` trên tin thô (gói + chữ + phút), rồi
`txnKey` trên giao dịch đọc được (ngân hàng + mã giao dịch, hoặc thời gian +
số tiền + số dư).

**Ví:** mỗi ngân hàng một ví mặc định, ghi đè theo đuôi số tài khoản
(`account_wallets`). Chưa có ví thì tin nằm `unmapped`, chọn ví xong lần đồng
bộ sau tự ghi. Chuyển giữa hai tài khoản của mình KHÔNG ghép thành chuyển ví
(quyết định D7): số dư từng ví vẫn đúng, nhưng thống kê tháng đếm cả hai vế.

**Phân loại** (`categorizer.dart`, hàm thuần): người nhận chuẩn hoá bằng
`normalizeReceiver` → quy tắc đúng tên (tin được, `needsReview` false) → tên
gần giống → từ khoá (hai bước sau chỉ là đoán, luôn chờ xác nhận) → không có
(`categoryId` null = "Chưa phân loại", KHÔNG tạo danh mục riêng). Quy tắc tách
theo `flow`. Chọn danh mục cho khoản chưa phân loại / đang đoán thì học và áp
cho các khoản cùng người nhận (`AutoTrackRepository.learn`, có `undoLearn`);
đổi khoản đã theo quy tắc thì hỏi "Chỉ giao dịch này / Luôn dùng".
`updateTransaction` luôn đặt `needsReview` = false: lưu ở màn sửa là đã xem.

**Sức khoẻ** (`autotrack_health.dart`, banner ở Tổng quan): mất quyền đọc
thông báo; lệch số dư (so số dư trong tin ghi gần nhất với
`balanceOf(asOf: lúc đó)` — vẫn đúng một công thức); tin có số tiền +/- mà
không đọc được (nghi đổi mẫu); im lặng quá 3 ngày.

**Sao lưu v6:** mang theo `trackedApps` (chỉ ngân hàng, không app ghi mẫu),
`accountWallets`, `receiverRules`, `categoryKeywords`, `needsReview`. KHÔNG
bao giờ xuất `notification_events` (số tài khoản, số dư, OTP); vì vậy giao
dịch khôi phục mất `autoEventId`.

**Thử trên máy:** ngân hàng tắt app khi bật Tuỳ chọn nhà phát triển, nên
không dùng được `flutter run`/adb. Build `--debug` (id `.dev`, tên "Chi Tiêu
(dev)", cài song song bản thật) rồi cài APK bằng tay. Android 13+ chặn quyền
đọc thông báo cho app cài từ APK: Cài đặt → Ứng dụng → app → ⋮ → Cho phép
cài đặt bị hạn chế.

## Chưa làm

Giao dịch định kỳ + nhắc nhở (bảng `recurring_templates` đã có sẵn), bộ lọc danh
sách giao dịch, dark mode toggle thủ công, icon app riêng.

Còn treo từ đợt dọn code (tháng 11/2026):

- Chi từ quỹ có tính vào ngân sách (đã chốt), nhưng vì thế phần hạn mức còn
  giữ giảm theo, nên tiền tự do TĂNG lên đúng khoản đó dù tiền tiêu được
  không đổi. Chưa quyết có sửa không.
- Nhập sao lưu kiểu gộp tạo trùng danh mục và người (chưa khớp theo tên).
- `ImportResult.stats` đếm dòng trong file, không phải dòng đã nhập (quỹ,
  ngân sách bị bỏ qua vẫn được đếm).
- SQL của phần sao lưu chưa dời về `lib/core/db/`.
- `recurringId` không được xuất ra file sao lưu.
- Chưa có test bắt `readsFrom` thiếu bảng cho từng miền của Repository.
