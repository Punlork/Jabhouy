import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:my_app/app/app.dart';
import 'package:my_app/l10n/l10n.dart';
import 'package:my_app/shop/shop.dart';

class CategoryDropdown extends StatefulWidget {
  const CategoryDropdown({
    super.key,
    this.initialValue,
    this.onChanged,
    this.decoration,
  });
  final CategoryItemModel? initialValue;
  final ValueChanged<CategoryItemModel?>? onChanged;
  final InputDecoration? decoration;

  @override
  State<CategoryDropdown> createState() => _CategoryDropdownState();
}

class _CategoryDropdownState extends State<CategoryDropdown> {
  CategoryItemModel? _categoryFilter;

  @override
  void initState() {
    super.initState();
    _categoryFilter = widget.initialValue;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context); // Ensure non-null access

    return BlocBuilder<CategoryBloc, CategoryState>(
      builder: (context, state) {
        if (state is CategoryLoaded) {
          return GestureDetector(
            onTap: () {
              if (state.items.isNotEmpty) return;
              showDialog<void>(
                context: context,
                builder: (_) => AlertDialog(
                  title: Text(l10n.noCategoriesAvailable),
                  content: Text(l10n.pleaseCreateCategoryFirst),
                  actions: [
                    TextButton(
                      onPressed: () {
                        context
                          ..pop()
                          ..pushNamed(
                            AppRoutes.category,
                            extra: {
                              'shop': context.read<ShopBloc>(),
                              'category': context.read<CategoryBloc>(),
                            },
                          );
                      },
                      child: Text(l10n.createCategory),
                    ),
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: Text(l10n.cancel),
                    ),
                  ],
                ),
              );
            },
            child: DropdownButtonFormField<CategoryItemModel?>(
              value: _categoryFilter != null
                  ? state.items.firstWhere(
                      (element) => element.id == _categoryFilter?.id,
                    )
                  : null,
              isExpanded: true,
              items: state.items
                  .map(
                    (value) => DropdownMenuItem(
                      value: value,
                      key: UniqueKey(),
                      child: Text(
                        value.name,
                      ),
                    ),
                  )
                  .toList(),
              onChanged: (value) {
                _categoryFilter = value;
                setState(() {});
                widget.onChanged?.call(value);
              },
              decoration: widget.decoration ??
                  InputDecoration(
                    labelText: l10n.category,
                    border: const OutlineInputBorder(),
                  ),
            ),
          );
        }
        return const SizedBox.shrink();
      },
    );
  }
}
