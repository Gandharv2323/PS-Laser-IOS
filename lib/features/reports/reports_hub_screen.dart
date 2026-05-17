/// Reports Hub Screen — Phase 6 full rewrite.
///
/// - Live OrderMetrics KPI strip (stream-based)
/// - Status donut mini-chart
/// - Featured Production Analytics card
/// - Quick Export section for raw tabular sub-reports
library;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import '../../core/models/models.dart';
import '../../core/services/firestore_service.dart';
import '../../core/services/order_engine.dart';
import '../../core/theme/ios_design_system.dart';

// ═══════════════════════════════════════════════════════════════════════════════
// REPORTS HUB
// ═══════════════════════════════════════════════════════════════════════════════

class ReportsHubScreen extends StatelessWidget {
  const ReportsHubScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? PSColors.darkBg : PSColors.lightBg,
      body: StreamBuilder<OrderMetrics>(
        stream: OrderEngine.streamMetrics(),
        builder: (context, snap) {
          final metrics = snap.data ?? OrderMetrics.empty;

          return CustomScrollView(
            slivers: [
              // ── App Bar ──────────────────────────────────────────
              SliverAppBar(
                pinned: true,
                backgroundColor:
                    isDark ? PSColors.darkBg : PSColors.lightBg,
                surfaceTintColor: Colors.transparent,
                title: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Reports', style: PSText.title()),
                    Text(
                      'Analytics & Export',
                      style:
                          PSText.caption(color: PSColors.textDark3),
                    ),
                  ],
                ),
              ),

              // ── KPI Strip ────────────────────────────────────────
              SliverToBoxAdapter(
                child: _KpiStrip(metrics: metrics),
              ),

              // ── Featured: Production Analytics ───────────────────
              _sectionHeader('Production Intelligence'),
              SliverToBoxAdapter(
                child: _AnalyticsFeaturedCard(isDark: isDark),
              ),

              // ── Quick Export ──────────────────────────────────────
              _sectionHeader('Quick Export'),
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                sliver: SliverList(
                  delegate: SliverChildListDelegate([
                    _ExportTile(
                      icon: Icons.receipt_long_rounded,
                      label: 'Order Report',
                      subtitle: '${metrics.total} orders',
                      color: PSColors.brand,
                      onTap: () {
                        HapticFeedback.lightImpact();
                        context.go('/reports/production');
                      },
                      isDark: isDark,
                    ),
                    const SizedBox(height: 8),
                    _ExportTile(
                      icon: Icons.people_outline_rounded,
                      label: 'Attendance Report',
                      subtitle: 'Last 30 days',
                      color: PSColors.neonCyan,
                      onTap: () {
                        HapticFeedback.lightImpact();
                        context.go('/reports/attendance');
                      },
                      isDark: isDark,
                    ),
                    const SizedBox(height: 8),
                    _ExportTile(
                      icon: Icons.inventory_2_outlined,
                      label: 'Inventory Report',
                      subtitle: 'Stock levels & reorder alerts',
                      color: PSColors.neonOrange,
                      onTap: () {
                        HapticFeedback.lightImpact();
                        context.go('/reports/inventory');
                      },
                      isDark: isDark,
                    ),
                    const SizedBox(height: 8),
                    _ExportTile(
                      icon: Icons.account_balance_outlined,
                      label: 'Financial Report',
                      subtitle: 'Payroll — current month',
                      color: PSColors.neonPurple,
                      onTap: () {
                        HapticFeedback.lightImpact();
                        context.go('/reports/financial');
                      },
                      isDark: isDark,
                    ),
                  ]),
                ),
              ),

              const SliverToBoxAdapter(child: SizedBox(height: 80)),
            ],
          );
        },
      ),
    );
  }

  Widget _sectionHeader(String title) => SliverToBoxAdapter(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 10),
          child: Text(
            title.toUpperCase(),
            style: PSText.sectionHeader(color: PSColors.textDark3),
          ),
        ),
      );
}

// ── KPI Strip ──────────────────────────────────────────────────────────────────

class _KpiStrip extends StatelessWidget {
  final OrderMetrics metrics;
  const _KpiStrip({required this.metrics});

