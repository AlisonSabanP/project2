# Modelo de datos

Motor: SQLite mediante Drift. Cuatro tablas, todas locales. El esquema se define
en `lib/core/database/tables.dart` y el archivo generado es
`lib/core/database/app_database.g.dart`.

## Diagrama de relaciones

```
categories 1 ----- n products
products   1 ----- n movements
profiles   (registro unico, sin relaciones)
```

- `products.category_id` referencia `categories.id` (nullable: un producto puede
  quedar sin categoria).
- `movements.product_id` referencia `products.id` (obligatorio).
- `profiles` guarda una sola fila con el nombre del responsable por defecto.

## Tabla `categories`

| Campo | Tipo | Restricciones | Descripcion |
| --- | --- | --- | --- |
| `id` | INTEGER | PK, autoincremental | Identificador interno. |
| `name` | TEXT | NOT NULL, UNIQUE, 1..80 | Nombre de la categoria. |

## Tabla `products`

| Campo | Tipo | Restricciones | Descripcion |
| --- | --- | --- | --- |
| `id` | INTEGER | PK, autoincremental | Identificador interno. |
| `code` | TEXT | NOT NULL, UNIQUE, 1..40 | Codigo unico de negocio. Es el valor codificado en el codigo de barras y en el QR. |
| `name` | TEXT | NOT NULL, 1..120 | Nombre comercial. |
| `description` | TEXT | NULL | Descripcion libre. |
| `category_id` | INTEGER | NULL, FK -> `categories.id` | Categoria del producto. |
| `purchase_price` | REAL | NOT NULL | Precio de compra unitario. |
| `sale_price` | REAL | NOT NULL | Precio de venta unitario. |
| `current_stock` | INTEGER | NOT NULL, default 0 | Existencias actuales. Solo cambia a traves de movimientos. |
| `minimum_stock` | INTEGER | NOT NULL, default 0 | Umbral de alerta de stock bajo. |
| `photo_path` | TEXT | NULL | Ruta absoluta de la fotografia opcional. |
| `active` | BOOLEAN | NOT NULL, default 1 | Un producto inactivo se oculta del listado, pero conserva su historial. |
| `created_at` | DATETIME | NOT NULL, default ahora | Fecha de alta. |

## Tabla `movements`

| Campo | Tipo | Restricciones | Descripcion |
| --- | --- | --- | --- |
| `id` | INTEGER | PK, autoincremental | Identificador interno. |
| `product_id` | INTEGER | NOT NULL, FK -> `products.id` | Producto afectado. |
| `type` | TEXT | NOT NULL, 1..20 | `entrada`, `salida` o `ajuste`. |
| `quantity` | INTEGER | NOT NULL, CHECK >= 0 | Unidades sumadas, restadas o contadas. |
| `previous_stock` | INTEGER | NOT NULL | Existencias antes del movimiento. |
| `resulting_stock` | INTEGER | NOT NULL, CHECK >= 0 | Existencias despues del movimiento. |
| `reason` | TEXT | NOT NULL, 1..200 | Motivo. En los ajustes es la justificacion obligatoria. |
| `responsible` | TEXT | NOT NULL, 1..80 | Nombre tomado del perfil local. |
| `recorded_at` | DATETIME | NOT NULL | Fecha y hora del registro. |

La columna se llama `recorded_at` en SQL y `recordedAt` en Dart. El nombre
`dateTime` se evito porque dentro de una clase `Table` de Drift colisiona con el
constructor de columnas `dateTime()`.

Los movimientos son inmutables: el repositorio no expone actualizacion ni
borrado, y las restricciones `CHECK` impiden guardar cantidades negativas o
existencias resultantes negativas.

## Tabla `profiles`

| Campo | Tipo | Restricciones | Descripcion |
| --- | --- | --- | --- |
| `id` | INTEGER | PK, autoincremental | Identificador interno. |
| `responsible_name` | TEXT | NOT NULL, 1..80 | Nombre por defecto del responsable. |

## Reglas de integridad

1. `products.code` es unico. La unicidad se valida ademas en el dominio para dar
   un mensaje claro antes de tocar la base de datos.
2. `movements` solo se inserta. Corregir un error requiere un movimiento nuevo.
3. El stock nunca se escribe directamente desde un formulario: la existencia
   inicial de un producto se registra como un movimiento de entrada.
4. `current_stock` se actualiza en la misma transaccion que inserta el
   movimiento, de modo que ambos quedan siempre consistentes.
5. Un producto con movimientos no se elimina fisicamente; solo se desactiva.
   La eliminacion fisica se reserva para productos sin historial.

## Migraciones

La revision de esquema es `1`. Al anadir campos o tablas, se incrementa
`schemaVersion` y se implementa `onUpgrade` dentro de `MigrationStrategy`,
anadiendo las sentencias `m.addColumn(...)` o `m.createTable(...)` necesarias.
