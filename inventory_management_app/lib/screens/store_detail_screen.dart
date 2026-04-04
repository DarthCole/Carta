import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/inventory_provider.dart';
import '../models/category.dart';

class StoreDetailScreen extends StatefulWidget {
  const StoreDetailScreen({super.key});

  @override
  State<StoreDetailScreen> createState() => _StoreDetailScreenState();
}

class _StoreDetailScreenState extends State<StoreDetailScreen> {
  int _totalProducts = 0;
  int _lowStockCount = 0;

  @override
  void initState() {
    super.initState();
    Future.microtask(() async {
      final provider = context.read<InventoryProvider>();
      await provider.loadCategories();
      await provider.loadBrands();
      await provider.loadProducts();
      final total = await provider.getProductCount();
      final low = await provider.getLowStockCount();
      if (mounted) setState(() { _totalProducts = total; _lowStockCount = low; });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<InventoryProvider>(
      builder: (context, provider, _) {
        final store = provider.selectedStore;
        if (store == null) return const Scaffold(body: Center(child: Text('No store selected')));

        return Scaffold(
          appBar: AppBar(
            title: Text(store.name),
            backgroundColor: const Color(0xFF1A237E),
            foregroundColor: Colors.white,
            actions: [
              IconButton(
                icon: const Icon(Icons.warning_amber_rounded),
                tooltip: 'Low Stock Alerts',
                onPressed: () => Navigator.pushNamed(context, '/low-stock'),
              ),
              IconButton(
                icon: const Icon(Icons.qr_code_scanner_rounded),
                tooltip: 'Scan Barcode',
                onPressed: () => Navigator.pushNamed(context, '/scanner'),
              ),
            ],
          ),
          body: Column(
            children: [
              // Stats bar
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                decoration: const BoxDecoration(
                  color: Color(0xFF1A237E),
                  borderRadius: BorderRadius.only(
                    bottomLeft: Radius.circular(24),
                    bottomRight: Radius.circular(24),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _StatChip(label: 'Products', value: '$_totalProducts', icon: Icons.inventory_2),
                    _StatChip(label: 'Categories', value: '${provider.categories.length}', icon: Icons.category),
                    _StatChip(
                      label: 'Low Stock',
                      value: '$_lowStockCount',
                      icon: Icons.trending_down,
                      color: _lowStockCount > 0 ? Colors.orange : Colors.green,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Categories header
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Categories', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                    TextButton.icon(
                      icon: const Icon(Icons.add, size: 18),
                      label: const Text('Add'),
                      onPressed: () => _showAddCategoryDialog(context),
                    ),
                  ],
                ),
              ),

              // Categories grid
              Expanded(
                child: provider.categories.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.category_outlined, size: 60, color: Colors.grey[400]),
                            const SizedBox(height: 12),
                            Text('No categories yet', style: TextStyle(color: Colors.grey[600])),
                          ],
                        ),
                      )
                    : GridView.builder(
                        padding: const EdgeInsets.all(16),
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          crossAxisSpacing: 12,
                          mainAxisSpacing: 12,
                          childAspectRatio: 1.3,
                        ),
                        itemCount: provider.categories.length,
                        itemBuilder: (context, index) {
                          return _CategoryCard(category: provider.categories[index]);
                        },
                      ),
              ),
            ],
          ),
          floatingActionButton: FloatingActionButton.extended(
            backgroundColor: const Color(0xFF1A237E),
            foregroundColor: Colors.white,
            onPressed: () {
              provider.clearFilters();
              Navigator.pushNamed(context, '/products');
            },
            icon: const Icon(Icons.list_alt),
            label: const Text('All Products'),
          ),
        );
      },
    );
  }

  void _showAddCategoryDialog(BuildContext context) {
    final nameCtrl = TextEditingController();
    final descCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Add Category'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: 'Category Name', border: OutlineInputBorder())),
            const SizedBox(height: 12),
            TextField(controller: descCtrl, decoration: const InputDecoration(labelText: 'Description (optional)', border: OutlineInputBorder())),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          FilledButton(
            onPressed: () async {
              if (nameCtrl.text.trim().isNotEmpty) {
                await context.read<InventoryProvider>().addCategory(
                  nameCtrl.text.trim(),
                  descCtrl.text.trim().isEmpty ? null : descCtrl.text.trim(),
                );
                if (ctx.mounted) Navigator.pop(ctx);
              }
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }
}

class _StatChip extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color? color;

  const _StatChip({required this.label, required this.value, required this.icon, this.color});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, color: color ?? Colors.white70, size: 22),
        const SizedBox(height: 4),
        Text(value, style: TextStyle(color: color ?? Colors.white, fontSize: 22, fontWeight: FontWeight.bold)),
        Text(label, style: const TextStyle(color: Colors.white60, fontSize: 12)),
      ],
    );
  }
}

class _CategoryCard extends StatelessWidget {
  final Category category;
  const _CategoryCard({required this.category});

  static const _icons = {
    'Beverages': Icons.local_drink,
    'Snacks': Icons.cookie,
    'Personal Care': Icons.spa,
    'Stationery': Icons.edit_note,
    'Electronics': Icons.devices,
    'Groceries': Icons.shopping_basket,
    'Clothing': Icons.checkroom,
  };

  @override
  Widget build(BuildContext context) {
    final icon = _icons[category.name] ?? Icons.category;

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () {
          context.read<InventoryProvider>().setSelectedCategory(category);
          Navigator.pushNamed(context, '/products');
        },
        onLongPress: () {
          showModalBottomSheet(
            context: context,
            builder: (ctx) => SafeArea(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ListTile(
                    leading: const Icon(Icons.delete_outline, color: Colors.red),
                    title: const Text('Delete Category'),
                    onTap: () {
                      Navigator.pop(ctx);
                      context.read<InventoryProvider>().removeCategory(category.id!);
                    },
                  ),
                ],
              ),
            ),
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 36, color: const Color(0xFF1A237E)),
              const SizedBox(height: 12),
              Text(
                category.name,
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              if (category.description != null) ...[
                const SizedBox(height: 4),
                Text(
                  category.description!,
                  style: TextStyle(fontSize: 11, color: Colors.grey[600]),
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
