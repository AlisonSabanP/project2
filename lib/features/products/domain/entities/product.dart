/// Inventory item of a single store or warehouse.
class Product {
  const Product({
    this.id,
    required this.code,
    required this.name,
    this.description,
    this.categoryId,
    required this.purchasePrice,
    required this.salePrice,
    required this.currentStock,
    required this.minimumStock,
    this.photoPath,
    this.active = true,
  });

  final int? id;

  /// Business identifier encoded into the barcode and QR label. Unique.
  final String code;
  final String name;
  final String? description;
  final int? categoryId;
  final double purchasePrice;
  final double salePrice;

  /// Derived value: it only changes through inventory movements.
  final int currentStock;
  final int minimumStock;

  /// Absolute path of the optional photograph stored on the device.
  final String? photoPath;
  final bool active;

  bool get isLowStock => currentStock <= minimumStock;

  double get stockPurchaseValue => currentStock * purchasePrice;

  double get stockSaleValue => currentStock * salePrice;

  Product copyWith({
    int? id,
    String? code,
    String? name,
    String? description,
    int? categoryId,
    double? purchasePrice,
    double? salePrice,
    int? currentStock,
    int? minimumStock,
    String? photoPath,
    bool? active,
  }) {
    return Product(
      id: id ?? this.id,
      code: code ?? this.code,
      name: name ?? this.name,
      description: description ?? this.description,
      categoryId: categoryId ?? this.categoryId,
      purchasePrice: purchasePrice ?? this.purchasePrice,
      salePrice: salePrice ?? this.salePrice,
      currentStock: currentStock ?? this.currentStock,
      minimumStock: minimumStock ?? this.minimumStock,
      photoPath: photoPath ?? this.photoPath,
      active: active ?? this.active,
    );
  }

  @override
  bool operator ==(Object other) =>
      other is Product &&
      other.id == id &&
      other.code == code &&
      other.name == name &&
      other.description == description &&
      other.categoryId == categoryId &&
      other.purchasePrice == purchasePrice &&
      other.salePrice == salePrice &&
      other.currentStock == currentStock &&
      other.minimumStock == minimumStock &&
      other.photoPath == photoPath &&
      other.active == active;

  @override
  int get hashCode => Object.hash(
        id,
        code,
        name,
        description,
        categoryId,
        purchasePrice,
        salePrice,
        currentStock,
        minimumStock,
        photoPath,
        active,
      );

  @override
  String toString() => 'Product(id: $id, code: $code, name: $name)';
}
