import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/inventory_provider.dart';
import '../models/product.dart';

class LowStockScreen extends StatefulWidget {
  const LowStockScreen({super.key});

  @override
  State<LowStockScreen> createState() => _LowStockScreenState();
}

class _LowStockScreenState extends State<LowStockScreen> {
  List<Product> _lowStockProducts = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    Future.microtask(() => _load());
  }

  Future<void> _load() async {
    setState(() => _isLoading = true);
    final products = await context.read<InventoryProvider>().getLowStockProducts();
    if (mounted) {
      setState(() {
        _lowStockProducts = products;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      appBar: AppBar(
        title: const Text('Low Stock Alerts', style: TextStyle(fontWeight: FontWeight.w700)),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_active_rounded),
            onPressed: () {
              HapticFeedback.heavyImpact();
              context.read<InventoryProvider>().checkAndNotifyLowStock();
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: const Text('Restock notifications sent for all low-stock items'),
                  behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
              );
            },
            tooltip: 'Notify All',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _lowStockProducts.isEmpty
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(color: Colors.green.withValues(alpha: 0.1), shape: BoxShape.circle),
                        child: const Icon(Icons.check_circle_outline_rounded, size: 56, color: Colors.green),
                      ),
                      const SizedBox(height: 20),
                      Text('All stocked up!', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600)),
                      const SizedBox(height: 8),
                      Text('No products need restocking right now.', style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _load,
                  child: ListView.builder(
                    padding: const EdgeInsets.fromLTRB(12, 8, 12, 100),
                    itemCount: _lowStockProducts.length,
                    itemBuilder: (context, index) {
                      final product = _lowStockProducts[index];
                      return _LowStockCard(product: product, onRestock: _load);
                    },
                  ),
                ),
    );
  }
}

class _LowStockCard extends StatelessWidget {
  final Product product;
  final VoidCallback onRestock;
  const _LowStockCard({required this.product, required this.onRestock});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final percentage = product.restockThreshold > 0
        ? (product.quantity / product.restockThreshold).clamp(0.0, 1.0)
        : 0.0;
    final isZero = product.quantity == 0;
    final stockColor = isZero ? Colors.red : Colors.orange;
    final dateFormat = DateFormat.yMMMd();
    final status = product.stockStatus;

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 44, height: 44,
                  decoration: BoxDecoration(
                    color: stockColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    isZero ? Icons.error_rounded : Icons.warning_amber_rounded,
                    color: stockColor,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(child: Text(product.name, style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600))),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: stockColor.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              status,
                              style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: stockColor),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 3),
                      Text(product.brand, style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
                      if (product.supplier != null)
                        Text('Supplier: ${product.supplier}', style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            // Stock progress bar
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('${product.quantity} / ${product.restockThreshold} units', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: stockColor)),
                          if (product.lastDeliveryDate != null)
                            Text('Last delivery: ${dateFormat.format(product.lastDeliveryDate!)}', style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant, fontSize: 11)),
                        ],
                      ),
                      const SizedBox(height: 6),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: percentage,
                          backgroundColor: Colors.grey[200],
                          color: stockColor,
                          minHeight: 6,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            if (product.lowStockFlagged) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.red.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.red.withValues(alpha: 0.2)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.flag_rounded, size: 14, color: Colors.red[700]),
                    const SizedBox(width: 4),
                    Text('Manually flagged as low stock', style: TextStyle(fontSize: 11, color: Colors.red[700], fontWeight: FontWeight.w500)),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                if (product.lowStockFlagged)
                  TextButton.icon(
                    onPressed: () {
                      HapticFeedback.lightImpact();
                      context.read<InventoryProvider>().unflagLowStock(product);
                      onRestock();
                    },
                    icon: const Icon(Icons.flag_outlined, size: 18),
                    label: const Text('Remove Flag'),
                  ),
                const SizedBox(width: 8),
                FilledButton.icon(
                  onPressed: () => _showRestockDialog(context, product),
                  icon: const Icon(Icons.add_shopping_cart_rounded, size: 18),
                  label: const Text('Restock'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showRestockDialog(BuildContext context, Product product) {
    HapticFeedback.lightImpact();
    final qtyCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('Restock ${product.name}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Current: ${product.quantity} units', style: TextStyle(color: Colors.grey[600])),
            Text('Threshold: ${product.restockThreshold} units', style: TextStyle(color: Colors.grey[600])),
            const SizedBox(height: 16),
            TextField(
              controller: qtyCtrl,
              keyboardType: TextInputType.number,
              autofocus: true,
              decoration: const InputDecoration(
                labelText: 'Units Delivered',
                border: OutlineInputBorder(),
                hintText: 'Enter delivered quantity',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          FilledButton(
            onPressed: () {
              final addQty = int.tryParse(qtyCtrl.text);
              if (addQty != null && addQty > 0) {
                HapticFeedback.mediumImpact();
                final updated = product.copyWith(
                  quantity: product.quantity + addQty,
                  lastDeliveryDate: DateTime.now(),
                  lowStockFlagged: false,
                );
                context.read<InventoryProvider>().updateProduct(updated);
                Navigator.pop(ctx);
                onRestock();
              }
            },
            child: const Text('Add Stock'),
          ),
        ],
      ),
    );
  }
}
