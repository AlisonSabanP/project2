import 'package:flutter_test/flutter_test.dart';
import 'package:inventario_bodega/core/error/domain_exception.dart';
import 'package:inventario_bodega/features/products/domain/services/product_validator.dart';

void main() {
  group('ProductValidator.validate', () {
    test('acepta un producto valido', () {
      expect(
        () => ProductValidator.validate(
          code: 'ab-001',
          name: 'Arroz',
          purchasePrice: 1000,
          salePrice: 1500,
          minimumStock: 5,
        ),
        returnsNormally,
      );
    });

    test('normaliza el codigo a mayusculas y sin espacios externos', () {
      expect(ProductValidator.normalizeCode('  ab-001 '), 'AB-001');
    });

    test('rechaza un codigo vacio', () {
      expect(
        () => ProductValidator.validate(
          code: '   ',
          name: 'Arroz',
          purchasePrice: 1000,
          salePrice: 1500,
          minimumStock: 5,
        ),
        throwsA(isA<ValidationException>()),
      );
    });

    test('rechaza un codigo con espacios internos', () {
      expect(
        () => ProductValidator.validate(
          code: 'AB 001',
          name: 'Arroz',
          purchasePrice: 1000,
          salePrice: 1500,
          minimumStock: 5,
        ),
        throwsA(isA<ValidationException>()),
      );
    });

    test('rechaza un nombre vacio', () {
      expect(
        () => ProductValidator.validate(
          code: 'AB-001',
          name: '   ',
          purchasePrice: 1000,
          salePrice: 1500,
          minimumStock: 5,
        ),
        throwsA(isA<ValidationException>()),
      );
    });

    test('rechaza precios no positivos', () {
      expect(
        () => ProductValidator.validate(
          code: 'AB-001',
          name: 'Arroz',
          purchasePrice: 0,
          salePrice: 1500,
          minimumStock: 5,
        ),
        throwsA(isA<ValidationException>()),
      );
      expect(
        () => ProductValidator.validate(
          code: 'AB-001',
          name: 'Arroz',
          purchasePrice: 1000,
          salePrice: 0,
          minimumStock: 5,
        ),
        throwsA(isA<ValidationException>()),
      );
    });

    test('rechaza un precio de venta inferior al de compra', () {
      expect(
        () => ProductValidator.validate(
          code: 'AB-001',
          name: 'Arroz',
          purchasePrice: 2000,
          salePrice: 1500,
          minimumStock: 5,
        ),
        throwsA(isA<ValidationException>()),
      );
    });

    test('rechaza un stock minimo negativo', () {
      expect(
        () => ProductValidator.validate(
          code: 'AB-001',
          name: 'Arroz',
          purchasePrice: 1000,
          salePrice: 1500,
          minimumStock: -1,
        ),
        throwsA(isA<ValidationException>()),
      );
    });

    test('rechaza un stock inicial negativo', () {
      expect(
        () => ProductValidator.validate(
          code: 'AB-001',
          name: 'Arroz',
          purchasePrice: 1000,
          salePrice: 1500,
          minimumStock: 5,
          initialStock: -3,
        ),
        throwsA(isA<ValidationException>()),
      );
    });

    test('genera el motivo de la existencia inicial', () {
      expect(
        ProductValidator.initialStockReason(20),
        'Existencia inicial de 20 unidades',
      );
    });
  });
}
