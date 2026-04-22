import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../core/services/firestore_service.dart';
import '../../core/providers/session_provider.dart';
import '../../core/providers/theme_provider.dart';
import '../../core/theme/app_theme.dart';
import '../widgets/stat_card.dart';
import '../widgets/alert_banner.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});
  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  Map<String, dynamic> _stats = {};
  List<Map<String, dynamic>> _alerts = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    if (!mounted) return;
    setState(() => _loading = true);
    final today = DateTime.now().toString().substring(0, 10);

    // Helper: safely get count from a query, returns 0 on any error
    Future<int> safeCount(Future<AggregateQuerySnapshot> query) async {
      try {
        final snap = await query.timeout(const Duration(seconds: 10));
        return snap.count ?? 0;
      } catch (_) {
        return 0;
      }
    }

    // Run all counts independently — one failure won't block others
    final present = await safeCount(FirestoreService.attendance
        .where('date', isEqualTo: today)
        .where('status', isEqualTo: 'PRESENT')
        .count()
        .get());

    final total = await safeCount(
        FirestoreService.employees.where('is_active', isEqualTo: 1).count().get());

    final machinesRunning = await safeCount(
        FirestoreService.machines.where('status', isEqualTo: 'RUNNING').count().get());

    final machinesTotal =
        await safeCount(FirestoreService.machines.count().get());

    final woOpen = await safeCount(FirestoreService.workOrders
        .where('status', whereIn: ['PENDING', 'IN_PROGRESS'])
        .count()
        .get());

    final alertsCritical = await safeCount(FirestoreService.alerts
        .where('is_resolved', isEqualTo: 0)
        .where('severity', isEqualTo: 'CRITICAL')
        .count()
        .get());

    final woHigh = await safeCount(FirestoreService.workOrders
        .where('priority', isEqualTo: 'HIGH')
        .where('status', whereIn: ['PENDING', 'IN_PROGRESS'])
        .count()
        .get());

    // Recent alerts (requires composite index — safe fallback)
    List<Map<String, dynamic>> alerts = [];
    try {
      final alertSnap = await FirestoreService.alerts
          .where('is_resolved', isEqualTo: 0)
          .orderBy('triggered_at', descending: true)
          .limit(5)
          .get()
          .timeout(const Duration(seconds: 10));
      alerts = alertSnap.docs.map(FirestoreService.docToMap).toList();
    } catch (_) {}

    if (!mounted) return;
    setState(() {
      _stats = {
        'present': present,
        'total': total,
        'machinesRunning': machinesRunning,
        'machinesTotal': machinesTotal,
        'woOpen': woOpen,
        'woHigh': woHigh,
        'alertsCritical': alertsCritical,
      };
      _alerts = alerts;
      _loading = false;
    });
  }


  @override
  Widget build(BuildContext context) {
    final session = context.watch<SessionProvider>().session;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final themeProvider = context.read<ThemeProvider>();
    final now = DateTime.now();
    final dateStr = '${_monthName(now.month)} ${now.day}';

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'ForgeOps',
              style: GoogleFonts.inter(
                fontSize: 20,
                fontWeight: FontWeight.w800,
              ),
            ),
            Text(
              dateStr,
              style: GoogleFonts.inter(
                fontSize: 12,
                color: const Color(0xFF6B7280),
                fontWeight: FontWeight.w400,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: Icon(
              isDark ? Icons.light_mode_outlined : Icons.dark_mode_outlined,
            ),
            onPressed: () => themeProvider.toggleTheme(),
          ),
          IconButton(
            icon: Stack(
              children: [
                const Icon(Icons.notifications_outlined),
                if ((_stats['alertsCritical'] ?? 0) > 0)
                  Positioned(
                    right: 0,
                    top: 0,
                    child: Container(
                      width: 8,
                      height: 8,
                      decoration: const BoxDecoration(
                        color: AppTheme.accentRed,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
              ],
            ),
            onPressed: () => context.go('/alerts'),
          ),
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: GestureDetector(
              onTap: () => context.go('/settings'),
              child: CircleAvatar(
                radius: 18,
                backgroundColor: const Color(0xFF1565C0).withValues(alpha: 0.2),
                child: Text(
                  session.userName.isNotEmpty ? session.userName[0] : 'U',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF1565C0),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadData,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Greeting
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF1565C0), Color(0xFF1976D2)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '${_greeting(now.hour)} 👋',
                                  style: GoogleFonts.inter(
                                    fontSize: 13,
                                    color: Colors.white70,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  session.userName,
                                  style: GoogleFonts.inter(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w700,
                                    color: Colors.white,
                                  ),
                                ),
                                Text(
                                  '${session.role.name.toUpperCase()} • ${session.department}',
                                  style: GoogleFonts.inter(
                                    fontSize: 11,
                                    color: Colors.white60,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(
                              Icons.precision_manufacturing_rounded,
                              color: Colors.white,
                              size: 28,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Stats grid
                    Text(
                      'FLOOR SUMMARY',
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF6B7280),
                        letterSpacing: 1.0,
                      ),
                    ),
                    const SizedBox(height: 12),
                    GridView.count(
                      crossAxisCount: 2,
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                      childAspectRatio: 1.6,
                      children: [
                        StatCard(
                          title: 'Workers Present',
                          value: '${_stats['present']} / ${_stats['total']}',
                          icon: Icons.people_outline,
                          color: AppTheme.statusRunning,
                          onTap: () => context.go('/attendance'),
                        ),
                        StatCard(
                          title: 'Machines Running',
                          value:
                              '${_stats['machinesRunning']} / ${_stats['machinesTotal']}',
                          icon: Icons.memory_outlined,
                          color: AppTheme.primaryBlue,
                          onTap: () => context.go('/machines'),
                        ),
                        StatCard(
                          title: 'Open Work Orders',
                          value:
                              '${_stats['woOpen']} (${_stats['woHigh']} HIGH)',
                          icon: Icons.assignment_outlined,
                          color: AppTheme.accentOrange,
                          onTap: () => context.go('/work-orders'),
                        ),
                        StatCard(
                          title: 'Active Alerts',
                          value: '${_stats['alertsCritical']} Critical',
                          icon: Icons.warning_amber_outlined,
                          color: AppTheme.accentRed,
                          onTap: () => context.go('/alerts'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),

                    // Quick actions
                    Text(
                      'QUICK ACTIONS',
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF6B7280),
                        letterSpacing: 1.0,
                      ),
                    ),
                    const SizedBox(height: 12),
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          _QuickAction(
                            icon: Icons.qr_code_scanner,
                            label: 'QR Check-in',
                            onTap: () => context.go('/attendance/qr-checkin'),
                          ),
                          const SizedBox(width: 12),
                          _QuickAction(
                            icon: Icons.add_circle_outline,
                            label: 'New Work Order',
                            onTap: () => context.go('/work-orders/create'),
                          ),
                          const SizedBox(width: 12),
                          _QuickAction(
                            icon: Icons.inventory_2_outlined,
                            label: 'Inventory',
                            onTap: () => context.go('/inventory'),
                          ),
                          const SizedBox(width: 12),
                          _QuickAction(
                            icon: Icons.analytics_outlined,
                            label: 'Reports',
                            onTap: () => context.go('/reports'),
                          ),
                          const SizedBox(width: 12),
                          _QuickAction(
                            icon: Icons.gas_meter_outlined,
                            label: 'Cylinders',
                            onTap: () => context.go('/cylinders'),
                          ),
                          const SizedBox(width: 12),
                          _QuickAction(
                            icon: Icons.calendar_today_outlined,
                            label: 'Leave',
                            onTap: () => context.go('/leave'),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Active alerts
                    if (_alerts.isNotEmpty) ...[
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'ACTIVE ALERTS',
                            style: GoogleFonts.inter(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: const Color(0xFF6B7280),
                              letterSpacing: 1.0,
                            ),
                          ),
                          TextButton(
                            onPressed: () => context.go('/alerts'),
                            child: const Text(
                              'See all',
                              style: TextStyle(fontSize: 12),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      ..._alerts.map((a) => AlertBanner(alert: a)),
                    ],

                    const SizedBox(height: 80),
                  ],
                ),
              ),
            ),
    );
  }

  String _greeting(int hour) {
    if (hour < 12) return 'Good Morning';
    if (hour < 17) return 'Good Afternoon';
    return 'Good Evening';
  }

  String _monthName(int m) => [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ][m - 1];
}

class _QuickAction extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  const _QuickAction({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        width: 80,
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        decoration: BoxDecoration(
          color: isDark ? AppTheme.darkCard : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isDark ? AppTheme.darkBorder : const Color(0xFFE5E7EB),
          ),
        ),
        child: Column(
          children: [
            Icon(icon, size: 24, color: AppTheme.primaryBlue),
            const SizedBox(height: 6),
            Text(
              label,
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                fontSize: 10,
                fontWeight: FontWeight.w600,
                color: isDark
                    ? const Color(0xFFD1D5DB)
                    : const Color(0xFF374151),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
