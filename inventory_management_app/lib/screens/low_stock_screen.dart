import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/inventory_provider.dart';
import '../models/product.dart';

class LowStockScreen extends StatefulWidget {
  const LowStockScreen({super.key});

  @override
  State<LowStockScreen> createState() => _LowStockScreenState();
}

class _LowStockScreenState extends State<LowStockScreen> {
  List<Product> _lowStockProducts = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final products = await context.read<InventoryProvider>().getLowStockProducts();
    if (mounted) {
      setState(() {
        _lowStockProducts = products;
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Low Stock Alerts'),
        backgroundColor: Colors.orange[800],
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_active),
            tooltip: 'Send All Restock Notifications',
            onPressed: () async {
              await context.read<InventoryProvider>().checkAndNotifyLowStock();
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Restock notifications sent!')),
                );
              }
            },
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _lowStockProducts.isEmpty
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.check_circle_outline, size: 80, color: Colors.green[400]),
                      const SizedBox(height: 16),
                      const Text('All stocked up!', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),
                      Text('No items are below restock level', style: TextStyle(color: Colors.grey[600])),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _lowStockProducts.length,
                  itemBuilder: (context, index) {
                    final product = _lowStockProducts[index];
                    final percentage = (product.quantity / product.restockThreshold).clamp(0.0, 1.0);

                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(
                                  product.quantity == 0 ? Icons.error : Icons.warning_amber_rounded,
                                  color: product.quantity == 0 ? Colors.red : Colors.orange,
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(product.name, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                                ),
                                Text('${product.quantity}/${product.restockThreshold}',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: product.quantity == 0 ? Colors.red : Colors.orange[800],
                                    )),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text('${product.brand}', style: TextStyle(color: Colors.grey[600])),
                            const SizedBox(height: 10),
                            ClipRRect(
                              borderRadius: BorderRadius.circular(4),
                              child: LinearProgressIndicator(
                                value: percentage,
                                backgroundColor: Colors.grey[200],
                                color: product.quantity == 0 ? Colors.red : Colors.orange,
                                minHeight: 6,
                              ),
                            ),
                            const SizedBox(height: 10),
                            Align(
                              alignment: Alignment.centerRight,
                              child: TextButton.icon(
                                icon: const Icon(Icons.add_shopping_cart, size: 18),
                                label: const Text('Restock'),
                                onPressed: () => _showRestockDialog(product),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
    );
  }

  void _showRestockDialog(Product product) {
    final qtyCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Restock ${product.name}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Current: ${product.quantity} units'),
            Text('Restock threshold: ${product.restockThreshold} units'),
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
                context.read<InventoryProvider>().updateProductQuantity(product, product.quantity + addQty);
                Navigator.pop(ctx);
                _load(); // Refresh the list
              }
            },
            child: const Text('Add Stock'),
          ),
        ],
      ),
    );
  }
}
