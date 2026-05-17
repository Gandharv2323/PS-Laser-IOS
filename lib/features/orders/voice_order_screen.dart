/// Voice-to-Order — Phase 4.
/// Speak a natural-language order, AI parses into structured fields.
library;

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import '../../core/models/models.dart';
import '../../core/services/order_engine.dart';
import '../../core/services/secure_storage_service.dart';
import '../../core/theme/ios_design_system.dart';
import '../../core/providers/session_provider.dart';

const _kOpenRouterUrl = 'https://openrouter.ai/api/v1/chat/completions';
const _kModel = 'openai/gpt-oss-120b:free';

class VoiceOrderScreen extends StatefulWidget {
  const VoiceOrderScreen({super.key});

  @override
  State<VoiceOrderScreen> createState() => _VoiceOrderScreenState();
}

class _VoiceOrderScreenState extends State<VoiceOrderScreen>
    with SingleTickerProviderStateMixin {
  final stt.SpeechToText _speech = stt.SpeechToText();
  bool _speechAvailable = false;
  bool _isListening = false;
  String _transcript = '';

  // Parsed fields
  String _clientName = '';
  String _description = '';
  String _material = '';
  int _quantity = 0;
  String _priority = 'MEDIUM';
  DateTime? _dueDate;

  bool _isParsing = false;
  bool _isParsed = false;
  bool _isSubmitting = false;
  String? _errorMessage;

  late final AnimationController _pulseCtrl;

  @override
  void initState() {
    super.initState();
    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);
    _initSpeech();
  }

  Future<void> _initSpeech() async {
    _speechAvailable = await _speech.initialize(
      onStatus: (status) {
        if (status == 'done' || status == 'notListening') {
          if (mounted) {
            setState(() => _isListening = false);
          }
        }
      },
      onError: (error) {
        if (mounted) {
          setState(() {
            _isListening = false;
            _errorMessage = 'Speech error: ${error.errorMsg}';
          });
        }
      },
    );
    if (mounted) setState(() {});
  }

  void _startListening() {
    if (!_speechAvailable) {
      setState(() => _errorMessage = 'Speech recognition not available on this device.');
      return;
    }
    HapticFeedback.mediumImpact();
    setState(() {
      _isListening = true;
      _transcript = '';
      _isParsed = false;
      _errorMessage = null;
    });
    _speech.listen(
      onResult: (result) {
        if (mounted) {
          setState(() => _transcript = result.recognizedWords);
        }
      },
      listenFor: const Duration(seconds: 30),
      pauseFor: const Duration(seconds: 3),
      localeId: 'en_US',
    );
  }

  void _stopListening() {
    _speech.stop();
    HapticFeedback.lightImpact();
    setState(() => _isListening = false);
    if (_transcript.trim().isNotEmpty) {
      _parseWithAI();
    }
  }

  // ── AI Parsing ──────────────────────────────────────────────────────────────

  Future<void> _parseWithAI() async {
    setState(() {
      _isParsing = true;
      _errorMessage = null;
    });

    final apiKey = await SecureStorageService.getOpenRouterKey() ?? '';

    if (apiKey.trim().isEmpty) {
      // Fallback: put entire transcript as description
      setState(() {
        _description = _transcript;
        _isParsing = false;
        _isParsed = true;
      });
      return;
    }

    try {
      final systemPrompt = '''You are an order-parsing assistant for PS Laser Industries, a laser cutting and manufacturing company.

The user will dictate a natural-language order. Extract structured fields and return ONLY valid JSON (no markdown, no explanation):

{
  "clientName": "string or empty",
  "description": "what needs to be done",
  "material": "material type or empty",
  "quantity": 0,
  "priority": "LOW|MEDIUM|HIGH|URGENT",
  "dueDateDays": null or number of days from today
}

Rules:
- If a field is not mentioned, use sensible defaults.
- priority defaults to MEDIUM if not specified.
- dueDateDays: if they say "by Friday" calculate days from today.
- Respond with ONLY the JSON object.''';

      final body = jsonEncode({
        'model': _kModel,
        'messages': [
          {'role': 'system', 'content': systemPrompt},
          {'role': 'user', 'content': _transcript},
        ],
        'max_tokens': 256,
        'temperature': 0.1,
      });

      final response = await http
          .post(
            Uri.parse(_kOpenRouterUrl),
            headers: {
              'Authorization': 'Bearer ${apiKey.trim()}',
              'Content-Type': 'application/json',
              'HTTP-Referer': 'https://pslaser.com',
              'X-Title': 'PS Laser Voice Order',
            },
            body: body,
          )
          .timeout(const Duration(seconds: 20));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final content = data['choices']?[0]?['message']?['content'] as String? ?? '';

        // Try to extract JSON from the response
        final jsonStr = _extractJson(content);
        if (jsonStr != null) {
          final parsed = jsonDecode(jsonStr) as Map<String, dynamic>;
          setState(() {
            _clientName = parsed['clientName'] as String? ?? '';
            _description = parsed['description'] as String? ?? _transcript;
            _material = parsed['material'] as String? ?? '';
            _quantity = (parsed['quantity'] as num?)?.toInt() ?? 0;
            _priority = parsed['priority'] as String? ?? 'MEDIUM';
            final dueDays = parsed['dueDateDays'] as num?;
            if (dueDays != null) {
              _dueDate = DateTime.now().add(Duration(days: dueDays.toInt()));
            }
            _isParsed = true;
            _isParsing = false;
          });
          return;
        }
      }

      // Fallback
      setState(() {
        _description = _transcript;
        _isParsed = true;
        _isParsing = false;
      });
    } catch (e) {
      debugPrint('Voice parse error: $e');
      setState(() {
        _description = _transcript;
        _isParsed = true;
        _isParsing = false;
      });
    }
  }

  String? _extractJson(String text) {
    // Try to find JSON object in the response
    final start = text.indexOf('{');
    final end = text.lastIndexOf('}');
    if (start != -1 && end > start) {
      return text.substring(start, end + 1);
    }
    return null;
  }

  // ── Submit Order ────────────────────────────────────────────────────────────

  Future<void> _submitOrder() async {
    if (_description.trim().isEmpty) {
      setState(() => _errorMessage = 'Description is required.');
      return;
    }

    final session = context.read<SessionProvider>().session;

    setState(() {
      _isSubmitting = true;
      _errorMessage = null;
    });

    try {
      final order = Order(
        id: '',
        clientId: '',
        clientName: _clientName.isEmpty ? 'Walk-in' : _clientName,
        description: _description,
        material: _material,
        quantity: _quantity.toDouble(),
        unit: 'pcs',
        priority: _priority,
        status: 'RECEIVED',
        estimatedDurationMins: 0,
        notes: 'Created via Voice Order',
        voiceTranscription: _transcript,
        dueDate: _dueDate,
        createdAt: DateTime.now(),
      );

      await OrderEngine.createOrder(order, session.userId);

      if (mounted) {
        HapticFeedback.heavyImpact();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Order created from voice!'),
            backgroundColor: PSColors.neonGreen,
            behavior: SnackBarBehavior.floating,
          ),
        );
        GoRouter.of(context).go('/orders');
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
          _errorMessage = 'Failed to create order: $e';
        });
      }
    }
  }

  @override
  void dispose() {
    _speech.stop();
    _pulseCtrl.dispose();
    super.dispose();
  }

  // ── UI ──────────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      backgroundColor: isDark ? PSColors.darkBg : PSColors.lightBg,
      appBar: AppBar(
        backgroundColor: isDark ? PSColors.darkBg : PSColors.lightBg,
        surfaceTintColor: Colors.transparent,
        title: Text('Voice Order', style: PSText.title()),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            children: [
              const SizedBox(height: 12),

              // ── Status indicator ─────────────────────────────────────
              _StatusChip(
                isListening: _isListening,
                isParsing: _isParsing,
                isParsed: _isParsed,
              ),

              const SizedBox(height: 20),

              // ── Main content ─────────────────────────────────────────
              Expanded(
                child: _isParsed
                    ? _buildReviewForm(isDark)
                    : _buildVoiceCapture(isDark),
              ),

              // ── Error message ────────────────────────────────────────
              if (_errorMessage != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Text(
                    _errorMessage!,
                    style: PSText.caption(color: PSColors.neonRed),
                    textAlign: TextAlign.center,
                  ),
                ),

              // ── Bottom action ────────────────────────────────────────
              _buildBottomAction(isDark),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildVoiceCapture(bool isDark) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // ── Microphone button ──────────────────────────────────────
        GestureDetector(
          onTap: _isListening ? _stopListening : _startListening,
          child: AnimatedBuilder(
            animation: _pulseCtrl,
            builder: (_, __) {
              final scale = _isListening ? 1.0 + (_pulseCtrl.value * 0.15) : 1.0;
              return Transform.scale(
                scale: scale,
                child: Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    gradient: _isListening
                        ? const LinearGradient(
                            colors: [PSColors.neonRed, PSColors.neonOrange],
                          )
                        : PSColors.aiGradient,
                    shape: BoxShape.circle,
                    boxShadow: _isListening
                        ? [
                            BoxShadow(
                              color: PSColors.neonRed.withAlpha(80),
                              blurRadius: 30,
                              spreadRadius: 5,
                            ),
                          ]
                        : [],
                  ),
                  child: Icon(
                    _isListening ? Icons.stop_rounded : Icons.mic_rounded,
                    color: Colors.white,
                    size: 42,
                  ),
                ),
              );
            },
          ),
        ),

        const SizedBox(height: 24),

        Text(
          _isListening ? 'Listening...' : 'Tap to speak your order',
          style: PSText.body(color: PSColors.textDark2),
        ),

        if (_isParsing) ...[
          const SizedBox(height: 24),
          const SizedBox(
            width: 24,
            height: 24,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: PSColors.neonCyan,
            ),
          ),
          const SizedBox(height: 8),
          Text('AI is parsing your order...',
              style: PSText.caption(color: PSColors.textDark3)),
        ],

        // ── Transcript preview ─────────────────────────────────────
        if (_transcript.isNotEmpty && !_isParsing) ...[
          const SizedBox(height: 24),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: isDark ? PSColors.darkCard : PSColors.lightCard,
              borderRadius: BorderRadius.circular(PSRadius.md),
              border: Border.all(
                color: isDark ? PSColors.darkBorder : PSColors.lightBorder,
                width: 0.5,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('TRANSCRIPT',
                    style: PSText.sectionHeader()),
                const SizedBox(height: 6),
                Text(_transcript,
                    style: PSText.body(color: PSColors.textDark1)),
              ],
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildReviewForm(bool isDark) {
    return ListView(
      children: [
        PSSectionHeader(title: 'Parsed Order'),
        const SizedBox(height: 4),
        _EditableField(
          label: 'Client',
          value: _clientName,
          icon: Icons.person_outline_rounded,
          onChanged: (v) => _clientName = v,
          isDark: isDark,
        ),
        _EditableField(
          label: 'Description',
          value: _description,
          icon: Icons.description_outlined,
          onChanged: (v) => _description = v,
          isDark: isDark,
          maxLines: 3,
        ),
        _EditableField(
          label: 'Material',
          value: _material,
          icon: Icons.layers_outlined,
          onChanged: (v) => _material = v,
          isDark: isDark,
        ),
        _EditableField(
          label: 'Quantity',
          value: _quantity > 0 ? '$_quantity' : '',
          icon: Icons.numbers_rounded,
          onChanged: (v) => _quantity = int.tryParse(v) ?? 0,
          isDark: isDark,
          keyboardType: TextInputType.number,
        ),

        // Priority selector
        const SizedBox(height: 12),
        Text('PRIORITY', style: PSText.sectionHeader()),
        const SizedBox(height: 8),
        Row(
          children: ['LOW', 'MEDIUM', 'HIGH', 'URGENT'].map((p) {
            final selected = _priority == p;
            final color = PSColors.forPriority(p);
            return Expanded(
              child: GestureDetector(
                onTap: () => setState(() => _priority = p),
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 3),
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  decoration: BoxDecoration(
                    color: selected ? color.withAlpha(30) : Colors.transparent,
                    borderRadius: BorderRadius.circular(PSRadius.sm),
                    border: Border.all(
                      color: selected ? color : (isDark ? PSColors.darkBorder : PSColors.lightBorder),
                      width: selected ? 1.5 : 0.5,
                    ),
                  ),
                  child: Text(
                    p,
                    style: PSText.caption(color: selected ? color : PSColors.textDark3)
                        .copyWith(fontWeight: selected ? FontWeight.w700 : FontWeight.w500),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
            );
          }).toList(),
        ),

        const SizedBox(height: 16),

        // Due date
        GestureDetector(
          onTap: () async {
            final picked = await showDatePicker(
              context: context,
              initialDate: _dueDate ?? DateTime.now().add(const Duration(days: 1)),
              firstDate: DateTime.now(),
              lastDate: DateTime.now().add(const Duration(days: 365)),
            );
            if (picked != null) setState(() => _dueDate = picked);
          },
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
                const Icon(Icons.calendar_today_rounded,
                    size: 16, color: PSColors.textDark3),
                const SizedBox(width: 10),
                Text(
                  _dueDate != null
                      ? 'Due: ${_dueDate!.day}/${_dueDate!.month}/${_dueDate!.year}'
                      : 'Set due date (optional)',
                  style: PSText.body(
                    color: _dueDate != null ? PSColors.textDark1 : PSColors.textDark3,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildBottomAction(bool isDark) {
    if (_isParsed) {
      return SizedBox(
        width: double.infinity,
        height: 52,
        child: ElevatedButton(
          onPressed: _isSubmitting ? null : _submitOrder,
          style: ElevatedButton.styleFrom(
            backgroundColor: PSColors.brand,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(PSRadius.md),
            ),
          ),
          child: _isSubmitting
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : Text('Create Order',
                  style: PSText.body(color: Colors.white)
                      .copyWith(fontWeight: FontWeight.w700)),
        ),
      );
    }

    if (_transcript.isNotEmpty && !_isListening && !_isParsing) {
      return SizedBox(
        width: double.infinity,
        height: 52,
        child: OutlinedButton(
          onPressed: _parseWithAI,
          style: OutlinedButton.styleFrom(
            side: const BorderSide(color: PSColors.neonCyan),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(PSRadius.md),
            ),
          ),
          child: Text('Parse with AI',
              style: PSText.body(color: PSColors.neonCyan)
                  .copyWith(fontWeight: FontWeight.w700)),
        ),
      );
    }

    return const SizedBox.shrink();
  }
}

// ── Sub-widgets ──────────────────────────────────────────────────────────────

class _StatusChip extends StatelessWidget {
  final bool isListening;
  final bool isParsing;
  final bool isParsed;

  const _StatusChip({
    required this.isListening,
    required this.isParsing,
    required this.isParsed,
  });

  @override
  Widget build(BuildContext context) {
    String label;
    Color color;
    IconData icon;

    if (isListening) {
      label = 'RECORDING';
      color = PSColors.neonRed;
      icon = Icons.fiber_manual_record_rounded;
    } else if (isParsing) {
      label = 'AI PARSING';
      color = PSColors.neonCyan;
      icon = Icons.psychology_rounded;
    } else if (isParsed) {
      label = 'REVIEW & SUBMIT';
      color = PSColors.neonGreen;
      icon = Icons.check_circle_outline_rounded;
    } else {
      label = 'READY';
      color = PSColors.textDark3;
      icon = Icons.mic_none_rounded;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withAlpha(15),
        borderRadius: BorderRadius.circular(PSRadius.full),
        border: Border.all(color: color.withAlpha(60), width: 0.5),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 6),
          Text(label,
              style: PSText.caption(color: color)
                  .copyWith(fontWeight: FontWeight.w700, letterSpacing: 1.0)),
        ],
      ),
    );
  }
}

class _EditableField extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final ValueChanged<String> onChanged;
  final bool isDark;
  final int maxLines;
  final TextInputType keyboardType;

  const _EditableField({
    required this.label,
    required this.value,
    required this.icon,
    required this.onChanged,
    required this.isDark,
    this.maxLines = 1,
    this.keyboardType = TextInputType.text,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: TextFormField(
        initialValue: value,
        onChanged: onChanged,
        maxLines: maxLines,
        keyboardType: keyboardType,
        style: PSText.body(
          color: isDark ? PSColors.textDark1 : PSColors.textLight1,
        ),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: PSText.caption(color: PSColors.textDark3),
          prefixIcon: Icon(icon, size: 18, color: PSColors.textDark3),
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
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(PSRadius.sm),
            borderSide: const BorderSide(color: PSColors.brand, width: 1.0),
          ),
        ),
      ),
    );
  }
}
