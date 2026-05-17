/// Environment configuration — all secrets loaded via --dart-define at build time.
/// NEVER hardcode secrets in source code.
///
/// Build command example:
///   flutter run --dart-define=OPENROUTER_API_KEY=sk-or-v1-xxx
///   flutter build ios --dart-define=OPENROUTER_API_KEY=sk-or-v1-xxx
library;

class EnvConfig {
  EnvConfig._();

  // ── OpenRouter AI ──────────────────────────────────────────────────────────
  static const String openRouterApiKey = String.fromEnvironment(
    'OPENROUTER_API_KEY',
    defaultValue: '',
  );

  static const String openRouterModel = String.fromEnvironment(
    'OPENROUTER_MODEL',
    defaultValue: 'google/gemini-flash-1.5',
  );

  // ── Feature Flags ──────────────────────────────────────────────────────────
  static const bool enableVoiceOrders = bool.fromEnvironment(
    'ENABLE_VOICE_ORDERS',
    defaultValue: true,
  );

  static const bool enableAiInsights = bool.fromEnvironment(
    'ENABLE_AI_INSIGHTS',
    defaultValue: true,
  );

  // ── Environment ────────────────────────────────────────────────────────────
  static const String environment = String.fromEnvironment(
    'ENVIRONMENT',
    defaultValue: 'production',
  );

  static bool get isDebug => environment == 'debug';
  static bool get isProduction => environment == 'production';
  static bool get hasAiKey => openRouterApiKey.isNotEmpty;
}
