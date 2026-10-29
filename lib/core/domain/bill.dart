/// Một dòng của hoá đơn chi tiết, chưa ghi xuống DB.
class BillLine {
  const BillLine({
    required this.name,
    required this.quantity,
    required this.unitPrice,
    this.isDiscount = false,
  });

  final String name;
  final int quantity;

  /// Luôn dương; dòng giảm giá dùng [isDiscount].
  final int unitPrice;
  final bool isDiscount;

  /// Thành tiền có dấu: giảm giá là số âm.
  int get total => (isDiscount ? -1 : 1) * quantity * unitPrice;
}

/// Tổng hoá đơn, cũng là số tiền của khoản chi.
int billTotal(Iterable<BillLine> lines) =>
    lines.fold<int>(0, (sum, l) => sum + l.total);

/// Lý do không ghi được hoá đơn, hoặc null nếu hợp lệ.
String? validateBill(List<BillLine> lines) {
  for (final l in lines) {
    if (l.name.trim().isEmpty) return 'Hãy nhập tên cho mọi món';
    if (l.quantity <= 0) return 'Số lượng phải lớn hơn 0';
    if (l.unitPrice <= 0) return 'Hãy nhập giá cho "${l.name.trim()}"';
  }
  if (billTotal(lines) <= 0) return 'Tổng hoá đơn phải lớn hơn 0';
  return null;
}
