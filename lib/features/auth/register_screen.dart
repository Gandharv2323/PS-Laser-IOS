import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/providers/session_provider.dart';
import '../../core/providers/theme_provider.dart';
import '../../core/services/notification_service.dart';
import '../../core/theme/app_theme.dart';
import 'secure_auth_service.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _pinCtrl = TextEditingController();
  final _confirmPinCtrl = TextEditingController();
  final _departmentCtrl = TextEditingController();
  final _secretAnswerCtrl = TextEditingController();
  bool _obscurePin = true;
  bool _obscureConfirmPin = true;
  bool _isLoading = false;
  String? _error;
  String _selectedRole = 'Worker';
  String _selectedShift = 'Morning';
  String _selectedQuestion = 'What was the name of your first pet?';

  final List<String> _roles = ['Worker', 'Supervisor', 'Manager'];
  final List<String> _shifts = ['Morning', 'Afternoon', 'Night'];
  final List<String> _secretQuestions = [
    'What was the name of your first pet?',
    'What city were you born in?',
    'What is your mother\'s maiden name?',
    'What was the name of your first school?',
    'What was your childhood nickname?',
    'What is the name of your favorite teacher?',
  ];

  Future<void> _register() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      // Check if name is already taken
      if (await SecureAuthService.isNameTaken(_nameCtrl.text.trim())) {
        setState(() {
          _isLoading = false;
          _error = 'Name already exists. Please choose a different name.';
        });
        return;
      }

      // Register new user
      final user = await SecureAuthService.registerUser(
        name: _nameCtrl.text.trim(),
        pin: _pinCtrl.text,
        role: _selectedRole,
        department: _departmentCtrl.text.trim(),
        shift: _selectedShift,
        secretQuestion: _selectedQuestion,
        secretAnswer: _secretAnswerCtrl.text.trim(),
      );

      // Create secure session — Remember Me ON by default at registration
      await SecureAuthService.createSecureSession(user, rememberMe: true);

      if (!mounted) return;

      // Convert role string to UserRole enum
      UserRole role;
      switch (user['role'] as String) {
        case 'Owner':
          role = UserRole.owner;
          break;
        case 'Manager':
          role = UserRole.manager;
          break;
        case 'Supervisor':
          role = UserRole.supervisor;
          break;
        default:
          role = UserRole.worker;
      }

      // Auto-login the new user
      await context.read<SessionProvider>().login(
        userId: user['id'] as String,
        userName: user['name'] as String,
        role: role,
        department: user['department'] as String,
        shift: user['shift'] as String,
        teamIds: const <String>[],
      );
      // Bind FCM token to this employee for push notifications
      await NotificationService.bindEmployee(user['id'] as String);

    } catch (e) {
      setState(() {
        _isLoading = false;
        _error = e.toString();
      });
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _pinCtrl.dispose();
    _confirmPinCtrl.dispose();
    _departmentCtrl.dispose();
    _secretAnswerCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final themeProvider = context.read<ThemeProvider>();

    return Scaffold(
      backgroundColor: isDark ? AppTheme.darkBg : const Color(0xFF0A1628),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            children: [
              // Header
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 32,
                ),
                child: Column(
                  children: [
                    Container(
                      width: 72,
                      height: 72,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF059669).withValues(alpha: 0.4),
                            blurRadius: 24,
                            spreadRadius: 2,
                          ),
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(20),
                        child: Image.asset(
                          'assets/ps.png',
                          width: 72,
                          height: 72,
                          fit: BoxFit.contain,
                          errorBuilder: (context, error, stackTrace) {
                            // Fallback to icon if image fails to load
                            return Container(
                              width: 72,
                              height: 72,
                              decoration: const BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [Color(0xFF059669), Color(0xFF10B981)],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                              ),
                              child: const Icon(
                                Icons.person_add_rounded,
                                color: Colors.white,
                                size: 40,
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      'Join ForgeOps',
                      style: GoogleFonts.inter(
                        fontSize: 28,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                        letterSpacing: -0.5,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Create your account to get started',
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        color: const Color(0xFF9CA3AF),
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  ],
                ),
              ),

              // Form card
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 24),
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: isDark ? AppTheme.darkCard : Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isDark
                        ? AppTheme.darkBorder
                        : const Color(0xFFE5E7EB),
                  ),
                ),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Create Account',
                        style: GoogleFonts.inter(
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                          color: isDark
                              ? Colors.white
                              : const Color(0xFF111827),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Fill in your details to register',
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          color: const Color(0xFF6B7280),
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Full Name
                      _buildTextField(
                        label: 'Full Name',
                        controller: _nameCtrl,
                        icon: Icons.person_outline,
                        hintText: 'Enter your full name',
                        validator: (v) => (v?.isEmpty ?? true)
                            ? 'Enter your full name'
                            : null,
                      ),
                      const SizedBox(height: 16),

                      // Department
                      _buildTextField(
                        label: 'Department',
                        controller: _departmentCtrl,
                        icon: Icons.business_outlined,
                        hintText: 'e.g. Production, Quality, Maintenance',
                        validator: (v) => (v?.isEmpty ?? true)
                            ? 'Enter your department'
                            : null,
                      ),
                      const SizedBox(height: 16),

                      // Role dropdown (full width)
                      Text(
                        'Role',
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
                        isExpanded: true,
                        initialValue: _selectedRole,
                        onChanged: (value) =>
                            setState(() => _selectedRole = value!),
                        decoration: _buildInputDecoration(
                          context,
                          Icons.badge_outlined,
                          'Select role',
                        ),
                        items: _roles
                            .map((role) => DropdownMenuItem(
                                  value: role,
                                  child: Text(role,
                                      overflow: TextOverflow.ellipsis),
                                ))
                            .toList(),
                      ),
                      const SizedBox(height: 16),

                      // Shift dropdown (full width)
                      Text(
                        'Shift',
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
                        isExpanded: true,
                        initialValue: _selectedShift,
                        onChanged: (value) =>
                            setState(() => _selectedShift = value!),
                        decoration: _buildInputDecoration(
                          context,
                          Icons.schedule_outlined,
                          'Select shift',
                        ),
                        items: _shifts
                            .map((shift) => DropdownMenuItem(
                                  value: shift,
                                  child: Text(shift,
                                      overflow: TextOverflow.ellipsis),
                                ))
                            .toList(),
                      ),
                      const SizedBox(height: 16),

                      // PIN
                      _buildTextField(
                        label: 'Create PIN',
                        controller: _pinCtrl,
                        icon: Icons.lock_outline,
                        hintText: 'Enter 4-6 digit PIN',
                        obscureText: _obscurePin,
                        keyboardType: TextInputType.number,
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscurePin
                                ? Icons.visibility_off_outlined
                                : Icons.visibility_outlined,
                            size: 20,
                          ),
                          onPressed: () => setState(() => _obscurePin = !_obscurePin),
                        ),
                        validator: (v) {
                          if (v?.isEmpty ?? true) return 'Enter a PIN';
                          if (v!.length < 4) return 'PIN must be at least 4 digits';
                          if (v.length > 6) return 'PIN must be 6 digits or less';
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),

                      // Confirm PIN
                      _buildTextField(
                        label: 'Confirm PIN',
                        controller: _confirmPinCtrl,
                        icon: Icons.lock_outline,
                        hintText: 'Re-enter your PIN',
                        obscureText: _obscureConfirmPin,
                        keyboardType: TextInputType.number,
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscureConfirmPin
                                ? Icons.visibility_off_outlined
                                : Icons.visibility_outlined,
                            size: 20,
                          ),
                          onPressed: () => setState(() => _obscureConfirmPin = !_obscureConfirmPin),
                        ),
                        validator: (v) {
                          if (v?.isEmpty ?? true) return 'Confirm your PIN';
                          if (v != _pinCtrl.text) return 'PINs do not match';
                          return null;
                        },
                      ),

                      // ── Security Question (for Forgot PIN) ──────────────
                      const SizedBox(height: 20),
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: const Color(0xFF1565C0).withValues(alpha: 0.06),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: const Color(0xFF1565C0).withValues(alpha: 0.15),
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                const Icon(Icons.shield_outlined,
                                    size: 16, color: Color(0xFF1565C0)),
                                const SizedBox(width: 6),
                                Text(
                                  'PIN Recovery Setup',
                                  style: GoogleFonts.inter(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w700,
                                    color: const Color(0xFF1565C0),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Used if you forget your PIN',
                              style: GoogleFonts.inter(
                                fontSize: 11,
                                color: const Color(0xFF6B7280),
                              ),
                            ),
                            const SizedBox(height: 12),
                            Text(
                              'Security Question',
                              style: GoogleFonts.inter(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: isDark
                                    ? const Color(0xFFD1D5DB)
                                    : const Color(0xFF374151),
                              ),
                            ),
                            const SizedBox(height: 6),
                            DropdownButtonFormField<String>(
                              initialValue: _selectedQuestion,
                              isExpanded: true,
                              decoration: _buildInputDecoration(
                                  context, Icons.help_outline, ''),
                              items: _secretQuestions
                                  .map((q) => DropdownMenuItem(
                                      value: q,
                                      child: Text(q,
                                          style: GoogleFonts.inter(
                                              fontSize: 13),
                                          overflow: TextOverflow.ellipsis)))
                                  .toList(),
                              onChanged: (v) =>
                                  setState(() => _selectedQuestion = v!),
                            ),
                            const SizedBox(height: 12),
                            _buildTextField(
                              label: 'Your Answer',
                              controller: _secretAnswerCtrl,
                              icon: Icons.question_answer_outlined,
                              hintText: 'Type your answer (keep it memorable)',
                              validator: (v) {
                                if (v == null || v.trim().isEmpty) {
                                  return 'Set a secret answer for PIN recovery';
                                }
                                return null;
                              },
                            ),
                          ],
                        ),
                      ),

                      if (_error != null) ...[
                        const SizedBox(height: 12),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 10,
                          ),
                          decoration: BoxDecoration(
                            color: AppTheme.accentRed.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: AppTheme.accentRed.withValues(alpha: 0.3),
                            ),
                          ),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.error_outline,
                                size: 16,
                                color: AppTheme.accentRed,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  _error!,
                                  style: GoogleFonts.inter(
                                    fontSize: 13,
                                    color: AppTheme.accentRed,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],

                      const SizedBox(height: 24),
                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: ElevatedButton(
                          onPressed: _isLoading ? null : _register,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF059669),
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: _isLoading
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    color: Colors.white,
                                    strokeWidth: 2,
                                  ),
                                )
                              : Text(
                                  'Create Account',
                                  style: GoogleFonts.inter(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        child: TextButton(
                          onPressed: () => Navigator.of(context).pop(),
                          child: Text(
                            'Already have an account? Sign In',
                            style: GoogleFonts.inter(
                              fontSize: 14,
                              color: const Color(0xFF059669),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Theme toggle
              TextButton.icon(
                onPressed: () => themeProvider.toggleTheme(),
                icon: Icon(
                  isDark ? Icons.light_mode_outlined : Icons.dark_mode_outlined,
                  size: 18,
                  color: const Color(0xFF6B7280),
                ),
                label: Text(
                  isDark ? 'Switch to Light Mode' : 'Switch to Dark Mode',
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    color: const Color(0xFF6B7280),
                  ),
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required String label,
    required TextEditingController controller,
    required IconData icon,
    required String hintText,
    bool obscureText = false,
    TextInputType? keyboardType,
    Widget? suffixIcon,
    String? Function(String?)? validator,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: isDark
                ? const Color(0xFFD1D5DB)
                : const Color(0xFF374151),
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          obscureText: obscureText,
          keyboardType: keyboardType,
          style: GoogleFonts.inter(
            fontSize: 15,
            color: isDark ? Colors.white : const Color(0xFF111827),
          ),
          decoration: _buildInputDecoration(context, icon, hintText, suffixIcon: suffixIcon),
          validator: validator,
        ),
      ],
    );
  }

  InputDecoration _buildInputDecoration(
    BuildContext context,
    IconData icon,
    String hintText, {
    Widget? suffixIcon,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return InputDecoration(
      hintText: hintText,
      prefixIcon: Icon(icon, size: 20),
      suffixIcon: suffixIcon,
      filled: true,
      fillColor: isDark ? AppTheme.darkBg : const Color(0xFFF9FAFB),
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
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(
          color: Color(0xFF059669),
          width: 1.5,
        ),
      ),
    );
  }
}