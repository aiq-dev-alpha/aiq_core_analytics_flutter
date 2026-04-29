import 'dart:async';

enum CrashLevel { debug, info, warning, error, fatal }

class CrashContext {
  final String? userId;
  final String? environment;
  final String? release;
  final String? screen;
  final Map<String, dynamic> tags;
  final Map<String, dynamic> extra;

  const CrashContext({
    this.userId,
    this.environment,
    this.release,
    this.screen,
    this.tags = const {},
    this.extra = const {},
  });
}

class Breadcrumb {
  final DateTime timestamp;
  final String category;
  final String message;
  final CrashLevel level;
  final Map<String, dynamic> data;

  Breadcrumb({
    required this.category,
    required this.message,
    this.level = CrashLevel.info,
    this.data = const {},
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();

  Map<String, dynamic> toMap() => {
        'timestamp': timestamp.toIso8601String(),
        'category': category,
        'message': message,
        'level': level.name,
        'data': data,
      };
}

abstract class CrashReporter {
  Future<void> init();

  Future<void> captureException(
    Object error, {
    StackTrace? stackTrace,
    CrashContext? context,
    CrashLevel level = CrashLevel.error,
  });

  Future<void> captureMessage(
    String message, {
    CrashLevel level = CrashLevel.info,
    CrashContext? context,
  });

  void addBreadcrumb(Breadcrumb crumb);

  void setUser({required String userId, String? email, String? username});

  void setTag(String key, String value);

  void clearUser();

  Future<void> flush();
}

class NoopCrashReporter implements CrashReporter {
  @override
  Future<void> init() async {}

  @override
  Future<void> captureException(
    Object error, {
    StackTrace? stackTrace,
    CrashContext? context,
    CrashLevel level = CrashLevel.error,
  }) async {}

  @override
  Future<void> captureMessage(
    String message, {
    CrashLevel level = CrashLevel.info,
    CrashContext? context,
  }) async {}

  @override
  void addBreadcrumb(Breadcrumb crumb) {}

  @override
  void setUser({required String userId, String? email, String? username}) {}

  @override
  void setTag(String key, String value) {}

  @override
  void clearUser() {}

  @override
  Future<void> flush() async {}
}

class ConsoleCrashReporter implements CrashReporter {
  final List<Breadcrumb> _breadcrumbs = [];
  String? _userId;
  final Map<String, String> _tags = {};
  final void Function(String) _logger;

  ConsoleCrashReporter({void Function(String)? logger})
      : _logger = logger ?? _defaultLogger;

  static void _defaultLogger(String line) {
    // ignore: avoid_print
    print(line);
  }

  @override
  Future<void> init() async {}

  @override
  Future<void> captureException(
    Object error, {
    StackTrace? stackTrace,
    CrashContext? context,
    CrashLevel level = CrashLevel.error,
  }) async {
    final userPart = _userId == null ? '' : ' user=$_userId';
    final tagPart = _tags.isEmpty ? '' : ' tags=$_tags';
    _logger('[CrashReporter:${level.name}]$userPart$tagPart $error');
    if (stackTrace != null) _logger(stackTrace.toString());
    if (_breadcrumbs.isNotEmpty) {
      _logger('Breadcrumbs: ${_breadcrumbs.map((b) => b.toMap()).toList()}');
    }
  }

  @override
  Future<void> captureMessage(
    String message, {
    CrashLevel level = CrashLevel.info,
    CrashContext? context,
  }) async {
    _logger('[CrashReporter:${level.name}] $message');
  }

  @override
  void addBreadcrumb(Breadcrumb crumb) {
    _breadcrumbs.add(crumb);
    if (_breadcrumbs.length > 100) _breadcrumbs.removeAt(0);
  }

  @override
  void setUser({required String userId, String? email, String? username}) {
    _userId = userId;
  }

  @override
  void setTag(String key, String value) {
    _tags[key] = value;
  }

  @override
  void clearUser() {
    _userId = null;
  }

  @override
  Future<void> flush() async {}
}

class SentryCrashReporter implements CrashReporter {
  final String dsn;
  final String environment;
  final String release;
  final double sampleRate;

  SentryCrashReporter({
    required this.dsn,
    required this.environment,
    required this.release,
    this.sampleRate = 1.0,
  });

  @override
  Future<void> init() async {}

  @override
  Future<void> captureException(
    Object error, {
    StackTrace? stackTrace,
    CrashContext? context,
    CrashLevel level = CrashLevel.error,
  }) async {}

  @override
  Future<void> captureMessage(
    String message, {
    CrashLevel level = CrashLevel.info,
    CrashContext? context,
  }) async {}

  @override
  void addBreadcrumb(Breadcrumb crumb) {}

  @override
  void setUser({required String userId, String? email, String? username}) {}

  @override
  void setTag(String key, String value) {}

  @override
  void clearUser() {}

  @override
  Future<void> flush() async {}
}

class CrashReporterRegistry {
  CrashReporterRegistry._();
  static final CrashReporterRegistry instance = CrashReporterRegistry._();

  CrashReporter _active = NoopCrashReporter();

  CrashReporter get active => _active;

  void register(CrashReporter reporter) {
    _active = reporter;
  }
}
