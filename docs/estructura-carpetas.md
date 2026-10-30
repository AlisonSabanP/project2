# Estructura de carpetas

```
lib/
  main.dart
  app/
    inventory_app.dart          MaterialApp, tema, locale
    app_shell.dart              Navegacion inferior de cinco secciones
  core/
    database/
      app_database.dart         Definicion de la base de datos Drift
      app_database.g.dart       Codigo generado por drift_dev
      database_provider.dart    Apertura del archivo SQLite
      demo_data.dart            Categorias, productos y movimientos de demostracion
      mappers.dart              Traduccion entre filas Drift y entidades
      tables.dart               Esquema de tablas
    error/
      domain_exception.dart     Jerarquia de errores de negocio
    formatting/
      formatters.dart           Formatos de moneda, fecha y nombre de archivo
    providers/
      database_provider.dart    Provider raiz de la base de datos
    widgets/
      async_value_view.dart     Estados de carga, error y vacio
      stock_badge.dart          Colores y etiquetas de stock
  features/
    products/
      domain/
        entities/               Category, Product, ProductDraft
        repositories/           ProductRepository, CategoryRepository,
                                LabelExportRepository
        services/               ProductValidator
        usecases/               CreateProduct, UpdateProduct,
                                ManageProductState, ProductQueries
      data/
        drift_product_repository.dart
        drift_category_repository.dart
        share_label_repository.dart
      presentation/
        providers/product_providers.dart
        screens/product_list_screen.dart
        screens/product_form_screen.dart
        screens/product_detail_screen.dart
        widgets/product_label.dart
    inventory/
      domain/
        entities/               Movement, MovementType, MovementFilter
        repositories/           MovementRepository
        services/               InventoryRules
        usecases/               RegisterMovement, MovementQueries
      data/
        drift_movement_repository.dart
      presentation/
        providers/inventory_providers.dart
        screens/movement_form_screen.dart
        widgets/movement_tile.dart
    scanner/
      domain/
        usecases/resolve_scanned_code.dart
      presentation/
        providers/scanner_providers.dart
        screens/scanner_screen.dart
        screens/unknown_code_sheet.dart
        widgets/manual_code_search.dart
    reports/
      domain/
        entities/inventory_summary.dart
        repositories/inventory_export_repository.dart
        usecases/build_inventory_csv.dart
        usecases/inventory_reporting.dart
      data/
        file_inventory_export_repository.dart
      presentation/
        providers/reports_providers.dart
        screens/dashboard_screen.dart
        screens/history_screen.dart
    settings/
      domain/
        entities/local_profile.dart
        repositories/profile_repository.dart
        usecases/profile_usecases.dart
      data/
        drift_profile_repository.dart
      presentation/
        providers/settings_providers.dart
        screens/settings_screen.dart
test/
  domain/                       Pruebas puras de reglas y validaciones
  data/                         Pruebas de integracion sobre SQLite en memoria
docs/                           Documentacion tecnica
tool/                           Utilidad de captura de pantallas
```

## Convenciones

- Un archivo por clase publica, con nombre en `snake_case`.
- Los sufijos indican la capa: `_screen.dart`, `_providers.dart`,
  `_repository.dart`, `_usecase.dart`.
- Las entidades y los casos de uso no llevan sufijo adicional.
- Los nombres de archivo y de clase se escriben sin tildes, para evitar
  problemas entre sistemas de archivos.
