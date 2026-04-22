import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/services/firestore_service.dart';
import '../../core/theme/app_theme.dart';

class InventoryListScreen extends StatefulWidget {
  const InventoryListScreen({super.key});
  @override
  State<InventoryListScreen> createState() => _InventoryListScreenState();
}

class _InventoryListScreenState extends State<InventoryListScreen> {
  List<Map<String, dynamic>> _items = [];
  List<Map<String, dynamic>> _filtered = [];
  bool _loading = true;
  String _search = '';
  String _filter = 'ALL';

  final _filters = [
    'ALL',
    'LOW_STOCK',
    'Gas',
    'Optics',
    'Consumables',
    'Raw Material',
  ];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    if (!mounted) return;
    setState(() => _loading = true);
    final snap = await FirestoreService.inventory.orderBy('name').get();
    if (!mounted) return;
    setState(() {
      _items = snap.docs.map(FirestoreService.docToMap).toList();
      _applyFilter();
      _loading = false;
    });
  }

  void _applyFilter() {
    _filtered = _items.where((item) {
      final matchesSearch =
          _search.isEmpty ||
          (item['name'] as String).toLowerCase().contains(
            _search.toLowerCase(),
          );
      final matchesFilter = _filter == 'ALL'
          ? true
          : _filter == 'LOW_STOCK'
          ? (item['current_qty'] as num) <= (item['reorder_level'] as num)
          : item['category'] == _filter;
      return matchesSearch && matchesFilter;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final lowStockCount = _items
        .where((i) => (i['current_qty'] as num) <= (i['reorder_level'] as num))
        .length;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Inventory'),
        actions: [
          IconButton(
            icon: const Icon(Icons.qr_code_outlined),
            onPressed: () => context.go('/inventory/qr-scan'),
          ),
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => context.go('/inventory/add'),
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                if (lowStockCount > 0)
                  Container(
                    margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: AppTheme.accentRed.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: AppTheme.accentRed.withValues(alpha: 0.3),
                      ),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.warning_amber_rounded,
                          color: AppTheme.accentRed,
                          size: 18,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '$lowStockCount item(s) below reorder level',
                          style: GoogleFonts.inter(
                            fontSize: 13,
                            color: AppTheme.accentRed,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                  child: TextField(
                    onChanged: (v) => setState(() {
                      _search = v;
                      _applyFilter();
                    }),
                    decoration: InputDecoration(
                      hintText: 'Search inventory...',
                      prefixIcon: const Icon(Icons.search, size: 18),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 10,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide(
                          color: isDark
                              ? AppTheme.darkBorder
                              : const Color(0xFFE5E7EB),
                        ),
                      ),
                    ),
                  ),
                ),
                SizedBox(
                  height: 44,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    itemCount: _filters.length,
                    separatorBuilder: (_, _) => const SizedBox(width: 8),
                    itemBuilder: (_, i) {
                      final isSelected = _filter == _filters[i];
                      return FilterChip(
                        label: Text(_filters[i].replaceAll('_', ' ')),
                        selected: isSelected,
                        onSelected: (_) => setState(() {
                          _filter = _filters[i];
                          _applyFilter();
                        }),
                        selectedColor: AppTheme.primaryBlue.withValues(
                          alpha: 0.15,
                        ),
                        checkmarkColor: AppTheme.primaryBlue,
                      );
                    },
                  ),
                ),
                Expanded(
                  child: RefreshIndicator(
                    onRefresh: _load,
                    child: _filtered.isEmpty
                        ? const Center(child: Text('No items found'))
                        : ListView.builder(
                            padding: const EdgeInsets.all(16),
                            itemCount: _filtered.length,
                            itemBuilder: (_, i) =>
                                _InventoryCard(item: _filtered[i]),
                          ),
                  ),
                ),
              ],
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.go('/inventory/receive-stock'),
        icon: const Icon(Icons.add_box_outlined),
        label: const Text('Receive Stock'),
        backgroundColor: AppTheme.primaryBlue,
        foregroundColor: Colors.white,
      ),
    );
  }
}

class _InventoryCard extends StatelessWidget {
  final Map<String, dynamic> item;
  const _InventoryCard({required this.item});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isLow =
        (item['current_qty'] as num) <= (item['reorder_level'] as num);
    final pct =
        ((item['current_qty'] as num) /
                (((item['reorder_level'] as num) * 2).clamp(
                  1,
                  double.infinity,
                )))
            .clamp(0.0, 1.0)
            .toDouble();
    final color = isLow
        ? AppTheme.accentRed
        : pct < 0.5
        ? AppTheme.accentYellow
        : AppTheme.statusRunning;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.darkCard : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isLow
              ? AppTheme.accentRed.withValues(alpha: 0.4)
              : (isDark ? AppTheme.darkBorder : const Color(0xFFE5E7EB)),
        ),
      ),
      child: InkWell(
        onTap: () => context.go('/inventory/detail/${item['id']}'),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item['name'] as String,
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: isDark
                              ? Colors.white
                              : const Color(0xFF111827),
                        ),
                      ),
                      Text(
                        '${item['sku']} • ${item['category']}',
                        style: const TextStyle(
                          fontSize: 11,
                          color: Color(0xFF6B7280),
                        ),
                      ),
                    ],
                  ),
                ),
                if (isLow)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: AppTheme.accentRed.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      'LOW',
                      style: GoogleFonts.inter(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.accentRed,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: LinearProgressIndicator(
                    value: pct,
                    backgroundColor: isDark
                        ? const Color(0xFF2A3547)
                        : const Color(0xFFE5E7EB),
                    valueColor: AlwaysStoppedAnimation<Color>(color),
                    borderRadius: BorderRadius.circular(4),
                    minHeight: 6,
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  '${item['current_qty']} ${item['unit']}',
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: color,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              'Reorder at: ${item['reorder_level']} ${item['unit']}',
              style: const TextStyle(fontSize: 11, color: Color(0xFF6B7280)),
            ),
          ],
        ),
      ),
    );
  }
}
