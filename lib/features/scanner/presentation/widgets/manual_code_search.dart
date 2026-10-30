import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../products/domain/entities/product.dart';
import '../../../products/presentation/providers/product_providers.dart';

/// Search by code or name, used when the camera is unavailable or when the
/// label cannot be read.
class ManualCodeSearch extends ConsumerStatefulWidget {
  const ManualCodeSearch({super.key, required this.onProductSelected});

  final ValueChanged<Product> onProductSelected;

  @override
  ConsumerState<ManualCodeSearch> createState() => _ManualCodeSearchState();
}

class _ManualCodeSearchState extends ConsumerState<ManualCodeSearch> {
  late final TextEditingController _controller;
  late Future<List<Product>> _results;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController();
    _results = _search('');
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<List<Product>> _search(String term) {
    return ref.read(productQueriesProvider).search(term);
  }

  void _runSearch(String term) {
    setState(() => _results = _search(term));
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: TextField(
            controller: _controller,
            autofocus: true,
            textInputAction: TextInputAction.search,
            onSubmitted: _runSearch,
            onChanged: (value) {
              if (value.isEmpty) _runSearch('');
            },
            decoration: InputDecoration(
              hintText: 'Escriba el codigo o el nombre',
              prefixIcon: const Icon(Icons.search),
              border: const OutlineInputBorder(),
              suffixIcon: IconButton(
                icon: const Icon(Icons.arrow_forward),
                onPressed: () => _runSearch(_controller.text),
              ),
            ),
          ),
        ),
        Expanded(
          child: FutureBuilder<List<Product>>(
            future: _results,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              if (snapshot.hasError) {
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Text('No fue posible buscar: ${snapshot.error}'),
                  ),
                );
              }
              final products = snapshot.data ?? const <Product>[];
              if (products.isEmpty) {
                return const Center(
                  child: Padding(
                    padding: EdgeInsets.all(24),
                    child: Text(
                      'Sin resultados. Verifique el codigo o el nombre.',
                      textAlign: TextAlign.center,
                    ),
                  ),
                );
              }
              return ListView.separated(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                itemCount: products.length,
                separatorBuilder: (_, _) => const SizedBox(height: 8),
                itemBuilder: (context, index) {
                  final product = products[index];
                  return Card(
                    margin: EdgeInsets.zero,
                    child: ListTile(
                      onTap: () => widget.onProductSelected(product),
                      title: Text(product.name),
                      subtitle: Text(
                        '${product.code}  |  ${product.currentStock} unidades',
                      ),
                      trailing: const Icon(Icons.chevron_right),
                    ),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }
}
