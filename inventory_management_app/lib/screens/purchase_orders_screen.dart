import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/inventory_provider.dart';
import '../models/purchase_order.dart';

class PurchaseOrdersScreen extends StatefulWidget {
  const PurchaseOrdersScreen({super.key});

  @override
  State<PurchaseOrdersScreen> createState() => _PurchaseOrdersScreenState();
}

class _PurchaseOrdersScreenState extends State<PurchaseOrdersScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(() => _loadOrders());
    Future.microtask(() => _loadOrders());
  }

  Future<void> _loadOrders() async {
    final provider = context.read<InventoryProvider>();
    bool? delivered;
    if (_tabController.index == 1) delivered = false;
    if (_tabController.index == 2) delivered = true;
    await provider.loadPurchaseOrders(delivered: delivered);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      appBar: AppBar(
        title: const Text('Purchase Orders', style: TextStyle(fontWeight: FontWeight.w700)),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'All'),
            Tab(text: 'Pending'),
            Tab(text: 'Delivered'),
          ],
        ),
      ),
      body: Consumer<InventoryProvider>(
        builder: (context, provider, _) {
          if (provider.purchaseOrders.isEmpty) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(color: theme.colorScheme.primaryContainer.withValues(alpha: 0.3), shape: BoxShape.circle),
                    child: Icon(Icons.receipt_long_rounded, size: 48, color: theme.colorScheme.primary),
                  ),
                  const SizedBox(height: 16),
                  Text('No orders found', style: theme.textTheme.titleMedium),
                  const SizedBox(height: 8),
                  Text('Tap + to create a purchase order', style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 100),
            itemCount: provider.purchaseOrders.length,
            itemBuilder: (context, index) {
              final order = provider.purchaseOrders[index];
              return _OrderCard(order: order, onRefresh: _loadOrders);
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showCreateOrderDialog(context),
        icon: const Icon(Icons.add_shopping_cart_rounded),
        label: const Text('New Order'),
      ),
    );
  }

  void _showCreateOrderDialog(BuildContext context) {
    final provider = context.read<InventoryProvider>();
    final productNameCtrl = TextEditingController();
    final supplierCtrl = TextEditingController();
    final quantityCtrl = TextEditingController();
    final notesCtrl = TextEditingController();
    int? selectedProductId;

    // load products for dropdown
    final products = provider.products;

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
                Text('Create Purchase Order', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700)),
                const SizedBox(height: 20),
                if (products.isNotEmpty)
                  DropdownButtonFormField<int>(
                    decoration: const InputDecoration(labelText: 'Product', border: OutlineInputBorder()),
                    items: products.map((p) => DropdownMenuItem<int>(value: p.id, child: Text(p.name))).toList(),
                    onChanged: (v) {
                      setDialogState(() {
                        selectedProductId = v;
                        final product = products.firstWhere((p) => p.id == v);
                        productNameCtrl.text = product.name;
                        if (product.supplier != null) supplierCtrl.text = product.supplier!;
                      });
                    },
                  )
                else
                  TextField(controller: productNameCtrl, decoration: const InputDecoration(labelText: 'Product Name', border: OutlineInputBorder()), textCapitalization: TextCapitalization.words),
                const SizedBox(height: 14),
                TextField(controller: supplierCtrl, decoration: const InputDecoration(labelText: 'Supplier', border: OutlineInputBorder()), textCapitalization: TextCapitalization.words),
                const SizedBox(height: 14),
                TextField(controller: quantityCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Quantity', border: OutlineInputBorder())),
                const SizedBox(height: 14),
                TextField(controller: notesCtrl, decoration: const InputDecoration(labelText: 'Notes (optional)', border: OutlineInputBorder()), textCapitalization: TextCapitalization.sentences, maxLines: 2),
                const SizedBox(height: 24),
                FilledButton.icon(
                  onPressed: () {
                    final qty = int.tryParse(quantityCtrl.text);
                    if (supplierCtrl.text.trim().isEmpty || qty == null || qty <= 0) return;
                    if (selectedProductId == null && productNameCtrl.text.trim().isEmpty) return;

                    final order = PurchaseOrder(
                      storeId: provider.selectedStore!.id!,
                      productId: selectedProductId ?? 0,
                      productName: productNameCtrl.text.trim().isNotEmpty ? productNameCtrl.text.trim() : products.firstWhere((p) => p.id == selectedProductId).name,
                      supplier: supplierCtrl.text.trim(),
                      quantity: qty,
                      notes: notesCtrl.text.trim().isEmpty ? null : notesCtrl.text.trim(),
                    );
                    provider.addPurchaseOrder(order);
                    Navigator.pop(ctx);
                  },
                  icon: const Icon(Icons.check_rounded),
                  label: const Text('Create Order'),
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

class _OrderCard extends StatelessWidget {
  final PurchaseOrder order;
  final VoidCallback onRefresh;
  const _OrderCard({required this.order, required this.onRefresh});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final dateFormat = DateFormat.yMMMd();
    final statusColor = order.delivered ? Colors.green : Colors.orange;

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
                  width: 42, height: 42,
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    order.delivered ? Icons.check_circle_rounded : Icons.pending_rounded,
                    color: statusColor,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(order.productName, style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600)),
                      Text('${order.quantity} units from ${order.supplier}', style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    order.delivered ? 'Delivered' : 'Pending',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: statusColor),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Icon(Icons.calendar_today_rounded, size: 14, color: theme.colorScheme.onSurfaceVariant),
                const SizedBox(width: 6),
                Text('Ordered: ${dateFormat.format(order.orderDate)}', style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
                if (order.deliveryDate != null) ...[
                  const SizedBox(width: 16),
                  Icon(Icons.local_shipping_rounded, size: 14, color: theme.colorScheme.onSurfaceVariant),
                  const SizedBox(width: 6),
                  Text('Delivered: ${dateFormat.format(order.deliveryDate!)}', style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
                ],
              ],
            ),
            if (order.notes != null) ...[
              const SizedBox(height: 6),
              Text(order.notes!, style: theme.textTheme.bodySmall?.copyWith(fontStyle: FontStyle.italic, color: theme.colorScheme.onSurfaceVariant)),
            ],
            if (!order.delivered) ...[
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton.icon(
                    onPressed: () {
                      HapticFeedback.mediumImpact();
                      context.read<InventoryProvider>().deletePurchaseOrder(order.id!);
                    },
                    icon: const Icon(Icons.delete_outline, size: 18, color: Colors.red),
                    label: const Text('Delete', style: TextStyle(color: Colors.red)),
                  ),
                  const SizedBox(width: 8),
                  FilledButton.icon(
                    onPressed: () {
                      HapticFeedback.heavyImpact();
                      context.read<InventoryProvider>().markOrderDelivered(order);
                    },
                    icon: const Icon(Icons.check_rounded, size: 18),
                    label: const Text('Mark Delivered'),
                    style: FilledButton.styleFrom(backgroundColor: Colors.green),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}
