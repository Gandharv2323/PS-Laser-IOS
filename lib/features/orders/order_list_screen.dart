/// Order List Screen — placeholder for Phase 2 build.
/// Full implementation follows in Phase 2.
library;

import 'package:flutter/material.dart';
import '../../core/theme/ios_design_system.dart';

class OrderListScreen extends StatelessWidget {
  const OrderListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      backgroundColor: isDark ? PSColors.darkBg : PSColors.lightBg,
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Orders', style: PSText.title()),
            Text(
              'Order Control System',
              style: PSText.caption(color: PSColors.textDark3),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.mic_none_rounded),
            tooltip: 'Voice Order',
            onPressed: () {},
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                gradient: PSColors.brandGradient,
                borderRadius: BorderRadius.circular(PSRadius.lg),
              ),
              child: const Icon(Icons.receipt_long_rounded, color: Colors.white, size: 34),
            ),
            const SizedBox(height: 20),
            Text('Order Control System', style: PSText.title()),
            const SizedBox(height: 8),
            Text(
              'Phase 2 — Coming next',
              style: PSText.body(color: PSColors.textDark2),
            ),
            const SizedBox(height: 4),
            Text(
              'Full CRUD, realtime streams, priority engine',
              style: PSText.caption(color: PSColors.textDark3),
            ),
          ],
        ),
      ),
    );
  }
}
