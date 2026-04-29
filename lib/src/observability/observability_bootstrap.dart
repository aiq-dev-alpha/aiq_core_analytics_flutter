import 'dart:async';

import 'analytics_tracker.dart';
import 'crash_reporter.dart';
import 'performance_monitor.dart';

enum ObservabilityEnvironment { dev, uat, prod }

class ObservabilityConfig {
  final ObservabilityEnvironment environment;
  final String release;
  final String? sentryDsn;
  final String? posthogApiKey;
  final String? posthogHost;
  final double sampleRate;
  final bool enableConsoleFallback;

  const ObservabilityConfig({
    required this.environment,
    required this.release,
    this.sentryDsn,
    this.posthogApiKey,
    this.posthogHost,
    this.sampleRate = 0.2,
    this.enableConsoleFallback = true,
  });

  bool get isProduction => environment == ObservabilityEnvironment.prod;
}

class ObservabilityBootstrap {
  ObservabilityBootstrap._();

  static bool _initialized = false;
  static ObservabilityConfig? _config;

  static bool get isInitialized => _initialized;
  static ObservabilityConfig? get config => _config;

  static Future<void> init(ObservabilityConfig config) async {
    if (_initialized) return;
    _config = config;

    final crashReporter = _resolveCrashReporter(config);
    await crashReporter.init();
    CrashReporterRegistry.instance.register(crashReporter);

    final analyticsTracker = _resolveAnalyticsTracker(config);
    await analyticsTracker.init();
    AnalyticsTrackerRegistry.instance.register(analyticsTracker);

    final perfMonitor = _resolvePerformanceMonitor(config);
    await perfMonitor.init();
    PerformanceMonitorRegistry.instance.register(perfMonitor);

    _initialized = true;
  }

  static CrashReporter _resolveCrashReporter(ObservabilityConfig config) {
    if (config.sentryDsn != null && config.sentryDsn!.isNotEmpty) {
      return SentryCrashReporter(
        dsn: config.sentryDsn!,
        environment: config.environment.name,
        release: config.release,
        sampleRate: config.sampleRate,
      );
    }
    if (config.enableConsoleFallback) {
      return ConsoleCrashReporter();
    }
    return NoopCrashReporter();
  }

  static AnalyticsTracker _resolveAnalyticsTracker(ObservabilityConfig config) {
    final trackers = <AnalyticsTracker>[];
    if (config.posthogApiKey != null && config.posthogApiKey!.isNotEmpty) {
      trackers.add(PostHogAnalyticsTracker(
        apiKey: config.posthogApiKey!,
        host: config.posthogHost ?? 'https://app.posthog.com',
      ));
    }
    if (trackers.isEmpty && config.enableConsoleFallback) {
      trackers.add(ConsoleAnalyticsTracker());
    }
    if (trackers.isEmpty) {
      return NoopAnalyticsTracker();
    }
    if (trackers.length == 1) return trackers.first;
    return FanOutAnalyticsTracker(trackers);
  }

  static PerformanceMonitor _resolvePerformanceMonitor(ObservabilityConfig config) {
    if (config.enableConsoleFallback && !config.isProduction) {
      return ConsolePerformanceMonitor();
    }
    return NoopPerformanceMonitor();
  }

  static void identify(String userId, {Map<String, dynamic> traits = const {}}) {
    AnalyticsTrackerRegistry.instance.active.identify(userId, traits: traits);
    CrashReporterRegistry.instance.active.setUser(userId: userId);
  }

  static void reset() {
    AnalyticsTrackerRegistry.instance.active.reset();
    CrashReporterRegistry.instance.active.clearUser();
  }

  static void track(String event, {Map<String, dynamic> properties = const {}}) {
    AnalyticsTrackerRegistry.instance.active.track(event, properties: properties);
    CrashReporterRegistry.instance.active.addBreadcrumb(
      Breadcrumb(category: 'analytics', message: event, data: properties),
    );
  }

  static void screen(String name, {Map<String, dynamic> properties = const {}}) {
    AnalyticsTrackerRegistry.instance.active.screen(name, properties: properties);
    CrashReporterRegistry.instance.active.addBreadcrumb(
      Breadcrumb(category: 'navigation', message: name, data: properties),
    );
  }

  static Future<void> captureException(
    Object error, {
    StackTrace? stackTrace,
    String? screen,
    Map<String, dynamic> extra = const {},
  }) async {
    final ctx = CrashContext(
      environment: _config?.environment.name,
      release: _config?.release,
      screen: screen,
      extra: extra,
    );
    await CrashReporterRegistry.instance.active.captureException(
      error,
      stackTrace: stackTrace,
      context: ctx,
    );
  }

  static PerformanceTransaction startTransaction(String name, String operation) =>
      PerformanceMonitorRegistry.instance.active.startTransaction(name, operation);

  static Future<void> flushAll() async {
    await Future.wait([
      CrashReporterRegistry.instance.active.flush(),
      AnalyticsTrackerRegistry.instance.active.flush(),
      PerformanceMonitorRegistry.instance.active.flush(),
    ]);
  }
}
