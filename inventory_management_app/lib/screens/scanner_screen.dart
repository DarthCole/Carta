import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:provider/provider.dart';
import '../providers/inventory_provider.dart';

class ScannerScreen extends StatefulWidget {
  const ScannerScreen({super.key});

  @override
  State<ScannerScreen> createState() => _ScannerScreenState();
}

class _ScannerScreenState extends State<ScannerScreen> {
  final MobileScannerController _controller = MobileScannerController();
  bool _isProcessing = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Scan Barcode / QR', style: TextStyle(fontWeight: FontWeight.w700)),
        actions: [
          IconButton(
            icon: const Icon(Icons.flash_on_rounded),
            onPressed: () => _controller.toggleTorch(),
            tooltip: 'Toggle Flashlight',
          ),
          IconButton(
            icon: const Icon(Icons.cameraswitch_rounded),
            onPressed: () => _controller.switchCamera(),
            tooltip: 'Switch Camera',
          ),
        ],
      ),
      body: Stack(
        children: [
          MobileScanner(
            controller: _controller,
            onDetect: _onDetect,
          ),
          // Scanning overlay
          Center(
            child: Container(
              width: 260,
              height: 260,
              decoration: BoxDecoration(
                border: Border.all(color: Colors.white.withValues(alpha: 0.8), width: 2.5),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(color: Colors.black.withValues(alpha: 0.3), blurRadius: 20, spreadRadius: 5),
                ],
              ),
              child: Stack(
                children: [
                  // Corner accents
                  Positioned(top: -1, left: -1, child: _cornerAccent(true, true)),
                  Positioned(top: -1, right: -1, child: _cornerAccent(true, false)),
                  Positioned(bottom: -1, left: -1, child: _cornerAccent(false, true)),
                  Positioned(bottom: -1, right: -1, child: _cornerAccent(false, false)),
                ],
              ),
            ),
          ),
          // Bottom instruction
          Positioned(
            bottom: 80,
            left: 0,
            right: 0,
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.6),
                  borderRadius: BorderRadius.circular(24),
                ),
                child: const Text(
                  'Point camera at barcode or QR code',
                  style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w500),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _cornerAccent(bool isTop, bool isLeft) {
    return Container(
      width: 30,
      height: 30,
      decoration: BoxDecoration(
        border: Border(
          top: isTop ? const BorderSide(color: Color(0xFF0EA5E9), width: 4) : BorderSide.none,
          bottom: !isTop ? const BorderSide(color: Color(0xFF0EA5E9), width: 4) : BorderSide.none,
          left: isLeft ? const BorderSide(color: Color(0xFF0EA5E9), width: 4) : BorderSide.none,
          right: !isLeft ? const BorderSide(color: Color(0xFF0EA5E9), width: 4) : BorderSide.none,
        ),
      ),
    );
  }

  Future<void> _onDetect(BarcodeCapture capture) async {
    if (_isProcessing) return;
    final barcode = capture.barcodes.firstOrNull;
    if (barcode == null || barcode.rawValue == null) return;

    setState(() => _isProcessing = true);
    _controller.stop();
    HapticFeedback.heavyImpact();

    final code = barcode.rawValue!;
    final provider = context.read<InventoryProvider>();

    if (provider.selectedStore == null) {
      _showNotFoundDialog(code);
      return;
    }

    final product = await provider.products.where((p) => p.barcode == code).firstOrNull != null
        ? provider.products.firstWhere((p) => p.barcode == code)
        : null;

    if (product != null) {
      _showFoundDialog(product, code);
    } else {
      _showNotFoundDialog(code);
    }
  }

  void _showFoundDialog(dynamic product, String code) {
    final theme = Theme.of(context);
    final statusColor = product.stockStatus == 'OK' ? Colors.green : product.stockStatus == 'Reorder Soon' ? Colors.amber[800]! : Colors.red;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Icon(Icons.check_circle_rounded, color: Colors.green[600], size: 28),
            const SizedBox(width: 10),
            const Expanded(child: Text('Product Found', style: TextStyle(fontWeight: FontWeight.w700))),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(product.name, style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600)),
            const SizedBox(height: 12),
            _infoRow('Brand', product.brand),
            _infoRow('Supplier', product.supplier ?? 'N/A'),
            _infoRow('Price', 'GH₵ ${product.price.toStringAsFixed(2)}'),
            _infoRow('Stock', '${product.quantity} units'),
            _infoRow('Status', product.stockStatus),
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: statusColor.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(product.verified ? Icons.verified_rounded : Icons.help_outline_rounded, size: 16, color: product.verified ? Colors.green : Colors.orange),
                  const SizedBox(width: 6),
                  Text(product.verified ? 'Verified ✓' : 'Not Verified', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: product.verified ? Colors.green[700] : Colors.orange[800])),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () { Navigator.pop(ctx); _resumeScanning(); }, child: const Text('Scan Again')),
          if (!product.verified)
            FilledButton(
              onPressed: () {
                context.read<InventoryProvider>().verifyProduct(product, true);
                Navigator.pop(ctx);
                _resumeScanning();
              },
              child: const Text('Verify Product'),
            ),
          FilledButton(onPressed: () { Navigator.pop(ctx); Navigator.pop(context); }, child: const Text('Done')),
        ],
      ),
    );
  }

  Widget _infoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          SizedBox(width: 80, child: Text(label, style: TextStyle(color: Colors.grey[600], fontSize: 13))),
          Expanded(child: Text(value, style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 13))),
        ],
      ),
    );
  }

  void _showNotFoundDialog(String code) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            const Icon(Icons.search_off_rounded, color: Colors.orange, size: 28),
            const SizedBox(width: 10),
            const Expanded(child: Text('Product Not Found', style: TextStyle(fontWeight: FontWeight.w700))),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('No product matched the scanned code.', style: TextStyle(color: Colors.grey[600])),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                children: [
                  const Icon(Icons.qr_code_rounded, size: 18, color: Colors.grey),
                  const SizedBox(width: 8),
                  Expanded(child: Text(code, style: const TextStyle(fontFamily: 'monospace', fontSize: 13))),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () { Navigator.pop(ctx); _resumeScanning(); }, child: const Text('Scan Again')),
          FilledButton(onPressed: () { Navigator.pop(ctx); Navigator.pop(context); }, child: const Text('Done')),
        ],
      ),
    );
  }

  void _resumeScanning() {
    setState(() => _isProcessing = false);
    _controller.start();
  }
}
