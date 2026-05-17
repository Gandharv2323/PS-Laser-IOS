import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'core/config/env_config.dart';
import 'core/theme/app_theme.dart';
import 'core/providers/session_provider.dart';
import 'core/providers/theme_provider.dart';
import 'core/router/app_router.dart';
import 'core/services/notification_service.dart';
import 'core/services/secure_storage_service.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Catch all unhandled Flutter framework errors — log, never crash.
  FlutterError.onError = (FlutterErrorDetails details) {
    FlutterError.presentError(details);
  };

  try {
    // ── Firebase ──────────────────────────────────────────────────────────────
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );

    // ── Firestore offline persistence ─────────────────────────────────────────
    FirebaseFirestore.instance.settings = const Settings(
      persistenceEnabled: true,
      cacheSizeBytes: Settings.CACHE_SIZE_UNLIMITED,
    );

    // ── Session ───────────────────────────────────────────────────────────────
    final sessionProvider = SessionProvider();
    await sessionProvider.loadSession();

    // ── API Key (from --dart-define, falls back to secure storage) ────────────
    await _ensureApiKey();

    // ── Push Notifications ────────────────────────────────────────────────────
    try {
      await NotificationService.init(
        employeeId: sessionProvider.session.isLoggedIn
            ? sessionProvider.session.userId
            : null,
      );
    } catch (e) {
      debugPrint('⚠️ NotificationService init failed: $e');
    }

    // ── Orientation (all directions for iPad compatibility) ───────────────────
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);

    runApp(PSLaserApp(sessionProvider: sessionProvider));
  } catch (e, stack) {
    debugPrint('🚨 Fatal startup error: $e\n$stack');
    runApp(_ErrorApp(error: e.toString()));
  }
}

/// Writes the API key to secure storage if it has not been stored yet.
/// Key comes from --dart-define at build time. Safe to call every launch.
Future<void> _ensureApiKey() async {
  if (!EnvConfig.hasAiKey) {
    debugPrint('⚠️ No OpenRouter API key configured via --dart-define.');
    return;
  }
  final stored = await SecureStorageService.getOpenRouterKey();
  if (stored == null || stored.trim().isEmpty) {
    await SecureStorageService.setOpenRouterKey(EnvConfig.openRouterApiKey);
    debugPrint('✅ OpenRouter API key initialised from build config.');
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// Root App Widget
// ══════════════════════════════════════════════════════════════════════════════

class PSLaserApp extends StatefulWidget {
  final SessionProvider sessionProvider;
  const PSLaserApp({super.key, required this.sessionProvider});

  @override
  State<PSLaserApp> createState() => _PSLaserAppState();
}

class _PSLaserAppState extends State<PSLaserApp> {
  late final GoRouter _router;

  @override
  void initState() {
    super.initState();
    // Create the router ONCE — reacts to sessionProvider via refreshListenable.
    _router = AppRouter.createRouter(widget.sessionProvider);
  }

  @override
  void dispose() {
    _router.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ChangeNotifierProvider.value(value: widget.sessionProvider),
      ],
      child: Consumer<ThemeProvider>(
        builder: (context, themeProvider, _) {
          return MaterialApp.router(
            title: 'PS LASER',
            debugShowCheckedModeBanner: false,
            theme: AppTheme.lightTheme,
            darkTheme: AppTheme.darkTheme,
            themeMode: themeProvider.themeMode,
            routerConfig: _router,
          );
        },
      ),
    );
  }
}

// ── Fatal error fallback ──────────────────────────────────────────────────────

class _ErrorApp extends StatelessWidget {
  final String error;
  const _ErrorApp({required this.error});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        backgroundColor: const Color(0xFF0D0D0D),
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.error_outline, color: Color(0xFFFF2D55), size: 48),
                const SizedBox(height: 16),
                const Text(
                  'Startup Error',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 12),
                Expanded(
                  child: SingleChildScrollView(
                    child: Text(
                      error,
                      style: const TextStyle(color: Color(0xFFAEAEB2), fontSize: 13),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
