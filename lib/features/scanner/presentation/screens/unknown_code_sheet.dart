import 'package:flutter/material.dart';

/// Clear message shown when a scanned code has no product behind it.
Future<void> showUnknownCodeSheet(BuildContext context, String code) {
  return showModalBottomSheet<void>(
    context: context,
    builder: (context) {
      final theme = Theme.of(context);
      return SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.search_off, size: 44, color: theme.colorScheme.error),
              const SizedBox(height: 12),
              Text(
                'Codigo no registrado',
                style: theme.textTheme.titleMedium
                    ?.copyWith(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 8),
              Text(
                'El codigo "$code" no corresponde a ningun producto del '
                'inventario. Verifique la etiqueta o cree el producto desde '
                'la seccion Productos.',
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium,
              ),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Entendido'),
              ),
            ],
          ),
        ),
      );
    },
  );
}
