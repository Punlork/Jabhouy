import 'package:flutter/material.dart';
import 'package:jabhouy_l10n/jabhouy_l10n.dart';
import 'package:jabhouy_ui/jabhouy_ui.dart';

/// Every unit of the category, searchable, with the current one checked.
/// Returns the picked unit.
Future<String?> showUnitPicker(
  BuildContext context, {
  required List<String> units,
  String? selected,
}) => showAppSheet<String>(
  context,
  initialSize: 0.7,
  builder: (_, controller) => _UnitPickerSheet(
    units: units,
    selected: selected,
    scrollController: controller,
  ),
);

class _UnitPickerSheet extends StatefulWidget {
  const _UnitPickerSheet({
    required this.units,
    this.selected,
    this.scrollController,
  });

  final List<String> units;
  final String? selected;
  final ScrollController? scrollController;

  @override
  State<_UnitPickerSheet> createState() => _UnitPickerSheetState();
}

class _UnitPickerSheetState extends State<_UnitPickerSheet> {
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final t = context.tokens;
    final query = _query.trim().toLowerCase();
    return AppSheet(
      scrollController: widget.scrollController,
      title: l10n.all,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextField(
            onChanged: (v) => setState(() => _query = v),
            textInputAction: TextInputAction.search,
            decoration: InputDecoration(
              prefixIcon: Icon(Icons.search_rounded, color: t.textMuted),
            ),
          ),
          const SizedBox(height: 8),
          for (final unit in widget.units)
            if (unit.toLowerCase().contains(query))
              InkWell(
                onTap: () => Navigator.pop(context, unit),
                child: Container(
                  height: 52,
                  decoration: BoxDecoration(
                    border: Border(bottom: BorderSide(color: t.divider)),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          unit,
                          style: AppTextTheme.body.copyWith(
                            color: t.textPrimary,
                            fontWeight: unit == widget.selected
                                ? FontWeight.w600
                                : FontWeight.w400,
                          ),
                        ),
                      ),
                      if (unit == widget.selected)
                        Icon(Icons.check_rounded, color: t.textPrimary),
                    ],
                  ),
                ),
              ),
          const SizedBox(height: 12),
        ],
      ),
    );
  }
}
