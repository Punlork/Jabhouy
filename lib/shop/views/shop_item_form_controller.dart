import 'dart:io';

import 'package:flutter/material.dart';
import 'package:my_app/app/app.dart';
import 'package:my_app/shop/shop.dart';

enum ShopItemKind { single, pack }

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

  factory ShopItemVariantDraft.single() => ShopItemVariantDraft(packAmount: '1');

  factory ShopItemVariantDraft.pack() => ShopItemVariantDraft(packAmount: '12');

  factory ShopItemVariantDraft.named(String label) => ShopItemVariantDraft(label: label);

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
  final packAmountController = TextEditingController();
  final defaultPriceController = TextEditingController();
  final customerPriceController = TextEditingController();
  final sellerPriceController = TextEditingController();
  final noteController = TextEditingController();

  final List<ShopItemVariantDraft> variantDrafts = <ShopItemVariantDraft>[];

  CategoryItemModel? categoryFilter;
  String? imageUrl;
  ShopItemKind itemKind = ShopItemKind.single;

  late final Map<String, String> _initialTextValues;
  late final CategoryItemModel? _initialCategory;
  late final String? _initialImageUrl;
  late final ShopItemKind _initialItemKind;
  late final String _initialVariantSnapshot;

  bool get isEditing => existingItem != null;

  String get variantSnapshot => variantDrafts.map((draft) => draft.snapshot()).join('||');

  void _registerBaseListeners() {
    for (final controller in [
      nameController,
      packAmountController,
      defaultPriceController,
      customerPriceController,
      sellerPriceController,
      noteController,
    ]) {
      controller.addListener(onChanged);
    }
  }

  void _initialize() {
    _initialTextValues = <String, String>{};
    imageUrl = existingItem?.imageUrl;

    if (existingItem case final item?) {
      nameController.text = item.baseName;
      packAmountController.text = item.packAmount?.toString() ?? '';
      defaultPriceController.text = item.defaultPrice?.toString() ?? '';
      customerPriceController.text = item.customerPrice?.toString() ?? '';
      sellerPriceController.text = item.sellerPrice?.toString() ?? '';
      noteController.text = item.note ?? '';

      categoryFilter = item.category;
      itemKind = item.isPack ? ShopItemKind.pack : ShopItemKind.single;

      _initialTextValues.addAll({
        'name': item.baseName,
        'packAmount': item.packAmount?.toString() ?? '',
        'defaultPrice': item.defaultPrice?.toString() ?? '',
        'customerPrice': item.customerPrice?.toString() ?? '',
        'sellerPrice': item.sellerPrice?.toString() ?? '',
        'note': item.note ?? '',
      });
    } else {
      categoryFilter = activeCategory;
      final initialDraft = ShopItemVariantDraft.single();
      _registerVariantDraftListeners(initialDraft);
      variantDrafts.add(initialDraft);

      _initialTextValues.addAll({
        'name': '',
        'packAmount': '',
        'defaultPrice': '',
        'customerPrice': '',
        'sellerPrice': '',
        'note': '',
      });
    }

    _initialCategory = categoryFilter;
    _initialImageUrl = imageUrl;
    _initialItemKind = itemKind;
    _initialVariantSnapshot = variantSnapshot;
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

  void setItemKind(ShopItemKind nextKind) {
    itemKind = nextKind;
    if (nextKind == ShopItemKind.single) {
      packAmountController.clear();
    }
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
      'packAmount': packAmountController.text,
      'defaultPrice': defaultPriceController.text,
      'customerPrice': customerPriceController.text,
      'sellerPrice': sellerPriceController.text,
      'note': noteController.text,
    }.entries.any((entry) => entry.value != _initialTextValues[entry.key]);

    final hasVariantChanges = !isEditing && variantSnapshot != _initialVariantSnapshot;

    return hasTextChanges ||
        categoryFilter != _initialCategory ||
        itemKind != _initialItemKind ||
        hasVariantChanges ||
        selectedImage != null ||
        imageUrl != _initialImageUrl ||
        uploadState is UploadSuccess;
  }

  int? get parsedPackAmount {
    final raw = packAmountController.text.trim();
    if (raw.isEmpty) {
      return null;
    }
    return int.tryParse(raw);
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
    final packSuffix = packAmount != null && packAmount > 1 ? ' x$packAmount' : '';
    return '$baseName$labelSuffix$packSuffix';
  }

  ShopItemModel buildEditedItem({String? imageUrlOverride}) {
    return ShopItemModel(
      id: existingItem?.id ?? 0,
      name: ShopItemModel.buildDisplayName(
        nameController.text.trim(),
        packAmount: itemKind == ShopItemKind.pack ? parsedPackAmount : null,
      ),
      defaultPrice: parseControllerPrice(defaultPriceController),
      customerPrice: parseControllerPrice(customerPriceController),
      sellerPrice: parseControllerPrice(sellerPriceController),
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
    packAmountController.dispose();
    defaultPriceController.dispose();
    customerPriceController.dispose();
    sellerPriceController.dispose();
    noteController.dispose();
    for (final draft in variantDrafts) {
      draft.dispose();
    }
  }
}
