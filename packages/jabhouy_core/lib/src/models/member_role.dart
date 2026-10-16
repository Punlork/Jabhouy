/// What a Member may do in a Shop.
enum MemberRole {
  owner,
  editor,
  viewer;

  /// Prices, categories and units: owner and editor.
  bool get canEditPrices => this != viewer;

  static MemberRole parse(String value) =>
      values.firstWhere((r) => r.name == value, orElse: () => viewer);
}
