import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/theme/app_theme.dart';

/// Reusable empty state widget used across list screens
/// when there is no data to display.
class EmptyStateWidget extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final String? actionLabel;
  final VoidCallback? onAction;

  const EmptyStateWidget({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    this.actionLabel,
    this.onAction,
  });

  // ── Convenience constructors for common cases ─────────────────────────────

  const EmptyStateWidget.clients({super.key, VoidCallback? onAdd})
      : icon = Icons.people_outline,
        title = 'No Clients Yet',
        subtitle = 'Add your first client to start tracking orders and relationships.',
        actionLabel = 'Add Client',
        onAction = onAdd;

  const EmptyStateWidget.orders({super.key, VoidCallback? onAdd})
      : icon = Icons.work_outline,
        title = 'No Work Orders',
        subtitle = 'Create a work order to begin tracking production progress.',
        actionLabel = 'Create Order',
        onAction = onAdd;

  const EmptyStateWidget.payroll({super.key, VoidCallback? onGenerate})
      : icon = Icons.payments_outlined,
        title = 'No Payroll Records',
        subtitle = 'Generate payroll for this month to see records here.',
        actionLabel = 'Generate Payroll',
        onAction = onGenerate;

  const EmptyStateWidget.search({super.key})
      : icon = Icons.search_off_rounded,
        title = 'No Results Found',
        subtitle = 'Try a different search term or clear the filter.',
        actionLabel = null,
        onAction = null;

  const EmptyStateWidget.generic({super.key})
      : icon = Icons.inbox_outlined,
        title = 'Nothing Here Yet',
        subtitle = 'Add some data to get started.',
        actionLabel = null,
        onAction = null;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Icon container
            Container(
              width: 88,
              height: 88,
              decoration: BoxDecoration(
                color: AppTheme.primaryBlue.withValues(alpha: 0.08),
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                size: 44,
                color: AppTheme.primaryBlue.withValues(alpha: 0.5),
              ),
            ),
            const SizedBox(height: 20),

            // Title
            Text(
              title,
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: isDark ? Colors.white : const Color(0xFF111827),
              ),
            ),
            const SizedBox(height: 8),

            // Subtitle
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                fontSize: 13,
                color: const Color(0xFF6B7280),
                height: 1.5,
              ),
            ),

            // Action button
            if (actionLabel != null && onAction != null) ...[
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: onAction,
                icon: const Icon(Icons.add, size: 16),
                label: Text(
                  actionLabel!,
                  style: GoogleFonts.inter(fontWeight: FontWeight.w600),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryBlue,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                      horizontal: 24, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
