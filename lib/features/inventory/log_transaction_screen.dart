import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/services/firestore_service.dart';
import '../../core/services/notification_service.dart';
import '../../core/theme/app_theme.dart';


// Log Transaction Screen
class LogTransactionScreen extends StatefulWidget {
  const LogTransactionScreen({super.key});
  @override
  State<LogTransactionScreen> createState() => _LogTransactionScreenState();
}

class _LogTransactionScreenState extends State<LogTransactionScreen> {
  final _formKey = GlobalKey<FormState>();
  final _qtyCtrl = TextEditingController();
  final _refCtrl = TextEditingController();
  List<Map<String, dynamic>> _items = [];
  String? _selectedItem;
  String _type = 'USE';
  bool _saving = false;
  String? _warning;

  final _types = ['USE', 'REMOVE', 'ADD', 'ADJUST', 'TRANSFER'];

  @override
  void initState() {
    super.initState();
    _loadItems();
  }

  Future<void> _loadItems() async {
    final snap = await FirestoreService.inventory.orderBy('name').get();
    if (mounted) {
      setState(() {
        _items = snap.docs.map(FirestoreService.docToMap).toList();
        if (_items.isNotEmpty) _selectedItem = _items.first['id'] as String;
      });
    }
  }

  Future<void> _validate() async {
    if (_selectedItem == null || _qtyCtrl.text.isEmpty) return;
    final qty = double.tryParse(_qtyCtrl.text) ?? 0;
    if (_type == 'USE' || _type == 'REMOVE') {
      final doc = await FirestoreService.inventory.doc(_selectedItem).get();
      if (doc.exists) {
        final item = FirestoreService.docToMap(doc);
        final currentQty = (item['current_qty'] as num).toDouble();
        final reorderLevel = (item['reorder_level'] as num).toDouble();
        if (qty > currentQty) {
          setState(() => _warning = 'Only $currentQty ${item['unit']} in stock. Requested: $qty');
        } else if ((currentQty - qty) < reorderLevel) {
          setState(() => _warning = 'This will bring stock below reorder level ($reorderLevel ${item['unit']}).');
        } else {
          setState(() => _warning = null);
        }
      }
    } else {
      setState(() => _warning = null);
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    if (_warning != null && _warning!.contains('Only')) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_warning!), backgroundColor: AppTheme.accentRed),
      );
      return;
    }
    setState(() => _saving = true);
    final qty = double.tryParse(_qtyCtrl.text) ?? 0;
    // Log the transaction
    await FirestoreService.inventoryTransactions.add({
      'item_id': _selectedItem,
      'transaction_type': _type,
      'qty': qty,
      'reference': _refCtrl.text,
      'created_at': DateTime.now().toIso8601String(),
    });
    // Update current_qty on the inventory item
    final doc = await FirestoreService.inventory.doc(_selectedItem).get();
    if (doc.exists) {
      final item = FirestoreService.docToMap(doc);
      double newQty = (item['current_qty'] as num).toDouble();
      if (_type == 'USE' || _type == 'REMOVE') {
        newQty -= qty;
      } else if (_type == 'ADD') {
        newQty += qty;
      } else if (_type == 'ADJUST') {
        newQty = qty;
      }
      await FirestoreService.inventory.doc(_selectedItem).update({
        'current_qty': newQty,
        'last_transaction_date': DateTime.now().toString().substring(0, 10),
      });
      // 🔔 Fire low-stock push alert if below reorder level
      final reorderLevel = (item['reorder_level'] as num? ?? 0).toDouble();
      if (newQty <= reorderLevel) {
        final itemName = item['name'] as String? ?? 'Item';
        await NotificationService.triggerAlert(
          title: '⚠️ Low Stock Alert',
          body: '$itemName is at ${newQty.toStringAsFixed(0)} ${item['unit'] ?? 'units'} '
              '(reorder level: ${reorderLevel.toStringAsFixed(0)}). Reorder immediately.',
          type: 'LOW_STOCK',
          route: '/inventory',
          relatedId: _selectedItem,
        );
      }
    }
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Transaction logged.')));
      context.go('/inventory');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Log Transaction'),
        leading: BackButton(onPressed: () => context.go('/inventory')),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _label('Item'),
              const SizedBox(height: 8),
              if (_items.isNotEmpty)
                DropdownButtonFormField<String>(
                  value: _selectedItem,
                  onChanged: (v) => setState(() => _selectedItem = v),
                  decoration: _inputDec(context),
                  items: _items
                      .map(
                        (i) => DropdownMenuItem(
                          value: i['id'] as String,
                          child: Text(i['name'] as String),
                        ),
                      )
                      .toList(),
                ),
              const SizedBox(height: 16),
              _label('Transaction Type'),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                initialValue: _type,
                onChanged: (v) => setState(() => _type = v!),
                decoration: _inputDec(context),
                items: _types
                    .map((t) => DropdownMenuItem(value: t, child: Text(t)))
                    .toList(),
              ),
              const SizedBox(height: 16),
              _label('Quantity'),
              const SizedBox(height: 8),
              TextFormField(
                controller: _qtyCtrl,
                keyboardType: TextInputType.number,
                onChanged: (_) => _validate(),
                decoration: _inputDec(context).copyWith(hintText: '0'),
                validator: (v) => v?.isEmpty ?? true ? 'Required' : null,
              ),
              if (_warning != null) ...[
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color:
                        (_warning!.contains('Only')
                                ? AppTheme.accentRed
                                : AppTheme.accentYellow)
                            .withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color:
                          (_warning!.contains('Only')
                                  ? AppTheme.accentRed
                                  : AppTheme.accentYellow)
                              .withValues(alpha: 0.3),
                    ),
                  ),
                  child: Text(
                    _warning!,
                    style: TextStyle(
                      fontSize: 12,
                      color: _warning!.contains('Only')
                          ? AppTheme.accentRed
                          : AppTheme.accentYellow,
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 16),
              _label('Reference / Note'),
              const SizedBox(height: 8),
              TextFormField(
                controller: _refCtrl,
                decoration: _inputDec(
                  context,
                ).copyWith(hintText: 'e.g. WO-1042'),
              ),
              const SizedBox(height: 28),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _saving ? null : _save,
                  child: _saving
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : const Text('Log Transaction'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _label(String t) => Text(
    t,
    style: GoogleFonts.inter(
      fontSize: 13,
      fontWeight: FontWeight.w600,
      color: Theme.of(context).brightness == Brightness.dark
          ? const Color(0xFFD1D5DB)
          : const Color(0xFF374151),
    ),
  );
  InputDecoration _inputDec(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return InputDecoration(
      filled: true,
      fillColor: isDark ? const Color(0xFF0A0E1A) : const Color(0xFFF9FAFB),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide(
          color: isDark ? AppTheme.darkBorder : const Color(0xFFE5E7EB),
        ),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide(
          color: isDark ? AppTheme.darkBorder : const Color(0xFFE5E7EB),
        ),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
    );
  }
}

// Receive Stock Screen
class ReceiveStockScreen extends StatelessWidget {
  const ReceiveStockScreen({super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Receive Stock'),
        leading: BackButton(onPressed: () => context.go('/inventory')),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF00838F), Color(0xFF00ACC1)],
                ),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.local_shipping_outlined,
                    color: Colors.white,
                    size: 32,
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Receive Stock',
                        style: GoogleFonts.inter(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                      Text(
                        'Record incoming inventory',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          color: Colors.white70,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Feature coming soon...',
              style: TextStyle(color: Color(0xFF6B7280)),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => context.go('/inventory'),
                child: const Text('Back to Inventory'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
