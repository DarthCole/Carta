import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/inventory_provider.dart';
import '../models/product.dart';
import '../models/purchase_order.dart';
import '../services/supabase_service.dart';

class StoreDetailScreen extends StatefulWidget {
  const StoreDetailScreen({super.key});

  @override
  State<StoreDetailScreen> createState() => _StoreDetailScreenState();
}

class _StoreDetailScreenState extends State<StoreDetailScreen> {
  int _productCount = 0;
  int _lowStockCount = 0;
  int _pendingOrders = 0;
  List<Product> _reorderSoon = [];
  List<Product> _flaggedLow = [];
  List<PurchaseOrder> _recentDeliveries = [];

  @override
  void initState() {
    super.initState();
    Future.microtask(() => _load());
  }

  Future<void> _load() async {
    final provider = context.read<InventoryProvider>();
    await provider.loadCategories();
    await provider.loadProducts();
    final pc = await provider.getProductCount();
    final lsc = await provider.getLowStockCount();
    final po = await provider.getPendingOrderCount();
    final rs = await provider.getReorderSoonProducts();
    final fl = await provider.getFlaggedLowStockProducts();
    final rd = await provider.getRecentDeliveries();
    if (mounted) {
      setState(() {
        _productCount = pc;
        _lowStockCount = lsc;
        _pendingOrders = po;
        _reorderSoon = rs;
        _flaggedLow = fl;
        _recentDeliveries = rd;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Consumer<InventoryProvider>(
      builder: (context, provider, _) {
        final store = provider.selectedStore;
        if (store == null) return const Scaffold(body: Center(child: Text('No store selected')));

        return Scaffold(
          backgroundColor: theme.colorScheme.surface,
          appBar: AppBar(
            title: Text(store.name, style: const TextStyle(fontWeight: FontWeight.w700)),
            actions: [
              IconButton(
                icon: const Icon(Icons.qr_code_scanner_rounded),
                onPressed: () => Navigator.pushNamed(context, '/scanner'),
                tooltip: 'Scan Barcode',
              ),
            ],
          ),
          body: RefreshIndicator(
            onRefresh: _load,
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
              children: [
                // ── Dashboard Section ──
                _buildSectionTitle('Dashboard', Icons.dashboard_rounded),
                const SizedBox(height: 10),
                _buildStatCards(theme),
                const SizedBox(height: 16),

                // Quick Actions
                _buildSectionTitle('Quick Actions', Icons.flash_on_rounded),
                const SizedBox(height: 10),
                _buildQuickActions(context, theme),
                const SizedBox(height: 16),

                // Reorder Soon alerts
                if (_reorderSoon.isNotEmpty) ...[
                  _buildSectionTitle('Reorder Soon', Icons.schedule_rounded),
                  const SizedBox(height: 10),
                  ..._reorderSoon.take(3).map((p) => _buildAlertTile(p, theme, isReorder: true)),
                  const SizedBox(height: 16),
                ],

                // Flagged Low Stock
                if (_flaggedLow.isNotEmpty) ...[
                  _buildSectionTitle('Flagged Low Stock', Icons.flag_rounded),
                  const SizedBox(height: 10),
                  ..._flaggedLow.take(3).map((p) => _buildAlertTile(p, theme)),
                  const SizedBox(height: 16),
                ],

                // Recent Deliveries
                if (_recentDeliveries.isNotEmpty) ...[
                  _buildSectionTitle('Recent Deliveries', Icons.local_shipping_rounded),
                  const SizedBox(height: 10),
                  ..._recentDeliveries.map((o) => _buildDeliveryTile(o, theme)),
                  const SizedBox(height: 16),
                ],

                // ── Categories Section ──
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _buildSectionTitle('Categories', Icons.category_rounded),
                    TextButton.icon(
                      icon: const Icon(Icons.add_rounded, size: 18),
                      label: const Text('Add'),
                      onPressed: () => _showAddCategoryDialog(context),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                provider.categories.isEmpty
                    ? Container(
                        padding: const EdgeInsets.all(32),
                        child: Center(child: Text('No categories yet', style: TextStyle(color: theme.colorScheme.onSurfaceVariant))),
                      )
                    : GridView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          crossAxisSpacing: 12,
                          mainAxisSpacing: 12,
                          childAspectRatio: 1.5,
                        ),
                        itemCount: provider.categories.length,
                        itemBuilder: (context, index) {
                          final cat = provider.categories[index];
                          final icon = _categoryIcon(cat.name);
                          return Card(
                            child: InkWell(
                              borderRadius: BorderRadius.circular(16),
                              onTap: () {
                                HapticFeedback.lightImpact();
                                provider.setSelectedCategory(cat);
                                Navigator.pushNamed(context, '/products');
                              },
                              onLongPress: () {
                                HapticFeedback.mediumImpact();
                                showModalBottomSheet(
                                  context: context,
                                  builder: (ctx) => SafeArea(
                                    child: ListTile(
                                      leading: const Icon(Icons.delete_outline, color: Colors.red),
                                      title: const Text('Delete Category', style: TextStyle(color: Colors.red)),
                                      onTap: () {
                                        Navigator.pop(ctx);
                                        provider.removeCategory(cat.id!);
                                      },
                                    ),
                                  ),
                                );
                              },
                              child: Padding(
                                padding: const EdgeInsets.all(14),
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(icon, size: 30, color: theme.colorScheme.primary),
                                    const SizedBox(height: 10),
                                    Text(cat.name, style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600), textAlign: TextAlign.center, maxLines: 1, overflow: TextOverflow.ellipsis),
                                    if (cat.description != null)
                                      Text(cat.description!, style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant), textAlign: TextAlign.center, maxLines: 1, overflow: TextOverflow.ellipsis),
                                  ],
                                ),
                              ),
                            ),
                          );
                        },
                      ),

                const SizedBox(height: 16),
                // View all products button
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () {
                      provider.setSelectedCategory(null);
                      Navigator.pushNamed(context, '/products');
                    },
                    icon: const Icon(Icons.inventory_2_rounded),
                    label: const Text('View All Products'),
                    style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 14)),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildSectionTitle(String title, IconData icon) {
    final theme = Theme.of(context);
    return Row(
      children: [
        Icon(icon, size: 20, color: theme.colorScheme.primary),
        const SizedBox(width: 8),
        Text(title, style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
      ],
    );
  }

  Widget _buildStatCards(ThemeData theme) {
    return Row(
      children: [
        _StatCard(label: 'Products', value: '$_productCount', icon: Icons.inventory_2_rounded, color: theme.colorScheme.primary),
        const SizedBox(width: 10),
        _StatCard(label: 'Low Stock', value: '$_lowStockCount', icon: Icons.warning_amber_rounded, color: Colors.orange),
        const SizedBox(width: 10),
        _StatCard(label: 'Pending', value: '$_pendingOrders', icon: Icons.pending_actions_rounded, color: Colors.blue),
      ],
    );
  }

  Widget _buildQuickActions(BuildContext context, ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Main Feature Cards
        Row(
          children: [
            _FeatureCard(
              title: 'Products',
              subtitle: 'Manage inventory',
              icon: Icons.inventory_2_rounded,
              color: theme.colorScheme.primary,
              onTap: () {
                final provider = context.read<InventoryProvider>();
                provider.setSelectedCategory(null);
                Navigator.pushNamed(context, '/products');
              },
            ),
            const SizedBox(width: 12),
            _FeatureCard(
              title: 'Orders',
              subtitle: 'Purchase orders',
              icon: Icons.shopping_cart_rounded,
              color: Colors.green,
              onTap: () => Navigator.pushNamed(context, '/purchase-orders'),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            _FeatureCard(
              title: 'Low Stock',
              subtitle: 'Stock alerts',
              icon: Icons.warning_amber_rounded,
              color: Colors.orange,
              onTap: () => Navigator.pushNamed(context, '/low-stock'),
            ),
            const SizedBox(width: 12),
            _FeatureCard(
              title: 'Scan',
              subtitle: 'Barcode scanner',
              icon: Icons.qr_code_scanner_rounded,
              color: Colors.blue,
              onTap: () => Navigator.pushNamed(context, '/scanner'),
            ),
          ],
        ),
        const SizedBox(height: 16),
        // Quick Action Chips
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            _QuickAction(label: 'Add Product', icon: Icons.add_rounded, onTap: () {
              final provider = context.read<InventoryProvider>();
              provider.setSelectedCategory(null);
              Navigator.pushNamed(context, '/products');
            }),
            _QuickAction(label: 'New Order', icon: Icons.add_shopping_cart_rounded, onTap: () => Navigator.pushNamed(context, '/purchase-orders')),
            _QuickAction(label: 'Categories', icon: Icons.category_rounded, onTap: () => _showAddCategoryDialog(context)),
            _QuickAction(label: 'Sync to Cloud', icon: Icons.cloud_sync_rounded, onTap: () async {
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Syncing to Supabase...')));
              try {
                await SupabaseService().syncAll();
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Sync complete!')));
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Sync failed: $e')));
                }
              }
            }),
          ],
        ),
      ],
    );
  }

  Widget _buildAlertTile(Product product, ThemeData theme, {bool isReorder = false}) {
    final days = product.lastDeliveryDate != null
        ? DateTime.now().difference(product.lastDeliveryDate!).inDays
        : 0;
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: isReorder ? Colors.amber.withValues(alpha: 0.2) : Colors.red.withValues(alpha: 0.15),
          child: Icon(
            isReorder ? Icons.schedule_rounded : Icons.warning_amber_rounded,
            color: isReorder ? Colors.amber[800] : Colors.red,
            size: 20,
          ),
        ),
        title: Text(product.name, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
        subtitle: Text(
          isReorder
              ? '$days days since last delivery (interval: ${product.reorderIntervalDays}d)'
              : 'Qty: ${product.quantity} / Threshold: ${product.restockThreshold}',
          style: TextStyle(fontSize: 12, color: theme.colorScheme.onSurfaceVariant),
        ),
        trailing: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: isReorder ? Colors.amber.withValues(alpha: 0.15) : Colors.red.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            isReorder ? 'Reorder' : 'Low',
            style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: isReorder ? Colors.amber[900] : Colors.red[700]),
          ),
        ),
      ),
    );
  }

  Widget _buildDeliveryTile(PurchaseOrder order, ThemeData theme) {
    final dateStr = order.deliveryDate != null ? DateFormat.MMMd().format(order.deliveryDate!) : 'N/A';
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: Colors.green.withValues(alpha: 0.15),
          child: const Icon(Icons.check_circle_rounded, color: Colors.green, size: 20),
        ),
        title: Text(order.productName, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
        subtitle: Text('${order.quantity} units from ${order.supplier}', style: TextStyle(fontSize: 12, color: theme.colorScheme.onSurfaceVariant)),
        trailing: Text(dateStr, style: TextStyle(fontSize: 12, color: theme.colorScheme.onSurfaceVariant)),
      ),
    );
  }

  IconData _categoryIcon(String name) {
    final lower = name.toLowerCase();
    if (lower.contains('beverage') || lower.contains('drink')) return Icons.local_drink_rounded;
    if (lower.contains('snack') || lower.contains('food')) return Icons.fastfood_rounded;
    if (lower.contains('personal') || lower.contains('care')) return Icons.spa_rounded;
    if (lower.contains('station') || lower.contains('office')) return Icons.edit_rounded;
    if (lower.contains('electronic')) return Icons.devices_rounded;
    if (lower.contains('clean')) return Icons.cleaning_services_rounded;
    return Icons.category_rounded;
  }

  void _showAddCategoryDialog(BuildContext context) {
    final nameCtrl = TextEditingController();
    final descCtrl = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => Padding(
        padding: EdgeInsets.fromLTRB(24, 24, 24, MediaQuery.of(ctx).viewInsets.bottom + 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(2)))),
            const SizedBox(height: 20),
            Text('New Category', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700)),
            const SizedBox(height: 20),
            TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: 'Category Name', border: OutlineInputBorder(), prefixIcon: Icon(Icons.category_rounded)), textCapitalization: TextCapitalization.words),
            const SizedBox(height: 14),
            TextField(controller: descCtrl, decoration: const InputDecoration(labelText: 'Description (optional)', border: OutlineInputBorder(), prefixIcon: Icon(Icons.description_rounded)), textCapitalization: TextCapitalization.sentences),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: () {
                if (nameCtrl.text.trim().isEmpty) return;
                context.read<InventoryProvider>().addCategory(nameCtrl.text.trim(), descCtrl.text.trim().isEmpty ? null : descCtrl.text.trim());
                Navigator.pop(ctx);
                _load();
              },
              icon: const Icon(Icons.check_rounded),
              label: const Text('Create Category'),
              style: FilledButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16)),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const _StatCard({required this.label, required this.value, required this.icon, required this.color});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            children: [
              Icon(icon, color: color, size: 24),
              const SizedBox(height: 8),
              Text(value, style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: color)),
              const SizedBox(height: 4),
              Text(label, style: TextStyle(fontSize: 11, color: Theme.of(context).colorScheme.onSurfaceVariant)),
            ],
          ),
        ),
      ),
    );
  }
}

class _QuickAction extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback onTap;

  const _QuickAction({required this.label, required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ActionChip(
      avatar: Icon(icon, size: 18, color: theme.colorScheme.primary),
      label: Text(label),
      onPressed: () {
        HapticFeedback.lightImpact();
        onTap();
      },
    );
  }
}

class _FeatureCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _FeatureCard({required this.title, required this.subtitle, required this.icon, required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Expanded(
      child: Card(
        color: color.withValues(alpha: 0.1),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, color: color, size: 28),
                const SizedBox(height: 8),
                Text(title, style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600)),
                const SizedBox(height: 4),
                Text(subtitle, style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
