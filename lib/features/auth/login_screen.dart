import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/providers/session_provider.dart';
import '../../core/providers/theme_provider.dart';
import '../../core/services/notification_service.dart';
import '../../core/theme/app_theme.dart';
import 'secure_auth_service.dart';
import 'register_screen.dart';
import 'forgot_pin_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _employeeIdCtrl = TextEditingController();
  final _pinCtrl = TextEditingController();
  bool _obscurePin = true;
  bool _isLoading = false;
  bool _rememberMe = true; // Default ON — users stay logged in
  String? _error;
  bool _isInitialized = false;
  bool _hasUsers = false;

  @override
  void initState() {
    super.initState();
    _initializeSecureAuth();
  }

  Future<void> _initializeSecureAuth() async {
    try {
      await SecureAuthService.setupSecurePins();
      final hasUsers = await SecureAuthService.hasAnyUsers();
      if (!mounted) return;
      setState(() {
        _isInitialized = true;
        _hasUsers = hasUsers;
      });

      if (!hasUsers) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) _navigateToRegister();
        });
      }
    } catch (e) {
      // Non-fatal — allow login attempt even if pre-check fails
      if (!mounted) return;
      setState(() {
        _isInitialized = true; // unblock the login button
        _hasUsers = true;      // assume users exist, auth will verify
      });
    }
  }


  void _navigateToRegister() {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const RegisterScreen()),
    ).then((_) {
      // Refresh user list after returning from register
      if (mounted) _initializeSecureAuth();
    });
  }

  void _navigateToForgotPin() {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const ForgotPinScreen()),
    );
  }

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;
    if (!_isInitialized) {
      setState(() => _error = 'Security system not initialized');
      return;
    }

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final employeeId = _employeeIdCtrl.text.trim();
      final pin = _pinCtrl.text.trim();

      if (employeeId.isEmpty) {
        setState(() {
          _isLoading = false;
          _error = 'Employee ID or name cannot be empty';
        });
        return;
      }

      if (pin.length < 4) {
        setState(() {
          _isLoading = false;
          _error = 'PIN must be at least 4 digits';
        });
        return;
      }

      if (await SecureAuthService.isAccountLocked(employeeId)) {
        final remaining =
            await SecureAuthService.getLockoutTimeRemaining(employeeId);
        if (!mounted) return;
        setState(() {
          _isLoading = false;
          _error =
              'Account locked. Try again in ${remaining?.inMinutes ?? 0} minutes.';
        });
        return;
      }

      final user =
          await SecureAuthService.authenticateUser(employeeId, pin);

      if (user == null) {
        if (!mounted) return;
        setState(() {
          _isLoading = false;
          _error = 'Authentication failed';
        });
        return;
      }

      UserRole role;
      switch (user['role'] as String) {
        case 'Administrator':
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

      // Create session — remember me keeps user signed in for 365 days
      await SecureAuthService.createSecureSession(
        user,
        rememberMe: _rememberMe,
      );

      if (!mounted) return;

      await context.read<SessionProvider>().login(
            userId: user['id'] as String,
            userName: user['name'] as String,
            role: role,
            department: user['department'] as String? ?? 'Production',
            shift: user['shift'] as String? ?? 'Morning',
            teamIds: const <String>[],
          );
      // Bind FCM token to this employee for push notifications
      await NotificationService.bindEmployee(user['id'] as String);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _error =
            e is AuthException ? e.toString() : 'Login failed. Please try again.';
      });
    }
  }

  @override
  void dispose() {
    _employeeIdCtrl.dispose();
    _pinCtrl.dispose();
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
              // ── Header ──────────────────────────────────────────────────
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 48),
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
                            color: const Color(0xFF1565C0).withValues(alpha: 0.4),
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
                          errorBuilder: (context, e, s) => Container(
                            decoration: const BoxDecoration(
                              gradient: LinearGradient(
                                colors: [Color(0xFF1565C0), Color(0xFF42A5F5)],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                            ),
                            child: const Icon(
                              Icons.precision_manufacturing_rounded,
                              color: Colors.white,
                              size: 40,
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      'ForgeOps',
                      style: GoogleFonts.inter(
                        fontSize: 32,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                        letterSpacing: -0.5,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Manufacturing Intelligence Platform',
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        color: const Color(0xFF9CA3AF),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 4),
                      decoration: BoxDecoration(
                        color:
                            const Color(0xFF1565C0).withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: const Color(0xFF1565C0)
                              .withValues(alpha: 0.5),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 6,
                            height: 6,
                            decoration: const BoxDecoration(
                              color: Color(0xFF00C853),
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            'PS Laser Industries',
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              color: const Color(0xFF93C5FD),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // ── Form card ────────────────────────────────────────────────
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
                        'Sign In',
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
                        'Enter your employee credentials',
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          color: const Color(0xFF6B7280),
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Employee ID field
                      _fieldLabel('Employee ID or Name', isDark),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: _employeeIdCtrl,
                        keyboardType: TextInputType.text,
                        textInputAction: TextInputAction.next,
                        style: _inputStyle(isDark),
                        decoration: _inputDeco(
                          hint: 'Enter your ID or full name',
                          icon: Icons.badge_outlined,
                          isDark: isDark,
                        ),
                        validator: (v) {
                          final val = v?.trim() ?? '';
                          if (val.isEmpty) return 'Enter your ID or name';
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),

                      // PIN field
                      _fieldLabel('PIN', isDark),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: _pinCtrl,
                        obscureText: _obscurePin,
                        keyboardType: TextInputType.number,
                        textInputAction: TextInputAction.done,
                        onFieldSubmitted: (_) => _login(),
                        style: _inputStyle(isDark),
                        decoration: _inputDeco(
                          hint: '••••',
                          icon: Icons.lock_outline,
                          isDark: isDark,
                          suffix: IconButton(
                            icon: Icon(
                              _obscurePin
                                  ? Icons.visibility_off_outlined
                                  : Icons.visibility_outlined,
                              size: 20,
                            ),
                            onPressed: () =>
                                setState(() => _obscurePin = !_obscurePin),
                          ),
                        ),
                        validator: (v) {
                          final val = v?.trim() ?? '';
                          if (val.isEmpty) return 'Enter your PIN';
                          if (val.length < 4) {
                            return 'PIN must be at least 4 digits';
                          }
                          return null;
                        },
                      ),

                      // Remember Me + Forgot PIN row
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          GestureDetector(
                            onTap: () =>
                                setState(() => _rememberMe = !_rememberMe),
                            child: Row(
                              children: [
                                SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: Checkbox(
                                    value: _rememberMe,
                                    onChanged: (v) =>
                                        setState(() => _rememberMe = v ?? true),
                                    activeColor: const Color(0xFF1565C0),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  'Remember me',
                                  style: GoogleFonts.inter(
                                    fontSize: 13,
                                    color: isDark
                                        ? const Color(0xFFD1D5DB)
                                        : const Color(0xFF374151),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const Spacer(),
                          TextButton(
                            onPressed: _navigateToForgotPin,
                            style: TextButton.styleFrom(
                              padding: EdgeInsets.zero,
                              minimumSize: const Size(0, 0),
                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            ),
                            child: Text(
                              'Forgot PIN?',
                              style: GoogleFonts.inter(
                                fontSize: 13,
                                color: const Color(0xFF1565C0),
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),

                      // Error box
                      if (_error != null) ...[
                        const SizedBox(height: 12),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 10),
                          decoration: BoxDecoration(
                            color: AppTheme.accentRed.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: AppTheme.accentRed.withValues(alpha: 0.3),
                            ),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.error_outline,
                                  size: 16, color: AppTheme.accentRed),
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
                          onPressed: _isLoading ? null : _login,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF1565C0),
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
                                  'Sign In',
                                  style: GoogleFonts.inter(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // ── Registration section ──────────────────────────────────────
              Padding(
                padding: const EdgeInsets.all(24),
                child: _buildBottomSection(isDark),
              ),

              // ── Theme toggle ─────────────────────────────────────────────
              TextButton.icon(
                onPressed: () => themeProvider.toggleTheme(),
                icon: Icon(
                  isDark
                      ? Icons.light_mode_outlined
                      : Icons.dark_mode_outlined,
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

  Widget _buildBottomSection(bool isDark) {
    if (!_isInitialized) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: _cardDeco(isDark),
        child: Row(
          children: [
            const SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(strokeWidth: 2)),
            const SizedBox(width: 12),
            Text('Initializing authentication...',
                style: GoogleFonts.inter(
                    fontSize: 13, color: const Color(0xFF6B7280))),
          ],
        ),
      );
    }

    if (!_hasUsers) {
      return Container(
        padding: const EdgeInsets.all(20),
        decoration: _cardDeco(isDark),
        child: Column(
          children: [
            const Icon(Icons.people_outline_rounded,
                color: Color(0xFF059669), size: 48),
            const SizedBox(height: 12),
            Text(
              'Welcome to ForgeOps!',
              style: GoogleFonts.inter(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: isDark ? Colors.white : const Color(0xFF111827),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Create your first account to get started',
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                  fontSize: 13, color: const Color(0xFF6B7280)),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _navigateToRegister,
                icon: const Icon(Icons.person_add_rounded, size: 18),
                label: Text('Create First Account',
                    style: GoogleFonts.inter(
                        fontSize: 14, fontWeight: FontWeight.w600)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF059669),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8)),
                ),
              ),
            ),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'NEW USER?',
              style: GoogleFonts.inter(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF6B7280),
                letterSpacing: 1.0,
              ),
            ),
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: const Color(0xFF059669).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(4),
                border: Border.all(
                    color: const Color(0xFF059669).withValues(alpha: 0.3)),
              ),
              child: Text(
                'SECURE',
                style: GoogleFonts.inter(
                  fontSize: 9,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF059669),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: _cardDeco(isDark),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: const Color(0xFF059669).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.person_add_rounded,
                        color: Color(0xFF059669), size: 18),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Join the team',
                            style: GoogleFonts.inter(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: isDark
                                  ? Colors.white
                                  : const Color(0xFF111827),
                            )),
                        Text('Register with a secret question for PIN recovery',
                            style: GoogleFonts.inter(
                                fontSize: 12,
                                color: const Color(0xFF6B7280))),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: _navigateToRegister,
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Color(0xFF059669)),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8)),
                    foregroundColor: const Color(0xFF059669),
                  ),
                  child: Text('Create New Account',
                      style: GoogleFonts.inter(
                          fontSize: 13, fontWeight: FontWeight.w600)),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ── Style helpers ──────────────────────────────────────────────────────────
  TextStyle _inputStyle(bool isDark) => GoogleFonts.inter(
        fontSize: 15,
        color: isDark ? Colors.white : const Color(0xFF111827),
      );

  Widget _fieldLabel(String label, bool isDark) => Text(
        label,
        style: GoogleFonts.inter(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: isDark ? const Color(0xFFD1D5DB) : const Color(0xFF374151),
        ),
      );

  InputDecoration _inputDeco({
    required String hint,
    required IconData icon,
    required bool isDark,
    Widget? suffix,
  }) =>
      InputDecoration(
        hintText: hint,
        prefixIcon: Icon(icon, size: 20),
        suffixIcon: suffix,
        filled: true,
        fillColor: isDark ? AppTheme.darkBg : const Color(0xFFF9FAFB),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(
            color: isDark ? AppTheme.darkBorder : const Color(0xFFE5E7EB),
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Color(0xFF1565C0), width: 1.5),
        ),
      );

  BoxDecoration _cardDeco(bool isDark) => BoxDecoration(
        color: isDark ? AppTheme.darkCard : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark ? AppTheme.darkBorder : const Color(0xFFE5E7EB),
        ),
      );
}
