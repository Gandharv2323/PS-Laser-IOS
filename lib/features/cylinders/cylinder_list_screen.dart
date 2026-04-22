import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/services/firestore_service.dart';
import '../../core/theme/app_theme.dart';
import '../widgets/stat_card.dart';

class CylinderListScreen extends StatefulWidget {
  const CylinderListScreen({super.key});
  @override
  State<CylinderListScreen> createState() => _CylinderListScreenState();
}

class _CylinderListScreenState extends State<CylinderListScreen> {
  List<Map<String, dynamic>> _cylinders = [];
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
    final snap = await FirestoreService.cylinders.orderBy('gas_type').get();
    if (!mounted) return;
    setState(() {
      _cylinders = snap.docs.map(FirestoreService.docToMap).toList();
      _loading = false;
    });
  }

  List<Map<String, dynamic>> get _filtered => _filter == 'ALL'
      ? _cylinders
      : _cylinders
            .where((c) => c['status'] == _filter || c['gas_type'] == _filter)
            .toList();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Gas Cylinders'),
        actions: [
          IconButton(
            icon: const Icon(Icons.qr_code_scanner),
            onPressed: () => context.go('/cylinders/qr-scan'),
            tooltip: 'QR Scan',
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                SizedBox(
                  height: 44,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    children:
                        [
                              'ALL',
                              'FULL',
                              'IN_USE',
                              'EMPTY',
                              'Nitrogen',
                              'Oxygen',
                              'CO2',
                            ]
                            .map(
                              (s) => Padding(
                                padding: const EdgeInsets.only(right: 8),
                                child: FilterChip(
                                  label: Text(s.replaceAll('_', ' ')),
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
                    child: ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: _filtered.length,
                      itemBuilder: (_, i) =>
                          _CylinderCard(cylinder: _filtered[i]),
                    ),
                  ),
                ),
              ],
            ),
    );
  }
}

class _CylinderCard extends StatelessWidget {
  final Map<String, dynamic> cylinder;
  const _CylinderCard({required this.cylinder});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final status = cylinder['status'] as String;
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      child: InkWell(
        onTap: () => context.go('/cylinders/detail/${cylinder['id']}'),
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: isDark ? AppTheme.darkCard : Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isDark ? AppTheme.darkBorder : const Color(0xFFE5E7EB),
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: _gasColor(
                    cylinder['gas_type'] as String,
                  ).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.gas_meter_outlined,
                  color: _gasColor(cylinder['gas_type'] as String),
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            cylinder['serial_no'] as String,
                            style: GoogleFonts.inter(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: isDark
                                  ? Colors.white
                                  : const Color(0xFF111827),
                            ),
                          ),
                        ),
                        StatusBadge(status: status),
                      ],
                    ),
                    Text(
                      '${cylinder['gas_type']} • ${cylinder['capacity']} L',
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFF6B7280),
                      ),
                    ),
                    Text(
                      cylinder['current_location'] as String? ?? '',
                      style: const TextStyle(
                        fontSize: 11,
                        color: Color(0xFF6B7280),
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right, color: Color(0xFF6B7280)),
            ],
          ),
        ),
      ),
    );
  }

  Color _gasColor(String gas) {
    switch (gas) {
      case 'Nitrogen':
        return const Color(0xFF1565C0);
      case 'Oxygen':
        return const Color(0xFF00838F);
      case 'CO2':
        return const Color(0xFF7C3AED);
      case 'Argon':
        return const Color(0xFF00C853);
      default:
        return const Color(0xFF6B7280);
    }
  }
}

class CylinderDetailScreen extends StatefulWidget {
  final String cylinderId;
  const CylinderDetailScreen({super.key, required this.cylinderId});
  @override
  State<CylinderDetailScreen> createState() => _CylinderDetailScreenState();
}

class _CylinderDetailScreenState extends State<CylinderDetailScreen> {
  Map<String, dynamic>? _cylinder;
  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    if (!mounted) return;
    final doc = await FirestoreService.cylinders.doc(widget.cylinderId).get();
    if (doc.exists && mounted) setState(() => _cylinder = FirestoreService.docToMap(doc));
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    if (_cylinder == null) {
      return Scaffold(
        appBar: AppBar(),
        body: const Center(child: CircularProgressIndicator()),
      );
    }
    return Scaffold(
      appBar: AppBar(
        title: Text(_cylinder!['serial_no'] as String),
        leading: BackButton(onPressed: () => context.go('/cylinders')),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF1565C0), Color(0xFF1976D2)],
                ),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        _cylinder!['gas_type'] as String,
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 13,
                        ),
                      ),
                      StatusBadge(status: _cylinder!['status'] as String),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '${_cylinder!['serial_no']}',
                    style: GoogleFonts.inter(
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                    ),
                  ),
                  Text(
                    'Capacity: ${_cylinder!['capacity']} L',
                    style: const TextStyle(color: Colors.white70, fontSize: 13),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: isDark ? AppTheme.darkCard : Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isDark ? AppTheme.darkBorder : const Color(0xFFE5E7EB),
                ),
              ),
              child: Column(
                children: [
                  _buildRow(
                    'Last Refill',
                    _cylinder!['last_refill_date'] ?? 'N/A',
                    isDark,
                  ),
                  _buildRow(
                    'Current Location',
                    _cylinder!['current_location'] ?? 'N/A',
                    isDark,
                  ),
                  _buildRow('Gas Type', _cylinder!['gas_type'] ?? '', isDark),
                  _buildRow('Status', _cylinder!['status'] ?? '', isDark),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {},
                    icon: const Icon(Icons.refresh, size: 16),
                    label: const Text('Log Refill'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => context.go('/cylinders/qr-scan'),
                    icon: const Icon(Icons.qr_code_scanner, size: 16),
                    label: const Text('Scan QR'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRow(String label, String value, bool isDark) => Padding(
    padding: const EdgeInsets.only(bottom: 10),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 13, color: Color(0xFF6B7280)),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: isDark ? Colors.white : const Color(0xFF111827),
          ),
        ),
      ],
    ),
  );
}

class CylinderQrScanScreen extends StatelessWidget {
  const CylinderQrScanScreen({super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: const Text('QR Scan — Cylinders'),
        leading: BackButton(onPressed: () => context.go('/cylinders')),
      ),
      body: Stack(
        children: [
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 250,
                  height: 250,
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.white, width: 2),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Icon(
                    Icons.qr_code_scanner,
                    color: Colors.white38,
                    size: 80,
                  ),
                ),
                const SizedBox(height: 24),
                const Text(
                  'Point camera at cylinder QR code',
                  style: TextStyle(color: Colors.white70, fontSize: 14),
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: () => context.go('/cylinders/scan-success/1'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryBlue,
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('Simulate Scan Success'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class CylinderScanSuccessScreen extends StatelessWidget {
  final String cylinderId;
  const CylinderScanSuccessScreen({super.key, required this.cylinderId});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Scan Result')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: AppTheme.statusRunning.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.check_circle,
                  color: AppTheme.statusRunning,
                  size: 48,
                ),
              ),
              const SizedBox(height: 20),
              Text(
                'Cylinder Identified!',
                style: GoogleFonts.inter(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'CYL-N2-001 • Nitrogen • FULL',
                style: TextStyle(color: Color(0xFF6B7280), fontSize: 14),
              ),
              const SizedBox(height: 32),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () =>
                          context.go('/cylinders/detail/$cylinderId'),
                      child: const Text('View Details'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () {},
                      child: const Text('Log Refill'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              TextButton(
                onPressed: () => context.go('/cylinders'),
                child: const Text('Back to List'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
