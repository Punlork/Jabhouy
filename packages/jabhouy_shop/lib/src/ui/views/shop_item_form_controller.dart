import 'dart:io';

import 'package:flutter/material.dart';
import 'package:jabhouy_shop/jabhouy_shop.dart';
import 'package:jabhouy_shop/src/ui/widgets/whole_number_input.dart';
import 'package:jabhouy_ui/jabhouy_ui.dart';

/// What stops a variant from saving, read from its text alone.
///
/// A collapsed card keeps its fields mounted, so `Form.validate()` still
/// checks them; this is what the collapsed summary and expand-on-save
/// read, without depending on which widgets are showing.
enum VariantProblem { missingCustomerPrice, invalidPrice, invalidPackSize }

class ShopItemVariantDraft {
  ShopItemVariantDraft({
    String label = '',
    String customerPrice = '',
    String defaultPrice = '',
    String sellerPrice = '',
    String packAmount = '',
    this.isPack = false,
  })  : key = GlobalKey(),
        labelController = TextEditingController(text: label),
        customerPriceController = TextEditingController(text: customerPrice),
        defaultPriceController = TextEditingController(text: defaultPrice),
        sellerPriceController = TextEditingController(text: sellerPrice),
        packAmountController = TextEditingController(text: packAmount);

  factory ShopItemVariantDraft.single() =>
      ShopItemVariantDraft(packAmount: '1');

  factory ShopItemVariantDraft.pack() =>
      ShopItemVariantDraft(packAmount: '12', isPack: true);

  factory ShopItemVariantDraft.named(String label) =>
      ShopItemVariantDraft(label: label);

  /// Also the card's handle for scrolling to it when it cannot save.
  final GlobalKey key;
  bool isPack;

  /// View state only, and kept out of [snapshot]: opening or closing a
  /// card is not an unsaved change.
  bool isExpanded = true;

  final TextEditingController labelController;
  final TextEditingController customerPriceController;
  final TextEditingController defaultPriceController;
  final TextEditingController sellerPriceController;
  final TextEditingController packAmountController;

  Set<VariantProblem> get problems {
    bool unreadable(TextEditingController c) =>
        c.text.trim().isNotEmpty && parseWholeNumber(c.text) == null;

    return {
      if (customerPriceController.text.trim().isEmpty)
        VariantProblem.missingCustomerPrice,
      if (unreadable(customerPriceController) ||
          unreadable(defaultPriceController) ||
          unreadable(sellerPriceController))
        VariantProblem.invalidPrice,
      if (isPack && (parseWholeNumber(packAmountController.text) ?? 0) < 2)
        VariantProblem.invalidPackSize,
    };
  }

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
      final initialDraft = ShopItemVariantDraft(
        label: item.variantLabel,
        customerPrice: item.customerPrice?.toString() ?? '',
        defaultPrice: item.defaultPrice?.toString() ?? '',
        sellerPrice: item.sellerPrice?.toString() ?? '',
        packAmount: item.packAmount?.toString() ?? '1',
        isPack: (item.packAmount ?? 0) > 1,
      );

      nameController.text = item.productName;
      noteController.text = item.note ?? '';
      categoryFilter = item.category;

      _registerVariantDraftListeners(initialDraft);
      variantDrafts.add(initialDraft);

      _initialTextValues.addAll({
        'name': item.productName,
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

  void _registerVariantDraftListeners(ShopItemVariantDraft draft) {
    draft.labelController.addListener(onChanged);
    draft.customerPriceController.addListener(onChanged);
    draft.defaultPriceController.addListener(onChanged);
    draft.sellerPriceController.addListener(onChanged);
    draft.packAmountController.addListener(onChanged);
  }

  /// Adds [draft] open, and closes every card that could already save,
  /// so only the one being filled in takes the screen.
  void addVariantDraft(ShopItemVariantDraft draft) {
    for (final existing in variantDrafts) {
      if (existing.problems.isEmpty) existing.isExpanded = false;
    }
    _registerVariantDraftListeners(draft);
    variantDrafts.add(draft);
    onChanged();
  }

  void setExpanded(ShopItemVariantDraft draft, {required bool isExpanded}) {
    draft.isExpanded = isExpanded;
    onChanged();
  }

  /// Switching to Single clears the pack size; switching to Pack starts it
  /// where [ShopItemVariantDraft.pack] does.
  void setPack(ShopItemVariantDraft draft, {required bool isPack}) {
    if (draft.isPack == isPack) return;
    draft
      ..isPack = isPack
      ..packAmountController.text = isPack ? '12' : '1';
    onChanged();
  }

  /// Opens every card that cannot save and returns the first, so the page
  /// can scroll to it.
  ShopItemVariantDraft? expandDraftsWithProblems() {
    ShopItemVariantDraft? first;
    for (final draft in variantDrafts) {
      if (draft.problems.isEmpty) continue;
      draft.isExpanded = true;
      first ??= draft;
    }
    if (first != null) onChanged();
    return first;
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

  /// Null only for an empty field: validation refuses anything else the
  /// form cannot read before this runs.
  int? parseControllerPrice(TextEditingController controller) =>
      parseWholeNumber(controller.text);

  int? parseDraftPackAmount(ShopItemVariantDraft draft) =>
      draft.isPack ? parseWholeNumber(draft.packAmountController.text) : null;

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
