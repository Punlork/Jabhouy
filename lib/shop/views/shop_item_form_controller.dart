import 'dart:io';

import 'package:flutter/material.dart';
import 'package:my_app/app/app.dart';
import 'package:my_app/shop/shop.dart';

class ShopItemVariantDraft {
  ShopItemVariantDraft({
    String label = '',
    String customerPrice = '',
    String defaultPrice = '',
    String sellerPrice = '',
    String packAmount = '',
  })  : key = UniqueKey(),
        labelController = TextEditingController(text: label),
        customerPriceController = TextEditingController(text: customerPrice),
        defaultPriceController = TextEditingController(text: defaultPrice),
        sellerPriceController = TextEditingController(text: sellerPrice),
        packAmountController = TextEditingController(text: packAmount);

  factory ShopItemVariantDraft.single() =>
      ShopItemVariantDraft(packAmount: '1');

  factory ShopItemVariantDraft.pack() => ShopItemVariantDraft(packAmount: '12');

  factory ShopItemVariantDraft.named(String label) =>
      ShopItemVariantDraft(label: label);

  final Key key;
  final TextEditingController labelController;
  final TextEditingController customerPriceController;
  final TextEditingController defaultPriceController;
  final TextEditingController sellerPriceController;
  final TextEditingController packAmountController;

  String snapshot() {
    return [
      labelController.text,
      customerPriceController.text,
      defaultPriceController.text,
      sellerPriceController.text,
      packAmountController.text,
    ].join('|');
  }

  void dispose() {
    labelController.dispose();
    customerPriceController.dispose();
    defaultPriceController.dispose();
    sellerPriceController.dispose();
    packAmountController.dispose();
  }
}

class ShopItemFormController {
  ShopItemFormController({
    required this.onChanged,
    this.existingItem,
    this.activeCategory,
  }) {
    _registerBaseListeners();
    _initialize();
  }

  final VoidCallback onChanged;
  final ShopItemModel? existingItem;
  final CategoryItemModel? activeCategory;

  final nameController = TextEditingController();
  final noteController = TextEditingController();

  final List<ShopItemVariantDraft> variantDrafts = <ShopItemVariantDraft>[];

  CategoryItemModel? categoryFilter;
  String? imageUrl;

  late final Map<String, String> _initialTextValues;
  late final CategoryItemModel? _initialCategory;
  late final String? _initialImageUrl;
  late final String _initialVariantSnapshot;

  bool get isEditing => existingItem != null;

  String get variantSnapshot =>
      variantDrafts.map((draft) => draft.snapshot()).join('||');

  void _registerBaseListeners() {
    for (final controller in [nameController, noteController]) {
      controller.addListener(onChanged);
    }
  }

  void _initialize() {
    _initialTextValues = <String, String>{};
    imageUrl = existingItem?.imageUrl;

    if (existingItem case final item?) {
      final editableName = _splitEditableName(item);
      final initialDraft = ShopItemVariantDraft(
        label: editableName.label,
        customerPrice: item.customerPrice?.toString() ?? '',
        defaultPrice: item.defaultPrice?.toString() ?? '',
        sellerPrice: item.sellerPrice?.toString() ?? '',
        packAmount: item.packAmount?.toString() ?? '1',
      );

      nameController.text = editableName.baseName;
      noteController.text = item.note ?? '';
      categoryFilter = item.category;

      _registerVariantDraftListeners(initialDraft);
      variantDrafts.add(initialDraft);

      _initialTextValues.addAll({
        'name': editableName.baseName,
        'note': item.note ?? '',
      });
    } else {
      categoryFilter = activeCategory;
      final initialDraft = ShopItemVariantDraft.single();
      _registerVariantDraftListeners(initialDraft);
      variantDrafts.add(initialDraft);

      _initialTextValues.addAll({
        'name': '',
        'note': '',
      });
    }

    _initialCategory = categoryFilter;
    _initialImageUrl = imageUrl;
    _initialVariantSnapshot = variantSnapshot;
  }

