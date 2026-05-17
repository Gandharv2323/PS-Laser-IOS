import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/services/firestore_service.dart';
import '../../core/theme/app_theme.dart';
import '../widgets/stat_card.dart';

class MachineListScreen extends StatefulWidget {
  const MachineListScreen({super.key});
  @override
  State<MachineListScreen> createState() => _MachineListScreenState();
}

class _MachineListScreenState extends State<MachineListScreen> {
  List<Map<String, dynamic>> _machines = [];
  String _statusFilter = 'ALL';
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    if (!mounted) return;
    setState(() => _loading = true);
    final snap = await FirestoreService.machines.orderBy('name').get();
    if (!mounted) return;
    setState(() {
      _machines = snap.docs.map(FirestoreService.docToMap).toList();
      _loading = false;
    });
  }

  List<Map<String, dynamic>> get _filtered => _statusFilter == 'ALL'
      ? _machines
      : _machines.where((m) => m['status'] == _statusFilter).toList();

  @override
  Widget build(BuildContext context) {
    final running = _machines.where((m) => m['status'] == 'RUNNING').length;
    final maintenance =
        _machines.where((m) => m['status'] == 'MAINTENANCE').length;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Machines'),
        actions: [
          IconButton(icon: const Icon(Icons.filter_list), onPressed: () {}),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddMachineSheet(context),
        icon: const Icon(Icons.add),
        label: const Text('Add Machine'),
        backgroundColor: AppTheme.primaryBlue,
        foregroundColor: Colors.white,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                  child: Row(
                    children: [
                      Expanded(
                        child: StatCard(
                          title: 'Running',
                          value: '$running',
                          icon: Icons.play_circle_outline,
                          color: AppTheme.statusRunning,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: StatCard(
                          title: 'Maintenance',
                          value: '$maintenance',
                          icon: Icons.build_outlined,
                          color: AppTheme.statusMaintenance,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: StatCard(
                          title: 'Idle',
                          value:
                              '${_machines.length - running - maintenance}',
                          icon: Icons.pause_circle_outline,
                          color: AppTheme.statusIdle,
                        ),
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
                    children: ['ALL', 'RUNNING', 'IDLE', 'MAINTENANCE']
                        .map(
                          (s) => Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: FilterChip(
                              label: Text(s),
                              selected: _statusFilter == s,
                              onSelected: (_) =>
                                  setState(() => _statusFilter = s),
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
                          _MachineCard(machine: _filtered[i]),
                    ),
                  ),
                ),
              ],
            ),
    );
  }

  // ── Add Machine bottom sheet ──────────────────────────────────────────────

  Future<void> _showAddMachineSheet(BuildContext context) async {
    final formKey = GlobalKey<FormState>();
    final nameCtrl = TextEditingController();
    final codeCtrl = TextEditingController();
    final locationCtrl = TextEditingController();
    final capacityCtrl = TextEditingController();
    final runtimeTodayCtrl = TextEditingController(text: '0');
    final runtimeMonthCtrl = TextEditingController(text: '0');
    final lastServicedCtrl = TextEditingController();
    final nextServiceCtrl = TextEditingController();
    String selectedStatus = 'IDLE';
    bool saving = false;

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetCtx) {
        return StatefulBuilder(
          builder: (ctx, setSheetState) {
            final isDark = Theme.of(ctx).brightness == Brightness.dark;
            return Container(
              decoration: BoxDecoration(
                color: isDark ? AppTheme.darkCard : Colors.white,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(24),
                ),
              ),
              padding: EdgeInsets.only(
                left: 20,
                right: 20,
                top: 20,
                bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
              ),
              child: SingleChildScrollView(
                child: Form(
                  key: formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Handle bar
                      Center(
                        child: Container(
                          width: 40,
                          height: 4,
                          decoration: BoxDecoration(
                            color: isDark
                                ? AppTheme.darkBorder
                                : const Color(0xFFE5E7EB),
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Add New Machine',
                        style: GoogleFonts.inter(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: isDark
                              ? Colors.white
                              : const Color(0xFF111827),
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Name
                      _FormField(
                        controller: nameCtrl,
                        label: 'Machine Name',
                        hint: 'e.g. Laser Cutter A',
                        isDark: isDark,
                        validator: (v) => (v == null || v.trim().isEmpty)
                            ? 'Required'
                            : null,
                      ),
                      const SizedBox(height: 12),

                      // Code
                      _FormField(
                        controller: codeCtrl,
                        label: 'Machine Code',
                        hint: 'e.g. MC-001',
                        isDark: isDark,
                        validator: (v) => (v == null || v.trim().isEmpty)
                            ? 'Required'
                            : null,
                      ),
                      const SizedBox(height: 12),

                      // Location
                      _FormField(
                        controller: locationCtrl,
                        label: 'Location',
                        hint: 'e.g. Bay 1',
                        isDark: isDark,
                        validator: (v) => (v == null || v.trim().isEmpty)
                            ? 'Required'
                            : null,
                      ),
                      const SizedBox(height: 12),

                      // Status Dropdown
                      Text(
                        'Status',
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: isDark
                              ? Colors.white70
                              : const Color(0xFF374151),
                        ),
                      ),
                      const SizedBox(height: 6),
                      DropdownButtonFormField<String>(
                        initialValue: selectedStatus,
                        decoration: InputDecoration(
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 12,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: BorderSide(
                              color: isDark
                                  ? AppTheme.darkBorder
                                  : const Color(0xFFD1D5DB),
                            ),
                          ),
                          filled: true,
                          fillColor: isDark
                              ? const Color(0xFF1E293B)
                              : const Color(0xFFF9FAFB),
                        ),
                        items: ['RUNNING', 'IDLE', 'MAINTENANCE']
                            .map(
                              (s) => DropdownMenuItem(
                                value: s,
                                child: Text(s),
                              ),
                            )
                            .toList(),
                        onChanged: (v) {
                          if (v != null) {
                            setSheetState(() => selectedStatus = v);
                          }
                        },
                      ),
                      const SizedBox(height: 12),

                      // Capacity
                      _FormField(
                        controller: capacityCtrl,
                        label: 'Capacity (units/hr)',
                        hint: 'e.g. 100',
                        isDark: isDark,
                        keyboardType: TextInputType.number,
                        validator: (v) {
                          if (v == null || v.trim().isEmpty) return 'Required';
                          if (int.tryParse(v.trim()) == null) {
                            return 'Enter a valid number';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 12),

                      // Runtime row
                      Row(
                        children: [
                          Expanded(
                            child: _FormField(
                              controller: runtimeTodayCtrl,
                              label: 'Runtime Today (h)',
                              hint: '0',
                              isDark: isDark,
                              keyboardType:
                                  const TextInputType.numberWithOptions(
                                      decimal: true),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _FormField(
                              controller: runtimeMonthCtrl,
                              label: 'Runtime Month (h)',
                              hint: '0',
                              isDark: isDark,
                              keyboardType:
                                  const TextInputType.numberWithOptions(
                                      decimal: true),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),

                      // Service dates row
                      Row(
                        children: [
                          Expanded(
                            child: _DateField(
                              controller: lastServicedCtrl,
                              label: 'Last Serviced',
                              isDark: isDark,
                              sheetContext: ctx,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _DateField(
                              controller: nextServiceCtrl,
                              label: 'Next Service Due',
                              isDark: isDark,
                              sheetContext: ctx,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),

                      // Submit button
                      SizedBox(
                        width: double.infinity,
                        height: 48,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.primaryBlue,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          onPressed: saving
                              ? null
                              : () async {
                                  if (!formKey.currentState!.validate()) {
                                    return;
                                  }
                                  setSheetState(() => saving = true);
                                  try {
                                    await FirestoreService.addMachine({
                                      'name': nameCtrl.text.trim(),
                                      'code': codeCtrl.text.trim(),
                                      'location': locationCtrl.text.trim(),
                                      'status': selectedStatus,
                                      'capacity': int.tryParse(
                                              capacityCtrl.text.trim()) ??
                                          0,
                                      'runtime_today': double.tryParse(
                                              runtimeTodayCtrl.text.trim()) ??
                                          0,
                                      'runtime_month': double.tryParse(
                                              runtimeMonthCtrl.text.trim()) ??
                                          0,
                                      'last_serviced_date':
                                          lastServicedCtrl.text.trim().isNotEmpty
                                              ? lastServicedCtrl.text.trim()
                                              : null,
                                      'next_service_due':
                                          nextServiceCtrl.text.trim().isNotEmpty
                                              ? nextServiceCtrl.text.trim()
                                              : null,
                                    });
                                    if (sheetCtx.mounted) {
                                      Navigator.of(sheetCtx).pop();
                                    }
                                    _load();
                                  } catch (e) {
                                    setSheetState(() => saving = false);
                                    if (ctx.mounted) {
                                      ScaffoldMessenger.of(ctx).showSnackBar(
                                        SnackBar(
                                          content: Text('Error: $e'),
                                          backgroundColor: Colors.red,
                                        ),
                                      );
                                    }
                                  }
                                },
                          child: saving
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    color: Colors.white,
                                    strokeWidth: 2,
                                  ),
                                )
                              : Text(
                                  'Save Machine',
                                  style: GoogleFonts.inter(
                                    fontWeight: FontWeight.w600,
                                    fontSize: 15,
                                  ),
                                ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }
}

// ── Reusable labelled text field ──────────────────────────────────────────────

class _FormField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final String hint;
  final bool isDark;
  final TextInputType? keyboardType;
  final String? Function(String?)? validator;

  const _FormField({
    required this.controller,
    required this.label,
    required this.hint,
    required this.isDark,
    this.keyboardType,
    this.validator,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: isDark ? Colors.white70 : const Color(0xFF374151),
          ),
        ),
        const SizedBox(height: 6),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          validator: validator,
          decoration: InputDecoration(
            hintText: hint,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 14,
              vertical: 12,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(
                color: isDark
                    ? AppTheme.darkBorder
                    : const Color(0xFFD1D5DB),
              ),
            ),
            filled: true,
            fillColor: isDark
                ? const Color(0xFF1E293B)
                : const Color(0xFFF9FAFB),
          ),
        ),
      ],
    );
  }
}

// ── Date picker field ─────────────────────────────────────────────────────────

class _DateField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final bool isDark;
  final BuildContext sheetContext;

  const _DateField({
    required this.controller,
    required this.label,
    required this.isDark,
    required this.sheetContext,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: isDark ? Colors.white70 : const Color(0xFF374151),
          ),
        ),
        const SizedBox(height: 6),
        TextFormField(
          controller: controller,
          readOnly: true,
          decoration: InputDecoration(
            hintText: 'YYYY-MM-DD',
            suffixIcon:
                const Icon(Icons.calendar_today_outlined, size: 18),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 14,
              vertical: 12,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(
                color: isDark
                    ? AppTheme.darkBorder
                    : const Color(0xFFD1D5DB),
              ),
            ),
            filled: true,
            fillColor: isDark
                ? const Color(0xFF1E293B)
                : const Color(0xFFF9FAFB),
          ),
          onTap: () async {
            final picked = await showDatePicker(
              context: sheetContext,
              initialDate: DateTime.now(),
              firstDate: DateTime(2000),
              lastDate: DateTime(2100),
            );
            if (picked != null) {
              controller.text =
                  '${picked.year}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}';
            }
          },
        ),
      ],
    );
  }
}

// ── Machine list card ─────────────────────────────────────────────────────────

class _MachineCard extends StatelessWidget {
  final Map<String, dynamic> machine;
  const _MachineCard({required this.machine});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final status = machine['status'] as String;
    final isMaintenanceDue =
        machine['next_service_due'] != null &&
        DateTime.tryParse(
              machine['next_service_due'],
            )?.isBefore(DateTime.now()) ==
            true;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      child: InkWell(
        onTap: () => context.go('/machines/detail/${machine['id']}'),
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: isDark ? AppTheme.darkCard : Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isMaintenanceDue
                  ? AppTheme.accentOrange.withValues(alpha: 0.5)
                  : (isDark
                      ? AppTheme.darkBorder
                      : const Color(0xFFE5E7EB)),
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: AppTheme.statusColor(status)
                      .withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.memory_outlined,
                  color: AppTheme.statusColor(status),
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
                            machine['name'] as String,
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
                    const SizedBox(height: 2),
                    Text(
                      '${machine['code']} • ${machine['location']}',
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFF6B7280),
                      ),
                    ),
                    if (isMaintenanceDue) ...[
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          const Icon(
                            Icons.warning_amber_rounded,
                            size: 12,
                            color: AppTheme.accentOrange,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'Maintenance Overdue',
                            style: GoogleFonts.inter(
                              fontSize: 11,
                              color: AppTheme.accentOrange,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ],
                    const SizedBox(height: 4),
                    Text(
                      'Runtime today: ${machine['runtime_today']}h',
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
}
