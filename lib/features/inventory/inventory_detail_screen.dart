import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/services/firestore_service.dart';
import '../../core/theme/app_theme.dart';
import '../widgets/stat_card.dart';

class InventoryDetailScreen extends StatefulWidget {
  final String itemId;
  const InventoryDetailScreen({super.key, required this.itemId});
  @override
  State<InventoryDetailScreen> createState() => _InventoryDetailScreenState();
}

class _InventoryDetailScreenState extends State<InventoryDetailScreen> {
  Map<String, dynamic>? _item;
  List<Map<String, dynamic>> _transactions = [];
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    if (!mounted) return;
    try {
      final doc =
          await FirestoreService.inventory.doc(widget.itemId).get();
      if (!mounted) return;
      if (!doc.exists) {
        setState(() => _error = 'Item not found (id: ${widget.itemId})');
        return;
      }
      // Load item first — always works
      final itemData = FirestoreService.docToMap(doc);

      // Load transactions separately — needs Firestore composite index
      List<Map<String, dynamic>> txns = [];
      try {
        final txnSnap = await FirestoreService.inventoryTransactions
            .where('item_id', isEqualTo: widget.itemId)
            .orderBy('created_at', descending: true)
            .limit(10)
            .get();
        txns = txnSnap.docs.map(FirestoreService.docToMap).toList();
      } catch (_) {
        // Index not yet created — transactions show as empty
      }

      if (!mounted) return;
      setState(() {
        _item = itemData;
        _transactions = txns;
      });
    } catch (e) {
      if (mounted) setState(() => _error = 'Error loading item: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    // ── Error state ─────────────────────────────────────────────────────────
    if (_error != null) {
      return Scaffold(
        appBar: AppBar(
          leading: BackButton(onPressed: () => context.go('/inventory')),
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.error_outline, size: 48, color: Colors.red),
                const SizedBox(height: 16),
                Text(
                  _error!,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.red),
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: () => context.go('/inventory'),
                  child: const Text('Back to Inventory'),
                ),
              ],
            ),
          ),
        ),
      );
    }
    // ── Loading state ────────────────────────────────────────────────────────
    if (_item == null) {
      return Scaffold(
        appBar: AppBar(
          leading: BackButton(onPressed: () => context.go('/inventory')),
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    final isLow =
        (_item!['current_qty'] as num) <= (_item!['reorder_level'] as num);

    return Scaffold(
      appBar: AppBar(
        title: Text(_item!['name'] as String),
        leading: BackButton(onPressed: () => context.go('/inventory')),
        actions: [
          IconButton(icon: const Icon(Icons.edit_outlined), onPressed: () {}),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: isLow
                      ? [AppTheme.accentRed, const Color(0xFFEF5350)]
                      : [AppTheme.primaryBlue, AppTheme.primaryLight],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
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
                        _item!['sku'] as String,
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 13,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          _item!['category'] as String,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    '${_item!['current_qty']} ${_item!['unit']}',
                    style: GoogleFonts.inter(
                      fontSize: 36,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                    ),
                  ),
                  Text(
                    'In Stock',
                    style: const TextStyle(color: Colors.white70, fontSize: 13),
                  ),
                  if (isLow) ...[
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Text(
                        '⚠ Below Reorder Level',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: StatCard(
                    title: 'Reorder At',
                    value: '${_item!['reorder_level']} ${_item!['unit']}',
                    icon: Icons.trending_down,
                    color: AppTheme.accentOrange,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: StatCard(
                    title: 'Location',
                    value: _item!['location'] as String? ?? 'N/A',
                    icon: Icons.location_on_outlined,
                    color: AppTheme.primaryBlue,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Text(
              'LOG TRANSACTION',
              style: GoogleFonts.inter(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF6B7280),
                letterSpacing: 1.0,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => context.go('/inventory/log-transaction'),
                    icon: const Icon(Icons.remove_circle_outline, size: 18),
                    label: const Text('Use / Remove'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.accentOrange,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => context.go('/inventory/receive-stock'),
                    icon: const Icon(Icons.add_circle_outline, size: 18),
                    label: const Text('Receive Stock'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.statusRunning,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Text(
              'TRANSACTION HISTORY',
              style: GoogleFonts.inter(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF6B7280),
                letterSpacing: 1.0,
              ),
            ),
            const SizedBox(height: 12),
            if (_transactions.isEmpty)
              const Center(
                child: Text(
                  'No transactions yet',
                  style: TextStyle(color: Color(0xFF6B7280)),
                ),
              )
            else
              ..._transactions.map((t) => _TxnTile(txn: t)),
          ],
        ),
      ),
    );
  }
}

class _TxnTile extends StatelessWidget {
  final Map<String, dynamic> txn;
  const _TxnTile({required this.txn});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final type = txn['transaction_type'] as String;
    final isAdd = type == 'ADD';
    final color = isAdd ? AppTheme.statusRunning : AppTheme.accentRed;
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.darkCard : Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: isDark ? AppTheme.darkBorder : const Color(0xFFE5E7EB),
        ),
      ),
      child: Row(
        children: [
          Icon(
            isAdd ? Icons.add_circle : Icons.remove_circle,
            color: color,
            size: 20,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$type • ${txn['qty']} units',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: isDark ? Colors.white : const Color(0xFF111827),
                  ),
                ),
                Text(
                  txn['reference'] ?? '',
                  style: const TextStyle(
                    fontSize: 11,
                    color: Color(0xFF6B7280),
                  ),
                ),
              ],
            ),
          ),
          Text(
            txn['created_at']?.toString().substring(0, 10) ?? '',
            style: const TextStyle(fontSize: 11, color: Color(0xFF6B7280)),
          ),
        ],
      ),
    );
  }
}
