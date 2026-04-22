import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/theme/app_theme.dart';
import 'secure_auth_service.dart';

/// Self-service PIN reset flow:
/// Step 1 → Enter employee name → Fetch secret question
/// Step 2 → Answer secret question → Set new PIN
class ForgotPinScreen extends StatefulWidget {
  const ForgotPinScreen({super.key});

  @override
  State<ForgotPinScreen> createState() => _ForgotPinScreenState();
}

class _ForgotPinScreenState extends State<ForgotPinScreen> {
  // Step tracking
  int _step = 1; // 1 = enter name, 2 = answer question, 3 = success

  // Step 1
  final _nameCtrl = TextEditingController();
  bool _searching = false;
  Map<String, dynamic>? _foundUser;

  // Step 2
  final _answerCtrl = TextEditingController();
  final _newPinCtrl = TextEditingController();
  final _confirmPinCtrl = TextEditingController();
  bool _obscureNew = true;
  bool _obscureConfirm = true;
  bool _resetting = false;

  String? _error;

  // ── Step 1: Find user ────────────────────────────────────────────────────

  Future<void> _findUser() async {
    final name = _nameCtrl.text.trim();
    if (name.isEmpty) {
      setState(() => _error = 'Enter your registered name');
      return;
    }

    setState(() {
      _searching = true;
      _error = null;
    });

    try {
      final user = await SecureAuthService.findUserForReset(name);

      if (!mounted) return;

      if (user == null) {
        setState(() {
          _searching = false;
          _error = 'No active account found with that name.';
        });
        return;
      }

      final question = user['secret_question'] as String?;
      if (question == null || question.isEmpty) {
        setState(() {
          _searching = false;
          _error =
              'No security question set on this account.\nContact your administrator to reset your PIN.';
        });
        return;
      }

      setState(() {
        _searching = false;
        _foundUser = user;
        _step = 2;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _searching = false;
        _error = 'Error: $e';
      });
    }
  }

  // ── Step 2: Verify answer + reset PIN ────────────────────────────────────

  Future<void> _resetPin() async {
    final answer = _answerCtrl.text.trim();
    final newPin = _newPinCtrl.text.trim();
    final confirm = _confirmPinCtrl.text.trim();

    if (answer.isEmpty) {
      setState(() => _error = 'Enter your secret answer');
      return;
    }

    if (newPin.length < 4) {
      setState(() => _error = 'New PIN must be at least 4 digits');
      return;
    }

    if (newPin != confirm) {
      setState(() => _error = 'PINs do not match');
      return;
    }

    // Check digits only
    if (!RegExp(r'^\d+$').hasMatch(newPin)) {
      setState(() => _error = 'PIN must contain digits only');
      return;
    }

    setState(() {
      _resetting = true;
      _error = null;
    });

    try {
      final userId = _foundUser!['id'].toString();
      final isCorrect =
          await SecureAuthService.verifySecretAnswer(userId, answer);

      if (!mounted) return;

      if (!isCorrect) {
        setState(() {
          _resetting = false;
          _error = 'Secret answer is incorrect. Please try again.';
        });
        return;
      }

      await SecureAuthService.resetPin(userId, newPin);

      if (!mounted) return;
      setState(() {
        _resetting = false;
        _step = 3;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _resetting = false;
        _error = 'Reset failed: $e';
      });
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _answerCtrl.dispose();
    _newPinCtrl.dispose();
    _confirmPinCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppTheme.darkBg : const Color(0xFF0A1628),
      appBar: AppBar(
        title: Text(
          'Forgot PIN',
          style: GoogleFonts.inter(fontWeight: FontWeight.w700),
        ),
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.white,
        elevation: 0,
        leading: BackButton(
          onPressed: () {
            if (_step == 2) {
              setState(() {
                _step = 1;
                _error = null;
                _foundUser = null;
              });
            } else {
              Navigator.of(context).pop();
            }
          },
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: _buildCurrentStep(isDark),
        ),
      ),
    );
  }

