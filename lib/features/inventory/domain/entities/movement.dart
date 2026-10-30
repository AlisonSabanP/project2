/// Kind of stock movement. Every change of [Product.currentStock] is recorded
/// as one of these.
enum MovementType {
  /// Increases stock: purchases, customer returns, transfers in.
  entry('entrada'),

  /// Decreases stock: sales, damages, transfers out.
  exit('salida'),

  /// Overrides stock after a physical count.
  adjustment('ajuste');

  const MovementType(this.label);

  final String label;

  static MovementType fromName(String value) {
    return MovementType.values.firstWhere(
      (type) => type.name == value,
      orElse: () => throw ArgumentError.value(value, 'value', 'Tipo invalido'),
    );
  }
}

/// Immutable audit record of a stock change.
///
/// Confirmed movements are append only: corrections are new movements.
class Movement {
  const Movement({
    this.id,
    required this.productId,
    required this.type,
    required this.quantity,
    required this.previousStock,
    required this.resultingStock,
    required this.reason,
    required this.responsible,
    required this.dateTime,
  });

  final int? id;
  final int productId;
  final MovementType type;

  /// Units added, removed, or the counted stock for adjustments.
  final int quantity;
  final int previousStock;
  final int resultingStock;
  final String reason;

  /// Name of the person who performed the movement, taken from the local
  /// profile.
  final String responsible;
  final DateTime dateTime;

  /// Signed effect of the movement on stock.
  int get delta => resultingStock - previousStock;

  @override
  bool operator ==(Object other) =>
      other is Movement &&
      other.id == id &&
      other.productId == productId &&
      other.type == type &&
      other.quantity == quantity &&
      other.previousStock == previousStock &&
      other.resultingStock == resultingStock &&
      other.reason == reason &&
      other.responsible == responsible &&
      other.dateTime == dateTime;

  @override
  int get hashCode => Object.hash(
        id,
        productId,
        type,
        quantity,
        previousStock,
        resultingStock,
        reason,
        responsible,
        dateTime,
      );

  @override
  String toString() =>
      'Movement(id: $id, productId: $productId, type: ${type.name})';
}
