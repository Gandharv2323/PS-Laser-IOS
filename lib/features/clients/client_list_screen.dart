import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:share_plus/share_plus.dart';
import '../../core/services/firestore_service.dart';
import '../../core/theme/app_theme.dart';
import '../widgets/stat_card.dart';
import '../widgets/empty_state_widget.dart';

class ClientListScreen extends StatefulWidget {
  const ClientListScreen({super.key});
  @override
  State<ClientListScreen> createState() => _ClientListScreenState();
}

class _ClientListScreenState extends State<ClientListScreen> {
  List<Map<String, dynamic>> _clients = [];
  String _search = '';
  bool _loading = true;
  static const int _pageSize = 25;
  int _currentPage = 1;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _showAddClientDialog(BuildContext context) async {
    final nameCtrl = TextEditingController();
    final contactCtrl = TextEditingController();
    final emailCtrl = TextEditingController();
    final gstinCtrl = TextEditingController();
    final addressCtrl = TextEditingController();
    final formKey = GlobalKey<FormState>();

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Add Client'),
        content: SingleChildScrollView(
          child: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: nameCtrl,
                  decoration: const InputDecoration(labelText: 'Company Name *', border: OutlineInputBorder()),
                  validator: (v) => v?.isEmpty ?? true ? 'Required' : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: contactCtrl,
                  decoration: const InputDecoration(labelText: 'Contact / Phone', border: OutlineInputBorder()),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: emailCtrl,
                  decoration: const InputDecoration(labelText: 'Email', border: OutlineInputBorder()),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: gstinCtrl,
                  decoration: const InputDecoration(labelText: 'GSTIN', border: OutlineInputBorder()),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: addressCtrl,
                  decoration: const InputDecoration(labelText: 'Address', border: OutlineInputBorder()),
                  maxLines: 2,
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              if (formKey.currentState!.validate()) Navigator.pop(ctx, true);
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await FirestoreService.clients.add({
        'name': nameCtrl.text.trim(),
        'contact': contactCtrl.text.trim(),
        'email': emailCtrl.text.trim(),
        'gstin': gstinCtrl.text.trim(),
        'address': addressCtrl.text.trim(),
        'created_at': DateTime.now().toIso8601String(),
      });
      await _load();
    }
  }

  Future<void> _load() async {
    if (!mounted) return;
    setState(() => _loading = true);
    final snap = await FirestoreService.clients.orderBy('name').get();
    if (!mounted) return;
    setState(() {
      _clients = snap.docs.map(FirestoreService.docToMap).toList();
      _loading = false;
    });
  }

  List<Map<String, dynamic>> get _filtered => _search.isEmpty
      ? _clients
      : _clients
            .where(
              (c) => (c['name'] as String? ?? '').toLowerCase().contains(
                _search.toLowerCase(),
              ),
            )
            .toList();

  List<Map<String, dynamic>> get _paginated =>
      _filtered.take(_currentPage * _pageSize).toList();

