import 'dart:io';
import 'dart:ui' as ui;

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:inventario_bodega/core/database/app_database.dart';
import 'package:inventario_bodega/core/database/demo_data.dart';
import 'package:inventario_bodega/core/providers/database_provider.dart';
import 'package:inventario_bodega/features/inventory/domain/entities/movement.dart';
import 'package:inventario_bodega/features/inventory/presentation/screens/movement_form_screen.dart';
import 'package:inventario_bodega/features/products/presentation/screens/product_detail_screen.dart';
import 'package:inventario_bodega/features/products/presentation/screens/product_form_screen.dart';
import 'package:inventario_bodega/features/products/presentation/screens/product_list_screen.dart';
import 'package:inventario_bodega/features/reports/presentation/screens/dashboard_screen.dart';
import 'package:inventario_bodega/features/reports/presentation/screens/history_screen.dart';
import 'package:inventario_bodega/features/scanner/presentation/screens/scanner_screen.dart';
import 'package:inventario_bodega/features/scanner/presentation/screens/unknown_code_sheet.dart';
import 'package:inventario_bodega/features/settings/presentation/screens/settings_screen.dart';

/// Renders the final screens to PNG files under `docs/screenshots`.
///
/// The images feed the user manual. Text needs real fonts, which are loaded
/// from the Flutter SDK, because the test binding replaces every family with
/// the Ahem placeholder font by default.
void main() {
  final outputDirectory = Directory('docs/screenshots');
  final captureKey = GlobalKey();
  late AppDatabase database;

  setUpAll(() async {
    await _loadFonts();
  });

  setUp(() async {
    database = AppDatabase(DatabaseConnection(NativeDatabase.memory()));
    await seedDemoData(database);
    if (!outputDirectory.existsSync()) {
      outputDirectory.createSync(recursive: true);
    }
  });

  tearDown(() async {
    await database.close();
  });

  Future<void> capture(
    WidgetTester tester,
    String fileName,
    Widget screen, {
    Future<void> Function(WidgetTester tester)? interact,
  }) async {
    tester.view.physicalSize = const Size(1080, 2160);
    tester.view.devicePixelRatio = 3.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [databaseProvider.overrideWithValue(database)],
        child: MaterialApp(
          debugShowCheckedModeBanner: false,
          theme: ThemeData(
            colorScheme:
                ColorScheme.fromSeed(seedColor: const Color(0xFF1B5E20)),
            useMaterial3: true,
            fontFamily: 'Roboto',
          ),
          home: RepaintBoundary(key: captureKey, child: screen),
        ),
      ),
    );
    await _settle(tester);

    if (interact != null) {
      await interact(tester);
      await _settle(tester);
    }

    final boundary = captureKey.currentContext!.findRenderObject()!
        as RenderRepaintBoundary;
    final image = await boundary.toImage(pixelRatio: 1.5);
    final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
    File('${outputDirectory.path}/$fileName')
        .writeAsBytesSync(bytes!.buffer.asUint8List());
  }

  testWidgets('inicio', (tester) async {
    await capture(tester, '01-inicio.png', const DashboardScreen());
  });

  testWidgets('productos', (tester) async {
    await capture(tester, '02-productos.png', const ProductListScreen());
  });

  testWidgets('formulario de producto', (tester) async {
    await capture(
        tester, '03-producto-formulario.png', const ProductFormScreen());
  });

  testWidgets('detalle de producto con etiquetas', (tester) async {
    await capture(
      tester,
      '04-producto-detalle.png',
      const ProductDetailScreen(productId: 1),
    );
  });

  testWidgets('movimiento de entrada', (tester) async {
    await capture(
      tester,
      '05-movimiento-entrada.png',
      const MovementFormScreen(productId: 1, initialType: MovementType.entry),
    );
  });

  testWidgets('movimiento de salida', (tester) async {
    await capture(
      tester,
      '06-movimiento-salida.png',
      const MovementFormScreen(productId: 1, initialType: MovementType.exit),
    );
  });

  testWidgets('movimiento de ajuste', (tester) async {
    await capture(
      tester,
      '07-movimiento-ajuste.png',
      const MovementFormScreen(
        productId: 1,
        initialType: MovementType.adjustment,
      ),
    );
  });

  testWidgets('escaner con busqueda manual', (tester) async {
    await capture(
      tester,
      '08-escaner-busqueda-manual.png',
      const ScannerScreen(),
      interact: (tester) async {
        await tester.tap(find.byIcon(Icons.keyboard));
      },
    );
  });

  testWidgets('codigo no registrado', (tester) async {
    await capture(
      tester,
      '09-codigo-no-registrado.png',
      const ProductListScreen(),
      interact: (tester) async {
        await showUnknownCodeSheet(
          tester.element(find.byType(Scaffold)),
          'AB-999',
        );
      },
    );
  });

  testWidgets('historial de movimientos', (tester) async {
    await capture(tester, '10-historial.png', const HistoryScreen());
  });

  testWidgets('perfil local', (tester) async {
    await capture(tester, '11-perfil.png', const SettingsScreen());
  });
}

/// Pumps a bounded number of frames.
///
/// `pumpAndSettle` is unusable here: several screens show a progress indicator
/// while their provider resolves, which never lets the frame queue drain.
Future<void> _settle(WidgetTester tester) async {
  for (var i = 0; i < 8; i++) {
    await tester.pump(const Duration(milliseconds: 250));
  }
}

Future<void> _loadFonts() async {
  final root = Platform.environment['FLUTTER_ROOT'] ??
      '/workspace/tools/flutter-sdk/flutter';
  final fontDirectory = Directory('$root/bin/cache/artifacts/material_fonts');

  Future<void> load(String family, List<String> files) async {
    final loader = FontLoader(family);
    var loaded = false;
    for (final file in files) {
      final candidate = File('${fontDirectory.path}/$file');
      if (candidate.existsSync()) {
        loader.addFont(
          Future.value(candidate.readAsBytesSync().buffer.asByteData()),
        );
        loaded = true;
      }
    }
    if (loaded) {
      await loader.load();
    }
  }

  await load('Roboto', [
    'Roboto-Regular.ttf',
    'Roboto-Medium.ttf',
    'Roboto-Bold.ttf',
  ]);
  await load('MaterialIcons', ['MaterialIcons-Regular.otf']);
}
