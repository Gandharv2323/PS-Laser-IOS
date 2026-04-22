import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/services/firestore_service.dart';
import '../../core/providers/session_provider.dart';
import '../../core/providers/theme_provider.dart';
import '../../core/services/secure_storage_service.dart';
import '../../core/theme/app_theme.dart';
import 'edit_user_screen.dart';

class SettingsHubScreen extends StatelessWidget {
  const SettingsHubScreen({super.key});

  Future<void> _showApiKeyDialog(BuildContext context) async {
    final currentKey = await SecureStorageService.getOpenRouterKey() ?? '';
    final ctrl = TextEditingController(text: currentKey);

    if (!context.mounted) return;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('OpenRouter API Key'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Get your free key at openrouter.ai',
              style: TextStyle(fontSize: 12, color: Color(0xFF6B7280)),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: ctrl,
              decoration: const InputDecoration(
                hintText: 'sk-or-v1-...',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.vpn_key_outlined),
              ),
              obscureText: true,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              await SecureStorageService.setOpenRouterKey(ctrl.text.trim());
              if (ctx.mounted) {
                Navigator.pop(ctx);
                ScaffoldMessenger.of(ctx).showSnackBar(
                  const SnackBar(
                    content: Text('API Key saved securely.'),
                    backgroundColor: Color(0xFF059669),
                  ),
                );
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final session = context.watch<SessionProvider>().session;
    final isAdmin =
        session.role == UserRole.owner || session.role == UserRole.manager;

    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Profile card
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF1565C0), Color(0xFF1976D2)],
                ),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 28,
                    backgroundColor: Colors.white.withValues(alpha: 0.2),
                    child: Text(
                      session.userName.isNotEmpty ? session.userName[0] : 'U',
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          session.userName,
                          style: GoogleFonts.inter(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                        Text(
                          session.role.name.toUpperCase(),
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 12,
                          ),
                        ),
                        Text(
                          session.department,
                          style: const TextStyle(
                            color: Colors.white60,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // App Preferences
            _SettingSection('APP PREFERENCES', [
              _SettingTile(
                icon: Icons.dark_mode_outlined,
                title: 'Dark Mode',
                subtitle: isDark ? 'Enabled' : 'Disabled',
                color: const Color(0xFF7C3AED),
                trailing: Switch(
                  value: isDark,
                  onChanged: (_) => context.read<ThemeProvider>().toggleTheme(),
                  activeThumbColor: AppTheme.primaryBlue,
                ),
              ),
            ], isDark),

            // AI Integration
            if (isAdmin) ...[
              const SizedBox(height: 16),
              _SettingSection('AI INTEGRATION', [
                _SettingTile(
                  icon: Icons.auto_awesome_outlined,
                  title: 'OpenRouter API Key',
                  subtitle: 'GPT-OSS 120B · openrouter.ai',
                  color: const Color(0xFF0F9D58),
                  onTap: () => _showApiKeyDialog(context),
                ),
              ], isDark),
            ],

            // Admin settings
            if (isAdmin) ...[
              const SizedBox(height: 16),
              _SettingSection('ADMINISTRATION', [
                _SettingTile(
                  icon: Icons.business_outlined,
                  title: 'Company Profile',
                  color: AppTheme.primaryBlue,
                  onTap: () => context.go('/settings/company-profile'),
                ),
                _SettingTile(
                  icon: Icons.manage_accounts_outlined,
                  title: 'User Management',
                  color: AppTheme.accentOrange,
                  onTap: () => context.go('/settings/user-management'),
                ),
                _SettingTile(
                  icon: Icons.security_outlined,
                  title: 'Role Permissions',
                  color: const Color(0xFF7C3AED),
                  onTap: () => context.go('/settings/role-permissions'),
                ),
                _SettingTile(
                  icon: Icons.schedule_outlined,
                  title: 'Shift Templates',
                  color: AppTheme.statusRunning,
                  onTap: () => context.go('/settings/shift-templates'),
                ),
                _SettingTile(
                  icon: Icons.tune_outlined,
                  title: 'System Config',
                  color: const Color(0xFF00838F),
                  onTap: () => context.go('/settings/system-config'),
                ),
              ], isDark),
              const SizedBox(height: 16),
              _SettingSection('DATA & BACKUP', [
                _SettingTile(
                  icon: Icons.backup_outlined,
                  title: 'Backup & Restore',
                  color: AppTheme.accentYellow,
                  onTap: () => context.go('/settings/backup-restore'),
                ),
                _SettingTile(
                  icon: Icons.developer_mode_outlined,
                  title: 'Developer Tools',
                  color: AppTheme.accentRed,
                  onTap: () => context.go('/settings/developer-tools'),
                ),
              ], isDark),
            ],

            const SizedBox(height: 16),
            _SettingSection('ACCOUNT', [
              _SettingTile(
                icon: Icons.logout_outlined,
                title: 'Logout',
                subtitle: 'Sign out of your account',
                color: AppTheme.accentRed,
                onTap: () async {
                  final sessionProv = context.read<SessionProvider>();
                  final confirmed = await showDialog<bool>(
                    context: context,
                    builder: (_) => AlertDialog(
                      title: const Text('Confirm Logout'),
                      content: const Text('Are you sure you want to log out?'),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context, false),
                          child: const Text('Cancel'),
                        ),
                        ElevatedButton(
                          onPressed: () => Navigator.pop(context, true),
                          child: const Text('Logout'),
                        ),
                      ],
                    ),
                  );
                  if (confirmed == true && context.mounted) {
                    await sessionProv.logout();
                    if (context.mounted) context.go('/login');
                  }
                },
              ),
            ], isDark),

            const SizedBox(height: 16),
            Center(
              child: Text(
                'ForgeOps v1.0.0 • PS Laser',
                style: GoogleFonts.inter(
                  fontSize: 11,
                  color: const Color(0xFF4B5563),
                ),
              ),
            ),
            const SizedBox(height: 80),
          ],
        ),
      ),
    );
  }
}