  bool get _hasMore => _paginated.length < _filtered.length;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Clients'),
        leading: BackButton(onPressed: () => context.go('/dashboard')),
        actions: [IconButton(icon: const Icon(Icons.add), onPressed: () => _showAddClientDialog(context))],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                  child: TextField(
                    onChanged: (v) => setState(() => _search = v),
                    decoration: InputDecoration(
                      hintText: 'Search clients...',
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
                Expanded(
                  child: RefreshIndicator(
                    onRefresh: _load,
                     child: _filtered.isEmpty
                        ? EmptyStateWidget.clients(
                            key: const Key('clients_empty'),
                            onAdd: () => _showAddClientDialog(context),
                          )
                        : ListView.builder(
                       padding: const EdgeInsets.symmetric(horizontal: 16),
                       itemCount: _paginated.length + (_hasMore ? 1 : 0),
                       itemBuilder: (_, i) {
                         if (i == _paginated.length) {
                           // Load more button
                           return Padding(
                             padding: const EdgeInsets.symmetric(vertical: 16),
                             child: Center(
                               child: OutlinedButton.icon(
                                 onPressed: () =>
                                     setState(() => _currentPage++),
                                 icon: const Icon(Icons.expand_more, size: 16),
                                 label: Text(
                                   'Load More (${_filtered.length - _paginated.length} remaining)',
                                 ),
                               ),
                             ),
                           );
                         }
                         final c = _paginated[i];
                        return Container(
                          margin: const EdgeInsets.only(bottom: 10),
                          child: InkWell(
                            onTap: () =>
                                context.go('/clients/detail/${c['id']}'),
                            borderRadius: BorderRadius.circular(12),
                            child: Container(
                              padding: const EdgeInsets.all(14),
                              decoration: BoxDecoration(
                                color: isDark
                                    ? AppTheme.darkCard
                                    : Colors.white,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: isDark
                                      ? AppTheme.darkBorder
                                      : const Color(0xFFE5E7EB),
                                ),
                              ),
                              child: Row(
                                children: [
                                  Container(
                                    width: 48,
                                    height: 48,
                                    decoration: BoxDecoration(
                                      color: AppTheme.primaryBlue.withValues(
                                        alpha: 0.1,
                                      ),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Center(
                                      child: Text(
                                        (c['name'] as String? ?? '?')[0],
                                        style: const TextStyle(
                                          fontWeight: FontWeight.w800,
                                          fontSize: 20,
                                          color: AppTheme.primaryBlue,
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          c['name'] as String? ?? '',
                                          style: GoogleFonts.inter(
                                            fontSize: 14,
                                            fontWeight: FontWeight.w700,
                                            color: isDark
                                                ? Colors.white
                                                : const Color(0xFF111827),
                                          ),
                                        ),
                                        Text(
                                          c['contact'] as String? ?? '',
                                          style: const TextStyle(
                                            fontSize: 12,
                                            color: Color(0xFF6B7280),
                                          ),
                                        ),
                                        Text(
                                          c['address'] as String? ?? '',
                                          style: const TextStyle(
                                            fontSize: 11,
                                            color: Color(0xFF9CA3AF),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const Icon(
                                    Icons.chevron_right,
                                    color: Color(0xFF6B7280),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
              ],
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.go('/clients/create-order'),
        backgroundColor: AppTheme.primaryBlue,
        foregroundColor: Colors.white,
        child: const Icon(Icons.note_add_outlined),
      ),
    );
  }
}

class ClientDetailScreen extends StatefulWidget {
  final String clientId;
  const ClientDetailScreen({super.key, required this.clientId});
  @override
  State<ClientDetailScreen> createState() => _ClientDetailScreenState();
}

class _ClientDetailScreenState extends State<ClientDetailScreen> {
  Map<String, dynamic>? _client;
  List<Map<String, dynamic>> _orders = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    if (!mounted) return;
    final clientDoc = await FirestoreService.clients.doc(widget.clientId).get();
    if (clientDoc.exists) {
      final ordersSnap = await FirestoreService.orders
          .where('client_id', isEqualTo: widget.clientId)
          .orderBy('created_at', descending: true)
          .limit(10)
          .get();
      if (!mounted) return;
      setState(() {
        _client = FirestoreService.docToMap(clientDoc);
        _orders = ordersSnap.docs.map(FirestoreService.docToMap).toList();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    if (_client == null) {
      return Scaffold(
        appBar: AppBar(
          leading: BackButton(onPressed: () => context.go('/clients')),
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }
    final totalValue = _orders.fold<double>(
      0,
      (s, o) => s + (o['invoice_total'] as num? ?? 0).toDouble(),
    );

    return Scaffold(
      appBar: AppBar(
        title: Text(_client!['name'] as String? ?? ''),
        leading: BackButton(onPressed: () => context.go('/clients')),
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
                  Text(
                    _client!['name'] as String? ?? '',
                    style: GoogleFonts.inter(
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                    ),
                  ),
                  Text(
                    _client!['contact'] as String? ?? '',
                    style: const TextStyle(color: Colors.white70, fontSize: 13),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      const Icon(
                        Icons.location_on_outlined,
                        color: Colors.white70,
                        size: 14,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        _client!['address'] as String? ?? '',
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: StatCard(
                    title: 'Total Orders',
                    value: '${_orders.length}',
                    icon: Icons.shopping_bag_outlined,
                    color: AppTheme.primaryBlue,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: StatCard(
                    title: 'Total Value',
                    value: '₹${(totalValue / 1000).toStringAsFixed(0)}K',
                    icon: Icons.currency_rupee,
                    color: AppTheme.statusRunning,
                  ),
                ),
              ],
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
                  _buildInfoRow(
                    'Phone',
                    _client!['contact'] as String? ?? 'N/A',
                    isDark,
                  ),
                  _buildInfoRow(
                    'GST',
                    _client!['gstin'] as String? ?? 'N/A',
                    isDark,
                  ),
                  _buildInfoRow(
                    'Address',
                    _client!['address'] as String? ?? 'N/A',
                    isDark,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => context.go('/clients/create-order'),
                    icon: const Icon(Icons.add, size: 16),
                    label: const Text('New Order'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => context.go('/clients/invoice/${widget.clientId}'),
                    icon: const Icon(Icons.receipt_long_outlined, size: 16),
                    label: const Text('Invoice'),
                  ),
                ),
              ],
            ),
            if (_orders.isNotEmpty) ...[
              const SizedBox(height: 16),
              Text(
                'RECENT ORDERS',
                style: GoogleFonts.inter(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF6B7280),
                  letterSpacing: 1.0,
                ),
              ),
              const SizedBox(height: 8),
              ..._orders.map(
                (o) => Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: isDark ? AppTheme.darkCard : Colors.white,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: isDark
                          ? AppTheme.darkBorder
                          : const Color(0xFFE5E7EB),
                    ),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              o['order_number'] as String? ?? '',
                              style: GoogleFonts.inter(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: isDark
                                    ? Colors.white
                                    : const Color(0xFF111827),
                              ),
                            ),
                            Text(
                              o['created_at']?.toString().substring(0, 10) ??
                                  '',
                              style: const TextStyle(
                                fontSize: 11,
                                color: Color(0xFF6B7280),
                              ),
                            ),
                          ],
                        ),
                      ),
                      Text(
                        '₹${(o['invoice_total'] as num? ?? 0).toStringAsFixed(0)}',
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.primaryBlue,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, bool isDark) => Padding(
    padding: const EdgeInsets.only(bottom: 8),
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

class CreateOrderScreen extends StatefulWidget {
  const CreateOrderScreen({super.key});
  @override
  State<CreateOrderScreen> createState() => _CreateOrderScreenState();
}

class _CreateOrderScreenState extends State<CreateOrderScreen> {
  final _formKey = GlobalKey<FormState>();
  final _descCtrl = TextEditingController();
  final _amtCtrl = TextEditingController();
  List<Map<String, dynamic>> _clients = [];
  String? _selectedClient;
  String _dueDate = '';
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _loadClients();
  }

  Future<void> _loadClients() async {
    final snap = await FirestoreService.clients.orderBy('name').get();
    if (mounted) {
      final list = snap.docs.map(FirestoreService.docToMap).toList();
      setState(() {
        _clients = list;
        if (list.isNotEmpty) _selectedClient = list.first['id'] as String?;
      });
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    final countSnap = await FirestoreService.orders.count().get();
    final count = countSnap.count ?? 0;
    await FirestoreService.orders.add({
      'client_id': _selectedClient,
      'order_number': 'ORD-${2100 + count}',
      'description': _descCtrl.text,
      'invoice_total': double.tryParse(_amtCtrl.text) ?? 0,
      'status': 'PENDING',
      'due_date': _dueDate,
      'created_at': DateTime.now().toIso8601String(),
    });
    if (mounted) context.go('/clients');
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Create Order'),
        leading: BackButton(onPressed: () => context.go('/clients')),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (_clients.isNotEmpty) ...[
                Text(
                  'Client',
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: isDark
                        ? const Color(0xFFD1D5DB)
                        : const Color(0xFF374151),
                  ),
                ),
                const SizedBox(height: 8),
                DropdownButtonFormField<String>(
                  initialValue: _selectedClient,
                  onChanged: (v) => setState(() => _selectedClient = v),
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: isDark ? const Color(0xFF0A0E1A) : const Color(0xFFF9FAFB),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide(color: isDark ? AppTheme.darkBorder : const Color(0xFFE5E7EB)),
                    ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  ),
                  items: _clients
                      .map((c) => DropdownMenuItem<String>(
                            value: c['id'] as String?,
                            child: Text(c['name'] as String? ?? ''),
                          ))
                      .toList(),
                ),
                const SizedBox(height: 16),
              ],
              _buildField(
                'Order Description',
                ctrl: _descCtrl,
                isDark: isDark,
                validator: (v) => v?.isEmpty ?? true ? 'Required' : null,
                maxLines: 3,
              ),
              const SizedBox(height: 16),
              _buildField(
                'Total Amount (₹)',
                ctrl: _amtCtrl,
                isDark: isDark,
                keyboardType: TextInputType.number,
                validator: (v) => v?.isEmpty ?? true ? 'Required' : null,
              ),
              const SizedBox(height: 16),
              _buildField(
                'Due Date',
                ctrl: TextEditingController(text: _dueDate),
                isDark: isDark,
                readOnly: true,
                onTap: () async {
                  final d = await showDatePicker(
                    context: context,
                    initialDate: DateTime.now(),
                    firstDate: DateTime.now(),
                    lastDate: DateTime.now().add(const Duration(days: 365)),
                  );
                  if (d != null) {
                    setState(() => _dueDate = d.toString().substring(0, 10));
                  }
                },
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
                      : const Text('Create Order'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildField(
    String label, {
    TextEditingController? ctrl,
    required bool isDark,
    String? Function(String?)? validator,
    bool readOnly = false,
    VoidCallback? onTap,
    TextInputType? keyboardType,
    int maxLines = 1,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: isDark ? const Color(0xFFD1D5DB) : const Color(0xFF374151),
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: ctrl,
          readOnly: readOnly,
          onTap: onTap,
          validator: validator,
          keyboardType: keyboardType,
          maxLines: maxLines,
          decoration: InputDecoration(
            filled: true,
            fillColor: isDark
                ? const Color(0xFF0A0E1A)
                : const Color(0xFFF9FAFB),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(
                color: isDark ? AppTheme.darkBorder : const Color(0xFFE5E7EB),
              ),
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 14,
              vertical: 12,
            ),
          ),
        ),
      ],
    );
  }
}

class InvoicePreviewScreen extends StatefulWidget {
  final String clientId;
  const InvoicePreviewScreen({super.key, required this.clientId});
  @override
  State<InvoicePreviewScreen> createState() => _InvoicePreviewScreenState();
}

class _InvoicePreviewScreenState extends State<InvoicePreviewScreen> {
  Map<String, dynamic>? _client;
  Map<String, dynamic>? _order;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    if (!mounted) return;
    setState(() => _loading = true);
    final clientDoc = await FirestoreService.clients.doc(widget.clientId).get();
    final ordersSnap = await FirestoreService.orders
        .where('client_id', isEqualTo: widget.clientId)
        .orderBy('created_at', descending: true)
        .limit(1)
        .get();
    if (!mounted) return;
    setState(() {
      _client = clientDoc.exists ? FirestoreService.docToMap(clientDoc) : null;
      _order = ordersSnap.docs.isNotEmpty ? FirestoreService.docToMap(ordersSnap.docs.first) : null;
      _loading = false;
    });
  }

  Future<Uint8List> _buildPdfBytes() async {
    final client = _client;
    final order = _order;
    final pdf = pw.Document();
    final total = (order?['invoice_total'] as num? ?? 0).toDouble();
    final tax = (order?['tax_amount'] as num? ?? total * 0.18).toDouble();
    final orderNum = order?['order_number'] as String? ?? 'N/A';
    final createdAt = order?['created_at'] as String? ?? '';
    final clientName = client?['name'] as String? ?? 'Client';
    final clientAddress = client?['address'] as String? ?? '';

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (ctx) => pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text('PS Laser Industries', style: pw.TextStyle(fontSize: 20, fontWeight: pw.FontWeight.bold)),
                    pw.Text('GSTIN: 27AABC1234D1Z5'),
                  ],
                ),
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.end,
                  children: [
                    pw.Text('INVOICE', style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold)),
                    pw.Text(orderNum),
                    pw.Text(createdAt.substring(0, createdAt.length >= 10 ? 10 : createdAt.length)),
                  ],
                ),
              ],
            ),
            pw.SizedBox(height: 16),
            pw.Divider(),
            pw.SizedBox(height: 8),
            pw.Text('Bill To:', style: const pw.TextStyle(fontSize: 12)),
            pw.Text(clientName, style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold)),
            if (clientAddress.isNotEmpty) pw.Text(clientAddress, style: const pw.TextStyle(fontSize: 12)),
            pw.SizedBox(height: 16),
            pw.TableHelper.fromTextArray(
              headers: ['Description', 'Amount (₹)'],
              data: [
                ['Services / Products', (total - tax).toStringAsFixed(0)],
                ['GST (18%)', tax.toStringAsFixed(0)],
              ],
            ),
            pw.SizedBox(height: 16),
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.end,
              children: [
                pw.Text('TOTAL: ₹${total.toStringAsFixed(0)}',
                  style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold)),
              ],
            ),
          ],
        ),
      ),
    );
    return pdf.save();
  }

  Future<void> _exportPdf() => _buildPdfBytes().then(
    (bytes) => Printing.layoutPdf(onLayout: (_) async => bytes),
  );

  Future<void> _shareInvoice() async {
    final bytes = await _buildPdfBytes();
    final orderNum = _order?['order_number'] as String? ?? 'invoice';
    final file = File('${Directory.systemTemp.path}/$orderNum.pdf');
    await file.writeAsBytes(bytes);
    await SharePlus.instance.share(
      ShareParams(files: [XFile(file.path)], subject: 'Invoice — $orderNum'),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (_loading) {
      return Scaffold(
        appBar: AppBar(title: const Text('Invoice Preview'), leading: BackButton(onPressed: () => context.go('/clients'))),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    final clientName = _client?['name'] as String? ?? 'Unknown Client';
    final clientAddress = _client?['address'] as String? ?? '';
    final orderNum = _order?['order_number'] as String? ?? 'N/A';
    final total = (_order?['invoice_total'] as num? ?? 0).toDouble();
    final tax = (_order?['tax_amount'] as num? ?? total * 0.18).toDouble();
    final subtotal = total - tax;
    final status = (_order?['is_approved'] as int? ?? 0) == 1 ? 'APPROVED' : 'PENDING';
    final createdAt = (_order?['created_at'] as String? ?? '').substring(0, 10);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Invoice Preview'),
        leading: BackButton(onPressed: () => context.go('/clients')),
        actions: [
          IconButton(icon: const Icon(Icons.picture_as_pdf_outlined), onPressed: _exportPdf),
          IconButton(icon: const Icon(Icons.share_outlined), onPressed: _shareInvoice),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: isDark ? AppTheme.darkCard : Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: isDark ? AppTheme.darkBorder : const Color(0xFFE5E7EB)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.precision_manufacturing_rounded, color: AppTheme.primaryBlue, size: 32),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('PS Laser', style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.w800, color: AppTheme.primaryBlue)),
                      Text('Invoice #$orderNum', style: const TextStyle(color: Color(0xFF6B7280), fontSize: 12)),
                    ],
                  ),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: (status == 'APPROVED' ? AppTheme.statusRunning : AppTheme.accentYellow).withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      status,
                      style: TextStyle(
                        color: status == 'APPROVED' ? AppTheme.statusRunning : AppTheme.accentYellow,
                        fontWeight: FontWeight.w700,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text('Date: $createdAt', style: const TextStyle(fontSize: 12, color: Color(0xFF6B7280))),
              const SizedBox(height: 16),
              const Divider(),
              const SizedBox(height: 12),
              const Text('Bill To:', style: TextStyle(color: Color(0xFF6B7280), fontSize: 12)),
              Text(clientName, style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w700)),
              if (clientAddress.isNotEmpty)
                Text(clientAddress, style: const TextStyle(fontSize: 12, color: Color(0xFF6B7280))),
              const SizedBox(height: 16),
              Table(
                border: TableBorder.all(color: const Color(0xFFE5E7EB), borderRadius: BorderRadius.circular(8)),
                children: [
                  TableRow(
                    decoration: BoxDecoration(color: AppTheme.primaryBlue.withValues(alpha: 0.1)),
                    children: ['Description', 'Qty', 'Rate', 'Amount']
                        .map((h) => Padding(
                              padding: const EdgeInsets.all(10),
                              child: Text(h, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12)),
                            ))
                        .toList(),
                  ),
                  TableRow(children: [
                    'Laser Cutting / Services',
                    '1',
                    '₹${subtotal.toStringAsFixed(0)}',
                    '₹${subtotal.toStringAsFixed(0)}',
                  ].map((c) => Padding(padding: const EdgeInsets.all(10), child: Text(c, style: const TextStyle(fontSize: 12)))).toList()),
                ],
              ),
              const SizedBox(height: 14),
              Align(
                alignment: Alignment.centerRight,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text('Subtotal: ₹${subtotal.toStringAsFixed(0)}', style: const TextStyle(fontSize: 13, color: Color(0xFF6B7280))),
                    Text('GST 18%: ₹${tax.toStringAsFixed(0)}', style: const TextStyle(fontSize: 13, color: Color(0xFF6B7280))),
                    const SizedBox(height: 4),
                    Text(
                      'TOTAL: ₹${total.toStringAsFixed(0)}',
                      style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.w900, color: AppTheme.primaryBlue),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
