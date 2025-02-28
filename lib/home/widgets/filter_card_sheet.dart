// New FilterSheet widget
import 'package:flutter/material.dart';

class FilterSheet extends StatefulWidget {
  const FilterSheet({
    required this.initialCategoryFilter,
    required this.initialBuyerFilter,
    required this.onApply,
    super.key,
  });
  final String initialCategoryFilter;
  final String initialBuyerFilter;
  final void Function(String category, String buyer) onApply;

  @override
  State<FilterSheet> createState() => _FilterSheetState();
}

class _FilterSheetState extends State<FilterSheet> {
  late String _categoryFilter;
  late String _buyerFilter;

  @override
  void initState() {
    super.initState();
    _categoryFilter = widget.initialCategoryFilter;
    _buyerFilter = widget.initialBuyerFilter;
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Filter Items',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          DropdownButtonFormField<String>(
            value: _categoryFilter,
            items: ['All', 'Electronics', 'Accessories', 'Beverages']
                .map(
                  (value) => DropdownMenuItem(value: value, child: Text(value)),
                )
                .toList(),
            onChanged: (value) => setState(() => _categoryFilter = value!),
            decoration: const InputDecoration(
              labelText: 'Category',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 16),
          DropdownButtonFormField<String>(
            value: _buyerFilter,
            items: ['All', 'Customer Only', 'Seller Only']
                .map(
                  (value) => DropdownMenuItem(value: value, child: Text(value)),
                )
                .toList(),
            onChanged: (value) => setState(() => _buyerFilter = value!),
            decoration: const InputDecoration(
              labelText: 'Buyer Type',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
              const SizedBox(width: 8),
              ElevatedButton(
                onPressed: () {
                  widget.onApply(_categoryFilter, _buyerFilter);
                  Navigator.pop(context);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: colorScheme.primary,
                  foregroundColor: colorScheme.onPrimary,
                ),
                child: const Text('Apply'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
