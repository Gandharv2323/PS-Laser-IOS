/// Add Order Screen — Premium iOS-first order creation form.
/// Supports preselected client (from Clients tab) and voice-based creation.
library;

import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../core/models/models.dart';
import '../../core/services/order_engine.dart';
import '../../core/services/firestore_service.dart';
import '../../core/theme/ios_design_system.dart';
import '../../core/providers/session_provider.dart';


class AddOrderScreen extends StatefulWidget {
  final String? preselectedClientId;
  final String? preselectedClientName;

  const AddOrderScreen({
    super.key,
    this.preselectedClientId,
    this.preselectedClientName,
  });

  @override
  State<AddOrderScreen> createState() => _AddOrderScreenState();
}

class _AddOrderScreenState extends State<AddOrderScreen> {
  final _formKey = GlobalKey<FormState>();
  bool _isSaving = false;

  // ── Form State ─────────────────────────────────────────────────────────────
  String? _clientId;
  String? _clientName;
  final _descCtrl    = TextEditingController();
  final _materialCtrl = TextEditingController();
  final _qtyCtrl     = TextEditingController(text: '1');
  String _unit       = 'pcs';
  String _priority   = 'MEDIUM';
  DateTime? _dueDate;
  int _durationMins  = 60;
  final _notesCtrl   = TextEditingController();

  // ── Client search ──────────────────────────────────────────────────────────
  List<Map<String, dynamic>> _clients     = [];
  List<Map<String, dynamic>> _filteredClients = [];
  bool _showClientDropdown = false;
  final _clientSearchCtrl = TextEditingController();
  final _clientFocus      = FocusNode();

  static const _units = ['pcs', 'kg', 'mm', 'meters', 'sheets', 'sets', 'lots'];
  static const _priorities = ['LOW', 'MEDIUM', 'HIGH', 'URGENT'];
  static const _durations = [30, 60, 90, 120, 180, 240, 360, 480];

  @override
  void initState() {
    super.initState();
    _clientId   = widget.preselectedClientId;
    _clientName = widget.preselectedClientName;
    if (_clientName != null) _clientSearchCtrl.text = _clientName!;
    _loadClients();

    _clientSearchCtrl.addListener(_onClientSearch);
    _clientFocus.addListener(() {
      if (!_clientFocus.hasFocus) {
        Future.delayed(const Duration(milliseconds: 200),
            () => setState(() => _showClientDropdown = false));
      }
    });
  }

  @override
  void dispose() {
    _descCtrl.dispose();
    _materialCtrl.dispose();
    _qtyCtrl.dispose();
    _notesCtrl.dispose();
    _clientSearchCtrl.dispose();
    _clientFocus.dispose();
    super.dispose();
  }

  Future<void> _loadClients() async {
    final snap = await FirestoreService.clients.orderBy('name').get();
    setState(() {
      _clients = snap.docs
          .map((d) => FirestoreService.docToMap(d))
          .toList();
      _filteredClients = _clients;
    });
  }

  void _onClientSearch() {
    final q = _clientSearchCtrl.text.toLowerCase();
    setState(() {
      _showClientDropdown = q.isNotEmpty;
      _filteredClients = _clients
          .where((c) => (c['name'] as String).toLowerCase().contains(q))
          .toList();
      if (q.isEmpty) {
        _clientId   = null;
        _clientName = null;
      }
    });
  }

  void _selectClient(Map<String, dynamic> client) {
    HapticFeedback.selectionClick();
    setState(() {
      _clientId   = client['id'] as String;
      _clientName = client['name'] as String;
      _clientSearchCtrl.text = _clientName!;
      _showClientDropdown = false;
    });
    _clientFocus.unfocus();
  }

  // ── Due Date Picker ────────────────────────────────────────────────────────

