import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/inventory_provider.dart';
import '../models/store.dart';

/// displaying the list of all stores and allowing the user to add new ones.
///
/// this is the main landing screen after the splash. showing store cards
/// in a scrollable list. tapping a card navigates to the store detail view,
/// while long-pressing reveals a delete option.
class StoresScreen extends StatefulWidget {
  const StoresScreen({super.key});

  @override
  State<StoresScreen> createState() => _StoresScreenState();
}

class _StoresScreenState extends State<StoresScreen> {
  @override
  void initState() {
    super.initState();
    // loading stores from the database after the widget is built
    Future.microtask(() => context.read<InventoryProvider>().loadStores());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Stores'),
        centerTitle: true,
        backgroundColor: const Color(0xFF1A237E),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Consumer<InventoryProvider>(
        builder: (context, provider, _) {
          // showing an empty state when no stores exist
          if (provider.stores.isEmpty) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.store_outlined, size: 80, color: Colors.grey[400]),
                  const SizedBox(height: 16),
                  Text('No stores yet', style: TextStyle(fontSize: 18, color: Colors.grey[600])),
                  const SizedBox(height: 8),
                  const Text('Tap + to add your first store'),
                ],
              ),
            );
          }

          // rendering the store list with cards
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: provider.stores.length,
            itemBuilder: (context, index) {
              final store = provider.stores[index];
              return _StoreCard(store: store);
            },
          );
        },
      ),
      // floating action button for adding a new store
      floatingActionButton: FloatingActionButton(
        backgroundColor: const Color(0xFF1A237E),
        foregroundColor: Colors.white,
        onPressed: () => _showAddStoreDialog(context),
        child: const Icon(Icons.add),
      ),
    );
  }

  /// showing a dialog with text fields for creating a new store.
  /// validating that name and address are provided before saving.
  void _showAddStoreDialog(BuildContext context) {
    final nameCtrl = TextEditingController();
    final addressCtrl = TextEditingController();
    final phoneCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Add Store'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: 'Store Name', border: OutlineInputBorder())),
              const SizedBox(height: 12),
              TextField(controller: addressCtrl, decoration: const InputDecoration(labelText: 'Address', border: OutlineInputBorder())),
              const SizedBox(height: 12),
              TextField(controller: phoneCtrl, decoration: const InputDecoration(labelText: 'Phone (optional)', border: OutlineInputBorder())),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          FilledButton(
            onPressed: () {
              // ensuring required fields are not empty before saving
              if (nameCtrl.text.trim().isNotEmpty && addressCtrl.text.trim().isNotEmpty) {
                context.read<InventoryProvider>().addStore(
                  nameCtrl.text.trim(),
                  addressCtrl.text.trim(),
                  phoneCtrl.text.trim().isEmpty ? null : phoneCtrl.text.trim(),
                );
                Navigator.pop(ctx);
              }
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }
}

/// rendering a single store as a tappable card with name, address, and phone.
/// tapping navigates to the store detail screen. long-pressing shows delete option.
class _StoreCard extends StatelessWidget {
  final Store store;
  const _StoreCard({required this.store});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 3,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () {
          // selecting the store and navigating to its detail view
          context.read<InventoryProvider>().selectStore(store);
          Navigator.pushNamed(context, '/store-detail');
        },
        onLongPress: () => _showStoreOptions(context),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Row(
            children: [
              // store icon with themed background
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0xFF1A237E).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.store_rounded, size: 32, color: Color(0xFF1A237E)),
              ),
              const SizedBox(width: 16),
              // store details (name, address, phone)
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(store.name, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 4),
                    Text(store.address, style: TextStyle(color: Colors.grey[600], fontSize: 14)),
                    if (store.phone != null) ...[
                      const SizedBox(height: 2),
                      Text(store.phone!, style: TextStyle(color: Colors.grey[500], fontSize: 13)),
                    ],
                  ],
                ),
              ),
              const Icon(Icons.chevron_right, color: Colors.grey), // navigation hint arrow
            ],
          ),
        ),
      ),
    );
  }

  /// showing a bottom sheet with the option to delete this store.
  void _showStoreOptions(BuildContext context) {
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
