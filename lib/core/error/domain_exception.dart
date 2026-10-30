/// Base type for every business rule violation raised by the domain layer.
///
/// The presentation layer translates these into user facing messages, so the
/// domain never depends on widgets, localization packages or storage details.
class DomainException implements Exception {
  const DomainException(this.message);

  final String message;

  @override
  String toString() => '$runtimeType: $message';
}

/// A field of a product or category failed a validation rule.
class ValidationException extends DomainException {
  const ValidationException(super.message);
}

/// The unique product code is already used by another product.
class DuplicateProductCodeException extends DomainException {
  const DuplicateProductCodeException(this.code)
      : super('El codigo "$code" ya esta registrado en otro producto.');

  final String code;
}

/// No product matches the requested identifier or code.
class ProductNotFoundException extends DomainException {
  const ProductNotFoundException([this.code])
      : super('Producto no encontrado.');

  final String? code;
}

/// No product matches the requested identifier.
class ProductByIdNotFoundException extends DomainException {
  const ProductByIdNotFoundException(this.id)
      : super('No existe el producto con identificador $id.');

  final int id;
}

/// The requested movement quantity is zero or negative.
class NonPositiveQuantityException extends DomainException {
  const NonPositiveQuantityException()
      : super('La cantidad debe ser mayor que cero.');
}

/// An exit would leave the product with negative stock.
class InsufficientStockException extends DomainException {
  const InsufficientStockException({
    required this.available,
    required this.requested,
  }) : super(
          'Stock insuficiente: disponible $available, solicitado $requested.',
        );

  final int available;
  final int requested;
}

/// The movement is missing a reason or, for adjustments, a justification.
class MissingReasonException extends DomainException {
  const MissingReasonException(this.reason)
      : super('Debe indicar el motivo del movimiento ($reason).');

  final String reason;
}

/// An adjustment was submitted without the mandatory justification text.
class MissingJustificationException extends DomainException {
  const MissingJustificationException()
      : super('El ajuste requiere una justificacion no vacia.');
}

/// The product still has movements, so it cannot be deleted physically.
class ProductHasMovementsException extends DomainException {
  const ProductHasMovementsException()
      : super(
          'El producto tiene movimientos registrados; '
          'solo puede desactivarse.',
        );
}

/// A confirmed movement cannot be edited or deleted.
class ImmutableMovementException extends DomainException {
  const ImmutableMovementException()
      : super(
          'Los movimientos confirmados no se editan ni se eliminan; '
          'registre un nuevo movimiento para corregir.',
        );
}
