import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'core/theme/app_theme.dart';
import 'core/providers/session_provider.dart';
import 'core/providers/theme_provider.dart';
import 'core/router/app_router.dart';
import 'core/services/notification_service.dart';
import 'core/services/secure_storage_service.dart';
import 'firebase_options.dart';

// ── Permanently embedded OpenRouter API key ────────────────────────────────
// Written once to encrypted secure storage on first launch.
// Update this value here whenever the key changes — no UI action needed.
const _kOpenRouterApiKey =
    ''; // TODO: Replace with your OpenRouter API key

/// Writes the API key to secure storage if it has not been stored yet.
/// Safe to call on every launch — it is a no-op after the first write.
Future<void> _ensureApiKey() async {
  final stored = await SecureStorageService.getOpenRouterKey();
  if (stored == null || stored.trim().isEmpty) {
    await SecureStorageService.setOpenRouterKey(_kOpenRouterApiKey);
    debugPrint('✅ OpenRouter API key initialised from build config.');
  }
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Catch all unhandled Flutter framework errors — log, never crash.
  FlutterError.onError = (FlutterErrorDetails details) {
    FlutterError.presentError(details);
  };

  try {
    // ── Initialize Firebase ────────────────────────────────────────────────────
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );

    // ── Enable Firestore offline persistence ───────────────────────────────────
    FirebaseFirestore.instance.settings = const Settings(
      persistenceEnabled: true,
      cacheSizeBytes: Settings.CACHE_SIZE_UNLIMITED,
    );

    // ── Load session ───────────────────────────────────────────────────────────
    final sessionProvider = SessionProvider();
    await sessionProvider.loadSession();

    // ── Embed API key permanently (first-boot write, no-op thereafter) ─────────
    await _ensureApiKey();

    // ── Initialize push notifications (non-fatal if it fails) ─────────────────
    try {
      await NotificationService.init(
        employeeId: sessionProvider.session.isLoggedIn
            ? sessionProvider.session.userId
            : null,
      );
    } catch (e) {
      debugPrint('⚠️ NotificationService init failed: $e');
    }

    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);

    runApp(ForgeOpsApp(sessionProvider: sessionProvider));
  } catch (e, stack) {
    debugPrint('🚨 Fatal startup error: $e\n$stack');
    runApp(
      MaterialApp(
        home: Scaffold(
          backgroundColor: Colors.red[900],
          body: SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Startup Error', style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 16),
                  Text('$e', style: const TextStyle(color: Colors.white)),
                  const SizedBox(height: 16),
                  Expanded(
                    child: SingleChildScrollView(
                      child: Text('$stack', style: const TextStyle(color: Colors.white70, fontSize: 12)),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}


class ForgeOpsApp extends StatefulWidget {
  final SessionProvider sessionProvider;
  const ForgeOpsApp({super.key, required this.sessionProvider});

  @override
  State<ForgeOpsApp> createState() => _ForgeOpsAppState();
}

class _ForgeOpsAppState extends State<ForgeOpsApp> {
  late final GoRouter _router;

  @override
  void initState() {
    super.initState();
    // Create the router ONCE — it listens to sessionProvider via refreshListenable
    // so redirects fire automatically on login/logout without recreating the router.
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
            title: 'ForgeOps AI',
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
