import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'providers/inventory_provider.dart';
import 'services/notification_service.dart';
import 'screens/splash_screen.dart';
import 'screens/login_screen.dart';
import 'screens/signup_screen.dart';
import 'screens/stores_screen.dart';
import 'screens/store_detail_screen.dart';
import 'screens/products_screen.dart';
import 'screens/scanner_screen.dart';
import 'screens/low_stock_screen.dart';
import 'screens/purchase_orders_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize env and supabase
  await dotenv.load(fileName: ".env");
  await Supabase.initialize(
    url: dotenv.env['SUPABASE_URL'] ?? '',
    anonKey: dotenv.env['SUPABASE_ANON_KEY'] ?? '',
  );

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
            seedColor: const Color(0xFF0F172A),
            primary: const Color(0xFF1E3A5F),
            brightness: Brightness.light,
          ),
          useMaterial3: true,
          fontFamily: 'Roboto',
          appBarTheme: const AppBarTheme(
            centerTitle: false,
            elevation: 0,
            scrolledUnderElevation: 1,
          ),
          cardTheme: CardThemeData(
            elevation: 0,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            clipBehavior: Clip.antiAlias,
            color: const Color(0xFFF8FAFC),
          ),
          floatingActionButtonTheme: FloatingActionButtonThemeData(
            backgroundColor: const Color(0xFF1E3A5F),
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            elevation: 2,
          ),
          filledButtonTheme: FilledButtonThemeData(
            style: FilledButton.styleFrom(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
          outlinedButtonTheme: OutlinedButtonThemeData(
            style: OutlinedButton.styleFrom(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
          inputDecorationTheme: InputDecorationTheme(
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          ),
          chipTheme: ChipThemeData(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
          dialogTheme: DialogThemeData(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          ),
          bottomSheetTheme: const BottomSheetThemeData(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            ),
          ),
          snackBarTheme: SnackBarThemeData(
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        ),
        initialRoute: '/',
        routes: {
          '/': (context) => const SplashScreen(),
          '/login': (context) => const LoginScreen(),
          '/signup': (context) => const SignUpScreen(),
          '/stores': (context) => const StoresScreen(),
          '/store-detail': (context) => const StoreDetailScreen(),
          '/products': (context) => const ProductsScreen(),
          '/scanner': (context) => const ScannerScreen(),
          '/low-stock': (context) => const LowStockScreen(),
          '/purchase-orders': (context) => const PurchaseOrdersScreen(),
        },
      ),
    );
  }
}
