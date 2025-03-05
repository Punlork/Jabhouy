import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:my_app/home/home.dart';

class ShopItemFormPage extends StatefulWidget {
  const ShopItemFormPage({
    required this.onSave,
    super.key,
    this.existingItem,
  });
  final ShopItem? existingItem;
  final void Function(ShopItem) onSave;

  @override
  State<ShopItemFormPage> createState() => _ShopItemFormPageState();
}

class _ShopItemFormPageState extends State<ShopItemFormPage> {
  final _nameController = TextEditingController();
  final _defaultPriceController = TextEditingController();
  final _defaultBatchPriceController = TextEditingController();
  final _customerPriceController = TextEditingController();
  final _sellerPriceController = TextEditingController();
  final _customerBatchPriceController = TextEditingController();
  final _sellerBatchPriceController = TextEditingController();
  final _batchSizeController = TextEditingController();
  final _noteController = TextEditingController();
  final _imageUrlController = TextEditingController();
  late String _category;
  bool _hasChanges = false; // Track if form has unsaved changes

  bool get _isEditMode => widget.existingItem != null;

  @override
  void initState() {
    super.initState();
    if (_isEditMode) {
      final item = widget.existingItem!;
      _nameController.text = item.name;
      _defaultPriceController.text = item.defaultBatchPrice.toString();
      _defaultBatchPriceController.text = item.defaultBatchPrice.toString();
      _customerPriceController.text = item.customerPrice.toString();
      _sellerPriceController.text = item.sellerPrice.toString();
      _customerBatchPriceController.text = item.customerBatchPrice.toString();
      _sellerBatchPriceController.text = item.sellerBatchPrice.toString();
      _batchSizeController.text = item.batchSize.toString();
      _noteController.text = item.note ?? '';
      _imageUrlController.text = item.imageUrl;
      _category = item.category;
    } else {
      _category = 'Electronics';
    }

    // Add listeners to detect changes
    _nameController.addListener(_detectChanges);
    _defaultPriceController.addListener(_detectChanges);
    _defaultBatchPriceController.addListener(_detectChanges);
    _customerPriceController.addListener(_detectChanges);
    _sellerPriceController.addListener(_detectChanges);
    _customerBatchPriceController.addListener(_detectChanges);
    _sellerBatchPriceController.addListener(_detectChanges);
    _batchSizeController.addListener(_detectChanges);
    _noteController.addListener(_detectChanges);
    _imageUrlController.addListener(_detectChanges);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _defaultPriceController.dispose();
    _defaultBatchPriceController.dispose();
    _customerPriceController.dispose();
    _sellerPriceController.dispose();
    _customerBatchPriceController.dispose();
    _sellerBatchPriceController.dispose();
    _batchSizeController.dispose();
    _noteController.dispose();
    _imageUrlController.dispose();
    super.dispose();
  }

  void _detectChanges() {
    setState(() => _hasChanges = true);
  }

  Future<void> _onWillPop(bool didPop) async {
    if (didPop || !_hasChanges) return; // If already popped or no changes, do nothing

    final shouldPop = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Unsaved Changes'),
        content: const Text('You have unsaved changes. Are you sure you want to discard them?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Theme.of(context).colorScheme.error),
            child: const Text('Discard'),
          ),
        ],
      ),
    );

    if (shouldPop ?? false) {
      if (!context.mounted) return;
      // ignore: use_build_context_synchronously
      Navigator.pop(context); // Manually pop if user confirms
    }
  }

  void _submitItem() {
    final item = ShopItem(
      name: _nameController.text,
      defaultBatchPrice:
          double.parse(_defaultBatchPriceController.text.isEmpty ? '0' : _defaultBatchPriceController.text),
      customerPrice: double.parse(_customerPriceController.text.isEmpty ? '0' : _customerPriceController.text),
      sellerPrice: double.parse(_sellerPriceController.text.isEmpty ? '0' : _sellerPriceController.text),
      customerBatchPrice:
          double.parse(_customerBatchPriceController.text.isEmpty ? '0' : _customerBatchPriceController.text),
      sellerBatchPrice: double.parse(_sellerBatchPriceController.text.isEmpty ? '0' : _sellerBatchPriceController.text),
      batchSize: int.parse(_batchSizeController.text.isEmpty ? '1' : _batchSizeController.text),
      note: _noteController.text.isEmpty ? null : _noteController.text,
      imageUrl: _imageUrlController.text.isEmpty ? 'https://via.placeholder.com/150' : _imageUrlController.text,
      category: _category,
    );
    widget.onSave(item);
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return PopScope(
      canPop: !_hasChanges,
      onPopInvokedWithResult: (didPop, result) => _onWillPop(didPop),
      child: Scaffold(
        appBar: AppBar(
          title: Text(_isEditMode ? 'Edit Item' : 'Add New Item'),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () async {
              if (!_hasChanges) {
                context.pop();
                return;
              }
              await _onWillPop(false);
            },
          ),
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Name',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _defaultPriceController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Default Price (per unit)',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _defaultBatchPriceController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Default Batch Price',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _customerPriceController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Customer Price (per unit)',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _sellerPriceController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Seller Price (per unit)',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _customerBatchPriceController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Customer Batch Price',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _sellerBatchPriceController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Seller Batch Price',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _batchSizeController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Batch Size (units)',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: _category,
                items: ['Electronics', 'Accessories', 'Beverages', 'Other']
                    .map((value) => DropdownMenuItem(value: value, child: Text(value)))
                    .toList(),
                onChanged: (value) => setState(() {
                  _category = value!;
                  _hasChanges = true; // Category change also counts as an edit
                }),
                decoration: const InputDecoration(
                  labelText: 'Category',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _noteController,
                decoration: const InputDecoration(
                  labelText: 'Note',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _imageUrlController,
                decoration: const InputDecoration(
                  labelText: 'Image URL (optional)',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _submitItem,
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 50),
                  backgroundColor: colorScheme.primary,
                  foregroundColor: colorScheme.onPrimary,
                ),
                child: Text(_isEditMode ? 'Save Changes' : 'Add Item'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
