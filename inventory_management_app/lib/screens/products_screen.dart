import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/inventory_provider.dart';
import '../models/product.dart';

class ProductsScreen extends StatefulWidget {
  const ProductsScreen({super.key});

  @override
  State<ProductsScreen> createState() => _ProductsScreenState();
}

class _ProductsScreenState extends State<ProductsScreen> {
  final TextEditingController _searchCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      final provider = context.read<InventoryProvider>();
      provider.loadProducts();
      provider.loadBrands();
      provider.loadCategories();
    });
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<InventoryProvider>(
      builder: (context, provider, _) {
        final category = provider.selectedCategory;
        final title = category != null ? category.name : 'All Products';

        return Scaffold(
          appBar: AppBar(
            title: Text(title),
            backgroundColor: const Color(0xFF1A237E),
            foregroundColor: Colors.white,
            actions: [
              IconButton(
                icon: const Icon(Icons.qr_code_scanner),
                onPressed: () => Navigator.pushNamed(context, '/scanner'),
              ),
            ],
          ),
          body: Column(
            children: [
              // Search bar
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                child: TextField(
                  controller: _searchCtrl,
                  decoration: InputDecoration(
                    hintText: 'Search products by name, brand, barcode...',
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: _searchCtrl.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear),
                            onPressed: () {
                              _searchCtrl.clear();
                              provider.setSearchQuery('');
                            },
                          )
                        : null,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    filled: true,
                    fillColor: Colors.grey[100],
                  ),
                  onChanged: (value) {
                    provider.setSearchQuery(value);
                    setState(() {});
                  },
                ),
              ),

              // Filter chips
              if (provider.brands.isNotEmpty || provider.categories.length > 1)
                SizedBox(
                  height: 48,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    children: [
                      // Category filter chips
                      if (provider.selectedCategory != null)
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 4),
                          child: FilterChip(
                            label: Text(provider.selectedCategory!.name),
                            selected: true,
                            onSelected: (_) => provider.setSelectedCategory(null),
                            selectedColor: const Color(0xFF1A237E).withValues(alpha: 0.2),
                          ),
                        ),
                      // Brand filter chips
                      ...provider.brands.map((brand) => Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 4),
                            child: FilterChip(
                              label: Text(brand),
                              selected: provider.selectedBrand == brand,
                              onSelected: (selected) {
                                provider.setSelectedBrand(selected ? brand : null);
                              },
                              selectedColor: Colors.blue.withValues(alpha: 0.2),
                            ),
                          )),
                      if (provider.selectedBrand != null || provider.selectedCategory != null)
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 4),
                          child: ActionChip(
                            label: const Text('Clear All'),
                            avatar: const Icon(Icons.clear, size: 16),
                            onPressed: () {
                              _searchCtrl.clear();
                              provider.clearFilters();
                              setState(() {});
                            },
                          ),
                        ),
                    ],
                  ),
                ),

              const Divider(height: 1),

              // Product list
              Expanded(
                child: provider.products.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.inventory_2_outlined, size: 60, color: Colors.grey[400]),
                            const SizedBox(height: 12),
                            Text('No products found', style: TextStyle(color: Colors.grey[600])),
                          ],
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        itemCount: provider.products.length,
                        itemBuilder: (context, index) {
                          return _ProductTile(product: provider.products[index]);
                        },
                      ),
              ),
            ],
          ),
          floatingActionButton: FloatingActionButton(
            backgroundColor: const Color(0xFF1A237E),
            foregroundColor: Colors.white,
            onPressed: () => _showAddProductDialog(context, provider),
            child: const Icon(Icons.add),
          ),
        );
      },
    );
  }

  void _showAddProductDialog(BuildContext context, InventoryProvider provider) {
    final nameCtrl = TextEditingController();
    final brandCtrl = TextEditingController();
    final barcodeCtrl = TextEditingController();
    final qtyCtrl = TextEditingController(text: '0');
    final priceCtrl = TextEditingController(text: '0.0');
    final threshCtrl = TextEditingController(text: '10');
    int? selectedCategoryId = provider.selectedCategory?.id;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: const Text('Add Product'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: 'Product Name', border: OutlineInputBorder())),
                const SizedBox(height: 10),
                TextField(controller: brandCtrl, decoration: const InputDecoration(labelText: 'Brand', border: OutlineInputBorder())),
                const SizedBox(height: 10),
                TextField(controller: barcodeCtrl, decoration: const InputDecoration(labelText: 'Barcode (optional)', border: OutlineInputBorder())),
                const SizedBox(height: 10),
                DropdownButtonFormField<int>(
                  value: selectedCategoryId,
                  decoration: const InputDecoration(labelText: 'Category', border: OutlineInputBorder()),
                  items: provider.categories.map((c) => DropdownMenuItem(value: c.id, child: Text(c.name))).toList(),
                  onChanged: (v) => setDialogState(() => selectedCategoryId = v),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(child: TextField(controller: qtyCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Quantity', border: OutlineInputBorder()))),
                    const SizedBox(width: 10),
                    Expanded(child: TextField(controller: priceCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Price', border: OutlineInputBorder()))),
                  ],
                ),
                const SizedBox(height: 10),
                TextField(controller: threshCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Restock Threshold', border: OutlineInputBorder())),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
            FilledButton(
              onPressed: () {
                if (nameCtrl.text.trim().isEmpty || brandCtrl.text.trim().isEmpty || selectedCategoryId == null) return;
                final product = Product(
                  storeId: provider.selectedStore!.id!,
                  categoryId: selectedCategoryId!,
                  name: nameCtrl.text.trim(),
                  brand: brandCtrl.text.trim(),
                  barcode: barcodeCtrl.text.trim().isEmpty ? null : barcodeCtrl.text.trim(),
                  quantity: int.tryParse(qtyCtrl.text) ?? 0,
                  restockThreshold: int.tryParse(threshCtrl.text) ?? 10,
                  price: double.tryParse(priceCtrl.text) ?? 0.0,
                );
                provider.addProduct(product);
                Navigator.pop(ctx);
              },
              child: const Text('Add'),
            ),
          ],
        ),
      ),
    );
  }
}