class _SettingSection extends StatelessWidget {
  final String title;
  final List<Widget> tiles;
  final bool isDark;
  const _SettingSection(this.title, this.tiles, this.isDark);

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: GoogleFonts.inter(
            fontSize: 10,
            fontWeight: FontWeight.w700,
            color: const Color(0xFF6B7280),
            letterSpacing: 1.2,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: isDark ? AppTheme.darkCard : Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isDark ? AppTheme.darkBorder : const Color(0xFFE5E7EB),
            ),
          ),
          child: Column(
            children: tiles
                .asMap()
                .entries
                .map(
                  (e) => Column(
                    children: [
                      e.value,
                      if (e.key < tiles.length - 1)
                        Divider(
                          height: 1,
                          indent: 52,
                          color: isDark
                              ? AppTheme.darkBorder
                              : const Color(0xFFF3F4F6),
                        ),
                    ],
                  ),
                )
                .toList(),
          ),
        ),
      ],
    );
  }
}

class _SettingTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final Color color;
  final VoidCallback? onTap;
  final Widget? trailing;
  const _SettingTile({
    required this.icon,
    required this.title,
    this.subtitle,
    required this.color,
    this.onTap,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return ListTile(
      onTap: onTap,
      leading: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, color: color, size: 18),
      ),
      title: Text(
        title,
        style: GoogleFonts.inter(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: isDark ? Colors.white : const Color(0xFF111827),
        ),
      ),
      subtitle: subtitle != null
          ? Text(
              subtitle!,
              style: const TextStyle(fontSize: 12, color: Color(0xFF6B7280)),
            )
          : null,
      trailing:
          trailing ??
          (onTap != null
              ? const Icon(
                  Icons.chevron_right,
                  size: 18,
                  color: Color(0xFF6B7280),
                )
              : null),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
    );
  }
}

class CompanyProfileScreen extends StatefulWidget {
  const CompanyProfileScreen({super.key});
  @override
  State<CompanyProfileScreen> createState() => _CompanyProfileScreenState();
}

