import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../providers/inventory_provider.dart';
import '../models/store.dart';
import '../services/auth_service.dart';

class StoresScreen extends StatefulWidget {
  const StoresScreen({super.key});

  @override
  State<StoresScreen> createState() => _StoresScreenState();
}

class _StoresScreenState extends State<StoresScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() => context.read<InventoryProvider>().loadStores());
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      appBar: AppBar(
        title: const Text('My Stores', style: TextStyle(fontWeight: FontWeight.w700)),
        centerTitle: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout_rounded),
            tooltip: 'Sign Out',
            onPressed: () async {
              HapticFeedback.mediumImpact();
              await AuthService().signOut();
              if (context.mounted) {
                Navigator.of(context).pushReplacementNamed('/login');
              }
            },
          ),
        ],
      ),
      body: Consumer<InventoryProvider>(
        builder: (context, provider, _) {
          if (provider.stores.isEmpty) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primaryContainer.withValues(alpha: 0.3),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(Icons.store_outlined, size: 56, color: theme.colorScheme.primary),
                  ),
                  const SizedBox(height: 20),
                  Text('No stores yet', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600)),
                  const SizedBox(height: 8),
                  Text('Tap + to add your first store', style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
            itemCount: provider.stores.length,
            itemBuilder: (context, index) {
              final store = provider.stores[index];
              return _StoreCard(store: store);
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddStoreDialog(context),
        icon: const Icon(Icons.add_rounded),
        label: const Text('Add Store'),
      ),
    );
  }

  void _showAddStoreDialog(BuildContext context) {
    final nameCtrl = TextEditingController();
    final addressCtrl = TextEditingController();
    final phoneCtrl = TextEditingController();

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
            Text('New Store', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700)),
            const SizedBox(height: 20),
            TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: 'Store Name', border: OutlineInputBorder(), prefixIcon: Icon(Icons.store_rounded)), textCapitalization: TextCapitalization.words),
            const SizedBox(height: 14),
            TextField(controller: addressCtrl, decoration: const InputDecoration(labelText: 'Address', border: OutlineInputBorder(), prefixIcon: Icon(Icons.location_on_rounded)), textCapitalization: TextCapitalization.words),
            const SizedBox(height: 14),
            TextField(controller: phoneCtrl, decoration: const InputDecoration(labelText: 'Phone (optional)', border: OutlineInputBorder(), prefixIcon: Icon(Icons.phone_rounded)), keyboardType: TextInputType.phone),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: () {
                if (nameCtrl.text.trim().isEmpty || addressCtrl.text.trim().isEmpty) return;
                context.read<InventoryProvider>().addStore(
                  nameCtrl.text.trim(), addressCtrl.text.trim(),
                  phoneCtrl.text.trim().isEmpty ? null : phoneCtrl.text.trim(),
                );
                Navigator.pop(ctx);
              },
              icon: const Icon(Icons.check_rounded),
              label: const Text('Create Store'),
              style: FilledButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16)),
            ),
          ],
        ),
      ),
    );
  }
}

class _StoreCard extends StatelessWidget {
  final Store store;
  const _StoreCard({required this.store});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () {
          HapticFeedback.lightImpact();
          final provider = context.read<InventoryProvider>();
          provider.selectStore(store);
          Navigator.pushNamed(context, '/store-detail');
        },
        onLongPress: () => _showStoreOptions(context),
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Row(
            children: [
              Container(
                width: 52, height: 52,
                decoration: BoxDecoration(
                  color: theme.colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(Icons.storefront_rounded, color: theme.colorScheme.primary, size: 26),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(store.name, style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600)),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(Icons.location_on_outlined, size: 14, color: theme.colorScheme.onSurfaceVariant),
                        const SizedBox(width: 4),
                        Expanded(child: Text(store.address, style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant), maxLines: 1, overflow: TextOverflow.ellipsis)),
                      ],
                    ),
                    if (store.phone != null) ...[
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          Icon(Icons.phone_outlined, size: 14, color: theme.colorScheme.onSurfaceVariant),
                          const SizedBox(width: 4),
                          Text(store.phone!, style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
              Icon(Icons.chevron_right_rounded, color: theme.colorScheme.onSurfaceVariant),
            ],
          ),
        ),
      ),
    );
  }

  void _showStoreOptions(BuildContext context) {
    HapticFeedback.mediumImpact();
    showModalBottomSheet(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.delete_outline, color: Colors.red),
              title: const Text('Delete Store', style: TextStyle(color: Colors.red)),
              onTap: () {
                Navigator.pop(ctx);
                context.read<InventoryProvider>().removeStore(store.id!);
              },
            ),
          ],
        ),
      ),
    );
  }
}
