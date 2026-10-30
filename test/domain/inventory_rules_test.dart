import 'package:flutter_test/flutter_test.dart';
import 'package:inventario_bodega/core/error/domain_exception.dart';
import 'package:inventario_bodega/features/inventory/domain/entities/movement.dart';
import 'package:inventario_bodega/features/inventory/domain/services/inventory_rules.dart';

void main() {
  group('InventoryRules.apply', () {
    test('una entrada suma la cantidad al stock anterior', () {
      final outcome = InventoryRules.apply(
        type: MovementType.entry,
        previousStock: 10,
        quantity: 20,
      );

      expect(outcome.previousStock, 10);
      expect(outcome.resultingStock, 30);
      expect(outcome.delta, 20);
    });

    test('una salida resta la cantidad al stock anterior', () {
      final outcome = InventoryRules.apply(
        type: MovementType.exit,
        previousStock: 20,
        quantity: 16,
      );

      expect(outcome.resultingStock, 4);
      expect(outcome.delta, -16);
    });

    test('un ajuste reemplaza el stock por la cantidad contada', () {
      final outcome = InventoryRules.apply(
        type: MovementType.adjustment,
        previousStock: 4,
        quantity: 3,
      );

      expect(outcome.previousStock, 4);
      expect(outcome.resultingStock, 3);
      expect(outcome.delta, -1);
    });

    test('una entrada de cero unidades se rechaza', () {
      expect(
        () => InventoryRules.apply(
          type: MovementType.entry,
          previousStock: 5,
          quantity: 0,
        ),
        throwsA(isA<NonPositiveQuantityException>()),
      );
    });

    test('una salida de cero unidades se rechaza', () {
      expect(
        () => InventoryRules.apply(
          type: MovementType.exit,
          previousStock: 5,
          quantity: 0,
        ),
        throwsA(isA<NonPositiveQuantityException>()),
      );
    });

    test('una salida mayor al stock disponible se rechaza', () {
      expect(
        () => InventoryRules.apply(
          type: MovementType.exit,
          previousStock: 4,
          quantity: 5,
        ),
        throwsA(
          isA<InsufficientStockException>()
              .having((e) => e.available, 'available', 4)
              .having((e) => e.requested, 'requested', 5),
        ),
      );
    });

    test('una salida igual al stock disponible deja el stock en cero', () {
      final outcome = InventoryRules.apply(
        type: MovementType.exit,
        previousStock: 4,
        quantity: 4,
      );

      expect(outcome.resultingStock, 0);
    });

    test('un ajuste a cero unidades es valido', () {
      final outcome = InventoryRules.apply(
        type: MovementType.adjustment,
        previousStock: 4,
        quantity: 0,
      );

      expect(outcome.resultingStock, 0);
    });

    test('un ajuste con cantidad negativa se rechaza', () {
      expect(
        () => InventoryRules.apply(
          type: MovementType.adjustment,
          previousStock: 4,
          quantity: -1,
        ),
        throwsA(isA<ValidationException>()),
      );
    });
  });

  group('InventoryRules.validateAndApply', () {
    test('la entrada exige un motivo no vacio', () {
      expect(
        () => InventoryRules.validateAndApply(
          type: MovementType.entry,
          previousStock: 0,
          quantity: 5,
          reason: '   ',
        ),
        throwsA(isA<MissingReasonException>()),
      );
    });

    test('la salida exige un motivo no vacio', () {
      expect(
        () => InventoryRules.validateAndApply(
          type: MovementType.exit,
          previousStock: 10,
          quantity: 5,
          reason: '',
        ),
        throwsA(isA<MissingReasonException>()),
      );
    });

    test('el ajuste exige una justificacion no vacia', () {
      expect(
        () => InventoryRules.validateAndApply(
          type: MovementType.adjustment,
          previousStock: 10,
          quantity: 3,
          reason: '   ',
        ),
        throwsA(isA<MissingJustificationException>()),
      );
    });

    test('el ajuste con justificacion se aplica', () {
      final outcome = InventoryRules.validateAndApply(
        type: MovementType.adjustment,
        previousStock: 10,
        quantity: 3,
        reason: 'Conteo fisico',
      );

      expect(outcome.resultingStock, 3);
    });
  });
}
