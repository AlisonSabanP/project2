# Casos de uso

Los casos de uso viven en `features/<feature>/domain/usecases/`. Reciben
repositorios por constructor, aplican reglas de dominio y no conocen Flutter.

## Productos

### `CreateProductUseCase`

Crea un producto y convierte el stock inicial en un movimiento de entrada.

- Entrada: `ProductDraft`, `initialStock`, `responsible`.
- Validaciones: `ProductValidator.validate` (codigo, nombre, precios, stock
  minimo, stock inicial no negativo) y unicidad del codigo
  (`isCodeTaken`).
- Salida: el `Product` persistido, con `currentStock = initialStock`.
- Errores: `ValidationException`, `DuplicateProductCodeException`.
- Efecto atomico: inserta el producto, el movimiento de entrada y actualiza el
  stock en una sola transaccion.

### `UpdateProductUseCase`

Actualiza los campos descriptivos. No modifica `currentStock`.

- Entrada: `id`, `ProductDraft`.
- Validaciones: las mismas que la creacion, mas unicidad del codigo excluyendo
  el propio producto.
- Errores: `ValidationException`, `DuplicateProductCodeException`,
  `ProductByIdNotFoundException`.

### `SetProductActiveUseCase`

Activa o desactiva un producto. Es la via de retirada normal cuando el producto
ya tiene movimientos.

### `DeleteProductUseCase`

Elimina fisicamente un producto solo si no tiene movimientos.

- Errores: `ProductHasMovementsException`.

### `ProductQueries`

Lecturas compartidas: listar, buscar por texto, buscar por id, buscar por codigo,
listar con stock bajo y contar. `byCode` devuelve `null` cuando el codigo no
existe, para que el escaner muestre el estado "codigo no registrado".

## Inventario

### `RegisterMovementUseCase`

Registra un movimiento y actualiza el stock en una sola operacion.

- Entrada: `productId`, `type`, `quantity`, `reason`, `responsible`.
- Flujo:
  1. Carga el producto (`ProductByIdNotFoundException` si no existe).
  2. `InventoryRules.validateAndApply` calcula el stock resultante y valida.
  3. Construye el `Movement` con stock anterior y resultante.
  4. `MovementRepository.register` inserta el movimiento y actualiza
     `products.current_stock` dentro de una transaccion.
- Errores: `NonPositiveQuantityException`, `InsufficientStockException`,
  `MissingReasonException`, `MissingJustificationException`,
  `ProductByIdNotFoundException`.
- Reloj inyectable: permite fijar la fecha en pruebas.

### `MovementQueries`

Lecturas del libro de movimientos: `watchAll` con filtro, `watchByProduct`,
`all`, `detailed` (movimiento con nombre y codigo del producto) y
`countByProduct`.

## Escaner

### `ResolveScannedCodeUseCase`

Interpreta la carga leida por la camara.

- Entrada: el valor crudo del codigo de barras o del QR.
- Proceso: recorta espacios, pasa a mayusculas y busca por codigo.
- Salida: `ScanResolution` con `rawValue`, `code` y `product` (null si no existe).
- Nota: el QR contiene unicamente el codigo, por lo que no hay que interpretar
  cantidades.

## Reportes

### `ComputeInventorySummaryUseCase`

Calcula los indicadores del inicio: numero de productos, productos activos,
unidades totales, valor de compra, valor de venta y productos en alerta.

- El valor del inventario es existencias por precio de compra, una estimacion
  simple sin metodo contable.

### `GetStockAlertsUseCase`

Lista los productos con existencias iguales o inferiores al minimo, ordenados de
menor a mayor stock, e indica cuantas unidades faltan para alcanzar el minimo.

### `BuildInventoryCsvUseCase`

Genera el CSV del inventario, con encabezado estable, BOM UTF-8 y comillas
cuando el valor lo requiere.

### `CategoryLookup`

Resuelve nombres de categoria por identificador, para mostrarlos en listas e
historiales.

## Perfil

### `LoadProfileUseCase`

Devuelve el perfil local. Si no existe, devuelve un perfil vacio.

### `SaveProfileUseCase`

Guarda el nombre del responsable.

- Validaciones: no vacio, maximo 80 caracteres.
