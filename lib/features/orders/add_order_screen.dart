/// Add Order Screen — placeholder for Phase 2 build.
library;

import 'package:flutter/material.dart';
import '../../core/theme/ios_design_system.dart';

class AddOrderScreen extends StatelessWidget {
  final String? preselectedClientId;
  final String? preselectedClientName;

  const AddOrderScreen({
    super.key,
    this.preselectedClientId,
    this.preselectedClientName,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      backgroundColor: isDark ? PSColors.darkBg : PSColors.lightBg,
      appBar: AppBar(
        title: Text('New Order', style: PSText.title()),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (preselectedClientName != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: PSStatusBadge(status: 'RECEIVED'),
              ),
            Text('New Order Form', style: PSText.title()),
            const SizedBox(height: 8),
            Text('Phase 2 — Full form coming', style: PSText.body(color: PSColors.textDark2)),
          ],
        ),
      ),
    );
  }
}
