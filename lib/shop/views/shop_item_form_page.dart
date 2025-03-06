import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:my_app/app/app.dart';
import 'package:my_app/l10n/l10n.dart';

import 'package:my_app/shop/shop.dart';

class ShopItemFormPage extends StatelessWidget {
  const ShopItemFormPage({
    required this.onSaved,
    required this.bloc,
    this.existingItem,
    super.key,
  });

  final ShopItemModel? existingItem;
  final void Function(ShopItemModel) onSaved;
  final ShopBloc bloc;

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: bloc,
      child: _ShopItemFormPageContent(
        onSaved: onSaved,
        existingItem: existingItem,
      ),
    );
  }
}

class _ShopItemFormPageContent extends StatefulWidget {
  const _ShopItemFormPageContent({
    required this.onSaved,
    this.existingItem,
  });

  final ShopItemModel? existingItem;
  final void Function(ShopItemModel) onSaved;

  @override
  State<_ShopItemFormPageContent> createState() => _ShopItemFormPageState();
}

class _ShopItemFormPageState extends State<_ShopItemFormPageContent> {
  final _formKey = GlobalKey<FormState>();
  late final Map<String, TextEditingController> _controllers;
  late String _category;
  bool _hasChanges = false;
  bool _isDistributorMode = false; // false = Seller, true = Distributor
  bool get _isEditMode => widget.existingItem != null;

