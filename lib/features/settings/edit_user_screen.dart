import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../core/services/firestore_service.dart';
import '../../core/providers/session_provider.dart';
import '../../core/theme/app_theme.dart';
import '../auth/secure_auth_service.dart';

class EditUserScreen extends StatefulWidget {
  final Map<String, dynamic> user;
  const EditUserScreen({super.key, required this.user});

  @override
  State<EditUserScreen> createState() => _EditUserScreenState();
}

class _EditUserScreenState extends State<EditUserScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameCtrl;
  late final TextEditingController _newPinCtrl;
  late final TextEditingController _confirmPinCtrl;
  bool _obscureNew = true;
  bool _obscureConfirm = true;
  bool _changingPin = false;
  bool _saving = false;
  bool _isActive = true;
  String? _error;

  String _selectedRole = 'Worker';
  String _selectedDepartment = 'Production';
  String _selectedShift = 'Morning';

  late final String _originalName;

  static const _roles = ['Worker', 'Supervisor', 'Manager', 'Owner'];
  static const _departments = [
    'Production',
    'Maintenance',
    'Quality Control',
    'Logistics',
    'Administration',
    'HR',
    'Finance',
    'Sales',
  ];
  static const _shifts = ['Morning', 'Afternoon', 'Night', 'Rotational'];

  @override
  void initState() {
    super.initState();
    _originalName = widget.user['name'] as String? ?? '';
    _nameCtrl = TextEditingController(text: _originalName);
    _newPinCtrl = TextEditingController();
    _confirmPinCtrl = TextEditingController();
    _selectedRole = widget.user['role'] as String? ?? 'Worker';
    _selectedDepartment = widget.user['department'] as String? ?? 'Production';
    _selectedShift = widget.user['shift'] as String? ?? 'Morning';
    _isActive = (widget.user['is_active'] as int? ?? 1) == 1;

    if (!_roles.contains(_selectedRole)) _selectedRole = 'Worker';
    if (!_departments.contains(_selectedDepartment)) _selectedDepartment = 'Production';
    if (!_shifts.contains(_selectedShift)) _selectedShift = 'Morning';
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _newPinCtrl.dispose();
    _confirmPinCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    final newName = _nameCtrl.text.trim();
    final newPin = _newPinCtrl.text.trim();

    setState(() { _saving = true; _error = null; });

    try {
      if (newName != _originalName) {
        final existing = await FirestoreService.findEmployeeByName(newName);
        final currentId = widget.user['id'].toString();
        if (existing != null && existing['id'].toString() != currentId) {
          setState(() { _saving = false; _error = 'Name "$newName" is already taken.'; });
          return;
        }
      }

      if (_changingPin && newPin.isNotEmpty) {
        if (newPin.length < 4) { setState(() { _saving = false; _error = 'New PIN must be at least 4 digits'; }); return; }
        if (!RegExp(r'^\d+$').hasMatch(newPin)) { setState(() { _saving = false; _error = 'PIN must contain digits only'; }); return; }
        if (newPin != _confirmPinCtrl.text.trim()) { setState(() { _saving = false; _error = 'PINs do not match'; }); return; }
      }

      if (_selectedRole != 'Owner' && (widget.user['role'] as String?) == 'Owner') {
        final employees = await FirestoreService.getEmployees();
        final otherOwners = employees.where((e) =>
          e['role'] == 'Owner' &&
          e['is_active'] == 1 &&
          e['id'].toString() != widget.user['id'].toString()
        ).toList();
        if (otherOwners.isEmpty) {
          setState(() { _saving = false; _error = 'Cannot downgrade the only Owner. Assign another Owner first.'; });
          return;
        }
      }

      await SecureAuthService.updateUser(
        userId: widget.user['id'].toString(),
        name: newName,
        role: _selectedRole,
        department: _selectedDepartment,
        shift: _selectedShift,
        isActive: _isActive,
        newPin: (_changingPin && newPin.isNotEmpty) ? newPin : null,
      );

      if (!mounted) return;
      // ignore unused session read – kept for future refresh integration
      context.read<SessionProvider>();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('User updated successfully ✓'), backgroundColor: Color(0xFF059669)),
      );
      Navigator.of(context).pop(true);
    } catch (e) {
      if (!mounted) return;
      setState(() { _saving = false; _error = 'Save failed: $e'; });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: Text('Edit Employee', style: GoogleFonts.inter(fontWeight: FontWeight.w700)),
        leading: BackButton(onPressed: () => Navigator.of(context).pop()),
        actions: [
          TextButton(
            onPressed: _saving ? null : _save,
            child: _saving
                ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                : Text('Save', style: GoogleFonts.inter(fontWeight: FontWeight.w700)),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Profile header
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(colors: [Color(0xFF1565C0), Color(0xFF1976D2)]),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 28,
                      backgroundColor: Colors.white.withValues(alpha: 0.2),
                      child: Text(
                        _originalName.isNotEmpty ? _originalName[0].toUpperCase() : 'U',
                        style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: Colors.white),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Editing: $_originalName',
                              style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w700, color: Colors.white)),
                          Text('ID: ${widget.user['id']} · ${widget.user['role']}',
                              style: const TextStyle(color: Colors.white70, fontSize: 12)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              _sectionTitle('IDENTITY'),
              const SizedBox(height: 12),
              _buildField(label: 'Full Name *', controller: _nameCtrl, icon: Icons.badge_outlined, isDark: isDark,
                validator: (v) { if (v == null || v.trim().length < 2) return 'Enter a valid name'; return null; }),
              const SizedBox(height: 16),
              _dropdownField(label: 'Role *', icon: Icons.admin_panel_settings_outlined, value: _selectedRole,
                  items: _roles, isDark: isDark, onChanged: (v) => setState(() => _selectedRole = v!)),
              const SizedBox(height: 16),
              _dropdownField(label: 'Department *', icon: Icons.factory_outlined, value: _selectedDepartment,
                  items: _departments, isDark: isDark, onChanged: (v) => setState(() => _selectedDepartment = v!)),
              const SizedBox(height: 16),
              _dropdownField(label: 'Shift *', icon: Icons.schedule_outlined, value: _selectedShift,
                  items: _shifts, isDark: isDark, onChanged: (v) => setState(() => _selectedShift = v!)),

              const SizedBox(height: 24),
              _sectionTitle('ACCOUNT STATUS'),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: _cardDeco(isDark),
                child: Row(
                  children: [
                    Icon(_isActive ? Icons.check_circle_outline : Icons.cancel_outlined,
                        color: _isActive ? AppTheme.statusRunning : AppTheme.accentRed, size: 20),
                    const SizedBox(width: 12),
                    Expanded(child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(_isActive ? 'Account Active' : 'Account Inactive',
                            style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600,
                                color: isDark ? Colors.white : const Color(0xFF111827))),
                        Text(_isActive ? 'User can log in' : 'User is blocked from login',
                            style: const TextStyle(fontSize: 12, color: Color(0xFF6B7280))),
                      ],
                    )),
                    Switch(value: _isActive, onChanged: (v) => setState(() => _isActive = v),
                        activeThumbColor: AppTheme.statusRunning),
                  ],
                ),
              ),

              const SizedBox(height: 24),
              _sectionTitle('SECURITY — ADMIN PIN RESET'),
              const SizedBox(height: 12),
              Container(
                decoration: _cardDeco(isDark),
                child: Column(
                  children: [
                    ListTile(
                      leading: Container(
                        width: 36, height: 36,
                        decoration: BoxDecoration(color: const Color(0xFF7C3AED).withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
                        child: const Icon(Icons.lock_reset, color: Color(0xFF7C3AED), size: 18),
                      ),
                      title: Text('Reset PIN', style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600)),
                      subtitle: Text(_changingPin ? 'Enter new PIN below' : 'Toggle to set a new PIN',
                          style: const TextStyle(fontSize: 12, color: Color(0xFF6B7280))),
                      trailing: Switch(
                        value: _changingPin,
                        onChanged: (v) => setState(() {
                          _changingPin = v;
                          if (!v) { _newPinCtrl.clear(); _confirmPinCtrl.clear(); }
                        }),
                        activeThumbColor: const Color(0xFF7C3AED),
                      ),
                    ),
                    if (_changingPin) ...[
                      const Divider(height: 1, indent: 16),
                      Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          children: [
                            _buildField(label: 'New PIN', controller: _newPinCtrl, icon: Icons.lock_outline,
                              isDark: isDark, obscure: true, obscureToggle: _obscureNew,
                              onToggleObscure: () => setState(() => _obscureNew = !_obscureNew),
                              keyboardType: TextInputType.number),
                            const SizedBox(height: 12),
                            _buildField(label: 'Confirm New PIN', controller: _confirmPinCtrl,
                              icon: Icons.lock_reset_outlined, isDark: isDark, obscure: true,
                              obscureToggle: _obscureConfirm,
                              onToggleObscure: () => setState(() => _obscureConfirm = !_obscureConfirm),
                              keyboardType: TextInputType.number),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),

              if (_error != null) ...[
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppTheme.accentRed.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppTheme.accentRed.withValues(alpha: 0.3)),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.error_outline, size: 16, color: AppTheme.accentRed),
                      const SizedBox(width: 8),
                      Expanded(child: Text(_error!, style: GoogleFonts.inter(fontSize: 13, color: AppTheme.accentRed))),
                    ],
                  ),
                ),
              ],

              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity, height: 52,
                child: ElevatedButton.icon(
                  onPressed: _saving ? null : _save,
                  icon: _saving
                      ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                      : const Icon(Icons.save_outlined),
                  label: Text(_saving ? 'Saving...' : 'Save Changes',
                      style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w700)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryBlue, foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
              const SizedBox(height: 80),
            ],
          ),
        ),
      ),
    );
  }

  Widget _sectionTitle(String text) => Text(text,
      style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.w700,
          color: const Color(0xFF6B7280), letterSpacing: 1.2));

  BoxDecoration _cardDeco(bool isDark) => BoxDecoration(
      color: isDark ? AppTheme.darkCard : Colors.white,
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: isDark ? AppTheme.darkBorder : const Color(0xFFE5E7EB)));

  Widget _buildField({
    required String label,
    required TextEditingController controller,
    required IconData icon,
    required bool isDark,
    String? Function(String?)? validator,
    bool obscure = false,
    bool? obscureToggle,
    VoidCallback? onToggleObscure,
    TextInputType? keyboardType,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600,
            color: isDark ? const Color(0xFFD1D5DB) : const Color(0xFF374151))),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          obscureText: obscure ? (obscureToggle ?? true) : false,
          keyboardType: keyboardType,
          style: GoogleFonts.inter(fontSize: 15, color: isDark ? Colors.white : const Color(0xFF111827)),
          validator: validator,
          decoration: InputDecoration(
            prefixIcon: Icon(icon, size: 18),
            suffixIcon: obscure ? IconButton(
              icon: Icon((obscureToggle ?? true) ? Icons.visibility_off_outlined : Icons.visibility_outlined, size: 20),
              onPressed: onToggleObscure,
            ) : null,
            filled: true,
            fillColor: isDark ? const Color(0xFF0A0E1A) : const Color(0xFFF9FAFB),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(color: isDark ? AppTheme.darkBorder : const Color(0xFFE5E7EB))),
            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: Color(0xFF1565C0), width: 1.5)),
            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          ),
        ),
      ],
    );
  }

  Widget _dropdownField({
    required String label, required IconData icon, required String value,
    required List<String> items, required bool isDark, required ValueChanged<String?> onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600,
            color: isDark ? const Color(0xFFD1D5DB) : const Color(0xFF374151))),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          initialValue: value,
          isExpanded: true,
          decoration: InputDecoration(
            prefixIcon: Icon(icon, size: 18),
            filled: true,
            fillColor: isDark ? const Color(0xFF0A0E1A) : const Color(0xFFF9FAFB),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(color: isDark ? AppTheme.darkBorder : const Color(0xFFE5E7EB))),
            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: Color(0xFF1565C0), width: 1.5)),
            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          ),
          items: items.map((v) => DropdownMenuItem(value: v, child: Text(v))).toList(),
          onChanged: onChanged,
        ),
      ],
    );
  }
}
