import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
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
    final theme = Theme.of(context);
    return Consumer<InventoryProvider>(
      builder: (context, provider, _) {
        final category = provider.selectedCategory;
        final title = category != null ? category.name : 'All Products';

        return Scaffold(
          backgroundColor: theme.colorScheme.surface,
          appBar: AppBar(
            title: Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
            actions: [
              IconButton(
                icon: const Icon(Icons.qr_code_scanner_rounded),
                onPressed: () => Navigator.pushNamed(context, '/scanner'),
              ),
            ],
          ),
          body: Column(
            children: [
              // Search bar
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                child: TextField(
                  controller: _searchCtrl,
                  decoration: InputDecoration(
                    hintText: 'Search by name, brand, or barcode...',
                    prefixIcon: const Icon(Icons.search_rounded),
                    suffixIcon: _searchCtrl.text.isNotEmpty
                        ? IconButton(icon: const Icon(Icons.clear_rounded), onPressed: () { _searchCtrl.clear(); provider.setSearchQuery(''); setState(() {}); })
                        : null,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                    filled: true,
                    fillColor: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  ),
                  onChanged: (v) { provider.setSearchQuery(v); setState(() {}); },
                ),
              ),

              // Brand filter chips
              if (provider.brands.isNotEmpty)
                SizedBox(
                  height: 44,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    children: [
                      ...provider.brands.map((brand) => Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: FilterChip(
                          label: Text(brand, style: const TextStyle(fontSize: 13)),
                          selected: provider.selectedBrand == brand,
                          onSelected: (selected) => provider.setSelectedBrand(selected ? brand : null),
                        ),
                      )),
                      if (provider.selectedBrand != null || provider.selectedCategory != null)
                        ActionChip(
                          label: const Text('Clear All', style: TextStyle(fontSize: 13)),
                          avatar: const Icon(Icons.clear_rounded, size: 16),
                          onPressed: () { _searchCtrl.clear(); provider.clearFilters(); setState(() {}); },
                        ),
                    ],
                  ),
                ),

              const SizedBox(height: 4),

              // Product list
              Expanded(
                child: provider.products.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(20),
                              decoration: BoxDecoration(color: theme.colorScheme.primaryContainer.withValues(alpha: 0.3), shape: BoxShape.circle),
                              child: Icon(Icons.inventory_2_outlined, size: 48, color: theme.colorScheme.primary),
                            ),
                            const SizedBox(height: 16),
                            Text('No products found', style: theme.textTheme.titleMedium),
                          ],
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 12),
                        itemCount: provider.products.length,
                        itemBuilder: (context, index) => _ProductTile(product: provider.products[index]),
                      ),
              ),
            ],
          ),
          floatingActionButton: FloatingActionButton(
            onPressed: () => _showAddProductDialog(context, provider),
            child: const Icon(Icons.add_rounded),
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
    final supplierCtrl = TextEditingController();
    final intervalCtrl = TextEditingController(text: '7');
    int? selectedCategoryId = provider.selectedCategory?.id;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => Padding(
          padding: EdgeInsets.fromLTRB(24, 24, 24, MediaQuery.of(ctx).viewInsets.bottom + 24),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(2)))),
                const SizedBox(height: 20),
                Text('Add Product', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700)),
                const SizedBox(height: 20),
                TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: 'Product Name', border: OutlineInputBorder()), textCapitalization: TextCapitalization.words),
                const SizedBox(height: 12),
                TextField(controller: brandCtrl, decoration: const InputDecoration(labelText: 'Brand', border: OutlineInputBorder()), textCapitalization: TextCapitalization.words),
                const SizedBox(height: 12),
                TextField(controller: supplierCtrl, decoration: const InputDecoration(labelText: 'Supplier (optional)', border: OutlineInputBorder()), textCapitalization: TextCapitalization.words),
                const SizedBox(height: 12),
                TextField(controller: barcodeCtrl, decoration: const InputDecoration(labelText: 'Barcode (optional)', border: OutlineInputBorder())),
                const SizedBox(height: 12),
                DropdownButtonFormField<int>(
                  value: selectedCategoryId,
                  decoration: const InputDecoration(labelText: 'Category', border: OutlineInputBorder()),
                  items: provider.categories.map((c) => DropdownMenuItem<int>(value: c.id, child: Text(c.name))).toList(),
                  onChanged: (v) => setDialogState(() => selectedCategoryId = v),
                ),
                const SizedBox(height: 12),
                Row(children: [
                  Expanded(child: TextField(controller: qtyCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Quantity', border: OutlineInputBorder()))),
                  const SizedBox(width: 10),
                  Expanded(child: TextField(controller: priceCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Price (GH₵)', border: OutlineInputBorder()))),
                ]),
                const SizedBox(height: 12),
                Row(children: [
                  Expanded(child: TextField(controller: threshCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Restock Threshold', border: OutlineInputBorder()))),
                  const SizedBox(width: 10),
                  Expanded(child: TextField(controller: intervalCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Reorder Interval (days)', border: OutlineInputBorder()))),
                ]),
                const SizedBox(height: 24),
                FilledButton.icon(
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
                      supplier: supplierCtrl.text.trim().isEmpty ? null : supplierCtrl.text.trim(),
                      reorderIntervalDays: int.tryParse(intervalCtrl.text) ?? 7,
                    );
                    provider.addProduct(product);
                    Navigator.pop(ctx);
                  },
                  icon: const Icon(Icons.check_rounded),
                  label: const Text('Add Product'),
                  style: FilledButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16)),
                ),
              ],
            ),
          ),
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
    final theme = Theme.of(context);
    final status = product.stockStatus;
    final statusColor = status == 'OK' ? Colors.green : status == 'Reorder Soon' ? Colors.amber[800]! : Colors.red;

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => _showProductDetails(context, product),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          child: Row(
            children: [
              // Status indicator
              Container(
                width: 46, height: 46,
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  status == 'OK' ? Icons.check_circle_outlined : status == 'Reorder Soon' ? Icons.schedule_rounded : Icons.warning_amber_rounded,
                  color: statusColor,
                  size: 22,
                ),
              ),
              const SizedBox(width: 14),
              // Product info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(child: Text(product.name, style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600))),
                        if (product.verified) Icon(Icons.verified_rounded, color: Colors.green[600], size: 16),
                      ],
                    ),
                    const SizedBox(height: 3),
                    Text('${product.brand}  •  GH₵ ${product.price.toStringAsFixed(2)}', style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        _StatusBadge(label: 'Qty: ${product.quantity}', color: statusColor),
                        const SizedBox(width: 6),
                        _StatusBadge(label: status, color: statusColor),
                        if (product.barcode != null) ...[
                          const SizedBox(width: 6),
                          Icon(Icons.qr_code_rounded, size: 14, color: theme.colorScheme.onSurfaceVariant),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
              // Edit button
              IconButton(
                icon: Icon(Icons.edit_outlined, size: 20, color: theme.colorScheme.onSurfaceVariant),
                onPressed: () => _showUpdateQuantityDialog(context, product),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showUpdateQuantityDialog(BuildContext context, Product product) {
    HapticFeedback.lightImpact();
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
            TextField(controller: qtyCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'New Quantity', border: OutlineInputBorder()), autofocus: true),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          FilledButton(onPressed: () {
            final qty = int.tryParse(qtyCtrl.text);
            if (qty != null && qty >= 0) {
              context.read<InventoryProvider>().updateProductQuantity(product, qty);
              Navigator.pop(ctx);
            }
          }, child: const Text('Update')),
        ],
      ),
    );
  }

  void _showProductDetails(BuildContext context, Product product) {
    HapticFeedback.lightImpact();
    final theme = Theme.of(context);
    final dateFormat = DateFormat.yMMMd();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(2)))),
            const SizedBox(height: 20),
            Text(product.name, style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w700)),
            const SizedBox(height: 16),
            _DetailRow('Brand', product.brand),
            _DetailRow('Supplier', product.supplier ?? 'Not set'),
            _DetailRow('Barcode', product.barcode ?? 'N/A'),
            _DetailRow('Price', 'GH₵ ${product.price.toStringAsFixed(2)}'),
            _DetailRow('Quantity', '${product.quantity}'),
            _DetailRow('Restock Threshold', '${product.restockThreshold}'),
            _DetailRow('Reorder Interval', '${product.reorderIntervalDays} days'),
            _DetailRow('Last Delivery', product.lastDeliveryDate != null ? dateFormat.format(product.lastDeliveryDate!) : 'N/A'),
            _DetailRow('Status', product.stockStatus),
            _DetailRow('Verified', product.verified ? 'Yes ✓' : 'No'),
            _DetailRow('Last Updated', dateFormat.format(product.lastUpdated)),
            const SizedBox(height: 20),
            // Manual low stock flag buttons
            Row(
              children: [
                Expanded(
                  child: product.lowStockFlagged
                      ? OutlinedButton.icon(
                          onPressed: () {
                            context.read<InventoryProvider>().unflagLowStock(product);
                            Navigator.pop(ctx);
                          },
                          icon: const Icon(Icons.flag_outlined),
                          label: const Text('Remove Low Stock Flag'),
                        )
                      : FilledButton.icon(
                          onPressed: () {
                            context.read<InventoryProvider>().flagLowStock(product);
                            Navigator.pop(ctx);
                          },
                          icon: const Icon(Icons.flag_rounded),
                          label: const Text('Mark as Low Stock'),
                          style: FilledButton.styleFrom(backgroundColor: Colors.orange),
                        ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {
                      context.read<InventoryProvider>().removeProduct(product.id!);
                      Navigator.pop(ctx);
                    },
                    icon: const Icon(Icons.delete_outline, color: Colors.red),
                    label: const Text('Delete', style: TextStyle(color: Colors.red)),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final String label;
  final Color color;
  const _StatusBadge({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(label, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: color)),
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
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(width: 130, child: Text(label, style: TextStyle(color: Colors.grey[600], fontSize: 13))),
          Expanded(child: Text(value, style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 13))),
        ],
      ),
    );
  }
}
