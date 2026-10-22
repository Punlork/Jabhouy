import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:jabhouy/credit/data/credit_repository.dart';
import 'package:jabhouy/credit/models/credit.dart';
import 'package:jabhouy/credit/ui/bloc/customer_picker/customer_picker_cubit.dart';
import 'package:jabhouy_core/jabhouy_core.dart';
import 'package:jabhouy_l10n/jabhouy_l10n.dart';
import 'package:jabhouy_ui/jabhouy_ui.dart';

/// The customer picker (canvas ១១): search, every Customer with what they
/// owe, `បន្ថែមអតិថិជនថ្មី`, and ✎ to rename or delete one. Returns the
/// Customer that was tapped, or the one just added. With [manage] (Settings)
/// a tap edits the Customer and the sheet stays open.
Future<CreditCustomer?> showCustomerPicker(
  BuildContext context,
  CreditRepository repository, {
  String? selectedId,
  bool manage = false,
}) => showAppSheet<CreditCustomer>(
  context,
  initialSize: 0.7,
  builder: (_, controller) => BlocProvider(
    create: (_) => CustomerPickerCubit(repository)..start(),
    child: _CustomerPickerSheet(
      manage: manage,
      selectedId: selectedId,
      scrollController: controller,
    ),
  ),
);

class _CustomerPickerSheet extends StatelessWidget {
  const _CustomerPickerSheet({
    required this.manage,
    this.selectedId,
    this.scrollController,
  });

  final bool manage;
  final String? selectedId;
  final ScrollController? scrollController;

  Future<void> _add(BuildContext context) async {
    final cubit = context.read<CustomerPickerCubit>();
    final edit = await showDialog<_Edit>(
      context: context,
      builder: (_) => const _CustomerDialog(),
    );
    if (edit == null || !context.mounted) return;
    if (await cubit.save(edit.name) case Ok(:final value)) {
      if (context.mounted && !manage) Navigator.pop(context, value);
    }
  }

