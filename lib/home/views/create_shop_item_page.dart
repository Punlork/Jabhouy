import 'package:flutter/material.dart';
import 'package:my_app/home/widgets/widgets.dart';

class CreateShopItemPage extends StatefulWidget {
  const CreateShopItemPage({
    required this.onSave,
    super.key,
    this.existingItem,
  });
  final ShopItem? existingItem;
  final void Function(ShopItem) onSave;

  @override
  State<CreateShopItemPage> createState() => _CreateShopItemPageState();
}

class _CreateShopItemPageState extends State<CreateShopItemPage> {
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

  bool get _isEditMode => widget.existingItem != null;

  @override
  void initState() {
    super.initState();
    // If editing, populate fields with existing item data
    if (_isEditMode) {
      final item = widget.existingItem!;
      _nameController.text = item.name;
      _defaultPriceController.text = item.defaultPrice.toString();
      _defaultBatchPriceController.text = item.defaultBatchPrice.toString();
      _customerPriceController.text = item.customerPrice.toString();
      _sellerPriceController.text = item.sellerPrice.toString();
      _customerBatchPriceController.text = item.customerBatchPrice.toString();
      _sellerBatchPriceController.text = item.sellerBatchPrice.toString();
      _batchSizeController.text = item.batchSize.toString();
      _noteController.text = item.note;
      _imageUrlController.text = item.imageUrl;
      _category = item.category;
    } else {
      _category = 'Electronics'; // Default for new items
    }
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

  void _submitItem() {
    final item = ShopItem(
      name: _nameController.text,
      defaultPrice: double.parse(_defaultPriceController.text.isEmpty ? '0' : _defaultPriceController.text),
      defaultBatchPrice:
          double.parse(_defaultBatchPriceController.text.isEmpty ? '0' : _defaultBatchPriceController.text),
      customerPrice: double.parse(_customerPriceController.text.isEmpty ? '0' : _customerPriceController.text),
      sellerPrice: double.parse(_sellerPriceController.text.isEmpty ? '0' : _sellerPriceController.text),
      customerBatchPrice:
          double.parse(_customerBatchPriceController.text.isEmpty ? '0' : _customerBatchPriceController.text),
      sellerBatchPrice: double.parse(_sellerBatchPriceController.text.isEmpty ? '0' : _sellerBatchPriceController.text),
      batchSize: int.parse(_batchSizeController.text.isEmpty ? '1' : _batchSizeController.text),
      note: _noteController.text,
      imageUrl: _imageUrlController.text.isEmpty ? 'https://via.placeholder.com/150' : _imageUrlController.text,
      category: _category,
    );
    widget.onSave(item);
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditMode ? 'Edit Item' : 'Add New Item'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
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
              onChanged: (value) => setState(() => _category = value!),
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
    );
  }
}