  ({String baseName, String label}) _splitEditableName(ShopItemModel item) {
    final rawName = item.baseName;
    final separatorIndex = rawName.lastIndexOf(' - ');

    if (separatorIndex <= 0 || separatorIndex >= rawName.length - 3) {
      return (baseName: rawName, label: '');
    }

    return (
      baseName: rawName.substring(0, separatorIndex).trim(),
      label: rawName.substring(separatorIndex + 3).trim(),
    );
  }

  void _registerVariantDraftListeners(ShopItemVariantDraft draft) {
    draft.labelController.addListener(onChanged);
    draft.customerPriceController.addListener(onChanged);
    draft.defaultPriceController.addListener(onChanged);
    draft.sellerPriceController.addListener(onChanged);
    draft.packAmountController.addListener(onChanged);
  }

  void addVariantDraft(ShopItemVariantDraft draft) {
    _registerVariantDraftListeners(draft);
    variantDrafts.add(draft);
    onChanged();
  }

  void removeVariantDraft(ShopItemVariantDraft draft) {
    draft.dispose();
    variantDrafts.remove(draft);
    onChanged();
  }

  void setCategory(CategoryItemModel? category) {
    categoryFilter = category;
    onChanged();
  }

  void setImageUrl(String? nextImageUrl) {
    imageUrl = nextImageUrl;
    onChanged();
  }

  bool hasChanges({
    required UploadState uploadState,
    required File? selectedImage,
  }) {
    final hasTextChanges = <String, String>{
      'name': nameController.text,
      'note': noteController.text,
    }.entries.any((entry) => entry.value != _initialTextValues[entry.key]);

    final hasVariantChanges = variantSnapshot != _initialVariantSnapshot;

    return hasTextChanges ||
        categoryFilter != _initialCategory ||
        hasVariantChanges ||
        selectedImage != null ||
        imageUrl != _initialImageUrl ||
        uploadState is UploadSuccess;
  }

  String? get sharedNote {
    final note = noteController.text.trim();
    return note.isEmpty ? null : note;
  }

  int? parseControllerPrice(TextEditingController controller) {
    final raw = controller.text.trim();
    if (raw.isEmpty) {
      return null;
    }
    return int.tryParse(raw);
  }

  int? parseDraftPackAmount(ShopItemVariantDraft draft) {
    final raw = draft.packAmountController.text.trim();
    if (raw.isEmpty) {
      return null;
    }
    return int.tryParse(raw);
  }

  String buildVariantName(String baseName, ShopItemVariantDraft draft) {
    final label = draft.labelController.text.trim();
    final packAmount = parseDraftPackAmount(draft);
    final labelSuffix = label.isEmpty ? '' : ' - $label';
    final packSuffix =
        packAmount != null && packAmount > 1 ? ' x$packAmount' : '';
    return '$baseName$labelSuffix$packSuffix';
  }

  ShopItemModel buildEditedItem({String? imageUrlOverride}) {
    final draft = variantDrafts.first;

    return ShopItemModel(
      id: existingItem?.id ?? 0,
      name: buildVariantName(nameController.text.trim(), draft),
      defaultPrice: parseControllerPrice(draft.defaultPriceController),
      customerPrice: parseControllerPrice(draft.customerPriceController),
      sellerPrice: parseControllerPrice(draft.sellerPriceController),
      note: sharedNote,
      imageUrl: imageUrlOverride ?? imageUrl,
      category: categoryFilter,
    );
  }

  List<ShopItemModel> buildNewItems({String? imageUrlOverride}) {
    final baseName = nameController.text.trim();
    final resolvedImageUrl = imageUrlOverride ?? imageUrl;

    return variantDrafts
        .map(
          (draft) => ShopItemModel(
            id: 0,
            name: buildVariantName(baseName, draft),
            defaultPrice: parseControllerPrice(draft.defaultPriceController),
            customerPrice: parseControllerPrice(draft.customerPriceController),
            sellerPrice: parseControllerPrice(draft.sellerPriceController),
            note: sharedNote,
            imageUrl: resolvedImageUrl,
            category: categoryFilter,
          ),
        )
        .toList();
  }

  void dispose() {
    nameController.dispose();
    noteController.dispose();
    for (final draft in variantDrafts) {
      draft.dispose();
    }
  }
}