  @override
  Widget build(BuildContext context) {
    final items = [
      _KpiItem('Total', metrics.total, PSColors.brand),
      _KpiItem('Active', metrics.active, PSColors.neonCyan),
      _KpiItem('Overdue', metrics.overdue, PSColors.neonRed),
      _KpiItem('Done', metrics.completed, PSColors.neonGreen),
    ];

    return SizedBox(
      height: 82,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        itemCount: items.length,
        separatorBuilder: (_, _) => const SizedBox(width: 10),
        itemBuilder: (_, i) {
          final item = items[i];
          return Container(
            width: 82,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: item.color.withAlpha(15),
              borderRadius: BorderRadius.circular(PSRadius.md),
              border: Border.all(
                  color: item.color.withAlpha(40), width: 0.5),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  '${item.value}',
                  style: PSText.metricSmall(color: item.color),
                ),
                const SizedBox(height: 3),
                Text(
                  item.label,
                  style: PSText.caption(color: item.color)
                      .copyWith(fontSize: 10),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

// ── Analytics Featured Card ─────────────────────────────────────────────────

class _AnalyticsFeaturedCard extends StatelessWidget {
  final bool isDark;
  const _AnalyticsFeaturedCard({required this.isDark});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.mediumImpact();
        context.go('/reports/analytics');
      },
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 20),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: PSColors.brandGradient,
          borderRadius: BorderRadius.circular(PSRadius.lg),
          boxShadow: [
            BoxShadow(
              color: PSColors.brand.withAlpha(60),
              blurRadius: 20,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Row(
          children: [
            // Icon cluster
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: Colors.white.withAlpha(25),
                borderRadius: BorderRadius.circular(PSRadius.md),
              ),
              child: const Icon(
                Icons.bar_chart_rounded,
                color: Colors.white,
                size: 28,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Production Analytics',
                    style: PSText.body(color: Colors.white)
                        .copyWith(
                            fontWeight: FontWeight.w800, fontSize: 16),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Charts · Status · Volume · Priority',
                    style: PSText.caption(
                        color: Colors.white.withAlpha(180)),
                  ),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios_rounded,
                color: Colors.white, size: 16),
          ],
        ),
      ),
    );
  }
}

// ── Export Tile ─────────────────────────────────────────────────────────────