class _CompanyProfileScreenState extends State<CompanyProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _companyNameCtrl = TextEditingController();
  final _addressCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _gstinCtrl = TextEditingController();
  final _panCtrl = TextEditingController();
  bool _saving = false;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;
    setState(() {
      _companyNameCtrl.text = prefs.getString('co_name') ?? 'PS Laser Industries';
      _addressCtrl.text = prefs.getString('co_address') ?? 'Mumbai, Maharashtra';
      _phoneCtrl.text = prefs.getString('co_phone') ?? '+91 98765 43210';
      _emailCtrl.text = prefs.getString('co_email') ?? 'info@pslaser.com';
      _gstinCtrl.text = prefs.getString('co_gstin') ?? '27AABC1234D1Z5';
      _panCtrl.text = prefs.getString('co_pan') ?? 'AABC1234D';
      _loading = false;
    });
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    if (!mounted) return;
    setState(() => _saving = true);

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('co_name', _companyNameCtrl.text.trim());
    await prefs.setString('co_address', _addressCtrl.text.trim());
    await prefs.setString('co_phone', _phoneCtrl.text.trim());
    await prefs.setString('co_email', _emailCtrl.text.trim());
    await prefs.setString('co_gstin', _gstinCtrl.text.trim());
    await prefs.setString('co_pan', _panCtrl.text.trim());

    if (!mounted) return;
    setState(() => _saving = false);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Company profile saved successfully'),
        backgroundColor: Color(0xFF059669),
      ),
    );
  }

  @override
  void dispose() {
    _companyNameCtrl.dispose();
    _addressCtrl.dispose();
    _phoneCtrl.dispose();
    _emailCtrl.dispose();
    _gstinCtrl.dispose();
    _panCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    if (_loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    return Scaffold(
      appBar: AppBar(
        title: const Text('Company Profile'),
        leading: BackButton(onPressed: () => context.go('/settings')),
        actions: [
          TextButton(
            onPressed: _saving ? null : _save,
            child: _saving
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('Save'),
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
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF1565C0), Color(0xFF1976D2)],
                  ),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.business,
                        color: Colors.white,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Company Information',
                            style: GoogleFonts.inter(
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                          ),
                          const Text(
                            'Manage business details and registration info',
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              _buildField(
                'Company Name',
                _companyNameCtrl,
                Icons.business_outlined,
                isDark,
                required: true,
              ),
              const SizedBox(height: 16),
              _buildField(
                'Address',
                _addressCtrl,
                Icons.location_on_outlined,
                isDark,
                maxLines: 3,
              ),
              const SizedBox(height: 16),
              _buildField(
                'Phone',
                _phoneCtrl,
                Icons.phone_outlined,
                isDark,
                keyboardType: TextInputType.phone,
              ),
              const SizedBox(height: 16),
              _buildField(
                'Email',
                _emailCtrl,
                Icons.email_outlined,
                isDark,
                keyboardType: TextInputType.emailAddress,
              ),
              const SizedBox(height: 16),
              _buildField('GSTIN', _gstinCtrl, Icons.receipt_outlined, isDark),
              const SizedBox(height: 16),
              _buildField('PAN', _panCtrl, Icons.credit_card_outlined, isDark),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton.icon(
                  onPressed: _saving ? null : _save,
                  icon: _saving
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : const Icon(Icons.save_outlined),
                  label: Text(_saving ? 'Saving...' : 'Save Changes'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryBlue,
                    foregroundColor: Colors.white,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildField(
    String label,
    TextEditingController ctrl,
    IconData icon,
    bool isDark, {
    bool required = false,
    int maxLines = 1,
    TextInputType? keyboardType,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label + (required ? ' *' : ''),
          style: GoogleFonts.inter(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: isDark ? const Color(0xFFD1D5DB) : const Color(0xFF374151),
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: ctrl,
          maxLines: maxLines,
          keyboardType: keyboardType,
          validator: required
              ? (v) => v?.isEmpty ?? true ? 'Required' : null
              : null,
          decoration: InputDecoration(
            prefixIcon: Icon(icon, size: 18),
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

class UserManagementScreen extends StatefulWidget {
  const UserManagementScreen({super.key});
  @override
  State<UserManagementScreen> createState() => _UserManagementScreenState();
}

class _UserManagementScreenState extends State<UserManagementScreen> {
  List<Map<String, dynamic>> _users = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadUsers();
  }

  Future<void> _loadUsers() async {
    if (!mounted) return;
    final snap = await FirestoreService.employees.orderBy('name').get();
    if (mounted) {
      setState(() {
        _users = snap.docs.map(FirestoreService.docToMap).toList();
        _loading = false;
      });
    }
  }

  Future<void> _toggleUserStatus(String userId, bool isActive) async {
    await FirestoreService.employees.doc(userId).update({'is_active': isActive ? 1 : 0});
    await _loadUsers();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'User ${isActive ? 'activated' : 'deactivated'} successfully',
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      appBar: AppBar(
        title: const Text('User Management'),
        leading: BackButton(onPressed: () => context.go('/settings')),
        actions: [
          IconButton(
            icon: const Icon(Icons.person_add_outlined),
            onPressed: () => _showAddUserDialog(),
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Container(
                  margin: const EdgeInsets.all(16),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFFFF6B35), Color(0xFFFF8A65)],
                    ),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.people,
                          color: Colors.white,
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '${_users.length} Users',
                              style: GoogleFonts.inter(
                                fontSize: 18,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                              ),
                            ),
                            Text(
                              '${_users.where((u) => (u['is_active'] as int? ?? 0) == 1).length} active users',
                              style: const TextStyle(
                                color: Colors.white70,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: _users.length,
                    itemBuilder: (_, i) {
                      final user = _users[i];
                      final isActive = (user['is_active'] as int? ?? 0) == 1;
                      return Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        decoration: BoxDecoration(
                          color: isDark ? AppTheme.darkCard : Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: isDark
                                ? AppTheme.darkBorder
                                : const Color(0xFFE5E7EB),
                          ),
                        ),
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor: AppTheme.primaryBlue.withValues(
                              alpha: 0.1,
                            ),
                            child: Text(
                              (user['name'] as String)[0],
                              style: const TextStyle(
                                color: AppTheme.primaryBlue,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          title: Text(
                            user['name'] as String,
                            style: GoogleFonts.inter(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '${user['designation']} • ${user['department']}',
                                style: const TextStyle(fontSize: 12),
                              ),
                              const SizedBox(height: 2),
                              Row(
                                children: [
                                  Container(
                                    width: 8,
                                    height: 8,
                                    decoration: BoxDecoration(
                                      color: isActive
                                          ? AppTheme.statusRunning
                                          : AppTheme.accentRed,
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    isActive ? 'Active' : 'Inactive',
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: isActive
                                          ? AppTheme.statusRunning
                                          : AppTheme.accentRed,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          trailing: PopupMenuButton(
                            icon: const Icon(Icons.more_vert, size: 18),
                            itemBuilder: (_) => [
                              PopupMenuItem(
                                child: ListTile(
                                  leading: Icon(
                                    isActive
                                        ? Icons.person_off_outlined
                                        : Icons.person_outlined,
                                    size: 18,
                                  ),
                                  title: Text(
                                    isActive ? 'Deactivate' : 'Activate',
                                    style: const TextStyle(fontSize: 13),
                                  ),
                                  contentPadding: EdgeInsets.zero,
                                ),
                                onTap: () => _toggleUserStatus(
                                  user['id'] as String,
                                  !isActive,
                                ),
                              ),
                              PopupMenuItem(
                                child: const ListTile(
                                  leading: Icon(Icons.edit_outlined, size: 18),
                                  title: Text(
                                    'Edit Details',
                                    style: TextStyle(fontSize: 13),
                                  ),
                                  contentPadding: EdgeInsets.zero,
                                ),
                                onTap: () async {
                                  await Navigator.of(context).push(
                                    MaterialPageRoute(
                                      builder: (_) => EditUserScreen(user: user),
                                    ),
                                  );
                                  // Refresh list after editing
                                  _loadUsers();
                                },
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

  void _showAddUserDialog() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Add User'),
        content: const Text(
          'User creation feature requires full employee onboarding workflow.\n\nFor now, users can be added directly to the database.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              context.go('/settings/developer-tools');
            },
            child: const Text('Developer Tools'),
          ),
        ],
      ),
    );
  }
}


class RolePermissionsScreen extends StatelessWidget {
  const RolePermissionsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final roles = [
      {
        'name': 'OWNER',
        'color': AppTheme.accentRed,
        'permissions': [
          'All Permissions',
          'User Management',
          'System Config',
          'Financial Reports',
        ],
      },
      {
        'name': 'MANAGER',
        'color': AppTheme.primaryBlue,
        'permissions': [
          'View Reports',
          'Manage Orders',
          'View Payroll',
          'Approve Leave',
        ],
      },
      {
        'name': 'SUPERVISOR',
        'color': AppTheme.accentOrange,
        'permissions': [
          'View Machines',
          'Approve Attendance',
          'Manage Work Orders',
        ],
      },
      {
        'name': 'WORKER',
        'color': AppTheme.statusRunning,
        'permissions': ['View Dashboard', 'Clock In/Out', 'Apply Leave'],
      },
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Role Permissions'),
        leading: BackButton(onPressed: () => context.go('/settings')),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF7C3AED), Color(0xFF8B5CF6)],
                ),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.security,
                      color: Colors.white,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Role Permissions',
                          style: GoogleFonts.inter(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                        const Text(
                          'View and manage user role permissions',
                          style: TextStyle(color: Colors.white70, fontSize: 13),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            ...roles.map(
              (role) => Container(
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: isDark ? AppTheme.darkCard : Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isDark
                        ? AppTheme.darkBorder
                        : const Color(0xFFE5E7EB),
                  ),
                ),
                child: ExpansionTile(
                  leading: Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: (role['color'] as Color).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      Icons.person,
                      color: role['color'] as Color,
                      size: 18,
                    ),
                  ),
                  title: Text(
                    role['name'] as String,
                    style: GoogleFonts.inter(fontWeight: FontWeight.w600),
                  ),
                  subtitle: Text(
                    '${(role['permissions'] as List).length} permissions',
                  ),
                  children: [
                    const Divider(height: 1),
                    ...(role['permissions'] as List<String>).map(
                      (perm) => ListTile(
                        leading: const Icon(
                          Icons.check_circle,
                          color: AppTheme.statusRunning,
                          size: 16,
                        ),
                        title: Text(perm, style: const TextStyle(fontSize: 13)),
                        dense: true,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class ShiftTemplatesScreen extends StatelessWidget {
  const ShiftTemplatesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final shifts = [
      {
        'name': 'Morning Shift',
        'time': '06:00 - 14:00',
        'duration': '8 hours',
        'active': true,
      },
      {
        'name': 'Day Shift',
        'time': '09:00 - 17:00',
        'duration': '8 hours',
        'active': true,
      },
      {
        'name': 'Evening Shift',
        'time': '14:00 - 22:00',
        'duration': '8 hours',
        'active': false,
      },
      {
        'name': 'Night Shift',
        'time': '22:00 - 06:00',
        'duration': '8 hours',
        'active': false,
      },
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Shift Templates'),
        leading: BackButton(onPressed: () => context.go('/settings')),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Add shift template feature coming soon'),
                ),
              );
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF059669), Color(0xFF10B981)],
                ),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.schedule,
                      color: Colors.white,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Shift Templates',
                          style: GoogleFonts.inter(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                        const Text(
                          'Manage work shift schedules and timing',
                          style: TextStyle(color: Colors.white70, fontSize: 13),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            ...shifts.map(
              (shift) => Container(
                margin: const EdgeInsets.only(bottom: 12),
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
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color:
                            (shift['active'] as bool
                                    ? AppTheme.statusRunning
                                    : const Color(0xFF6B7280))
                                .withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(
                        Icons.access_time,
                        color: shift['active'] as bool
                            ? AppTheme.statusRunning
                            : const Color(0xFF6B7280),
                        size: 18,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            shift['name'] as String,
                            style: GoogleFonts.inter(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          Text(
                            shift['time'] as String,
                            style: const TextStyle(
                              fontSize: 12,
                              color: Color(0xFF6B7280),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color:
                                (shift['active'] as bool
                                        ? AppTheme.statusRunning
                                        : const Color(0xFF6B7280))
                                    .withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            shift['active'] as bool ? 'ACTIVE' : 'INACTIVE',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              color: shift['active'] as bool
                                  ? AppTheme.statusRunning
                                  : const Color(0xFF6B7280),
                            ),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          shift['duration'] as String,
                          style: const TextStyle(
                            fontSize: 11,
                            color: Color(0xFF6B7280),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class SystemConfigScreen extends StatefulWidget {
  const SystemConfigScreen({super.key});
  @override
  State<SystemConfigScreen> createState() => _SystemConfigScreenState();
}

class _SystemConfigScreenState extends State<SystemConfigScreen> {
  bool _enableNotifications = true;
  bool _autoBackup = false;
  bool _debugMode = false;
  String _workingHours = '8 hours';
  String _overtimeRate = '1.5x';
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadConfig();
  }

  Future<void> _loadConfig() async {
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;
    setState(() {
      _enableNotifications = prefs.getBool('cfg_notifications') ?? true;
      _autoBackup = prefs.getBool('cfg_auto_backup') ?? false;
      _debugMode = prefs.getBool('cfg_debug_mode') ?? false;
      _workingHours = prefs.getString('cfg_working_hours') ?? '8 hours';
      _overtimeRate = prefs.getString('cfg_overtime_rate') ?? '1.5x';
      _loading = false;
    });
  }

  Future<void> _saveConfig() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('cfg_notifications', _enableNotifications);
    await prefs.setBool('cfg_auto_backup', _autoBackup);
    await prefs.setBool('cfg_debug_mode', _debugMode);
    await prefs.setString('cfg_working_hours', _workingHours);
    await prefs.setString('cfg_overtime_rate', _overtimeRate);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('System preferences saved'),
        backgroundColor: Color(0xFF059669),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    if (_loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    return Scaffold(
      appBar: AppBar(
        title: const Text('System Config'),
        leading: BackButton(onPressed: () => context.go('/settings')),
        actions: [
          IconButton(
            icon: const Icon(Icons.save_outlined),
            onPressed: _saveConfig,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
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
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.tune,
                      color: Colors.white,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'System Configuration',
                          style: GoogleFonts.inter(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                        const Text(
                          'App-wide settings and preferences',
                          style: TextStyle(color: Colors.white70, fontSize: 13),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            _buildSection('NOTIFICATIONS', [
              _SettingTile(
                icon: Icons.notifications_outlined,
                title: 'Enable Notifications',
                subtitle: _enableNotifications
                    ? 'Alert notifications enabled'
                    : 'Notifications disabled',
                color: AppTheme.primaryBlue,
                trailing: Switch(
                  value: _enableNotifications,
                  onChanged: (v) => setState(() => _enableNotifications = v),
                  activeThumbColor: AppTheme.primaryBlue,
                ),
              ),
            ], isDark),
            const SizedBox(height: 16),
            _buildSection('DATA & STORAGE', [
              _SettingTile(
                icon: Icons.backup_outlined,
                title: 'Auto Backup',
                subtitle: _autoBackup
                    ? 'Daily backup enabled'
                    : 'Manual backup only',
                color: AppTheme.accentYellow,
                trailing: Switch(
                  value: _autoBackup,
                  onChanged: (v) => setState(() => _autoBackup = v),
                  activeThumbColor: AppTheme.primaryBlue,
                ),
              ),
            ], isDark),
            const SizedBox(height: 16),
            _buildSection('WORKING HOURS', [
              _SettingTile(
                icon: Icons.schedule_outlined,
                title: 'Standard Working Hours',
                subtitle: '$_workingHours per day',
                color: AppTheme.statusRunning,
                onTap: () => _showWorkingHoursDialog(),
              ),
              _SettingTile(
                icon: Icons.trending_up_outlined,
                title: 'Overtime Rate',
                subtitle: '$_overtimeRate base salary',
                color: AppTheme.accentOrange,
                onTap: () => _showOvertimeRateDialog(),
              ),
            ], isDark),
            const SizedBox(height: 16),
            _buildSection('DEVELOPER OPTIONS', [
              _SettingTile(
                icon: Icons.bug_report_outlined,
                title: 'Debug Mode',
                subtitle: _debugMode
                    ? 'Debug logging enabled'
                    : 'Production mode',
                color: AppTheme.accentRed,
                trailing: Switch(
                  value: _debugMode,
                  onChanged: (v) => setState(() => _debugMode = v),
                  activeThumbColor: AppTheme.primaryBlue,
                ),
              ),
              _SettingTile(
                icon: Icons.storage_outlined,
                title: 'Database Info',
                subtitle: 'View SQLite database details',
                color: const Color(0xFF7C3AED),
                onTap: () => _showDatabaseInfo(),
              ),
            ], isDark),
          ],
        ),
      ),
    );
  }

  Widget _buildSection(String title, List<Widget> tiles, bool isDark) {
    return _SettingSection(title, tiles, isDark);
  }

  void _showWorkingHoursDialog() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Working Hours'),
        content: RadioGroup<String>(
          groupValue: _workingHours,
          onChanged: (v) {
            if (v != null) {
              setState(() => _workingHours = v);
              Navigator.pop(context);
            }
          },
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: ['6 hours', '7 hours', '8 hours', '9 hours', '10 hours']
                .map((h) => RadioListTile<String>(value: h, title: Text(h)))
                .toList(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }

  void _showOvertimeRateDialog() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Overtime Rate'),
        content: RadioGroup<String>(
          groupValue: _overtimeRate,
          onChanged: (v) {
            if (v != null) {
              setState(() => _overtimeRate = v);
              Navigator.pop(context);
            }
          },
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: ['1.0x', '1.25x', '1.5x', '2.0x']
                .map((r) => RadioListTile<String>(
                      value: r,
                      title: Text('$r base salary'),
                    ))
                .toList(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }

  void _showDatabaseInfo() async {
    final collections = [
      'employees', 'attendance', 'work_orders', 'inventory',
      'machines', 'cylinders', 'payroll', 'alerts', 'leaves',
      'clients', 'orders', 'inventory_transactions',
    ];
    if (!mounted) return;
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Firestore Info'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Firebase Firestore (Cloud)',
              style: GoogleFonts.inter(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text('Collections: ${collections.length}'),
            const SizedBox(height: 8),
            ...collections.take(5).map((t) => Text('• $t')),
            if (collections.length > 5) Text('... and ${collections.length - 5} more'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }
}


class DeveloperToolsScreen extends StatefulWidget {
  const DeveloperToolsScreen({super.key});
  @override
  State<DeveloperToolsScreen> createState() => _DeveloperToolsScreenState();
}

class _DeveloperToolsScreenState extends State<DeveloperToolsScreen> {
  String _output = '';
  final _sqlCtrl = TextEditingController(
    text: 'SELECT name FROM sqlite_master WHERE type=\'table\'',
  );

  Future<void> _executeQuery() async {
    setState(() => _output = 'Firestore collections: employees, attendance, work_orders,\ninventory, machines, cylinders, payroll, alerts, leaves,\nclients, orders, inventory_transactions.\n\nUse Firebase Console at console.firebase.google.com\nto browse and query your live Firestore data.');
  }

  Future<void> _resetDatabase() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('⚠️ Reset Database'),
        content: const Text(
          'This will delete ALL data and recreate the database with sample data.\n\nThis action cannot be undone. Continue?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.accentRed,
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Reset'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        // This would require adding a reset method to DatabaseHelper
        setState(() {
          _output =
              'Database reset functionality would be implemented here.\nFor safety, this is disabled in production.';
        });
      } catch (e) {
        setState(() => _output = 'Error: $e');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Developer Tools'),
        leading: BackButton(onPressed: () => context.go('/settings')),
        backgroundColor: AppTheme.accentRed,
        foregroundColor: Colors.white,
        iconTheme: const IconThemeData(color: Colors.white),
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
                  colors: [Color(0xFFDC2626), Color(0xFFEF4444)],
                ),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.developer_mode,
                      color: Colors.white,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '⚠️ Developer Mode',
                          style: GoogleFonts.inter(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                        const Text(
                          'Advanced database and system tools',
                          style: TextStyle(color: Colors.white70, fontSize: 13),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'SQL Query',
              style: GoogleFonts.inter(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Container(
              decoration: BoxDecoration(
                color: isDark
                    ? const Color(0xFF1F2937)
                    : const Color(0xFFF9FAFB),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: isDark ? AppTheme.darkBorder : const Color(0xFFE5E7EB),
                ),
              ),
              padding: const EdgeInsets.all(12),
              child: TextField(
                controller: _sqlCtrl,
                maxLines: 4,
                style: GoogleFonts.jetBrainsMono(fontSize: 13),
                decoration: const InputDecoration.collapsed(
                  hintText: 'Enter SQL query...',
                ),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                ElevatedButton.icon(
                  onPressed: _executeQuery,
                  icon: const Icon(Icons.play_arrow, size: 18),
                  label: const Text('Execute'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryBlue,
                    foregroundColor: Colors.white,
                  ),
                ),
                const SizedBox(width: 12),
                OutlinedButton.icon(
                  onPressed: () => _sqlCtrl.clear(),
                  icon: const Icon(Icons.clear, size: 18),
                  label: const Text('Clear'),
                ),
              ],
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Text(
                  'Database Operations',
                  style: GoogleFonts.inter(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const Spacer(),
                TextButton.icon(
                  onPressed: _resetDatabase,
                  icon: const Icon(
                    Icons.warning,
                    color: AppTheme.accentRed,
                    size: 16,
                  ),
                  label: const Text(
                    'Reset DB',
                    style: TextStyle(color: AppTheme.accentRed),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF111827) : Colors.white,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: isDark
                      ? const Color(0xFF374151)
                      : const Color(0xFFE5E7EB),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.terminal, size: 16),
                      const SizedBox(width: 8),
                      Text(
                        'Output',
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: isDark
                          ? const Color(0xFF0F172A)
                          : const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      _output.isEmpty
                          ? 'No output yet. Execute a query to see results.'
                          : _output,
                      style: GoogleFonts.jetBrainsMono(
                        fontSize: 12,
                        color: _output.isEmpty
                            ? const Color(0xFF6B7280)
                            : (isDark ? Colors.white : Colors.black),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Quick Actions',
              style: GoogleFonts.inter(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                ElevatedButton.icon(
                  onPressed: () {
                    _sqlCtrl.text = 'SELECT * FROM employees LIMIT 5';
                  },
                  icon: const Icon(Icons.people, size: 16),
                  label: const Text('View Users'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.accentOrange,
                    foregroundColor: Colors.white,
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: () {
                    _sqlCtrl.text =
                        'SELECT name, current_qty, reorder_level FROM inventory WHERE current_qty <= reorder_level';
                  },
                  icon: const Icon(Icons.inventory, size: 16),
                  label: const Text('Low Stock'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.accentYellow,
                    foregroundColor: Colors.black,
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: () {
                    _sqlCtrl.text =
                        'SELECT COUNT(*) as total_alerts FROM alerts WHERE is_resolved=0';
                  },
                  icon: const Icon(Icons.warning, size: 16),
                  label: const Text('Active Alerts'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.accentRed,
                    foregroundColor: Colors.white,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _sqlCtrl.dispose();
    super.dispose();
  }
}
