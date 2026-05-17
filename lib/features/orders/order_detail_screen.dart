/// Order Detail Screen — placeholder for Phase 2 build.
library;

import 'package:flutter/material.dart';
import '../../core/theme/ios_design_system.dart';

class OrderDetailScreen extends StatelessWidget {
  final String orderId;
  const OrderDetailScreen({super.key, required this.orderId});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      backgroundColor: isDark ? PSColors.darkBg : PSColors.lightBg,
      appBar: AppBar(
        title: Text('Order Detail', style: PSText.title()),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('Order #${orderId.substring(0, 8)}', style: PSText.title()),
            const SizedBox(height: 8),
            Text('Phase 2 — Detail view coming', style: PSText.body(color: PSColors.textDark2)),
          ],
        ),
      ),
    );
  }
}