  Future<void> _pickDueDate() async {
    HapticFeedback.selectionClick();
    final now = DateTime.now();
    DateTime? picked;

    // Use Cupertino picker on iOS feel
    await showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) {
        DateTime temp = _dueDate ?? now.add(const Duration(days: 1));
        return Container(
          decoration: BoxDecoration(
            color: Theme.of(context).brightness == Brightness.dark
                ? PSColors.darkElevated
                : PSColors.lightCard,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 8),
              Container(
                width: 36, height: 4,
                decoration: BoxDecoration(
                  color: PSColors.darkBorder,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: Text('Cancel', style: PSText.body(color: PSColors.textDark3)),
                    ),
                    Text('Due Date & Time', style: PSText.titleSmall()),
                    TextButton(
                      onPressed: () {
                        picked = temp;
                        Navigator.pop(context);
                      },
                      child: Text('Done',
                          style: PSText.body(color: PSColors.brand)
                              .copyWith(fontWeight: FontWeight.w700)),
                    ),
                  ],
                ),
              ),
              SizedBox(
                height: 200,
                child: CupertinoDatePicker(
                  initialDateTime: _dueDate ?? now.add(const Duration(hours: 4)),
                  minimumDate: now,
                  mode: CupertinoDatePickerMode.dateAndTime,
                  use24hFormat: false,
                  onDateTimeChanged: (dt) => temp = dt,
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        );
      },
    );

    if (picked != null) setState(() => _dueDate = picked);
  }

  // ── Save ───────────────────────────────────────────────────────────────────

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    if (_clientId == null) {
      _showSnack('Please select a client', isError: true);
      return;
    }
    if (_dueDate == null) {
      _showSnack('Please set a due date', isError: true);
      return;
    }

    setState(() => _isSaving = true);
    HapticFeedback.mediumImpact();

    try {
      final session = context.read<SessionProvider>().session;
      final qty = double.tryParse(_qtyCtrl.text.trim()) ?? 1.0;

      final order = Order(
        id: '',
        clientId: _clientId!,
        clientName: _clientName!,
        description: _descCtrl.text.trim(),
        material: _materialCtrl.text.trim(),
        quantity: qty,
        unit: _unit,
        priority: _priority,
        status: 'RECEIVED',
        estimatedDurationMins: _durationMins,
        dueDate: _dueDate,
        notes: _notesCtrl.text.trim().isEmpty
            ? null
            : _notesCtrl.text.trim(),
        attachmentUrls: const [],
        createdAt: DateTime.now(),
      );

      final newId = await OrderEngine.createOrder(order, session.userId);

      if (mounted) {
        HapticFeedback.heavyImpact();
        _showSnack('Order created successfully!');
        await Future.delayed(const Duration(milliseconds: 600));
        if (mounted) context.go('/orders/detail/$newId');
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSaving = false);
        _showSnack('Failed to create order: $e', isError: true);
      }
    }
  }

  void _showSnack(String msg, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: isError ? PSColors.neonRed : PSColors.neonGreen,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(PSRadius.sm)),
      ),
    );
  }

  // ── Build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? PSColors.darkBg : PSColors.lightBg,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          onPressed: () => context.pop(),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('New Order', style: PSText.titleSmall()),
            Text('Order Control System',
                style: PSText.caption(color: PSColors.textDark3)),
          ],
        ),
        actions: [
          TextButton(
            onPressed: _isSaving ? null : _save,
            child: _isSaving
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: PSColors.brand,
                    ),
                  )
                : Text(
                    'Save',
                    style: PSText.body(color: PSColors.brand)
                        .copyWith(fontWeight: FontWeight.w700),
                  ),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 120),
          children: [
            // ── Client ──────────────────────────────────────────────
            _SectionLabel(label: 'Client *', isDark: isDark),
            _buildClientField(isDark),
            const SizedBox(height: 20),

            // ── Order Details ────────────────────────────────────────
            _SectionLabel(label: 'Order Details *', isDark: isDark),
            _buildTextField(
              controller: _descCtrl,
              hint: 'Description (e.g. Laser cutting MS sheet)',
              icon: Icons.edit_note_rounded,
              validator: (v) => v == null || v.trim().isEmpty ? 'Required' : null,
              isDark: isDark,
            ),
            const SizedBox(height: 10),
            _buildTextField(
              controller: _materialCtrl,
              hint: 'Material (e.g. MS 2mm, SS 304)',
              icon: Icons.category_outlined,
              validator: (v) => v == null || v.trim().isEmpty ? 'Required' : null,
              isDark: isDark,
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  flex: 2,
                  child: _buildTextField(
                    controller: _qtyCtrl,
                    hint: 'Quantity',
                    icon: Icons.numbers_rounded,
                    keyboardType: TextInputType.number,
                    validator: (v) {
                      if (v == null || v.trim().isEmpty) return 'Required';
                      if (double.tryParse(v) == null) return 'Number only';
                      return null;
                    },
                    isDark: isDark,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _buildDropdown(
                    value: _unit,
                    items: _units,
                    isDark: isDark,
                    onChanged: (v) => setState(() => _unit = v!),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // ── Priority ─────────────────────────────────────────────
            _SectionLabel(label: 'Priority', isDark: isDark),
            _buildPrioritySelector(isDark),
            const SizedBox(height: 20),

            // ── Schedule ─────────────────────────────────────────────
            _SectionLabel(label: 'Schedule *', isDark: isDark),
            _buildDueDateTile(isDark),
            const SizedBox(height: 10),
            _buildDurationSelector(isDark),
            const SizedBox(height: 20),

            // ── Notes ────────────────────────────────────────────────
            _SectionLabel(label: 'Notes (optional)', isDark: isDark),
            _buildTextField(
              controller: _notesCtrl,
              hint: 'Additional instructions, special requirements…',
              icon: Icons.sticky_note_2_outlined,
              maxLines: 3,
              isDark: isDark,
            ),
            const SizedBox(height: 24),

            // ── Save button ──────────────────────────────────────────
            SizedBox(
              height: 52,
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _isSaving ? null : _save,
                style: ElevatedButton.styleFrom(
                  backgroundColor: PSColors.brand,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(PSRadius.sm),
                  ),
                ),
                icon: _isSaving
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white),
                      )
                    : const Icon(Icons.add_circle_outline_rounded, size: 20),
                label: Text(
                  _isSaving ? 'Creating Order…' : 'Create Order',
                  style: PSText.body(color: Colors.white)
                      .copyWith(fontWeight: FontWeight.w700),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Field Builders ────────────────────────────────────────────────────────

  Widget _buildClientField(bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          decoration: BoxDecoration(
            color: isDark ? PSColors.darkCard : PSColors.lightCard,
            borderRadius: BorderRadius.circular(PSRadius.sm),
            border: Border.all(
              color: _clientId != null
                  ? PSColors.brand.withAlpha(150)
                  : isDark ? PSColors.darkBorder : PSColors.lightBorder,
              width: _clientId != null ? 1 : 0.5,
            ),
          ),
          child: TextFormField(
            controller: _clientSearchCtrl,
            focusNode: _clientFocus,
            style: PSText.body(color: isDark ? PSColors.textDark1 : PSColors.textLight1),
            decoration: InputDecoration(
              hintText: 'Search client by name…',
              hintStyle: PSText.body(color: PSColors.textDark3),
              prefixIcon: Icon(
                _clientId != null ? Icons.check_circle_rounded : Icons.person_search_rounded,
                color: _clientId != null ? PSColors.neonGreen : PSColors.textDark3,
                size: 20,
              ),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            ),
            onTap: () => setState(() => _showClientDropdown = true),
          ),
        ),
        if (_showClientDropdown && _filteredClients.isNotEmpty)
          Container(
            margin: const EdgeInsets.only(top: 4),
            constraints: const BoxConstraints(maxHeight: 200),
            decoration: BoxDecoration(
              color: isDark ? PSColors.darkCard : PSColors.lightCard,
              borderRadius: BorderRadius.circular(PSRadius.sm),
              border: Border.all(
                color: isDark ? PSColors.darkBorder : PSColors.lightBorder,
                width: 0.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withAlpha(40),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: _filteredClients.length,
              itemBuilder: (_, i) {
                final c = _filteredClients[i];
                return ListTile(
                  dense: true,
                  leading: Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: PSColors.brand.withAlpha(30),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.person_rounded,
                        size: 16, color: PSColors.brand),
                  ),
                  title: Text(c['name'] as String,
                      style: PSText.bodySmall(
                          color: isDark ? PSColors.textDark1 : PSColors.textLight1)),
                  subtitle: c['phone'] != null
                      ? Text(c['phone'] as String,
                          style: PSText.caption(color: PSColors.textDark3))
                      : null,
                  onTap: () => _selectClient(c),
                );
              },
            ),
          ),
      ],
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    required bool isDark,
    String? Function(String?)? validator,
    TextInputType? keyboardType,
    int maxLines = 1,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      maxLines: maxLines,
      style: PSText.body(color: isDark ? PSColors.textDark1 : PSColors.textLight1),
      validator: validator,
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: PSText.body(color: PSColors.textDark3).copyWith(fontSize: 14),
        prefixIcon: Icon(icon, size: 18,
            color: isDark ? PSColors.textDark3 : PSColors.textLight3),
      ),
    );
  }

  Widget _buildDropdown({
    required String value,
    required List<String> items,
    required bool isDark,
    required ValueChanged<String?> onChanged,
  }) {
    return DropdownButtonFormField<String>(
      value: value,
      items: items
          .map((u) => DropdownMenuItem(
                value: u,
                child: Text(u,
                    style: PSText.bodySmall(
                        color: isDark ? PSColors.textDark1 : PSColors.textLight1)),
              ))
          .toList(),
      onChanged: onChanged,
      style: PSText.body(color: isDark ? PSColors.textDark1 : PSColors.textLight1),
      dropdownColor: isDark ? PSColors.darkElevated : PSColors.lightCard,
      decoration: InputDecoration(
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
        filled: true,
        fillColor: isDark ? PSColors.darkCard : PSColors.lightCard,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(PSRadius.sm),
          borderSide: BorderSide(
            color: isDark ? PSColors.darkBorder : PSColors.lightBorder,
            width: 0.5,
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(PSRadius.sm),
          borderSide: BorderSide(
            color: isDark ? PSColors.darkBorder : PSColors.lightBorder,
            width: 0.5,
          ),
        ),
      ),
    );
  }

  Widget _buildPrioritySelector(bool isDark) {
    return Row(
      children: _priorities.map((p) {
        final isSelected = _priority == p;
        final color = PSColors.forPriority(p);
        return Expanded(
          child: GestureDetector(
            onTap: () {
              HapticFeedback.selectionClick();
              setState(() => _priority = p);
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              margin: EdgeInsets.only(
                  right: p == _priorities.last ? 0 : 8),
              padding: const EdgeInsets.symmetric(vertical: 10),
              decoration: BoxDecoration(
                color: isSelected ? color.withAlpha(40) : Colors.transparent,
                borderRadius: BorderRadius.circular(PSRadius.sm),
                border: Border.all(
                  color: isSelected ? color : (isDark ? PSColors.darkBorder : PSColors.lightBorder),
                  width: isSelected ? 1.5 : 0.5,
                ),
              ),
              child: Column(
                children: [
                  Container(
                    width: 8, height: 8,
                    decoration: BoxDecoration(
                      color: color,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    p,
                    style: PSText.caption(
                        color: isSelected ? color : (isDark ? PSColors.textDark3 : PSColors.textLight3))
                        .copyWith(fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500),
                  ),
                ],
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildDueDateTile(bool isDark) {
    return GestureDetector(
      onTap: _pickDueDate,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: isDark ? PSColors.darkCard : PSColors.lightCard,
          borderRadius: BorderRadius.circular(PSRadius.sm),
          border: Border.all(
            color: _dueDate != null
                ? PSColors.brand.withAlpha(150)
                : isDark ? PSColors.darkBorder : PSColors.lightBorder,
            width: _dueDate != null ? 1 : 0.5,
          ),
        ),
        child: Row(
          children: [
            Icon(
              Icons.calendar_today_rounded,
              size: 18,
              color: _dueDate != null ? PSColors.brand : PSColors.textDark3,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _dueDate != null
                  ? Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Due ${_formatDue(_dueDate!)}',
                          style: PSText.body(
                              color: isDark ? PSColors.textDark1 : PSColors.textLight1,
                              weight: FontWeight.w600),
                        ),
                        Text(
                          _timeUntilDue(_dueDate!),
                          style: PSText.caption(color: PSColors.textDark3),
                        ),
                      ],
                    )
                  : Text(
                      'Set due date & time  (required)',
                      style: PSText.body(color: PSColors.textDark3),
                    ),
            ),
            Icon(Icons.chevron_right_rounded,
                size: 18,
                color: isDark ? PSColors.textDark3 : PSColors.textLight3),
          ],
        ),
      ),
    );
  }

  Widget _buildDurationSelector(bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Row(
            children: [
              Icon(Icons.timer_outlined,
                  size: 16,
                  color: isDark ? PSColors.textDark3 : PSColors.textLight3),
              const SizedBox(width: 8),
              Text(
                'Estimated Duration',
                style: PSText.bodySmall(
                    color: isDark ? PSColors.textDark2 : PSColors.textLight2),
              ),
              const Spacer(),
              Text(
                _formatDuration(_durationMins),
                style: PSText.bodySmall(color: PSColors.brand)
                    .copyWith(fontWeight: FontWeight.w700),
              ),
            ],
          ),
        ),
        SizedBox(
          height: 36,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: _durations.length,
            separatorBuilder: (_, __) => const SizedBox(width: 8),
            itemBuilder: (_, i) {
              final d = _durations[i];
              final isSelected = _durationMins == d;
              return GestureDetector(
                onTap: () {
                  HapticFeedback.selectionClick();
                  setState(() => _durationMins = d);
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: isSelected ? PSColors.brand : Colors.transparent,
                    borderRadius: BorderRadius.circular(PSRadius.full),
                    border: Border.all(
                      color: isSelected
                          ? PSColors.brand
                          : isDark ? PSColors.darkBorder : PSColors.lightBorder,
                      width: 0.5,
                    ),
                  ),
                  child: Text(
                    _formatDuration(d),
                    style: PSText.caption(
                      color: isSelected
                          ? Colors.white
                          : isDark ? PSColors.textDark2 : PSColors.textLight2,
                    ).copyWith(fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  // ── Helpers ───────────────────────────────────────────────────────────────

  String _formatDue(DateTime dt) {
    final months = ['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'];
    final hour = dt.hour > 12 ? dt.hour - 12 : (dt.hour == 0 ? 12 : dt.hour);
    final period = dt.hour >= 12 ? 'PM' : 'AM';
    final min = dt.minute.toString().padLeft(2, '0');
    return '${dt.day} ${months[dt.month - 1]} ${dt.year}, $hour:$min $period';
  }

  String _timeUntilDue(DateTime dt) {
    final diff = dt.difference(DateTime.now());
    if (diff.isNegative) return 'Already passed';
    if (diff.inDays > 0) return '${diff.inDays} day${diff.inDays > 1 ? "s" : ""} from now';
    if (diff.inHours > 0) return '${diff.inHours}h from now';
    return '${diff.inMinutes}m from now';
  }

  String _formatDuration(int mins) {
    if (mins < 60) return '${mins}m';
    final h = mins ~/ 60;
    final m = mins % 60;
    return m == 0 ? '${h}h' : '${h}h ${m}m';
  }
}

// ── Section Label ─────────────────────────────────────────────────────────────

class _SectionLabel extends StatelessWidget {
  final String label;
  final bool isDark;
  const _SectionLabel({required this.label, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        label.toUpperCase(),
        style: PSText.sectionHeader(
          color: isDark ? PSColors.textDark3 : PSColors.textLight3,
        ),
      ),
    );
  }
}

// (end of file)
