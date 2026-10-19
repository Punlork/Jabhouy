import 'package:flutter/material.dart';
import 'package:jabhouy_l10n/jabhouy_l10n.dart';
import 'package:jabhouy_shop/src/models/item.dart';
import 'package:jabhouy_shop/src/ui/widgets/text_prompt_dialog.dart';
import 'package:jabhouy_ui/jabhouy_ui.dart';

/// Category picker (canvas ៥): search, the visible categories with the
/// chosen one checked, and `បង្កើតប្រភេទថ្មី`. Returns the picked id.
/// [onCreate] saves a typed name and returns its new id.
Future<String?> showCategoryPicker(
  BuildContext context, {
  required List<ItemCategory> categories,
  required Future<String> Function(String name) onCreate,
  String? selectedId,
}) => showModalBottomSheet<String>(
  context: context,
  isScrollControlled: true,
  builder: (_) => _CategoryPickerSheet(
    categories: [...categories.where((c) => !c.hidden)],
    selectedId: selectedId,
    onCreate: onCreate,
  ),
);

class _CategoryPickerSheet extends StatefulWidget {
  const _CategoryPickerSheet({
    required this.categories,
    required this.onCreate,
    this.selectedId,
  });

  final List<ItemCategory> categories;
  final Future<String> Function(String name) onCreate;
  final String? selectedId;

  @override
  State<_CategoryPickerSheet> createState() => _CategoryPickerSheetState();
}

class _CategoryPickerSheetState extends State<_CategoryPickerSheet> {
  String _query = '';

  Future<void> _create() async {
    final l10n = context.l10n;
    final name = await showTextPrompt(
      context,
      title: l10n.categoryNew,
      hintText: l10n.categoryNameHint,
    );
    if (name == null || name.trim().isEmpty || !mounted) return;
    final id = await widget.onCreate(name.trim());
    if (mounted) Navigator.pop(context, id);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final t = context.tokens;
    final query = _query.trim().toLowerCase();
    final shown = [
      for (final c in widget.categories)
        if (c.name.toLowerCase().contains(query)) c,
    ];
    return Padding(
      // Keeps the search field above the keyboard.
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: AppSheet(
        title: l10n.category,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SearchField(
              hintText: l10n.categorySearch,
              onChanged: (v) => setState(() => _query = v),
            ),
            const SizedBox(height: 8),
            for (final category in shown)
              InkWell(
                onTap: () => Navigator.pop(context, category.id),
                child: Container(
                  height: 52,
                  decoration: BoxDecoration(
                    border: Border(bottom: BorderSide(color: t.divider)),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          category.name,
                          style: AppTextTheme.body.copyWith(
                            color: t.textPrimary,
                            fontWeight: category.id == widget.selectedId
                                ? FontWeight.w600
                                : FontWeight.w400,
                          ),
                        ),
                      ),
                      if (category.id == widget.selectedId)
                        Icon(Icons.check_rounded, color: t.textPrimary),
                    ],
                  ),
                ),
              ),
            InkWell(
              onTap: _create,
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
                      l10n.categoryNew,
                      style: AppTextTheme.body.copyWith(
                        color: t.textPrimary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }
}
