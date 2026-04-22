import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import '../../core/services/firestore_service.dart';
import '../../core/providers/session_provider.dart';
import '../../core/theme/app_theme.dart';
import '../widgets/stat_card.dart';
import '../widgets/empty_state_widget.dart';

class PayrollListScreen extends StatefulWidget {
  const PayrollListScreen({super.key});
  @override
  State<PayrollListScreen> createState() => _PayrollListScreenState();
}

class _PayrollListScreenState extends State<PayrollListScreen> {
  List<Map<String, dynamic>> _payroll = [];
  bool _loading = true;
  final String _month = DateTime.now().toString().substring(0, 7);
  static const int _pageSize = 20;
  int _currentPage = 1;

  List<Map<String, dynamic>> get _paginated =>
      _payroll.take(_currentPage * _pageSize).toList();

  bool get _hasMore => _paginated.length < _payroll.length;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    if (!mounted) return;
    setState(() => _loading = true);
    final snap = await FirestoreService.payroll
        .where('month', isEqualTo: _month)
        .get();
    // Enrich with employee names
    final records = await Future.wait(
      snap.docs.map((doc) async {
        final p = FirestoreService.docToMap(doc);
        final empId = p['employee_id'] as String? ?? '';
        if (empId.isNotEmpty) {
          final empDoc = await FirestoreService.employees.doc(empId).get();
          if (empDoc.exists) {
            final emp = FirestoreService.docToMap(empDoc);
            p['name'] = emp['name'];
            p['designation'] = emp['designation'];
            p['department'] = emp['department'];
          }
        }
        return p;
      }),
    );
    records.sort((a, b) => (a['name'] as String? ?? '').compareTo(b['name'] as String? ?? ''));
    if (!mounted) return;
    setState(() {
      _payroll = records;
      _loading = false;
    });
  }

  Future<void> _generateAll() async {
    final session = context.read<SessionProvider>().session;
    if (!session.canViewPayroll) return;

    final empSnap = await FirestoreService.employees
        .where('is_active', isEqualTo: 1)
        .get();
    int generated = 0;
    for (final empDoc in empSnap.docs) {
      final emp = FirestoreService.docToMap(empDoc);
      final empId = emp['id'] as String;
      // Check if payslip already exists
      final existing = await FirestoreService.payroll
          .where('employee_id', isEqualTo: empId)
          .where('month', isEqualTo: _month)
          .limit(1)
          .get();
      if (existing.docs.isNotEmpty) continue;

      // Count attendance for this month
      final attSnap = await FirestoreService.attendance
          .where('employee_id', isEqualTo: empId)
          .where('status', isEqualTo: 'PRESENT')
          .get();
      final monthRecords = attSnap.docs
          .map(FirestoreService.docToMap)
          .where((a) => (a['date'] as String? ?? '').startsWith(_month))
          .toList();
      final paidDays = monthRecords.length;
      final otHours = monthRecords.fold<double>(
        0,
        (sum, a) => sum + ((a['overtime_hours'] as num?)?.toDouble() ?? 0),
      );

      final role = emp['role'] as String? ?? 'WORKER';
      final baseSalary = switch (role) {
        'OWNER' => 120000.0,
        'MANAGER' => 55000.0,
        'SUPERVISOR' => 35000.0,
        _ => 22000.0,
      };
      final dailyRate = baseSalary / 26;
      final overtimePay = otHours * (dailyRate / 8) * 1.5;
      const deductions = 1200.0;
      final netPay = (dailyRate * paidDays) + overtimePay - deductions;

      await FirestoreService.payroll.add({
        'employee_id': empId,
        'month': _month,
        'base_salary': baseSalary,
        'paid_days': paidDays,
        'overtime_pay': overtimePay.roundToDouble(),
        'deductions': deductions,
        'net_pay': netPay.roundToDouble(),
        'is_paid': 0,
        'created_at': DateTime.now().toIso8601String(),
      });
      generated++;
    }
    if (!mounted) return;
    await _load();
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          generated > 0
              ? 'Generated $generated payslip${generated > 1 ? 's' : ''} for $_month'
              : 'All payslips already generated for $_month',
        ),
        backgroundColor: generated > 0
            ? AppTheme.statusRunning
            : AppTheme.accentOrange,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final totalNet = _payroll.fold<double>(
      0,
      (sum, r) => sum + (r['net_pay'] as num? ?? 0).toDouble(),
    );
    final processed = _payroll.where((r) => (r['is_paid'] as int? ?? 0) == 1).length;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Payroll'),
        leading: BackButton(onPressed: () => context.go('/dashboard')),
        actions: [
          TextButton(
            onPressed: _generateAll,
            child: const Text(
              'Generate',
              style: TextStyle(color: AppTheme.accentOrange),
            ),
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'PAYROLL SUMMARY — $_month',
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF6B7280),
                          letterSpacing: 1.0,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Expanded(
                            child: StatCard(
                              title: 'Total Payout',
                              value:
                                  '₹${(totalNet / 1000).toStringAsFixed(0)}K',
                              icon: Icons.account_balance_wallet_outlined,
                              color: AppTheme.primaryBlue,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: StatCard(
                              title: 'Processed',
                              value: '$processed/${_payroll.length}',
                              icon: Icons.check_circle_outline,
                              color: AppTheme.statusRunning,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                Expanded(
                  child: _payroll.isEmpty
                      ? EmptyStateWidget.payroll(
                          key: const Key('payroll_empty'),
                          onGenerate: _generateAll,
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          itemCount: _paginated.length + (_hasMore ? 1 : 0),
                          itemBuilder: (_, i) {
                            if (i == _paginated.length) {
                              return Padding(
                                padding: const EdgeInsets.symmetric(vertical: 16),
                                child: Center(
                                  child: OutlinedButton.icon(
                                    onPressed: () =>
                                        setState(() => _currentPage++),
                                    icon: const Icon(Icons.expand_more, size: 16),
                                    label: Text(
                                      'Load More (${_payroll.length - _paginated.length} remaining)',
                                    ),
                                  ),
                                ),
                              );
                            }
                            final p = _paginated[i];
                            return Container(
                              margin: const EdgeInsets.only(bottom: 10),
                              child: InkWell(
                                onTap: () =>
                                    context.go('/payroll/payslip/${p['id']}'),
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
                                      CircleAvatar(
                                        radius: 22,
                                        backgroundColor: AppTheme.primaryBlue
                                            .withValues(alpha: 0.15),
                                        child: Text(
                                          (p['name'] as String)[0],
                                          style: const TextStyle(
                                            color: AppTheme.primaryBlue,
                                            fontWeight: FontWeight.w700,
                                            fontSize: 16,
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
                                              p['name'] as String,
                                              style: GoogleFonts.inter(
                                                fontSize: 14,
                                                fontWeight: FontWeight.w600,
                                                color: isDark
                                                    ? Colors.white
                                                    : const Color(0xFF111827),
                                              ),
                                            ),
                                            Text(
                                              p['designation'] as String,
                                              style: const TextStyle(
                                                fontSize: 12,
                                                color: Color(0xFF6B7280),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.end,
                                        children: [
                                          Text(
                                            '₹${(p['net_pay'] as num? ?? 0.0).toStringAsFixed(0)}',
                                            style: GoogleFonts.inter(
                                              fontSize: 15,
                                              fontWeight: FontWeight.w800,
                                              color: AppTheme.primaryBlue,
                                            ),
                                          ),
                                          StatusBadge(
                                            status: (p['is_paid'] as int? ?? 0) == 1
                                                ? 'PAID'
                                                : 'PENDING',
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
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

class PayslipPreviewScreen extends StatefulWidget {
  final String payslipId;
  const PayslipPreviewScreen({super.key, required this.payslipId});
  @override
  State<PayslipPreviewScreen> createState() => _PayslipPreviewScreenState();
}

class _PayslipPreviewScreenState extends State<PayslipPreviewScreen> {
  Map<String, dynamic>? _payslip;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    if (!mounted) return;
    final doc = await FirestoreService.payroll.doc(widget.payslipId).get();
    if (doc.exists && mounted) {
      final p = FirestoreService.docToMap(doc);
      final empId = p['employee_id'] as String? ?? '';
      if (empId.isNotEmpty) {
        final empDoc = await FirestoreService.employees.doc(empId).get();
        if (empDoc.exists) {
          final emp = FirestoreService.docToMap(empDoc);
          p['name'] = emp['name'];
          p['designation'] = emp['designation'];
          p['department'] = emp['department'];
          p['contact'] = emp['contact'];
        }
      }
      if (mounted) setState(() => _payslip = p);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    if (_payslip == null) {
      return Scaffold(
        appBar: AppBar(
          leading: BackButton(onPressed: () => context.go('/payroll')),
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }
    final p = _payslip!;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Payslip'),
        leading: BackButton(onPressed: () => context.go('/payroll')),
        actions: [
          IconButton(icon: const Icon(Icons.share_outlined), onPressed: _payslip == null ? null : _sharePayslip),
          IconButton(
            icon: const Icon(Icons.picture_as_pdf_outlined),
            onPressed: _payslip == null ? null : _exportPdf,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: isDark ? AppTheme.darkCard : Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isDark ? AppTheme.darkBorder : const Color(0xFFE5E7EB),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF1565C0), Color(0xFF1976D2)],
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.precision_manufacturing_rounded,
                      color: Colors.white,
                      size: 28,
                    ),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'PS Laser',
                          style: GoogleFonts.inter(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                        Text(
                          'Payslip — ${p['month']}',
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
              const SizedBox(height: 20),
              _buildEmpRow('Employee', p['name'] as String, isDark),
              _buildEmpRow('Designation', p['designation'] as String, isDark),
              _buildEmpRow('Department', p['department'] as String, isDark),
              const Divider(height: 24),
              Text(
                'EARNINGS',
                style: GoogleFonts.inter(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF6B7280),
                  letterSpacing: 1.0,
                ),
              ),
              const SizedBox(height: 10),
              Builder(builder: (context) {
                final baseSalary = (p['base_salary'] as num? ?? 0).toDouble();
                final paidDays = (p['paid_days'] as num? ?? 0).toInt();
                final overtimePay = (p['overtime_pay'] as num? ?? 0).toDouble();
                final deductions = (p['deductions'] as num? ?? 0).toDouble();
                final basicEarned = (baseSalary / 26.0) * paidDays;
                final hra = basicEarned * 0.40;
                final grossPay = basicEarned + hra + overtimePay;
                final pf = basicEarned * 0.12;
                final esi = grossPay * 0.0075;
                final tds = (deductions - pf - esi).clamp(0.0, double.infinity);
                return Column(
                  children: [
                    _buildAmtRow('Basic (${paidDays}d × ₹${(baseSalary / 26).toStringAsFixed(0)})', '₹${basicEarned.toStringAsFixed(0)}', isDark),
                    _buildAmtRow('HRA (40%)', '₹${hra.toStringAsFixed(0)}', isDark),
                    _buildAmtRow('OT Allowance', '₹${overtimePay.toStringAsFixed(0)}', isDark),
                    _buildAmtRow('Gross Pay', '₹${grossPay.toStringAsFixed(0)}', isDark, bold: true),
                    const Divider(height: 24),
                    Text('DEDUCTIONS', style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w700, color: const Color(0xFF6B7280), letterSpacing: 1.0)),
                    const SizedBox(height: 10),
                    _buildAmtRow('PF (12%)', '₹${pf.toStringAsFixed(0)}', isDark, color: AppTheme.accentRed),
                    _buildAmtRow('ESI (0.75%)', '₹${esi.toStringAsFixed(0)}', isDark, color: AppTheme.accentRed),
                    _buildAmtRow('TDS / Other', '₹${tds.toStringAsFixed(0)}', isDark, color: AppTheme.accentRed),
                  ],
                );
              }),
              const Divider(height: 24),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppTheme.primaryBlue.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: AppTheme.primaryBlue.withValues(alpha: 0.3),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'NET PAY',
                      style: GoogleFonts.inter(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: AppTheme.primaryBlue,
                      ),
                    ),
                    Text(
                      '₹${(p['net_pay'] as num? ?? 0).toStringAsFixed(0)}',
                      style: GoogleFonts.inter(
                        fontSize: 20,
                        fontWeight: FontWeight.w900,
                        color: AppTheme.primaryBlue,
                      ),
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

  Future<Uint8List> _buildPdfBytes() async {
    final p = _payslip!;
    final baseSalary = (p['base_salary'] as num? ?? 0).toDouble();
    final paidDays = (p['paid_days'] as num? ?? 0).toInt();
    final overtimePay = (p['overtime_pay'] as num? ?? 0).toDouble();
    final deductions = (p['deductions'] as num? ?? 0).toDouble();
    final basicEarned = (baseSalary / 26.0) * paidDays;
    final hra = basicEarned * 0.40;
    final grossPay = basicEarned + hra + overtimePay;
    final pf = basicEarned * 0.12;
    final esi = grossPay * 0.0075;
    final tds = (deductions - pf - esi).clamp(0.0, double.infinity);
    final netPay = (p['net_pay'] as num? ?? 0).toDouble();

    final pdf = pw.Document();
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
                pw.Text('PS Laser Industries', style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold)),
                pw.Text('Payslip — ${p['month']}', style: const pw.TextStyle(fontSize: 12)),
              ],
            ),
            pw.SizedBox(height: 12),
            pw.Text('Employee: ${p['name']}'),
            pw.Text('Designation: ${p['designation']}   Dept: ${p['department']}'),
            pw.SizedBox(height: 16),
            pw.Text('EARNINGS', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
            pw.SizedBox(height: 8),
            pw.TableHelper.fromTextArray(
              headers: ['Description', 'Amount (₹)'],
              data: [
                ['Basic Earned ($paidDays days)', basicEarned.toStringAsFixed(0)],
                ['HRA (40%)', hra.toStringAsFixed(0)],
                ['OT Allowance', overtimePay.toStringAsFixed(0)],
                ['Gross Pay', grossPay.toStringAsFixed(0)],
              ],
            ),
            pw.SizedBox(height: 12),
            pw.Text('DEDUCTIONS', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
            pw.SizedBox(height: 8),
            pw.TableHelper.fromTextArray(
              headers: ['Description', 'Amount (₹)'],
              data: [
                ['PF (12%)', pf.toStringAsFixed(0)],
                ['ESI (0.75%)', esi.toStringAsFixed(0)],
                ['TDS / Other', tds.toStringAsFixed(0)],
              ],
            ),
            pw.SizedBox(height: 16),
            pw.Container(
              padding: const pw.EdgeInsets.all(12),
              decoration: const pw.BoxDecoration(color: PdfColors.blue50),
              child: pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text('NET PAY', style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold)),
                  pw.Text('₹${netPay.toStringAsFixed(0)}', style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold)),
                ],
              ),
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

  Future<void> _sharePayslip() async {
    final p = _payslip!;
    final bytes = await _buildPdfBytes();
    final empName = (p['name'] as String? ?? 'Employee');
    final empMonth = (p['month'] as String? ?? '');
    final tempDir = Directory.systemTemp.path;
    final file = File('$tempDir/payslip_${p['employee_id']}_$empMonth.pdf');
    await file.writeAsBytes(bytes);
    await SharePlus.instance.share(
      ShareParams(
        files: [XFile(file.path)],
        subject: 'Payslip: $empName ($empMonth)',
      ),
    );
  }

  Widget _buildEmpRow(String label, String value, bool isDark) => Padding(
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

  Widget _buildAmtRow(
    String label,
    String value,
    bool isDark, {
    bool bold = false,
    Color? color,
  }) => Padding(
    padding: const EdgeInsets.only(bottom: 6),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 13,
            color: const Color(0xFF6B7280),
            fontWeight: bold ? FontWeight.w700 : FontWeight.normal,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 13,
            fontWeight: bold ? FontWeight.w700 : FontWeight.w500,
            color: color ?? (isDark ? Colors.white : const Color(0xFF111827)),
          ),
        ),
      ],
    ),
  );
}
