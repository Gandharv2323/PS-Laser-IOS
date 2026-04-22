import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../../core/services/firestore_service.dart';
import '../../core/theme/app_theme.dart';

class ReportsHubScreen extends StatelessWidget {
  const ReportsHubScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final reports = [
      {
        'title': 'Attendance Report',
        'icon': Icons.people_outline,
        'color': AppTheme.primaryBlue,
        'route': '/reports/attendance',
      },
      {
        'title': 'Inventory Report',
        'icon': Icons.inventory_2_outlined,
        'color': AppTheme.accentOrange,
        'route': '/reports/inventory',
      },
      {
        'title': 'Production Report',
        'icon': Icons.precision_manufacturing_outlined,
        'color': AppTheme.statusRunning,
        'route': '/reports/production',
      },
      {
        'title': 'Financial Report',
        'icon': Icons.account_balance_outlined,
        'color': const Color(0xFF7C3AED),
        'route': '/reports/financial',
      },
      {
        'title': 'Work Order Report',
        'icon': Icons.assignment_outlined,
        'color': const Color(0xFF00838F),
        'route': '/reports/work-orders',
      },
    ];

    return Scaffold(
      appBar: AppBar(title: const Text('Reports')),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF1565C0), Color(0xFF1976D2)],
                ),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.analytics_outlined,
                    color: Colors.white,
                    size: 32,
                  ),
                  const SizedBox(width: 14),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Reports Hub',
                        style: GoogleFonts.inter(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                      Text(
                        'Export and analyze your data',
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
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              'AVAILABLE REPORTS',
              style: GoogleFonts.inter(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF6B7280),
                letterSpacing: 1.0,
              ),
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: reports.length,
              separatorBuilder: (_, _) => const SizedBox(height: 10),
              itemBuilder: (_, i) {
                final r = reports[i];
                return InkWell(
                  onTap: () => context.go(r['route'] as String),
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: isDark ? AppTheme.darkCard : Colors.white,
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
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            color: (r['color'] as Color).withValues(
                              alpha: 0.12,
                            ),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Icon(
                            r['icon'] as IconData,
                            color: r['color'] as Color,
                            size: 22,
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Text(
                            r['title'] as String,
                            style: GoogleFonts.inter(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              color: isDark
                                  ? Colors.white
                                  : const Color(0xFF111827),
                            ),
                          ),
                        ),
                        Icon(
                          Icons.arrow_forward_ios,
                          size: 14,
                          color: isDark
                              ? const Color(0xFF4B5563)
                              : const Color(0xFF9CA3AF),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Generic Report Screen with Real PDF Export ──────────────────────────────

class AttendanceReportScreen extends StatelessWidget {
  const AttendanceReportScreen({super.key});
  @override
  Widget build(BuildContext context) => _LiveReportScreen(
    title: 'Attendance Report',
    icon: Icons.people_outline,
    color: AppTheme.primaryBlue,
    queryType: 'attendance',
  );
}

class InventoryReportScreen extends StatelessWidget {
  const InventoryReportScreen({super.key});
  @override
  Widget build(BuildContext context) => _LiveReportScreen(
    title: 'Inventory Report',
    icon: Icons.inventory_2_outlined,
    color: AppTheme.accentOrange,
    queryType: 'inventory',
  );
}

class ProductionReportScreen extends StatelessWidget {
  const ProductionReportScreen({super.key});
  @override
  Widget build(BuildContext context) => _LiveReportScreen(
    title: 'Production Report',
    icon: Icons.precision_manufacturing_outlined,
    color: AppTheme.statusRunning,
    queryType: 'production',
  );
}

class FinancialReportScreen extends StatelessWidget {
  const FinancialReportScreen({super.key});
  @override
  Widget build(BuildContext context) => _LiveReportScreen(
    title: 'Financial Report',
    icon: Icons.account_balance_outlined,
    color: const Color(0xFF7C3AED),
    queryType: 'financial',
  );
}

class WorkOrderReportScreen extends StatelessWidget {
  const WorkOrderReportScreen({super.key});
  @override
  Widget build(BuildContext context) => _LiveReportScreen(
    title: 'Work Order Report',
    icon: Icons.assignment_outlined,
    color: const Color(0xFF00838F),
    queryType: 'workorders',
  );
}

// ─── Live Report Screen ───────────────────────────────────────────────────────

class _LiveReportScreen extends StatefulWidget {
  final String title;
  final IconData icon;
  final Color color;
  final String queryType;

  const _LiveReportScreen({
    required this.title,
    required this.icon,
    required this.color,
    required this.queryType,
  });
  @override
  State<_LiveReportScreen> createState() => _LiveReportScreenState();
}

class _LiveReportScreenState extends State<_LiveReportScreen> {
  List<Map<String, dynamic>> _data = [];
  List<String> _columns = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    if (!mounted) return;
    final month = DateTime.now().toString().substring(0, 7);
    final thirtyDaysAgo = DateTime.now().subtract(const Duration(days: 30)).toString().substring(0, 10);

    List<Map<String, dynamic>> rows = [];
    List<String> cols = [];

    switch (widget.queryType) {
      case 'attendance':
        final attSnap = await FirestoreService.attendance
            .where('date', isGreaterThanOrEqualTo: thirtyDaysAgo)
            .orderBy('date', descending: true)
            .get();
        final attRecords = attSnap.docs.map(FirestoreService.docToMap).toList();
        // Enrich with employee name+dept
        for (final r in attRecords) {
          final empId = r['employee_id'] as String? ?? '';
          if (empId.isNotEmpty) {
            final empDoc = await FirestoreService.employees.doc(empId).get();
            if (empDoc.exists) {
              final emp = FirestoreService.docToMap(empDoc);
              rows.add({
                'Employee': emp['name'] ?? '',
                'Dept': emp['department'] ?? '',
                'Date': r['date'] ?? '',
                'Status': r['status'] ?? '',
                'Check In': r['check_in'] ?? '-',
                'Check Out': r['check_out'] ?? '-',
              });
            }
          }
        }
        cols = ['Employee', 'Dept', 'Date', 'Status', 'Check In', 'Check Out'];
        break;

      case 'inventory':
        final invSnap = await FirestoreService.inventory.orderBy('current_qty').get();
        rows = invSnap.docs.map((doc) {
          final i = FirestoreService.docToMap(doc);
          final qty = (i['current_qty'] as num?) ?? 0;
          final reorder = (i['reorder_level'] as num?) ?? 0;
          return {
            'Item': i['name'] ?? '',
            'Category': i['category'] ?? '',
            'Qty': qty,
            'Unit': i['unit'] ?? '',
            'Reorder': reorder,
            'Status': qty <= reorder ? 'LOW STOCK' : 'OK',
          };
        }).toList();
        cols = ['Item', 'Category', 'Qty', 'Unit', 'Reorder', 'Status'];
        break;

      case 'production':
        final woSnap = await FirestoreService.workOrders
            .orderBy('created_at', descending: true).get();
        rows = woSnap.docs.map((doc) {
          final w = FirestoreService.docToMap(doc);
          return {
            'WO #': w['wo_number'] ?? '',
            'Subject': w['subject'] ?? '',
            'Priority': w['priority'] ?? '',
            'Status': w['status'] ?? '',
            'Deadline': w['deadline'] ?? '',
          };
        }).toList();
        cols = ['WO #', 'Subject', 'Priority', 'Status', 'Deadline'];
        break;

      case 'financial':
        final paySnap = await FirestoreService.payroll
            .where('month', isEqualTo: month).get();
        for (final doc in paySnap.docs) {
          final p = FirestoreService.docToMap(doc);
          final empId = p['employee_id'] as String? ?? '';
          String empName = '';
          if (empId.isNotEmpty) {
            final empDoc = await FirestoreService.employees.doc(empId).get();
            if (empDoc.exists) empName = FirestoreService.docToMap(empDoc)['name'] as String? ?? '';
          }
          rows.add({
            'Employee': empName,
            'Month': p['month'] ?? '',
            'Base (₹)': p['base_salary'] ?? 0,
            'Days': p['paid_days'] ?? 0,
            'OT (₹)': p['overtime_pay'] ?? 0,
            'Deduct (₹)': p['deductions'] ?? 0,
            'Net Pay (₹)': p['net_pay'] ?? 0,
          });
        }
        rows.sort((a, b) => (a['Employee'] as String).compareTo(b['Employee'] as String));
        cols = ['Employee', 'Month', 'Base (₹)', 'Days', 'OT (₹)', 'Deduct (₹)', 'Net Pay (₹)'];
        break;

      case 'workorders':
        final woSnap2 = await FirestoreService.workOrders
            .orderBy('created_at', descending: true).get();
        rows = woSnap2.docs.map((doc) {
          final w = FirestoreService.docToMap(doc);
          return {
            'WO #': w['wo_number'] ?? '',
            'Subject': w['subject'] ?? '',
            'Priority': w['priority'] ?? '',
            'Status': w['status'] ?? '',
            'Deadline': w['deadline'] ?? '',
          };
        }).toList();
        cols = ['WO #', 'Subject', 'Priority', 'Status', 'Deadline'];
        break;
    }

    if (mounted) {
      setState(() {
        _data = rows;
        _columns = cols;
        _loading = false;
      });
    }
  }

  Future<void> _exportPdf() async {
    final pdf = pw.Document();
    final now = DateTime.now().toString().substring(0, 16);

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(24),
        build: (ctx) => [
          pw.Header(
            level: 0,
            child: pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text(
                  widget.title,
                  style: pw.TextStyle(
                    fontSize: 20,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
                pw.Text(
                  'PS Laser — $now',
                  style: const pw.TextStyle(fontSize: 10),
                ),
              ],
            ),
          ),
          pw.SizedBox(height: 12),
          if (_data.isEmpty)
            pw.Text('No data available for this report.')
          else
            pw.TableHelper.fromTextArray(
              headers: _columns,
              data: _data
                  .map(
                    (row) =>
                        _columns.map((col) => '${row[col] ?? '-'}').toList(),
                  )
                  .toList(),
              headerStyle: pw.TextStyle(
                fontWeight: pw.FontWeight.bold,
                fontSize: 9,
              ),
              cellStyle: const pw.TextStyle(fontSize: 8),
              headerDecoration: const pw.BoxDecoration(
                color: PdfColors.blue800,
              ),
              headerAlignments: {
                for (var col in _columns)
                  _columns.indexOf(col): pw.Alignment.centerLeft,
              },
              cellAlignments: {
                for (var i = 0; i < _columns.length; i++)
                  i: pw.Alignment.centerLeft,
              },
              border: pw.TableBorder.all(color: PdfColors.grey400, width: 0.5),
              oddRowDecoration: const pw.BoxDecoration(
                color: PdfColors.grey100,
              ),
            ),
          pw.SizedBox(height: 12),
          pw.Text(
            'Total records: ${_data.length}',
            style: const pw.TextStyle(fontSize: 9),
          ),
        ],
      ),
    );

    await Printing.layoutPdf(onLayout: (_) => pdf.save());
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
        leading: BackButton(onPressed: () => context.go('/reports')),
        actions: [
          if (!_loading) ...[
            IconButton(
              icon: const Icon(Icons.picture_as_pdf_outlined),
              tooltip: 'Export PDF',
              onPressed: _exportPdf,
            ),
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: () {
                setState(() => _loading = true);
                _load();
              },
            ),
          ],
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // Summary bar
                Container(
                  margin: const EdgeInsets.all(16),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: widget.color.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: widget.color.withValues(alpha: 0.2),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(widget.icon, color: widget.color, size: 28),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${_data.length} records',
                            style: GoogleFonts.inter(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: widget.color,
                            ),
                          ),
                          Text(
                            'Tap PDF to export full report',
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              color: const Color(0xFF6B7280),
                            ),
                          ),
                        ],
                      ),
                      const Spacer(),
                      ElevatedButton.icon(
                        onPressed: _exportPdf,
                        icon: const Icon(
                          Icons.picture_as_pdf_outlined,
                          size: 16,
                        ),
                        label: const Text('Export PDF'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: widget.color,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                // Data table
                Expanded(
                  child: _data.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                widget.icon,
                                size: 64,
                                color: widget.color.withValues(alpha: 0.3),
                              ),
                              const SizedBox(height: 12),
                              Text(
                                'No data available',
                                style: GoogleFonts.inter(
                                  fontSize: 16,
                                  color: const Color(0xFF6B7280),
                                ),
                              ),
                            ],
                          ),
                        )
                      : SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: SingleChildScrollView(
                            child: DataTable(
                              columnSpacing: 16,
                              headingRowColor: WidgetStateProperty.all(
                                isDark
                                    ? AppTheme.darkCard
                                    : const Color(0xFFF3F4F6),
                              ),
                              columns: _columns
                                  .map(
                                    (c) => DataColumn(
                                      label: Text(
                                        c,
                                        style: GoogleFonts.inter(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                    ),
                                  )
                                  .toList(),
                              rows: _data
                                  .map(
                                    (row) => DataRow(
                                      cells: _columns
                                          .map(
                                            (col) => DataCell(
                                              Text(
                                                '${row[col] ?? '-'}',
                                                style: GoogleFonts.inter(
                                                  fontSize: 12,
                                                ),
                                              ),
                                            ),
                                          )
                                          .toList(),
                                    ),
                                  )
                                  .toList(),
                            ),
                          ),
                        ),
                ),
              ],
            ),
    );
  }
}