  Future<void> _edit(BuildContext context, CustomerBalance balance) async {
    final customer = balance.customer;
    final cubit = context.read<CustomerPickerCubit>();
    final edit = await showDialog<_Edit>(
      context: context,
      builder: (_) => _CustomerDialog(
        existing: customer,
        canDelete: cubit.canDelete,
        hasCredits: balance.creditCount > 0,
      ),
    );
    if (edit == null || !context.mounted) return;
    if (edit.delete) {
      if (await cubit.delete(customer.id) case Err() when context.mounted) {
        showErrorSnackBar(context, context.l10n.customerHasCredits);
      }
    } else {
      await cubit.save(edit.name, id: customer.id);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final t = context.tokens;
    final cubit = context.read<CustomerPickerCubit>();
    return AppSheet(
      scrollController: scrollController,
      title: l10n.customers,
      child: BlocBuilder<CustomerPickerCubit, CustomerPickerState>(
        builder: (context, state) => Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // White with a border (canvas ១១), like the category picker.
            TextField(
              onChanged: cubit.search,
              textInputAction: TextInputAction.search,
              decoration: InputDecoration(
                hintText: l10n.searchCustomers,
                prefixIcon: Icon(Icons.search_rounded, color: t.textMuted),
              ),
            ),
            const SizedBox(height: 8),
            for (final balance in state.customers)
              _CustomerRow(
                balance: balance,
                selected: balance.customer.id == selectedId,
                manage: manage,
                onTap: () => manage
                    ? _edit(context, balance)
                    : Navigator.pop(context, balance.customer),
                onEdit: () => _edit(context, balance),
              ),
            InkWell(
              onTap: () => _add(context),
              child: SizedBox(
                height: 52,
                child: Row(
                  children: [
                    Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: t.surfaceSubtle,
                        borderRadius: BorderRadius.circular(9),
                      ),
                      child: Icon(
                        Icons.add_rounded,
                        size: 18,
                        color: t.textPrimary,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      l10n.customerAddNew,
                      style: AppTextTheme.body.copyWith(
                        color: t.textPrimary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}

class _CustomerRow extends StatelessWidget {
  const _CustomerRow({
    required this.balance,
    required this.selected,
    required this.manage,
    required this.onTap,
    required this.onEdit,
  });

  final CustomerBalance balance;
  final bool selected;
  final bool manage;
  final VoidCallback onTap;
  final VoidCallback onEdit;

  /// `ជំពាក់ 23,000 ៛`, `ជំពាក់ · មិនទាន់មានចំនួន`, `សងរួច`, or nothing for
  /// a Customer with no Credit yet.
  String? _text(AppLocalizations l10n) {
    final owed = balance.owed;
    final unknown = balance.unknownCount > 0;
    if (owed == null && !unknown) {
      return balance.creditCount > 0 ? l10n.creditPaid : null;
    }
    return [
      if (owed != null) l10n.creditOwes(owed.format()) else l10n.credit,
      if (unknown) l10n.creditNoAmount,
    ].join(' · ');
  }

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final text = _text(context.l10n);
    return InkWell(
      onTap: onTap,
      child: Container(
        constraints: const BoxConstraints(minHeight: 56),
        decoration: BoxDecoration(
          border: Border(bottom: BorderSide(color: t.divider)),
        ),
        child: Row(
          children: [
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      balance.customer.name,
                      style: AppTextTheme.body.copyWith(
                        color: t.textPrimary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    if (text != null)
                      Text(
                        text,
                        style: AppTextTheme.hint.copyWith(
                          color: balance.owed != null
                              ? t.dangerText
                              : t.textMuted,
                        ),
                      ),
                  ],
                ),
              ),
            ),
            if (selected) Icon(Icons.check_rounded, color: t.textPrimary),
            if (manage)
              Icon(Icons.chevron_right_rounded, color: t.textMuted)
            else
              IconButton(
                onPressed: onEdit,
                tooltip: context.l10n.editCustomer,
                icon: Icon(Icons.more_horiz_rounded, color: t.textMuted),
              ),
          ],
        ),
      ),
    );
  }
}

/// What the name dialog returned: a name to save, or a delete.
class _Edit {
  const _Edit(this.name, {this.delete = false});

  final String name;
  final bool delete;
}

/// Add (no [existing]) or rename a Customer; `លុប` only when [canDelete].
class _CustomerDialog extends StatefulWidget {
  const _CustomerDialog({
    this.existing,
    this.canDelete = false,
    this.hasCredits = false,
  });

  final CreditCustomer? existing;
  final bool canDelete;
  final bool hasCredits;

  @override
  State<_CustomerDialog> createState() => _CustomerDialogState();
}

class _CustomerDialogState extends State<_CustomerDialog> {
  late final _name = TextEditingController(text: widget.existing?.name);

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  void _save() {
    if (_name.text.trim().isEmpty) return;
    Navigator.pop(context, _Edit(_name.text));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return AlertDialog(
      title: Text(
        widget.existing == null ? l10n.addCustomer : l10n.editCustomer,
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextField(
            controller: _name,
            autofocus: true,
            decoration: InputDecoration(hintText: l10n.customerName),
            onSubmitted: (_) => _save(),
          ),
          if (widget.existing != null && widget.canDelete)
            Padding(
              padding: const EdgeInsets.only(top: 12),
              child: widget.hasCredits
                  ? Text(
                      l10n.customerHasCredits,
                      style: AppTextTheme.hint.copyWith(
                        color: context.tokens.textMuted,
                      ),
                    )
                  : TextButton.icon(
                      onPressed: () =>
                          Navigator.pop(context, const _Edit('', delete: true)),
                      style: TextButton.styleFrom(
                        foregroundColor: context.tokens.dangerText,
                      ),
                      icon: const Icon(Icons.delete_outline_rounded, size: 20),
                      label: Text(l10n.delete),
                    ),
            ),
        ],
      ),
      // Two equal buttons side by side; Delete sits under the field.
      actionsPadding: const EdgeInsets.fromLTRB(24, 0, 24, 20),
      actions: [
        Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: () => Navigator.pop(context),
                child: Text(l10n.cancel),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: FilledButton(onPressed: _save, child: Text(l10n.save)),
            ),
          ],
        ),
      ],
    );
  }
}