  Widget _buildCurrentStep(bool isDark) {
    return switch (_step) {
      1 => _buildStep1(isDark),
      2 => _buildStep2(isDark),
      3 => _buildStep3(isDark),
      _ => _buildStep1(isDark),
    };
  }

  // ── Step 1 UI: Enter name ─────────────────────────────────────────────────

  Widget _buildStep1(bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _stepIndicator(1, isDark),
        const SizedBox(height: 24),
        Container(
          padding: const EdgeInsets.all(24),
          decoration: _cardDeco(isDark),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.lock_reset, size: 40, color: Color(0xFF1565C0)),
              const SizedBox(height: 16),
              Text(
                'Reset Your PIN',
                style: GoogleFonts.inter(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: isDark ? Colors.white : const Color(0xFF111827),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Enter your registered employee name to begin the PIN reset process.',
                style: GoogleFonts.inter(
                  fontSize: 13,
                  color: const Color(0xFF6B7280),
                ),
              ),
              const SizedBox(height: 24),
              _fieldLabel('Your Registered Name', isDark),
              const SizedBox(height: 8),
              TextFormField(
                controller: _nameCtrl,
                textInputAction: TextInputAction.done,
                onFieldSubmitted: (_) => _findUser(),
                style: _inputStyle(isDark),
                decoration: _inputDeco(
                  hint: 'Enter your full name exactly',
                  icon: Icons.person_outline,
                  isDark: isDark,
                ),
              ),
              if (_error != null) ...[
                const SizedBox(height: 12),
                _errorBox(_error!),
              ],
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _searching ? null : _findUser,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1565C0),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                  child: _searching
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                              color: Colors.white, strokeWidth: 2),
                        )
                      : Text('Find My Account',
                          style: GoogleFonts.inter(
                              fontSize: 15, fontWeight: FontWeight.w700)),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ── Step 2 UI: Answer + new PIN ───────────────────────────────────────────

  Widget _buildStep2(bool isDark) {
    final question =
        _foundUser?['secret_question'] as String? ?? 'Secret Question';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _stepIndicator(2, isDark),
        const SizedBox(height: 24),
        Container(
          padding: const EdgeInsets.all(24),
          decoration: _cardDeco(isDark),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // User chip
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: const Color(0xFF059669).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: const Color(0xFF059669).withValues(alpha: 0.3),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.check_circle,
                        size: 14, color: Color(0xFF059669)),
                    const SizedBox(width: 6),
                    Text(
                      'Account found: ${_foundUser!['name']}',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF059669),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Security question block
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFF1565C0).withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: const Color(0xFF1565C0).withValues(alpha: 0.2),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'SECURITY QUESTION',
                      style: GoogleFonts.inter(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1.2,
                        color: const Color(0xFF1565C0),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      question,
                      style: GoogleFonts.inter(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: isDark ? Colors.white : const Color(0xFF111827),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              _fieldLabel('Your Answer', isDark),
              const SizedBox(height: 8),
              TextField(
                controller: _answerCtrl,
                style: _inputStyle(isDark),
                decoration: _inputDeco(
                  hint: 'Type your answer (case-insensitive)',
                  icon: Icons.question_answer_outlined,
                  isDark: isDark,
                ),
              ),
              const SizedBox(height: 16),

              _fieldLabel('New PIN', isDark),
              const SizedBox(height: 8),
              TextField(
                controller: _newPinCtrl,
                obscureText: _obscureNew,
                keyboardType: TextInputType.number,
                style: _inputStyle(isDark),
                decoration: _inputDeco(
                  hint: 'Min. 4 digits',
                  icon: Icons.lock_outline,
                  isDark: isDark,
                  suffix: IconButton(
                    icon: Icon(
                      _obscureNew
                          ? Icons.visibility_off_outlined
                          : Icons.visibility_outlined,
                      size: 20,
                    ),
                    onPressed: () =>
                        setState(() => _obscureNew = !_obscureNew),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              _fieldLabel('Confirm New PIN', isDark),
              const SizedBox(height: 8),
              TextField(
                controller: _confirmPinCtrl,
                obscureText: _obscureConfirm,
                keyboardType: TextInputType.number,
                onSubmitted: (_) => _resetPin(),
                style: _inputStyle(isDark),
                decoration: _inputDeco(
                  hint: 'Re-enter PIN',
                  icon: Icons.lock_reset_outlined,
                  isDark: isDark,
                  suffix: IconButton(
                    icon: Icon(
                      _obscureConfirm
                          ? Icons.visibility_off_outlined
                          : Icons.visibility_outlined,
                      size: 20,
                    ),
                    onPressed: () =>
                        setState(() => _obscureConfirm = !_obscureConfirm),
                  ),
                ),
              ),

              if (_error != null) ...[
                const SizedBox(height: 12),
                _errorBox(_error!),
              ],
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _resetting ? null : _resetPin,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF059669),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                  child: _resetting
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                              color: Colors.white, strokeWidth: 2),
                        )
                      : Text('Reset PIN',
                          style: GoogleFonts.inter(
                              fontSize: 15, fontWeight: FontWeight.w700)),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ── Step 3 UI: Success ────────────────────────────────────────────────────

  Widget _buildStep3(bool isDark) {
    return Center(
      child: Container(
        padding: const EdgeInsets.all(32),
        decoration: _cardDeco(isDark),
        child: Column(
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: const Color(0xFF059669).withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.check_circle,
                  size: 40, color: Color(0xFF059669)),
            ),
            const SizedBox(height: 20),
            Text(
              'PIN Reset Successfully!',
              style: GoogleFonts.inter(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: isDark ? Colors.white : const Color(0xFF111827),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'You can now sign in with your new PIN.',
              textAlign: TextAlign.center,
              style:
                  GoogleFonts.inter(fontSize: 14, color: const Color(0xFF6B7280)),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.of(context).pop(),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1565C0),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                child: Text('Back to Sign In',
                    style: GoogleFonts.inter(
                        fontSize: 15, fontWeight: FontWeight.w700)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Shared helpers ────────────────────────────────────────────────────────

  Widget _stepIndicator(int current, bool isDark) {
    final steps = ['Find Account', 'Verify & Reset', 'Done'];
    return Row(
      children: List.generate(steps.length, (i) {
        final active = i + 1 == current;
        final done = i + 1 < current;
        return Expanded(
          child: Row(
            children: [
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: done
                      ? const Color(0xFF059669)
                      : active
                          ? const Color(0xFF1565C0)
                          : Colors.transparent,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: done
                        ? const Color(0xFF059669)
                        : active
                            ? const Color(0xFF1565C0)
                            : const Color(0xFF6B7280),
                  ),
                ),
                child: Center(
                  child: done
                      ? const Icon(Icons.check, size: 14, color: Colors.white)
                      : Text(
                          '${i + 1}',
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: active
                                ? Colors.white
                                : const Color(0xFF6B7280),
                          ),
                        ),
                ),
              ),
              if (i < steps.length - 1)
                Expanded(
                  child: Container(
                    height: 1,
                    color: done
                        ? const Color(0xFF059669)
                        : const Color(0xFF4B5563),
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                  ),
                ),
            ],
          ),
        );
      }),
    );
  }

  Widget _errorBox(String message) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: AppTheme.accentRed.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
          border:
              Border.all(color: AppTheme.accentRed.withValues(alpha: 0.3)),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Padding(
              padding: EdgeInsets.only(top: 1),
              child:
                  Icon(Icons.error_outline, size: 16, color: AppTheme.accentRed),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                message,
                style: GoogleFonts.inter(
                    fontSize: 13, color: AppTheme.accentRed),
              ),
            ),
          ],
        ),
      );

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
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? AppTheme.darkBorder : const Color(0xFFE5E7EB),
        ),
      );
}
