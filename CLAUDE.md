# MoneyBook — App quản lý chi tiêu cá nhân

App Android offline, dùng riêng. Mọi nhập liệu thủ công. Dữ liệu nằm hoàn toàn
trong máy, không server, không tài khoản.

## Chạy và build

```powershell
flutter run -d <device>                 # dev, hot reload bằng phím r
flutter test                            # 123 test, chạy trong ~2 giây
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