class _ExportTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;
  final bool isDark;

  const _ExportTile({
    required this.icon,
    required this.label,
    required this.subtitle,
    required this.color,
    required this.onTap,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isDark ? PSColors.darkCard : PSColors.lightCard,
          borderRadius: BorderRadius.circular(PSRadius.md),
          border: Border.all(
            color: isDark ? PSColors.darkBorder : PSColors.lightBorder,
            width: 0.5,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: color.withAlpha(20),
                borderRadius: BorderRadius.circular(PSRadius.sm),
              ),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: PSText.body(
                      color: isDark
                          ? PSColors.textDark1
                          : PSColors.textLight1,
                    ).copyWith(fontWeight: FontWeight.w600),
                  ),
                  Text(
                    subtitle,
                    style:
                        PSText.caption(color: PSColors.textDark3),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.picture_as_pdf_outlined,
              size: 18,
              color: color.withAlpha(180),
            ),
            const SizedBox(width: 4),
            Icon(
              Icons.arrow_forward_ios_rounded,
              size: 14,
              color: PSColors.textDark3,
            ),
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// Generic Live Report Screen (polished with iOS design system)
// ═══════════════════════════════════════════════════════════════════════════════

class AttendanceReportScreen extends StatelessWidget {
  const AttendanceReportScreen({super.key});
  @override
  Widget build(BuildContext context) => _LiveReportScreen(
        title: 'Attendance Report',
        icon: Icons.people_outline_rounded,
        color: PSColors.neonCyan,
        queryType: 'attendance',
      );
}

class InventoryReportScreen extends StatelessWidget {
  const InventoryReportScreen({super.key});
  @override
  Widget build(BuildContext context) => _LiveReportScreen(
        title: 'Inventory Report',
        icon: Icons.inventory_2_outlined,
        color: PSColors.neonOrange,
        queryType: 'inventory',
      );
}

class ProductionReportScreen extends StatelessWidget {
  const ProductionReportScreen({super.key});
  @override
  Widget build(BuildContext context) => _LiveReportScreen(
        title: 'Order Report',
        icon: Icons.receipt_long_rounded,
        color: PSColors.brand,
        queryType: 'production',
      );
}

class FinancialReportScreen extends StatelessWidget {
  const FinancialReportScreen({super.key});
  @override
  Widget build(BuildContext context) => _LiveReportScreen(
        title: 'Financial Report',
        icon: Icons.account_balance_outlined,
        color: PSColors.neonPurple,
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

// ─── Internal live report screen ──────────────────────────────────────────────

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
    final thirtyDaysAgo = DateTime.now()
        .subtract(const Duration(days: 30))
        .toString()
        .substring(0, 10);

    List<Map<String, dynamic>> rows = [];
    List<String> cols = [];

    switch (widget.queryType) {
      case 'attendance':
        final attSnap = await FirestoreService.attendance
            .where('date', isGreaterThanOrEqualTo: thirtyDaysAgo)
            .orderBy('date', descending: true)
            .get();
        final attRecords =
            attSnap.docs.map(FirestoreService.docToMap).toList();
        for (final r in attRecords) {
          final empId = r['employee_id'] as String? ?? '';
          if (empId.isNotEmpty) {
            final empDoc =
                await FirestoreService.employees.doc(empId).get();
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
        cols = [
          'Employee',
          'Dept',
          'Date',
          'Status',
          'Check In',
          'Check Out'
        ];

      case 'inventory':
        final invSnap = await FirestoreService.inventory
            .orderBy('current_qty')
            .get();
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
            'Status': qty <= reorder ? '⚠ LOW STOCK' : '✓ OK',
          };
        }).toList();
        cols = ['Item', 'Category', 'Qty', 'Unit', 'Reorder', 'Status'];

      case 'production':
        // Uses typed Order model via OrderEngine — fetches all orders
        final allSnap = await FirestoreService.orders
            .orderBy('created_at', descending: true)
            .get();
        final allOrders = allSnap.docs
            .map((d) => Order.fromMap(FirestoreService.docToMap(d)))
            .toList();
        rows = allOrders.map((o) {
          return {
            'Client': o.clientName,
            'Description': o.description,
            'Material': o.material,
            'Qty': '${o.quantity} ${o.unit}',
            'Priority': o.priority,
            'Status': o.status.replaceAll('_', ' '),
            'Due': o.dueDate != null
                ? DateFormat('dd MMM yy').format(o.dueDate!)
                : '-',
            'Overdue': o.isOverdue ? 'YES' : '-',
          };
        }).toList();
        cols = [
          'Client',
          'Description',
          'Material',
          'Qty',
          'Priority',
          'Status',
          'Due',
          'Overdue'
        ];

      case 'financial':
        final paySnap = await FirestoreService.payroll
            .where('month', isEqualTo: month)
            .get();
        for (final doc in paySnap.docs) {
          final p = FirestoreService.docToMap(doc);
          final empId = p['employee_id'] as String? ?? '';
          String empName = '';
          if (empId.isNotEmpty) {
            final empDoc =
                await FirestoreService.employees.doc(empId).get();
            if (empDoc.exists) {
              empName = FirestoreService.docToMap(empDoc)['name']
                      as String? ??
                  '';
            }
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
        rows.sort((a, b) =>
            (a['Employee'] as String).compareTo(b['Employee'] as String));
        cols = [
          'Employee',
          'Month',
          'Base (₹)',
          'Days',
          'OT (₹)',
          'Deduct (₹)',
          'Net Pay (₹)'
        ];

      case 'workorders':
        final woSnap = await FirestoreService.workOrders
            .orderBy('created_at', descending: true)
            .get();
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
    }

    if (mounted) {
      setState(() {
        _data = rows;
        _columns = cols;
        _loading = false;
      });
    }
  }

  // ── PDF Export ──────────────────────────────────────────────────────────────

  Future<void> _exportPdf() async {
    HapticFeedback.mediumImpact();
    final pdf = pw.Document();
    final now = DateFormat('dd MMM yyyy HH:mm').format(DateTime.now());

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
                      fontSize: 18, fontWeight: pw.FontWeight.bold),
                ),
                pw.Text('PS Laser  ·  $now',
                    style: const pw.TextStyle(fontSize: 9)),
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
                  .map((row) => _columns
                      .map((col) => '${row[col] ?? '-'}')
                      .toList())
                  .toList(),
              headerStyle: pw.TextStyle(
                  fontWeight: pw.FontWeight.bold, fontSize: 8),
              cellStyle: const pw.TextStyle(fontSize: 7),
              headerDecoration:
                  const pw.BoxDecoration(color: PdfColors.blue800),
              border: pw.TableBorder.all(
                  color: PdfColors.grey400, width: 0.5),
              oddRowDecoration:
                  const pw.BoxDecoration(color: PdfColors.grey100),
            ),
          pw.SizedBox(height: 10),
          pw.Text(
            'Total records: ${_data.length}  ·  Generated: $now',
            style: const pw.TextStyle(fontSize: 8),
          ),
        ],
      ),
    );

    await Printing.layoutPdf(onLayout: (_) => pdf.save());
  }

  // ── Build ───────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? PSColors.darkBg : PSColors.lightBg,
      appBar: AppBar(
        backgroundColor: isDark ? PSColors.darkBg : PSColors.lightBg,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18),
          onPressed: () => context.go('/reports'),
        ),
        title: Text(widget.title, style: PSText.title()),
        actions: [
          if (!_loading)
            IconButton(
              icon: Icon(Icons.picture_as_pdf_outlined,
                  color: widget.color),
              tooltip: 'Export PDF',
              onPressed: _exportPdf,
            ),
          if (!_loading)
            IconButton(
              icon: const Icon(Icons.refresh_rounded),
              onPressed: () {
                setState(() => _loading = true);
                _load();
              },
            ),
        ],
      ),
      body: _loading
          ? Center(
              child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation(widget.color)),
            )
          : Column(
              children: [
                // Summary bar
                Container(
                  margin: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: widget.color.withAlpha(15),
                    borderRadius: BorderRadius.circular(PSRadius.md),
                    border: Border.all(
                        color: widget.color.withAlpha(40), width: 0.5),
                  ),
                  child: Row(
                    children: [
                      Icon(widget.icon, color: widget.color, size: 24),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${_data.length} records',
                            style: PSText.body(color: widget.color)
                                .copyWith(fontWeight: FontWeight.w700),
                          ),
                          Text(
                            'Tap Export PDF to print / share',
                            style: PSText.caption(
                                color: PSColors.textDark3),
                          ),
                        ],
                      ),
                      const Spacer(),
                      GestureDetector(
                        onTap: _exportPdf,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 7),
                          decoration: BoxDecoration(
                            color: widget.color,
                            borderRadius:
                                BorderRadius.circular(PSRadius.sm),
                          ),
                          child: Row(
                            children: [
                              const Icon(
                                  Icons.picture_as_pdf_outlined,
                                  color: Colors.white,
                                  size: 15),
                              const SizedBox(width: 6),
                              Text('Export',
                                  style: PSText.caption(
                                          color: Colors.white)
                                      .copyWith(
                                          fontWeight: FontWeight.w700)),
                            ],
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
                              Icon(widget.icon,
                                  size: 56,
                                  color: widget.color.withAlpha(60)),
                              const SizedBox(height: 12),
                              Text('No data available',
                                  style: PSText.body(
                                      color: PSColors.textDark3)),
                            ],
                          ),
                        )
                      : SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: SingleChildScrollView(
                            padding:
                                const EdgeInsets.symmetric(vertical: 8),
                            child: DataTable(
                              columnSpacing: 14,
                              horizontalMargin: 16,
                              headingRowHeight: 40,
                              dataRowMinHeight: 36,
                              dataRowMaxHeight: 40,
                              headingRowColor: WidgetStateProperty.all(
                                isDark
                                    ? PSColors.darkCard
                                    : PSColors.lightBg,
                              ),
                              columns: _columns
                                  .map(
                                    (c) => DataColumn(
                                      label: Text(
                                        c,
                                        style: PSText.caption(
                                          color: isDark
                                              ? PSColors.textDark2
                                              : PSColors.textLight2,
                                        ).copyWith(
                                            fontWeight: FontWeight.w700,
                                            fontSize: 11),
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
                                                style: PSText.caption(
                                                  color: isDark
                                                      ? PSColors.textDark1
                                                      : PSColors.textLight1,
                                                ).copyWith(fontSize: 11),
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

// ── Data model ─────────────────────────────────────────────────────────────────

class _KpiItem {
  final String label;
  final int value;
  final Color color;
  const _KpiItem(this.label, this.value, this.color);
}
