import 'package:flutter_dotenv/flutter_dotenv.dart';

/// Centralized configuration for Sik App, ensuring API keys and network
/// parameters are reliably resolved in both debug and release APK builds.
class AppConfig {
  /// Bundled fallback OpenAI API key (compile-time environment definition).
  static const String bundledOpenAiKey =
      String.fromEnvironment('OPENAI_API_KEY', defaultValue: '');

  /// Resolves the active OpenAI API key with multi-tiered fallback:
  /// 1. Saved custom key in persistent storage (if user configured one in Profile)
  /// 2. Compile-time `--dart-define=OPENAI_API_KEY=...`
  /// 3. Runtime `.env` loaded via flutter_dotenv
  /// 4. Bundled key fallback
  static String resolveApiKey(String? savedKey) {
    if (savedKey != null && savedKey.trim().isNotEmpty) {
      return savedKey.trim();
    }

    const compileTimeKey = String.fromEnvironment('OPENAI_API_KEY');
    if (compileTimeKey.trim().isNotEmpty) {
      return compileTimeKey.trim();
    }

    if (dotenv.isInitialized) {
      final envKey = dotenv.maybeGet('OPENAI_API_KEY') ?? dotenv.maybeGet('GEMINI_API_KEY');
      if (envKey != null && envKey.trim().isNotEmpty) {
        return envKey.trim();
      }
    }

    return bundledOpenAiKey.trim();
  }
}
