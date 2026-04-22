import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../../core/services/firestore_service.dart';
import '../../core/theme/app_theme.dart';

class InventoryQrScanScreen extends StatefulWidget {
  const InventoryQrScanScreen({super.key});
  @override
  State<InventoryQrScanScreen> createState() => _InventoryQrScanScreenState();
}

class _InventoryQrScanScreenState extends State<InventoryQrScanScreen> {
  final MobileScannerController _ctrl = MobileScannerController();
  bool _processing = false;
  String? _lastResult;
  String? _feedback;
  bool _success = false;
  Timer? _feedbackTimer;

  @override
  void dispose() {
    _feedbackTimer?.cancel();
    _ctrl.dispose();
    super.dispose();
  }

  Future<void> _onDetect(BarcodeCapture capture) async {
    final barcode = capture.barcodes.firstOrNull;
    if (barcode == null) return;
    final raw = barcode.rawValue;
    if (raw == null || raw == _lastResult || _processing) return;

    setState(() {
      _processing = true;
      _lastResult = raw;
    });

    final sku = raw.startsWith('SKU:') ? raw.substring(4) : raw;

    final snap = await FirestoreService.inventory
        .where('sku', isEqualTo: sku)
        .limit(1)
        .get();

    if (!mounted) return;

    if (snap.docs.isNotEmpty) {
      final item = FirestoreService.docToMap(snap.docs.first);
      _setFeedback('✅ Found: ${item['name']}', true);
      await Future.delayed(const Duration(seconds: 1));
      if (mounted) context.go('/inventory/detail/${item['id']}');
    } else {
      _setFeedback('❌ No item found for SKU: $sku', false);
    }

    if (mounted) setState(() => _processing = false);
  }

  void _setFeedback(String msg, bool success) {
    if (!mounted) return;
    setState(() {
      _feedback = msg;
      _success = success;
    });
    _feedbackTimer?.cancel();
    _feedbackTimer = Timer(const Duration(seconds: 3), () {
      if (mounted) setState(() { _feedback = null; _lastResult = null; });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: const Text('QR Scan — Inventory'),
        leading: BackButton(onPressed: () => context.go('/inventory')),
        actions: [
          IconButton(icon: const Icon(Icons.flash_on, color: Colors.white), onPressed: () => _ctrl.toggleTorch()),
          IconButton(icon: const Icon(Icons.flip_camera_ios, color: Colors.white), onPressed: () => _ctrl.switchCamera()),
        ],
      ),
      body: Stack(
        children: [
          MobileScanner(controller: _ctrl, onDetect: _onDetect),
          Center(
            child: Container(
              width: 240,
              height: 240,
              decoration: BoxDecoration(
                border: Border.all(
                  color: _success ? AppTheme.accentGreen : AppTheme.primaryBlue,
                  width: 3,
                ),
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
          Positioned(
            top: 40,
            left: 0,
            right: 0,
            child: Text(
              'Point camera at inventory QR / barcode',
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(color: Colors.white70, fontSize: 14),
            ),
          ),
          if (_feedback != null)
            Positioned(
              bottom: 100,
              left: 24,
              right: 24,
              child: Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: (_success ? AppTheme.accentGreen : AppTheme.accentRed).withValues(alpha: 0.9),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  _feedback!,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 15),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
