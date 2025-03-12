import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:my_app/app/app.dart';
import 'package:my_app/l10n/l10n.dart';

import 'package:my_app/shop/shop.dart';

class ShopItemFormPage extends StatelessWidget {
  const ShopItemFormPage({
    required this.onSaved,
    required this.shop,
    required this.category,
    this.existingItem,
    super.key,
  });

  final ShopItemModel? existingItem;
  final void Function(ShopItemModel) onSaved;
  final ShopBloc shop;
  final CategoryBloc category;

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider.value(value: shop),
        BlocProvider.value(value: category),
      ],
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
  CategoryItemModel? _categoryFilter;
  bool _hasChanges = false;

  @override
  void initState() {
    super.initState();
    _controllers = {
      'name': TextEditingController(),
      'defaultPrice': TextEditingController(),
      'customerPrice': TextEditingController(),
      'sellerPrice': TextEditingController(),
      'note': TextEditingController(),
    };

    if (widget.existingItem != null) {
      final item = widget.existingItem!;
      _controllers['name']!.text = item.name;
      _controllers['defaultPrice']!.text = item.defaultPrice.toString();
      _controllers['customerPrice']!.text = item.customerPrice?.toString() ?? '';
      _controllers['sellerPrice']!.text = item.sellerPrice?.toString() ?? '';
      _controllers['note']!.text = item.note ?? '';
      _categoryFilter = item.category;

      WidgetsBinding.instance.addPostFrameCallback((_) {
        context.read<ShopBloc>().upload.add(ClearImageEvent());
        if (item.imageUrl?.isNotEmpty ?? false) {
          context.read<ShopBloc>().upload.add(
                LoadExistingImageEvent(
                  imageUrl: item.imageUrl,
                ),
              );
        }
      });
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
    final valueChange = _controllers.values.any(
      (c) => c.text.isNotEmpty,
    );
    _hasChanges = valueChange || context.read<ShopBloc>().upload.selectedImage != null;
    setState(() {});
  }

  Future<bool> _onWillPop() async {
    if (!_hasChanges) return true;

    final l10n = AppLocalizations.of(context);
    final shouldPop = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.unsavedChanges, style: AppTextTheme.title),
        content: Text(l10n.confirmDiscardChanges, style: AppTextTheme.body),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(l10n.cancel, style: AppTextTheme.caption),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Theme.of(context).colorScheme.error),
            child: Text(l10n.discard, style: AppTextTheme.caption),
          ),
        ],
      ),
    );

    return shouldPop ?? false;
  }

  void _submitItem() {
    if (!_formKey.currentState!.validate()) return;

    final shopBloc = context.read<ShopBloc>();
    final uploadBloc = shopBloc.upload;
    final item = ShopItemModel(
      id: widget.existingItem?.id ?? 0,
      name: _controllers['name']!.text,
      defaultPrice: int.tryParse(_controllers['defaultPrice']!.text) ?? 0,
      customerPrice:
          _controllers['customerPrice']!.text.isNotEmpty ? int.tryParse(_controllers['customerPrice']!.text) : null,
      sellerPrice:
          _controllers['sellerPrice']!.text.isNotEmpty ? int.tryParse(_controllers['sellerPrice']!.text) : null,
      note: _controllers['note']!.text.isEmpty ? null : _controllers['note']!.text,
      imageUrl: uploadBloc.selectedImage?.path ?? widget.existingItem?.imageUrl,
      category: _categoryFilter,
    );

    if (uploadBloc.selectedImage != null) {
      uploadBloc.add(UploadImageEvent(uploadBloc.selectedImage!));
    } else {
      if (widget.existingItem != null) {
        shopBloc.add(ShopEditItemEvent(body: item));
      } else {
        shopBloc.add(ShopCreateItemEvent(body: item));
      }
    }
  }

  Widget _buildTextField({
    required String key,
    required String label,
    bool required = false,
    bool isPrice = false,
    TextInputType keyboardType = TextInputType.text,
    TextInputAction textInputAction = TextInputAction.next,
  }) {
    final l10n = AppLocalizations.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: CustomTextFormField(
        controller: _controllers[key]!,
        hintText: '',
        labelText: required ? '$label *' : label,
        keyboardType: isPrice ? TextInputType.number : keyboardType,
        action: textInputAction,
        useCustomBorder: false,
        validator: required ? (value) => value!.isEmpty ? l10n.nameRequired(label) : null : null,
        decoration: InputDecoration(
          contentPadding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
          labelStyle: AppTextTheme.body,
          suffixText: isPrice ? 'រៀល' : null,
          suffixStyle: isPrice ? AppTextTheme.caption : null,
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
          title: Text(
            widget.existingItem != null ? l10n.editItem : l10n.addNewItem,
            style: AppTextTheme.title,
          ),
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
        body: MultiBlocListener(
          listeners: [
            BlocListener<UploadBloc, UploadState>(
              bloc: context.read<ShopBloc>().upload,
              listener: (context, state) {
                if (state is UploadSuccess) {
                  final shopBloc = context.read<ShopBloc>();
                  final item = ShopItemModel(
                    id: widget.existingItem?.id ?? 0,
                    name: _controllers['name']!.text,
                    defaultPrice: int.tryParse(_controllers['defaultPrice']!.text) ?? 0,
                    customerPrice: _controllers['customerPrice']!.text.isNotEmpty
                        ? int.tryParse(_controllers['customerPrice']!.text)
                        : null,
                    sellerPrice: _controllers['sellerPrice']!.text.isNotEmpty
                        ? int.tryParse(_controllers['sellerPrice']!.text)
                        : null,
                    note: _controllers['note']!.text.isEmpty ? null : _controllers['note']!.text,
                    imageUrl: state.imageUrl, // Use uploaded URL
                    category: _categoryFilter,
                  );
                  if (widget.existingItem != null) {
                    shopBloc.add(ShopEditItemEvent(body: item));
                  } else {
                    shopBloc.add(ShopCreateItemEvent(body: item));
                  }
                } else if (state is UploadFailure) {
                  showErrorSnackBar(context, 'Upload failed: ${state.error}');
                }
              },
            ),
            BlocListener<ShopBloc, ShopState>(
              listener: (context, state) {
                if (state is ShopLoaded) context.pop();
              },
            ),
          ],
          child: Form(
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
                    key: 'customerPrice',
                    label: l10n.customerPrice,
                    isPrice: true,
                    required: true,
                    keyboardType: TextInputType.number,
                  ),
                  _buildTextField(
                    key: 'defaultPrice',
                    isPrice: true,
                    label: l10n.defaultPrice,
                    keyboardType: TextInputType.number,
                  ),
                  _buildTextField(
                    key: 'sellerPrice',
                    label: l10n.sellerPrice,
                    isPrice: true,
                    keyboardType: TextInputType.number,
                  ),
                  Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: CategoryDropdown(
                      initialValue: widget.existingItem?.category,
                      onChanged: (value) {
                        _categoryFilter = value;
                        _hasChanges = true;
                      },
                      decoration: InputDecoration(
                        labelText: l10n.category,
                        labelStyle: AppTextTheme.body,
                        border: const OutlineInputBorder(
                          borderRadius: BorderRadius.all(Radius.circular(8)),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 20,
                        ),
                        filled: true,
                        fillColor: colorScheme.surface,
                      ),
                    ),
                  ),
                  _buildTextField(
                    key: 'note',
                    label: l10n.note,
                  ),
                  Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          l10n.image,
                          style: AppTextTheme.body,
                        ),
                        const SizedBox(height: 8),
                        BlocBuilder<UploadBloc, UploadState>(
                          bloc: context.read<ShopBloc>().upload,
                          builder: (context, state) {
                            return Row(
                              children: [
                                ElevatedButton.icon(
                                  onPressed: () {
                                    if (state is UploadInProgress) return;
                                    final bloc = context.read<ShopBloc>().upload;
                                    bloc.showImageSourceDialog(
                                      context,
                                      onTakePhoto: () => bloc.add(
                                        SelectImageEvent(ImageSource.camera),
                                      ),
                                      onChoseFromGallery: () => bloc.add(
                                        SelectImageEvent(ImageSource.gallery),
                                      ),
                                    );
                                  },
                                  icon: const Icon(Icons.upload),
                                  label: Text(
                                    l10n.uploadImage,
                                    style: AppTextTheme.body,
                                  ),
                                  style: ElevatedButton.styleFrom(
                                    foregroundColor: colorScheme.onSurface,
                                    backgroundColor: colorScheme.surface,
                                  ),
                                ),
                                const SizedBox(width: 16),
                                switch (state) {
                                  UploadImageSelected() => ClipRRect(
                                      borderRadius: BorderRadius.circular(8),
                                      child: Image.file(
                                        state.selectedImage,
                                        width: 80,
                                        height: 80,
                                        fit: BoxFit.cover,
                                        errorBuilder: (context, error, stackTrace) => const SizedBox.shrink(),
                                      ),
                                    ),
                                  UploadImageUrlLoaded() => ClipRRect(
                                      borderRadius: BorderRadius.circular(8),
                                      child: Image.network(
                                        state.imageUrl,
                                        width: 80,
                                        height: 80,
                                        fit: BoxFit.cover,
                                        errorBuilder: (context, error, stackTrace) => const SizedBox.shrink(),
                                      ),
                                    ),
                                  _ => const SizedBox.shrink(),
                                },
                              ],
                            );
                          },
                        ),
                      ],
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
                    child: Text(
                      widget.existingItem != null ? l10n.saveChanges : l10n.addItem,
                      style: AppTextTheme.body,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
