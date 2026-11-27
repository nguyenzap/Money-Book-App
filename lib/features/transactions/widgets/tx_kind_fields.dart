import 'package:flutter/material.dart';

import '../../../core/db/repository.dart';
import '../../../core/domain/tx_kind.dart';
import '../tx_form_rules.dart';
import 'category_picker.dart';
import 'person_picker.dart';
import 'wallet_dropdown.dart';

/// Các ô chọn ví, danh mục và người theo loại giao dịch, dựng từ cờ của
/// [TxForm.kind]. Trả về danh sách để màn hình rải thẳng vào ListView của nó:
/// giữ nguyên hình dạng cây widget nên trạng thái các ô chọn không bị dựng lại.
List<Widget> txKindFields({
  required TxForm form,
  required List<WalletWithBalance> wallets,
  required ValueChanged<int?> onWalletFrom,
  required ValueChanged<int?> onWalletTo,
  required ValueChanged<int?> onCategory,
  required ValueChanged<int?> onPerson,
}) {
  final kind = form.kind;
  final widgets = <Widget>[];

  if (kind.requiresBothWallets) {
    widgets.addAll([
      WalletDropdown(
        label: 'Từ ví',
        icon: Icons.logout,
        wallets: wallets,
        value: form.walletFromId,
        onChanged: onWalletFrom,
      ),
      const SizedBox(height: 12),
      WalletDropdown(
        label: 'Đến ví',
        icon: Icons.login,
        wallets: wallets,
        value: form.walletToId,
        excludeId: form.fundId == null ? form.walletFromId : null,
        onChanged: onWalletTo,
      ),
    ]);
  } else if (kind.needsWalletFrom && !form.isPaidByOther) {
    // Người khác trả thì không có ví nào bị trừ, nên ẩn ô chọn ví.
    widgets.add(WalletDropdown(
      label: 'Trừ vào ví',
      icon: Icons.account_balance_wallet_outlined,
      wallets: wallets,
      value: form.walletFromId,
      onChanged: onWalletFrom,
    ));
  } else if (kind.needsWalletTo) {
    widgets.add(WalletDropdown(
      label: 'Cộng vào ví',
      icon: Icons.account_balance_wallet_outlined,
      wallets: wallets,
      value: form.walletToId,
      onChanged: onWalletTo,
    ));
  }

  if (kind.needsCategory) {
    if (widgets.isNotEmpty) widgets.add(const SizedBox(height: 12));
    widgets.add(CategoryPicker(
      flow: kind.categoryFlow,
      value: form.categoryId,
      onChanged: onCategory,
    ));
  }

  if (form.showsPersonPicker) {
    if (widgets.isNotEmpty) widgets.add(const SizedBox(height: 12));
    widgets.add(PersonPicker(
      label: form.isPaidByOther ? 'Ai trả dùm' : 'Với ai',
      value: form.personId,
      onChanged: onPerson,
    ));
  }

  return widgets;
}
