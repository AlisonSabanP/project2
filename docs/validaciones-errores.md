# Validaciones y manejo de errores

## Validaciones de formularios

Cada campo de entrada valida antes de enviar y, ademas, el dominio vuelve a
validar. La interfaz nunca es la unica barrera.

### Formulario de producto

| Campo | Regla | Mensaje |
| --- | --- | --- |
| Codigo | Obligatorio, sin espacios | "El codigo es obligatorio", "El codigo no puede contener espacios" |
| Nombre | Obligatorio | "El nombre es obligatorio" |
| Precio de compra | Numero mayor que cero, hasta dos decimales | "Ingrese un precio", "Ingrese un numero valido", "Debe ser mayor que cero" |
| Precio de venta | Numero mayor que cero, no menor que el de compra | "Debe ser mayor que cero" |
| Stock minimo | Entero no negativo | "Ingrese un numero entero", "No puede ser negativo" |
| Stock inicial | Entero no negativo, solo al crear | "Ingrese un numero entero", "No puede ser negativo" |
| Fotografia | Opcional | - |

Los campos numericos usan `TextInputFormatter` para admitir solo digitos o
decimales con dos cifras, de modo que la mayoria de los errores no llegan a
producirse.

### Formulario de movimiento

| Campo | Regla | Mensaje |
| --- | --- | --- |
| Cantidad (entrada y salida) | Entero mayor que cero | "Ingrese un numero entero", "Debe ser mayor que cero" |
| Cantidad (salida) | No mayor al stock disponible | "Solo hay N unidades disponibles" |
| Cantidad contada (ajuste) | Entero no negativo | "No puede ser negativo" |
| Motivo (entrada y salida) | Obligatorio | "El motivo es obligatorio" |
| Justificacion (ajuste) | Obligatoria | "La justificacion es obligatoria" |

### Formulario de perfil

| Campo | Regla | Mensaje |
| --- | --- | --- |
| Nombre del responsable | Obligatorio, minimo 3 caracteres | "El nombre es obligatorio", "Use al menos 3 caracteres" |

## Errores de dominio

`lib/core/error/domain_exception.dart` define la jerarquia. Todas heredan de
`DomainException` y llevan un mensaje en espanol listo para mostrar.

| Excepcion | Cuando ocurre |
| --- | --- |
| `ValidationException` | Un campo incumple una regla de negocio. |
| `DuplicateProductCodeException` | El codigo ya pertenece a otro producto. |
| `ProductNotFoundException` | No hay producto para el codigo indicado. |
| `ProductByIdNotFoundException` | No hay producto para el identificador indicado. |
| `NonPositiveQuantityException` | La cantidad de entrada o salida es cero o negativa. |
| `InsufficientStockException` | La salida supera las existencias. Informa disponible y solicitado. |
| `MissingReasonException` | Falta el motivo del movimiento. |
| `MissingJustificationException` | El ajuste no lleva justificacion. |
| `ProductHasMovementsException` | Se intenta borrar un producto con historial. |
| `ImmutableMovementException` | Se intenta modificar un movimiento confirmado. |

La capa de presentacion traduce cualquier error con `describeFailure`, que
muestra el mensaje del dominio cuando existe y un mensaje generico en caso
contrario. El usuario recibe el aviso mediante un `SnackBar` o dentro del propio
panel, nunca mediante una pantalla de error cruda.

## Errores de camara y permisos

| Situacion | Codigo | Mensaje |
| --- | --- | --- |
| Permiso denegado | `permissionDenied` | "La aplicacion no tiene permiso para usar la camara. Habilite el permiso de camara en los ajustes del sistema." |
| Dispositivo sin soporte | `unsupported` | "Este dispositivo no admite la lectura con camara. Use la busqueda manual por codigo o nombre." |
| Otro fallo de inicio | cualquiera | "No fue posible iniciar la camara. Use la busqueda manual por codigo o nombre." |

El permiso de camara se declara en `AndroidManifest.xml`. La camara se marca
como no obligatoria, de modo que la aplicacion se instala en dispositivos sin
camara y ofrece la busqueda manual.

## Errores de almacenamiento y exportacion

- Si la captura de la etiqueta falla porque el arbol aun no esta listo, se
  informa que la etiqueta no se pudo preparar.
- Si la escritura del CSV o de la imagen falla, se muestra el motivo y no se
  cierra ninguna pantalla.
- La base de datos abre el archivo dentro del directorio de documentos de la
  aplicacion, que no requiere permisos adicionales en Android moderno.

## Estados de la interfaz

Todas las listas cubren los tres estados con `AsyncValueView`:

- **Carga**: indicador circular, con etiqueta opcional.
- **Error**: icono, mensaje y boton "Reintentar" cuando hay una accion de
  recarga.
- **Vacio**: mensaje propio de cada lista, por ejemplo "No hay productos que
  coincidan con la busqueda" o "Aun no hay movimientos para este producto".

Las operaciones que escriben muestran confirmacion: "Producto creado",
"Movimiento registrado. Stock resultante: N", "Perfil actualizado", "CSV
generado en <ruta>".
