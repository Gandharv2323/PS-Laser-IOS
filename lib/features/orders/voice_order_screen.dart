/// Voice Order Screen — placeholder for Phase 4 build.
library;

import 'package:flutter/material.dart';
import '../../core/theme/ios_design_system.dart';

class VoiceOrderScreen extends StatelessWidget {
  const VoiceOrderScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      backgroundColor: isDark ? PSColors.darkBg : PSColors.lightBg,
      appBar: AppBar(
        title: Text('Voice Order', style: PSText.title()),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                gradient: PSColors.aiGradient,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.mic_rounded, color: Colors.white, size: 36),
            ),
            const SizedBox(height: 24),
            Text('Voice-to-Order', style: PSText.title()),
            const SizedBox(height: 8),
            Text('Phase 4 — AI voice recognition', style: PSText.body(color: PSColors.textDark2)),
          ],
        ),
      ),
    );
  }
}