class _ProductTile extends StatelessWidget {
  final Product product;
  const _ProductTile({required this.product});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: CircleAvatar(
          backgroundColor: product.needsRestock ? Colors.orange.withValues(alpha: 0.2) : const Color(0xFF1A237E).withValues(alpha: 0.1),
          child: Icon(
            product.needsRestock ? Icons.warning_amber_rounded : Icons.inventory_2,
            color: product.needsRestock ? Colors.orange : const Color(0xFF1A237E),
          ),
        ),
        title: Row(
          children: [
            Expanded(child: Text(product.name, style: const TextStyle(fontWeight: FontWeight.w600))),
            if (product.verified) const Icon(Icons.verified, color: Colors.green, size: 18),
          ],
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('${product.brand}  •  GH₵ ${product.price.toStringAsFixed(2)}', style: TextStyle(color: Colors.grey[600], fontSize: 13)),
            const SizedBox(height: 4),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: product.needsRestock ? Colors.orange.withValues(alpha: 0.15) : Colors.green.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    'Qty: ${product.quantity}',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: product.needsRestock ? Colors.orange[800] : Colors.green[800],
                    ),
                  ),
                ),
                if (product.barcode != null) ...[
                  const SizedBox(width: 8),
                  Icon(Icons.qr_code, size: 14, color: Colors.grey[500]),
                ],
              ],
            ),
          ],
        ),
        trailing: IconButton(
          icon: const Icon(Icons.edit_outlined),
          onPressed: () => _showUpdateQuantityDialog(context, product),
        ),
        onTap: () => _showProductDetails(context, product),
      ),
    );
  }

  void _showUpdateQuantityDialog(BuildContext context, Product product) {
    final qtyCtrl = TextEditingController(text: product.quantity.toString());

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Update ${product.name}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Current quantity: ${product.quantity}', style: TextStyle(color: Colors.grey[600])),
            const SizedBox(height: 16),
            TextField(
              controller: qtyCtrl,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'New Quantity', border: OutlineInputBorder()),
              autofocus: true,
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          FilledButton(
            onPressed: () {
              final qty = int.tryParse(qtyCtrl.text);
              if (qty != null && qty >= 0) {
                context.read<InventoryProvider>().updateProductQuantity(product, qty);
                Navigator.pop(ctx);
              }
            },
            child: const Text('Update'),
          ),
        ],
      ),
    );
  }

  void _showProductDetails(BuildContext context, Product product) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40, height: 4,
                decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(2)),
              ),
            ),
            const SizedBox(height: 20),
            Text(product.name, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            _DetailRow('Brand', product.brand),
            _DetailRow('Barcode', product.barcode ?? 'N/A'),
            _DetailRow('Price', 'GH₵ ${product.price.toStringAsFixed(2)}'),
            _DetailRow('Quantity', '${product.quantity}'),
            _DetailRow('Restock At', '${product.restockThreshold}'),
            _DetailRow('Verified', product.verified ? 'Yes ✓' : 'No ✗'),
            _DetailRow('Last Updated', product.lastUpdated.toString().substring(0, 16)),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    icon: const Icon(Icons.delete_outline, color: Colors.red),
                    label: const Text('Delete', style: TextStyle(color: Colors.red)),
                    onPressed: () {
                      Navigator.pop(ctx);
                      context.read<InventoryProvider>().removeProduct(product.id!);
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton.icon(
                    icon: const Icon(Icons.verified_outlined),
                    label: Text(product.verified ? 'Unverify' : 'Verify'),
                    onPressed: () {
                      Navigator.pop(ctx);
                      context.read<InventoryProvider>().verifyProduct(product, !product.verified);
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final String label;
  final String value;
  const _DetailRow(this.label, this.value);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(color: Colors.grey[600])),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }
}
