import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_keyboard_visibility/flutter_keyboard_visibility.dart';
import 'package:go_router/go_router.dart';
import 'package:my_app/app/app.dart';
import 'package:my_app/l10n/arb/app_localizations.dart';
import 'package:my_app/shop/shop.dart';

class ShopItemFormPage extends StatelessWidget {
  const ShopItemFormPage({
    required this.onSaved,
    required this.shop,
    required this.category,
    this.activeCategory,
    this.existingItem,
    super.key,
  });

  final ShopItemModel? existingItem;
  final CategoryItemModel? activeCategory;
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
        activeCategory: activeCategory,
        existingItem: existingItem,
      ),
    );
  }
}

class _ShopItemFormPageContent extends StatefulWidget {
  const _ShopItemFormPageContent({
    required this.onSaved,
    this.activeCategory,
    this.existingItem,
  });

  final ShopItemModel? existingItem;
  final CategoryItemModel? activeCategory;
  final void Function(ShopItemModel) onSaved;

  @override
  State<_ShopItemFormPageContent> createState() => _ShopItemFormPageState();
}

class _ShopItemFormPageState extends State<_ShopItemFormPageContent>
    with ClipboardImageMixin<_ShopItemFormPageContent> {
  final _formKey = GlobalKey<FormState>();
  late final ShopItemFormController _formController;

  UploadBloc get _uploadBloc => context.read<ShopBloc>().upload;

  @override
  void initState() {
    super.initState();
    registerClipboardObserver();
    _formController = ShopItemFormController(
      existingItem: widget.existingItem,
      activeCategory: widget.activeCategory,
      onChanged: _notifyFormChanged,
    );

    _uploadBloc.add(ClearImageEvent());

    if (widget.existingItem case final item?) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (item.imageUrl?.isNotEmpty ?? false) {
          _uploadBloc.add(LoadExistingImageEvent(imageUrl: item.imageUrl));
        }
      });
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      forceCheckClipboardForImage();
    });
  }

  void _notifyFormChanged() {
    if (mounted) {
      setState(() {});
    }
  }

  @override
  void onImageFound(File file) => showImagePreviewSnackBar(file);

  @override
  void onImageSelected(File file) {
    _uploadBloc.add(SelectUiImageEvent(image: file));
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    _notifyFormChanged();
  }

  @override
  void dispose() {
    _formController.dispose();
    unregisterClipboardObserver();
    super.dispose();
  }

  bool get _hasChanges => _formController.hasChanges(
        uploadState: _uploadBloc.state,
        selectedImage: _uploadBloc.selectedImage,
      );

  Future<bool> _confirmDiscardChanges() async {
    if (!_hasChanges) {
      return true;
    }

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
            style: TextButton.styleFrom(
              foregroundColor: Theme.of(context).colorScheme.error,
            ),
            child: Text(l10n.discard, style: AppTextTheme.caption),
          ),
        ],
      ),
    );

    return shouldPop ?? false;
  }

  Future<void> _handleBack() async {
    if (!_hasChanges || await _confirmDiscardChanges()) {
      if (mounted) {
        context.pop();
      }
    }
  }

  void _handleCategoryChanged(CategoryItemModel? category) {
    _formController.setCategory(category);
  }

  void _openCategoryPage() {
    context.push(
      '${AppRoutes.home.toPath}${AppRoutes.category.toPath}',
      extra: {
        'shop': context.read<ShopBloc>(),
        'category': context.read<CategoryBloc>(),
      },
    );
  }

  void _saveEditedItem(ShopItemModel item) {
    context.read<ShopBloc>().add(
          ShopEditItemEvent(
            body: item,
            onSuccess: () {
              if (!mounted) return;
              widget.onSaved(item);
              context.pop();
            },
          ),
        );
  }

  void _saveNewItems(List<ShopItemModel> items) {
    context.read<ShopBloc>().add(
          ShopCreateItemsEvent(
            items: items,
            onSuccess: () {
              if (!mounted) return;
              if (items.isNotEmpty) {
                widget.onSaved(items.first);
              }
              context.pop();
            },
          ),
        );
  }

  void _submitItem() {
    if (!_formKey.currentState!.validate()) return;

    if (!_formController.isEditing && _formController.variantDrafts.isEmpty) {
      showErrorSnackBar(
        context,
        AppLocalizations.of(context).selectVariantError,
      );
      return;
    }

    if (_uploadBloc.selectedImage != null) {
      _uploadBloc.add(UploadImageEvent(_uploadBloc.selectedImage!));
      return;
    }

    if (_formController.isEditing) {
      _saveEditedItem(_formController.buildEditedItem());
    } else {
      _saveNewItems(_formController.buildNewItems());
    }
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    bool required = false,
    bool isPrice = false,
    String? helperText,
    String? suffixText,
    String? Function(String?)? validator,
    TextInputType keyboardType = TextInputType.text,
    TextInputAction textInputAction = TextInputAction.next,
    int? maxLines,
    TextCapitalization? textCapitalization,
  }) {
    final l10n = AppLocalizations.of(context);

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: CustomTextFormField(
        onTapOutside: (_) {},
        controller: controller,
        hintText: '',
        textCapitalization: textCapitalization,
        labelText: required ? '$label *' : label,
        keyboardType: maxLines != null ? TextInputType.multiline : (isPrice ? TextInputType.number : keyboardType),
        action: textInputAction,
        useCustomBorder: false,
        validator: (value) {
          if (required && (value == null || value.isEmpty)) {
            return l10n.nameRequired(label);
          }
          return validator?.call(value);
        },
        maxLines: maxLines ?? 1,
        decoration: InputDecoration(
          contentPadding: const EdgeInsets.symmetric(
            vertical: 20,
            horizontal: 16,
          ),
          labelStyle: AppTextTheme.body,
          helperText: helperText,
          suffixText: suffixText ?? (isPrice ? 'រៀល' : null),
          suffixStyle: isPrice ? AppTextTheme.caption : null,
        ),
      ),
    );
  }

  Widget _buildEditOnlyVariantType() {
    final l10n = AppLocalizations.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.itemType,
          style: AppTextTheme.body,
        ),
        const SizedBox(height: 8),
        SegmentedButton<ShopItemKind>(
          segments: [
            ButtonSegment(
              value: ShopItemKind.single,
              label: Text(l10n.singleItem),
              icon: const Icon(Icons.sell_outlined),
            ),
            ButtonSegment(
              value: ShopItemKind.pack,
              label: Text(l10n.packItem),
              icon: const Icon(Icons.inventory_2_outlined),
            ),
          ],
          selected: {_formController.itemKind},
          onSelectionChanged: (selection) {
            final nextKind = selection.first;
            if (_formController.itemKind != nextKind) {
              _formController.setItemKind(nextKind);
            }
          },
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  Widget _buildEditOnlyPricingFields() {
    final l10n = AppLocalizations.of(context);

    return Column(
      children: [
        if (_formController.itemKind == ShopItemKind.pack)
          _buildTextField(
            controller: _formController.packAmountController,
            label: l10n.packSize,
            helperText: l10n.packSizeHint,
            suffixText: l10n.itemsSuffix,
            keyboardType: TextInputType.number,
            validator: (value) {
              if (value == null || value.isEmpty) {
                return l10n.packSizeRequired;
              }
              final parsed = int.tryParse(value);
              if (parsed == null || parsed <= 1) {
                return l10n.packSizeValidation;
              }
              return null;
            },
          ),
        _buildTextField(
          controller: _formController.customerPriceController,
          label: l10n.customerPrice,
          isPrice: true,
          required: true,
          keyboardType: TextInputType.number,
        ),
        _buildTextField(
          controller: _formController.defaultPriceController,
          label: l10n.defaultPrice,
          isPrice: true,
          keyboardType: TextInputType.number,
        ),
        _buildTextField(
          controller: _formController.sellerPriceController,
          label: l10n.sellerPrice,
          isPrice: true,
          keyboardType: TextInputType.number,
        ),
      ],
    );
  }

  Widget _buildSubmitButton(bool isKeyboardVisible) {
    final colorScheme = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context);
    final label = _formController.isEditing
        ? l10n.saveChanges
        : (_formController.variantDrafts.length > 1 ? l10n.addItems : l10n.addItem);

    if (!isKeyboardVisible) {
      return Positioned(
        bottom: 16,
        left: 16,
        right: 16,
        child: ElevatedButton(
          onPressed: _submitItem,
          style: ElevatedButton.styleFrom(
            minimumSize: const Size(double.infinity, 50),
            backgroundColor: colorScheme.primary,
            foregroundColor: colorScheme.onPrimary,
          ),
          child: Text(label, style: AppTextTheme.body),
        ),
      );
    }

    return Positioned(
      bottom: 16,
      right: 16,
      child: FloatingActionButton.extended(
        onPressed: _submitItem,
        backgroundColor: colorScheme.primary,
        foregroundColor: colorScheme.onPrimary,
        label: Text(label, style: AppTextTheme.body),
        icon: const Icon(Icons.save),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final inputTheme = Theme.of(context).inputDecorationTheme;
    final l10n = AppLocalizations.of(context);

    return PopScope(
      canPop: !_hasChanges,
      onPopInvokedWithResult: (didPop, _) async {
        if (!didPop && _hasChanges) {
          await _handleBack();
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(
            _formController.isEditing ? l10n.editItem : l10n.addNewItem,
            style: AppTextTheme.title,
          ),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: _handleBack,
          ),
        ),
        body: Stack(
          children: [
            MultiBlocListener(
              listeners: [
                BlocListener<UploadBloc, UploadState>(
                  bloc: _uploadBloc,
                  listener: (context, state) {
                    if (state is UploadSuccess) {
                      _formController.setImageUrl(state.imageUrl);
                      if (_formController.isEditing) {
                        _saveEditedItem(
                          _formController.buildEditedItem(
                            imageUrlOverride: state.imageUrl,
                          ),
                        );
                      } else {
                        _saveNewItems(
                          _formController.buildNewItems(
                            imageUrlOverride: state.imageUrl,
                          ),
                        );
                      }
                    } else if (state is UploadFailure) {
                      showErrorSnackBar(
                        context,
                        'Upload failed: ${state.error}',
                      );
                    }
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
                        controller: _formController.nameController,
                        label: l10n.name,
                        required: true,
                        textCapitalization: TextCapitalization.sentences,
                      ),
                      if (_formController.isEditing)
                        _buildEditOnlyVariantType()
                      else ...[
                        ShopItemVariantBuilder(
                          variants: _formController.variantDrafts,
                          onAddSingle: () => _formController.addVariantDraft(
                            ShopItemVariantDraft.single(),
                          ),
                          onAddPack: () => _formController.addVariantDraft(
                            ShopItemVariantDraft.pack(),
                          ),
                          onAddCustom: () => _formController.addVariantDraft(
                            ShopItemVariantDraft.single(),
                          ),
                          onRemove: _formController.removeVariantDraft,
                        ),
                        const SizedBox(height: 16),
                      ],
                      if (_formController.isEditing) _buildEditOnlyPricingFields(),
                      Padding(
                        padding: const EdgeInsets.only(bottom: 16),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: CategoryDropdown(
                                initialValue: widget.existingItem?.category,
                                onChanged: _handleCategoryChanged,
                                decoration: InputDecoration(
                                  contentPadding: const EdgeInsets.symmetric(
                                    vertical: 20,
                                  ),
                                  filled: inputTheme.filled,
                                  fillColor: inputTheme.fillColor,
                                  border: inputTheme.border,
                                  enabledBorder: inputTheme.enabledBorder,
                                  focusedBorder: inputTheme.focusedBorder,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            SizedBox(
                              height: 64,
                              child: OutlinedButton.icon(
                                style: OutlinedButton.styleFrom(
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                ),
                                onPressed: _openCategoryPage,
                                icon: const Icon(
                                  Icons.add_circle_outline_rounded,
                                ),
                                label: Text(l10n.createCategory),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      _buildTextField(
                        controller: _formController.noteController,
                        label: l10n.note,
                        maxLines: 3,
                        textInputAction: TextInputAction.newline,
                      ),
                      ShopItemImageSection(
                        uploadBloc: _uploadBloc,
                        onImageCleared: () => _formController.setImageUrl(null),
                      ),
                      const SizedBox(height: 80),
                    ],
                  ),
                ),
              ),
            ),
            KeyboardVisibilityBuilder(
              builder: (context, isKeyboardVisible) {
                return _buildSubmitButton(isKeyboardVisible);
              },
            ),
          ],
        ),
      ),
    );
  }
}