  @override
  void initState() {
    super.initState();
    _controllers = {
      'name': TextEditingController(),
      'defaultPrice': TextEditingController(),
      'defaultBatchPrice': TextEditingController(),
      'customerPrice': TextEditingController(),
      'sellerPrice': TextEditingController(),
      'customerBatchPrice': TextEditingController(),
      'sellerBatchPrice': TextEditingController(),
      'batchSize': TextEditingController(),
      'note': TextEditingController(),
      'imageUrl': TextEditingController(),
    };

    if (_isEditMode) {
      final item = widget.existingItem!;
      _controllers['name']!.text = item.name;
      _controllers['defaultPrice']!.text = item.defaultPrice.toString();
      _controllers['defaultBatchPrice']!.text = item.defaultBatchPrice?.toString() ?? '';
      _controllers['customerPrice']!.text = item.customerPrice?.toString() ?? '';
      _controllers['sellerPrice']!.text = item.sellerPrice?.toString() ?? '';
      _controllers['customerBatchPrice']!.text = item.customerBatchPrice?.toString() ?? '';
      _controllers['sellerBatchPrice']!.text = item.sellerBatchPrice?.toString() ?? '';
      _controllers['batchSize']!.text = item.batchSize?.toString() ?? '';
      _controllers['note']!.text = item.note ?? '';
      _controllers['imageUrl']!.text = item.imageUrl ?? '';
      _category = item.category ?? 'Electronics';

      if (item.isDistributorMode) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _isDistributorMode = item.isDistributorMode;
          setState(() {});
        });
      }
    } else {
      _category = 'Electronics';
    }

    _controllers.forEach((key, controller) {
      controller.addListener(_detectChanges);
    });
  }

  @override
  void dispose() {
    _controllers.forEach((_, controller) => controller.dispose());
    super.dispose();
  }

  void _detectChanges() {
    setState(() => _hasChanges = _controllers.values.any((c) => c.text.isNotEmpty));
  }

  Future<bool> _onWillPop() async {
    if (!_hasChanges) return true;

    final l10n = AppLocalizations.of(context);
    final shouldPop = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.unsavedChanges),
        content: Text(l10n.confirmDiscardChanges),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(l10n.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Theme.of(context).colorScheme.error),
            child: Text(l10n.discard),
          ),
        ],
      ),
    );

    return shouldPop ?? false;
  }

  void _submitItem() {
    if (!_formKey.currentState!.validate()) return;

    final item = ShopItemModel(
      id: _isEditMode ? widget.existingItem!.id : 0,
      userId: _isEditMode ? widget.existingItem!.userId : 'user123', // Replace with auth logic
      name: _controllers['name']!.text,
      defaultPrice: double.tryParse(_controllers['defaultPrice']!.text) ?? 0.0,
      defaultBatchPrice: _isDistributorMode && _controllers['defaultBatchPrice']!.text.isNotEmpty
          ? double.tryParse(_controllers['defaultBatchPrice']!.text)
          : null,
      customerPrice: _isDistributorMode && _controllers['customerPrice']!.text.isNotEmpty
          ? double.tryParse(_controllers['customerPrice']!.text)
          : null,
      sellerPrice: _isDistributorMode && _controllers['sellerPrice']!.text.isNotEmpty
          ? double.tryParse(_controllers['sellerPrice']!.text)
          : null,
      customerBatchPrice: _isDistributorMode && _controllers['customerBatchPrice']!.text.isNotEmpty
          ? double.tryParse(_controllers['customerBatchPrice']!.text)
          : null,
      sellerBatchPrice: _isDistributorMode && _controllers['sellerBatchPrice']!.text.isNotEmpty
          ? double.tryParse(_controllers['sellerBatchPrice']!.text)
          : null,
      batchSize: _isDistributorMode && _controllers['batchSize']!.text.isNotEmpty
          ? int.tryParse(_controllers['batchSize']!.text)
          : null,
      note: _controllers['note']!.text.isEmpty ? null : _controllers['note']!.text,
      imageUrl: _controllers['imageUrl']!.text.isEmpty ? null : _controllers['imageUrl']!.text,
      category: _category,
      // isDistributorMode: _isDistributorMode,
    );

    if (_isEditMode) {
      context.read<ShopBloc>().add(ShopEditItemEvent(body: item));
    } else {
      context.read<ShopBloc>().add(ShopCreateItemEvent(body: item));
    }
  }

  Widget _buildTextField({
    required String key,
    required String label,
    bool required = false,
    TextInputType keyboardType = TextInputType.text,
    TextInputAction textInputAction = TextInputAction.next, // Default to next
  }) {
    final l10n = AppLocalizations.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: CustomTextFormField(
        controller: _controllers[key]!,
        hintText: '', // Hint not used in original, can add if needed
        labelText: required ? '$label *' : label,
        keyboardType: keyboardType,
        action: textInputAction,
        useCustomBorder: false,
        validator: required ? (value) => value!.isEmpty ? l10n.nameRequired.replaceAll('Name', label) : null : null,
        decoration: const InputDecoration(
          border: OutlineInputBorder(),
          // errorBorder: OutlineInputBorder(),
          enabledBorder: OutlineInputBorder(),
          focusedBorder: OutlineInputBorder(),
          // focusedErrorBorder: OutlineInputBorder(),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context);

    return PopScope(
      canPop: !_hasChanges,
      onPopInvokedWithResult: (didPop, _) async {
        if (!didPop && _hasChanges) {
          final shouldPop = await _onWillPop();
          if (shouldPop && context.mounted) Navigator.pop(context);
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(_isEditMode ? l10n.editItem : l10n.addNewItem),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () async {
              if (!_hasChanges) {
                context.pop();
                return;
              }
              final shouldPop = await _onWillPop();
              if (shouldPop && context.mounted) context.pop();
            },
          ),
        ),
        body: Form(
          key: _formKey,
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildTextField(
                  key: 'name',
                  label: l10n.name,
                  required: true,
                ),
                _buildTextField(
                  key: 'sellerPrice',
                  label: l10n.sellerPrice,
                  required: true,
                  keyboardType: TextInputType.number,
                ),
                _buildTextField(
                  key: 'defaultPrice',
                  label: l10n.defaultPrice,
                  keyboardType: TextInputType.number,
                ),
                Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(
                      _isDistributorMode ? l10n.changeToSeller : l10n.changeToDistributor,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    onTap: () => setState(() {
                      _isDistributorMode = !_isDistributorMode;
                      _hasChanges = true;
                    }),
                    trailing: Switch(
                      value: _isDistributorMode,
                      onChanged: (value) => setState(() {
                        _isDistributorMode = value;
                        _hasChanges = true;
                      }),
                    ),
                  ),
                ),
                if (_isDistributorMode) ...[
                  _buildTextField(
                    key: 'defaultPrice',
                    label: l10n.defaultPrice,
                    required: true,
                    keyboardType: TextInputType.number,
                  ),
                  _buildTextField(
                    key: 'defaultBatchPrice',
                    label: l10n.defaultBatchPrice,
                    keyboardType: TextInputType.number,
                  ),
                  _buildTextField(
                    key: 'customerPrice',
                    label: l10n.customerPrice,
                    keyboardType: TextInputType.number,
                  ),
                  _buildTextField(
                    key: 'customerBatchPrice',
                    label: l10n.customerBatchPrice,
                    keyboardType: TextInputType.number,
                  ),
                  _buildTextField(
                    key: 'batchSize',
                    label: l10n.batchSize,
                    keyboardType: TextInputType.number,
                  ),
                  _buildTextField(
                    key: 'sellerBatchPrice',
                    label: l10n.sellerBatchPrice,
                    keyboardType: TextInputType.number,
                  ),
                ],
                // ... (keeping rest of the build method unchanged)
                Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: DropdownButtonFormField<String>(
                    value: _category,
                    items: const [
                      DropdownMenuItem(value: 'Electronics', child: Text('Electronics')),
                      DropdownMenuItem(value: 'Accessories', child: Text('Accessories')),
                      DropdownMenuItem(value: 'Beverages', child: Text('Beverages')),
                      DropdownMenuItem(value: 'Other', child: Text('Other')),
                    ].map((item) {
                      final l10n = AppLocalizations.of(context);
                      final translatedLabel = switch (item.value) {
                        'Electronics' => l10n.electronics,
                        'Accessories' => l10n.accessories,
                        'Beverages' => l10n.beverages,
                        'Other' => l10n.other,
                        _ => item.value!,
                      };
                      return DropdownMenuItem<String>(
                        value: item.value,
                        child: Text(translatedLabel),
                      );
                    }).toList(),
                    onChanged: (value) => setState(() {
                      _category = value!;
                      _hasChanges = true;
                    }),
                    decoration: InputDecoration(
                      labelText: l10n.category,
                      border: const OutlineInputBorder(),
                    ),
                  ),
                ),
                _buildTextField(
                  key: 'note',
                  label: l10n.note,
                ),
                _buildTextField(
                  key: 'imageUrl',
                  label: l10n.imageUrl,
                  textInputAction: TextInputAction.done,
                ),
                const SizedBox(height: 24),
                BlocListener<ShopBloc, ShopState>(
                  listener: (context, state) {
                    if (state is ShopLoaded) context.pop();
                  },
                  child: ElevatedButton(
                    onPressed: _submitItem,
                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size(double.infinity, 50),
                      backgroundColor: colorScheme.primary,
                      foregroundColor: colorScheme.onPrimary,
                    ),
                    child: Text(_isEditMode ? l10n.saveChanges : l10n.addItem),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
