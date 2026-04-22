import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/services/firestore_service.dart';
import '../../core/theme/app_theme.dart';
import '../widgets/alert_banner.dart';

class AlertsScreen extends StatefulWidget {
  const AlertsScreen({super.key});
  @override
  State<AlertsScreen> createState() => _AlertsScreenState();
}

class _AlertsScreenState extends State<AlertsScreen> {
  List<Map<String, dynamic>> _alerts = [];
  String _filter = 'ALL';
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    if (!mounted) return;
    setState(() => _loading = true);
    final snap = await FirestoreService.alerts
        .orderBy('triggered_at', descending: true)
        .get();
    if (!mounted) return;
    setState(() {
      _alerts = snap.docs.map(FirestoreService.docToMap).toList();
      _loading = false;
    });
  }

  Future<void> _resolve(String id) async {
    await FirestoreService.alerts.doc(id).update({'is_resolved': 1});
    await _load();
  }

  List<Map<String, dynamic>> get _filtered {
    if (_filter == 'ALL') return _alerts;
    if (_filter == 'ACTIVE') {
      return _alerts.where((a) => a['is_resolved'] == 0).toList();
    }
    if (_filter == 'RESOLVED') {
      return _alerts.where((a) => a['is_resolved'] == 1).toList();
    }
    return _alerts.where((a) => a['severity'] == _filter).toList();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final active = _alerts.where((a) => a['is_resolved'] == 0).length;
    final critical = _alerts
        .where((a) => a['severity'] == 'CRITICAL' && a['is_resolved'] == 0)
        .length;

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            const Text('Alerts'),
            if (active > 0) ...[
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: AppTheme.accentRed,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '$active',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () async {
              final unresolvedSnap = await FirestoreService.alerts
                  .where('is_resolved', isEqualTo: 0).get();
              for (final doc in unresolvedSnap.docs) {
                await doc.reference.update({'is_resolved': 1});
              }
              _load();
            },
            child: const Text(
              'Clear All',
              style: TextStyle(color: AppTheme.accentOrange),
            ),
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                if (critical > 0)
                  Container(
                    margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppTheme.accentRed.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: AppTheme.accentRed.withValues(alpha: 0.3),
                      ),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.crisis_alert,
                          color: AppTheme.accentRed,
                          size: 24,
                        ),
                        const SizedBox(width: 12),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '$critical Critical Alert${critical > 1 ? 's' : ''} Active',
                              style: GoogleFonts.inter(
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                                color: AppTheme.accentRed,
                              ),
                            ),
                            const Text(
                              'Immediate attention required.',
                              style: TextStyle(
                                fontSize: 12,
                                color: Color(0xFF6B7280),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                SizedBox(
                  height: 44,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    children:
                        ['ALL', 'ACTIVE', 'RESOLVED', 'CRITICAL', 'WARNING']
                            .map(
                              (s) => Padding(
                                padding: const EdgeInsets.only(right: 8),
                                child: FilterChip(
                                  label: Text(s),
                                  selected: _filter == s,
                                  onSelected: (_) =>
                                      setState(() => _filter = s),
                                  selectedColor: AppTheme.primaryBlue
                                      .withValues(alpha: 0.15),
                                  checkmarkColor: AppTheme.primaryBlue,
                                ),
                              ),
                            )
                            .toList(),
                  ),
                ),
                Expanded(
                  child: RefreshIndicator(
                    onRefresh: _load,
                    child: _filtered.isEmpty
                        ? const Center(
                            child: Text(
                              'No alerts',
                              style: TextStyle(color: Color(0xFF6B7280)),
                            ),
                          )
                        : ListView.builder(
                            padding: const EdgeInsets.all(16),
                            itemCount: _filtered.length,
                            itemBuilder: (_, i) {
                              final alert = _filtered[i];
                              final resolved = alert['is_resolved'] == 1;
                              return Opacity(
                                opacity: resolved ? 0.5 : 1.0,
                                child: Stack(
                                  children: [
                                    AlertBanner(alert: alert),
                                    if (!resolved)
                                      Positioned(
                                        top: 6,
                                        right: 6,
                                        child: GestureDetector(
                                          onTap: () =>
                                              _resolve(alert['id'] as String),
                                          child: Container(
                                            padding: const EdgeInsets.all(4),
                                            decoration: BoxDecoration(
                                              color: isDark
                                                  ? const Color(0xFF2A3547)
                                                  : const Color(0xFFF3F4F6),
                                              shape: BoxShape.circle,
                                            ),
                                            child: const Icon(
                                              Icons.check,
                                              size: 14,
                                              color: Color(0xFF6B7280),
                                            ),
                                          ),
                                        ),
                                      ),
                                  ],
                                ),
                              );
                            },
                          ),
                  ),
                ),
              ],
            ),
    );
  }
}
