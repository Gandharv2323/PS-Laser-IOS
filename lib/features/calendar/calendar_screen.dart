/// Calendar Screen — placeholder for Phase 5 build.
library;

import 'package:flutter/material.dart';
import '../../core/theme/ios_design_system.dart';

class CalendarScreen extends StatelessWidget {
  const CalendarScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      backgroundColor: isDark ? PSColors.darkBg : PSColors.lightBg,
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Calendar', style: PSText.title()),
            Text('Production Timeline', style: PSText.caption(color: PSColors.textDark3)),
          ],
        ),
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
              child: const Icon(Icons.calendar_month_rounded, color: Colors.white, size: 34),
            ),
            const SizedBox(height: 20),
            Text('Production Calendar', style: PSText.title()),
            const SizedBox(height: 8),
            Text('Phase 5 — table_calendar integration', style: PSText.body(color: PSColors.textDark2)),
          ],
        ),
      ),
    );
  }
}
