import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'providers/inventory_provider.dart';
import 'services/notification_service.dart';
import 'screens/splash_screen.dart';
import 'screens/stores_screen.dart';
import 'screens/store_detail_screen.dart';
import 'screens/products_screen.dart';
import 'screens/scanner_screen.dart';
import 'screens/low_stock_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await NotificationService().init();
  runApp(const CartaApp());
}

class CartaApp extends StatelessWidget {
  const CartaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => InventoryProvider(),
      child: MaterialApp(
        title: 'Carta',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(
            seedColor: const Color(0xFF1A237E),
            brightness: Brightness.light,
          ),
          useMaterial3: true,
          appBarTheme: const AppBarTheme(
            centerTitle: true,
            elevation: 0,
          ),
          cardTheme: CardThemeData(
            elevation: 2,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
        initialRoute: '/',
        routes: {
          '/': (context) => const SplashScreen(),
          '/stores': (context) => const StoresScreen(),
          '/store-detail': (context) => const StoreDetailScreen(),
          '/products': (context) => const ProductsScreen(),
          '/scanner': (context) => const ScannerScreen(),
          '/low-stock': (context) => const LowStockScreen(),
        },
      ),
    );
  }
}
