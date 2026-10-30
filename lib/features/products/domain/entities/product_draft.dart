/// Data typed by the user when creating or editing a product.
///
/// Deliberately excludes `currentStock`: stock only changes through inventory
/// movements.
class ProductDraft {
  const ProductDraft({
    required this.code,
    required this.name,
    this.description,
    this.categoryId,
    required this.purchasePrice,
    required this.salePrice,
    required this.minimumStock,
    this.photoPath,
    this.active = true,
  });

  final String code;
  final String name;
  final String? description;
  final int? categoryId;
  final double purchasePrice;
  final double salePrice;
  final int minimumStock;
  final String? photoPath;
  final bool active;

  ProductDraft copyWith({
    String? code,
    String? name,
    String? description,
    int? categoryId,
    double? purchasePrice,
    double? salePrice,
    int? minimumStock,
    String? photoPath,
    bool? active,
    bool clearCategory = false,
    bool clearPhoto = false,
  }) {
    return ProductDraft(
      code: code ?? this.code,
      name: name ?? this.name,
      description: description ?? this.description,
      categoryId: clearCategory ? null : (categoryId ?? this.categoryId),
      purchasePrice: purchasePrice ?? this.purchasePrice,
      salePrice: salePrice ?? this.salePrice,
      minimumStock: minimumStock ?? this.minimumStock,
      photoPath: clearPhoto ? null : (photoPath ?? this.photoPath),
      active: active ?? this.active,
    );
  }
}
