# Arquitectura feature + domain

## Resumen

La aplicacion sigue una arquitectura por funcionalidades (feature first) con
separacion en capas dentro de cada funcionalidad. Cada feature es un modulo
cerrado que expone su dominio y esconde su acceso a datos y su interfaz.

```
lib/
  app/                        Composicion de la aplicacion y navegacion
  core/                       Codigo transversal reutilizable
  features/
    products/                 Catalogo de productos
    inventory/                Movimientos de inventario
    scanner/                  Lectura de codigos
    reports/                  Consultas, reportes y exportacion
    settings/                 Perfil local
```

## Capas

Cada feature contiene hasta tres capas:

| Capa | Contenido | Dependencias permitidas |
| --- | --- | --- |
| `domain` | Entidades, casos de uso, contratos de repositorio y servicios de reglas | Solo Dart y otras capas `domain` |
| `data` | Implementaciones de repositorio y acceso al almacenamiento | `domain` y `core` |
| `presentation` | Pantallas, widgets y providers de Riverpod | `domain`, `data` y `core` |

Regla de dependencia: `presentation -> data -> domain`. El dominio nunca importa
widgets, `drift`, `sqflite` ni `flutter`. Las reglas de negocio viven en
`domain/services` y son funciones puras, sin estado ni acceso a datos.

## Responsabilidades por capa

### Domain

- **Entidades**: objetos inmutables con identidad (`Product`, `Movement`,
  `Category`, `LocalProfile`).
- **Contratos de repositorio**: interfaces que describen la persistencia sin
  nombrar tecnologia (`ProductRepository`, `MovementRepository`,
  `CategoryRepository`, `ProfileRepository`, `InventoryExportRepository`,
  `LabelExportRepository`).
- **Servicios**: `InventoryRules` y `ProductValidator`, con todas las reglas
  verificables de forma aislada.
- **Casos de uso**: orquestan entidades y repositorios
  (`RegisterMovementUseCase`, `CreateProductUseCase`,
  `ComputeInventorySummaryUseCase`, `ResolveScannedCodeUseCase`, etc.).

### Data

- Implementaciones `Drift...Repository` que traducen entre filas de la base de
  datos y entidades de dominio mediante `core/database/mappers.dart`.
- Repositorios de infraestructura: escritura de CSV y de la etiqueta PNG.

### Presentation

- Providers de Riverpod que exponen casos de uso y estado de la interfaz.
- Pantallas y widgets. Ninguna pantalla contiene aritmetica de stock ni consultas
  SQL.

## Gestion de estado

Se usa **Riverpod 3** en todo el proyecto, sin mezclar enfoques.

- `Provider` para dependencias inyectables (base de datos, repositorios, casos
  de uso).
- `NotifierProvider` para estado de interfaz mutable (termino de busqueda,
  filtros, revision de stock).
- `FutureProvider` y `StreamProvider` para lecturas asincronicas y reactivas.

El grafo de providers arranca en `databaseProvider`
(`lib/core/providers/database_provider.dart`), que `main` sobrescribe con la
instancia ya sembrada.

## Flujo de una operacion de inventario

```
Widget (MovementFormScreen)
  -> provider registerMovementProvider
     -> RegisterMovementUseCase             (domain)
        -> InventoryRules.validateAndApply  (domain, puro)
        -> MovementRepository.register      (contrato)
           -> DriftMovementRepository       (data)
              -> transaccion SQLite: INSERT movimiento + UPDATE stock
```

## Persistencia

Se usa **Drift** sobre SQLite, con `drift_flutter` para resolver la ruta del
archivo en Android. La base de datos es local y no requiere conexion.

- El esquema vive en `lib/core/database/tables.dart`.
- `lib/core/database/app_database.dart` define las consultas y migraciones.
- La revision de esquema es la version `1`; los cambios futuros se anaden como
  migraciones en `migration`.

## Por que feature + domain

- Cada funcionalidad se puede leer, probar y modificar sin recorrer el resto.
- Las reglas criticas (stock, unicidad, inmutabilidad) son comprobables con
  pruebas unitarias sin arrancar Flutter ni la base de datos.
- Sustituir Drift por otra tecnologia solo requiere escribir nuevas
  implementaciones de los contratos de `domain`.
