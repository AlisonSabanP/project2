# Generacion y lectura de codigos

## Que se genera

Cada producto tiene una etiqueta con dos simbolos que codifican el mismo valor:
el **codigo unico** del producto.

| Simbolo | Formato | Contenido |
| --- | --- | --- |
| Codigo de barras | Code 128 | El codigo del producto, por ejemplo `AB-001` |
| Codigo QR | QR, correccion de errores media | El codigo del producto, sin ningun otro dato |

No se codifican cantidades, existencias ni precios. Esos valores cambian con
cada movimiento y dejarian la etiqueta obsoleta.

## Implementacion

- La etiqueta se dibuja con `ProductLabel`
  (`lib/features/products/presentation/widgets/product_label.dart`) usando el
  paquete `barcode_widget`.
- `BarcodeWidget(barcode: Barcode.code128(), data: code)` genera el codigo de
  barras.
- `BarcodeWidget(barcode: Barcode.qrCode(), data: code)` genera el QR.
- La pantalla de detalle muestra la etiqueta completa, con nombre, codigo,
  precio y ambos simbolos, ademas de cada simbolo por separado.

## Exportacion para impresion

La etiqueta se captura como imagen PNG:

1. La etiqueta se envuelve en un `RepaintBoundary` con una `GlobalKey`.
2. `captureLabelBytes` convierte ese subarbol en `ui.Image` y luego en bytes PNG
   con un factor de escala de 3, suficiente para imprimir.
3. `ShareLabelRepository.saveLabel` escribe el archivo en
   `<documentos>/etiquetas/` y `shareLabel` abre la hoja de compartir del
   sistema, desde donde se puede enviar a una impresora, a mensajeria o a la
   nube.

El nombre del archivo incluye el codigo del producto y una marca de tiempo, de
modo que exportar dos veces no sobrescribe la imagen anterior.

## Lectura con camara

La lectura usa `mobile_scanner`
(`lib/features/scanner/presentation/screens/scanner_screen.dart`).

- El controlador se limita a los formatos `code128` y `qrCode`.
- `DetectionSpeed.noDuplicates` evita que un mismo codigo se procese en rafaga.
- Al detectar un codigo se detiene la camara, se resuelve el codigo y se
  reanuda cuando el usuario cierra el panel del producto.
- La resolucion se delega a `ResolveScannedCodeUseCase`, que normaliza el valor
  (recorte de espacios y mayusculas) y busca el producto por codigo.

## Resultados de la lectura

| Situacion | Comportamiento |
| --- | --- |
| El codigo existe | Se muestra un panel con nombre, codigo, existencias y stock minimo, y tres botones: Entrada, Salida y Ajuste. Al elegir uno se abre el formulario de movimiento con el tipo preseleccionado. |
| El codigo no existe | Se muestra el panel "Codigo no registrado" con el valor leido y la indicacion de crear el producto desde la seccion Productos. |
| Sin permiso de camara | La pantalla explica que hay que habilitar el permiso de camara en los ajustes del sistema. |
| Camara no disponible | La pantalla indica que el dispositivo no admite lectura con camara y sugiere la busqueda manual. |
| Otro error de camara | Mensaje generico con la misma sugerencia de busqueda manual. |

## Busqueda manual

El boton de la barra superior alterna entre camara y busqueda manual. La
busqueda acepta codigo o nombre, no distingue mayusculas y muestra el stock de
cada coincidencia. Es la via de respaldo cuando la camara no esta disponible.

## Unicidad

El codigo se valida antes de guardar:

- `ProductValidator.normalizeCode` recorta espacios y pasa a mayusculas.
- `CreateProductUseCase` y `UpdateProductUseCase` comprueban `isCodeTaken`.
- La columna `products.code` tiene restriccion `UNIQUE` como segunda barrera.

Si el codigo ya existe, se informa con `DuplicateProductCodeException` y el
producto no se guarda.

## Formatos aceptados

El lector acepta Code 128 (el formato que la aplicacion genera) y QR. Al
generar se usa exactamente ese par de formatos, por lo que una etiqueta
impresa por la propia aplicacion siempre se puede volver a leer.
