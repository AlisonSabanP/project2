import 'movement.dart';

/// Filter applied to the movement history.
class MovementFilter {
  const MovementFilter({this.productId, this.type, this.from, this.to});

  final int? productId;
  final MovementType? type;
  final DateTime? from;
  final DateTime? to;

  bool get isEmpty =>
      productId == null && type == null && from == null && to == null;

  MovementFilter copyWith({
    int? productId,
    MovementType? type,
    DateTime? from,
    DateTime? to,
    bool clearProduct = false,
    bool clearType = false,
    bool clearDates = false,
  }) {
    return MovementFilter(
      productId: clearProduct ? null : (productId ?? this.productId),
      type: clearType ? null : (type ?? this.type),
      from: clearDates ? null : (from ?? this.from),
      to: clearDates ? null : (to ?? this.to),
    );
  }

  @override
  bool operator ==(Object other) =>
      other is MovementFilter &&
      other.productId == productId &&
      other.type == type &&
      other.from == from &&
      other.to == to;

  @override
  int get hashCode => Object.hash(productId, type, from, to);
}
