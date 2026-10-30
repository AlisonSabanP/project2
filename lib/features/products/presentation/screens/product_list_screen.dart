import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/formatting/formatters.dart';
import '../../../../core/widgets/stock_badge.dart';
import '../../../inventory/domain/entities/movement.dart';
import '../../../inventory/presentation/screens/movement_form_screen.dart';
import '../../domain/entities/product.dart';
import '../providers/product_providers.dart';
import 'product_detail_screen.dart';
import 'product_form_screen.dart';

/// Product listing with search, category filter and inactive toggle.
class ProductListScreen extends ConsumerStatefulWidget {
  const ProductListScreen({super.key});

  @override
  ConsumerState<ProductListScreen> createState() => _ProductListScreenState();
}

class _ProductListScreenState extends ConsumerState<ProductListScreen> {
  late final TextEditingController _searchController;

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController(
      text: ref.read(productSearchProvider),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final productsAsync = ref.watch(productListProvider);
    final categories = ref.watch(categoriesProvider);
    final selectedCategory = ref.watch(productCategoryFilterProvider);
    final showInactive = ref.watch(showInactiveProductsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Productos'),
        actions: [
          IconButton(
            tooltip: showInactive ? 'Ocultar inactivos' : 'Mostrar inactivos',
            onPressed: () =>
                ref.read(showInactiveProductsProvider.notifier).toggle(),
            icon: Icon(
              showInactive ? Icons.visibility : Icons.visibility_off_outlined,
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.of(context).push(
          MaterialPageRoute<void>(
            builder: (_) => const ProductFormScreen(),
          ),
        ),
        icon: const Icon(Icons.add),
        label: const Text('Nuevo'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: TextField(
              controller: _searchController,
              textInputAction: TextInputAction.search,
              onChanged: (value) =>
                  ref.read(productSearchProvider.notifier).update(value),
              decoration: InputDecoration(
                hintText: 'Buscar por codigo o nombre',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchController.text.isEmpty
                    ? null
                    : IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          ref.read(productSearchProvider.notifier).clear();
                          setState(() {});
                        },
                      ),
                border: const OutlineInputBorder(),
                isDense: true,
              ),
            ),
          ),
          SizedBox(
            height: 46,
            child: categories.maybeWhen(
              data: (items) => ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: FilterChip(
                      label: const Text('Todas'),
                      selected: selectedCategory == null,
                      onSelected: (_) => ref
                          .read(productCategoryFilterProvider.notifier)
                          .select(null),
                    ),
                  ),
                  for (final category in items)
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: FilterChip(
                        label: Text(category.name),
                        selected: selectedCategory == category.id,
                        onSelected: (_) => ref
                            .read(productCategoryFilterProvider.notifier)
                            .select(category.id),
                      ),
                    ),
                ],
              ),
              orElse: () => const SizedBox.shrink(),
            ),
          ),
          Expanded(
            child: productsAsync.when(
              skipLoadingOnRefresh: true,
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, _) => Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Text(describeFailure(error), textAlign: TextAlign.center),
                ),
              ),
              data: (products) {
                if (products.isEmpty) {
                  return const Center(
                    child: Padding(
                      padding: EdgeInsets.all(24),
                      child: Text(
                        'No hay productos que coincidan con la busqueda.',
                        textAlign: TextAlign.center,
                      ),
                    ),
                  );
                }
                return ListView.separated(
                  padding: const EdgeInsets.fromLTRB(12, 8, 12, 96),
                  itemCount: products.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (context, index) {
                    final product = products[index];
                    return _ProductTile(
                      product: product,
                      onTap: () => Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          builder: (_) => ProductDetailScreen(productId: product.id!),
                        ),
                      ),
                      onQuickMovement: () => Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          builder: (_) => MovementFormScreen(
                            productId: product.id!,
                            initialType: MovementType.entry,
                          ),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _ProductTile extends StatelessWidget {
  const _ProductTile({
    required this.product,
    required this.onTap,
    required this.onQuickMovement,
  });

  final Product product;
  final VoidCallback onTap;
  final VoidCallback onQuickMovement;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      margin: EdgeInsets.zero,
      clipBehavior: Clip.antiAlias,
      child: ListTile(
        onTap: onTap,
        leading: CircleAvatar(
          backgroundColor: theme.colorScheme.surfaceContainerHighest,
          child: Text(
            product.name.isEmpty ? '?' : product.name.substring(0, 1).toUpperCase(),
            style: theme.textTheme.titleMedium,
          ),
        ),
        title: Text(
          product.name,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            fontWeight: FontWeight.w600,
            decoration: product.active ? null : TextDecoration.lineThrough,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 2),
            Text('${product.code}  |  ${Formatters.money(product.salePrice)}'),
            if (!product.active)
              Text(
                'Inactivo',
                style: theme.textTheme.bodySmall
                    ?.copyWith(color: theme.colorScheme.error),
              ),
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            StockBadge(
              currentStock: product.currentStock,
              minimumStock: product.minimumStock,
            ),
            IconButton(
              tooltip: 'Registrar movimiento',
              onPressed: onQuickMovement,
              icon: const Icon(Icons.swap_vert),
            ),
          ],
        ),
      ),
    );
  }
}
