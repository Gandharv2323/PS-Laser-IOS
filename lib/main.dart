import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'core/theme/app_theme.dart';
import 'core/providers/session_provider.dart';
import 'core/providers/theme_provider.dart';
import 'core/router/app_router.dart';
import 'core/services/notification_service.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Catch all unhandled Flutter framework errors — log, never crash.
  FlutterError.onError = (FlutterErrorDetails details) {
    FlutterError.presentError(details);
  };

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

  // ── Initialize push notifications (non-fatal if it fails) ─────────────────
  try {
    await NotificationService.init(
      employeeId: sessionProvider.session.isLoggedIn
          ? sessionProvider.session.userId
          : null,
    );
  } catch (e) {
    // Notification init failed (e.g. no Google Play Services) — safe to continue.
    debugPrint('⚠️ NotificationService init failed: $e');
  }

  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
    DeviceOrientation.landscapeLeft,
    DeviceOrientation.landscapeRight,
  ]);

  runApp(ForgeOpsApp(sessionProvider: sessionProvider));
}


class ForgeOpsApp extends StatelessWidget {
  final SessionProvider sessionProvider;
  const ForgeOpsApp({super.key, required this.sessionProvider});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ChangeNotifierProvider.value(value: sessionProvider),
      ],
      child: Consumer2<ThemeProvider, SessionProvider>(
        builder: (context, themeProvider, sessionProvider, _) {
          final router = AppRouter.createRouter(sessionProvider);
          return MaterialApp.router(
            title: 'ForgeOps AI',
            debugShowCheckedModeBanner: false,
            theme: AppTheme.lightTheme,
            darkTheme: AppTheme.darkTheme,
            themeMode: themeProvider.themeMode,
            routerConfig: router,
          );
        },
      ),
    );
  }
}
