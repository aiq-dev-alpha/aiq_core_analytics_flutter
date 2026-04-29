import 'dart:async';

class PerformanceTransaction {
  final String name;
  final String operation;
  final DateTime startedAt;
  DateTime? finishedAt;
  final Map<String, dynamic> data;
  final Map<String, num> measurements;

  PerformanceTransaction({
    required this.name,
    required this.operation,
    DateTime? startedAt,
    Map<String, dynamic>? data,
    Map<String, num>? measurements,
  })  : startedAt = startedAt ?? DateTime.now(),
        data = data ?? {},
        measurements = measurements ?? {};

  Duration? get duration =>
      finishedAt == null ? null : finishedAt!.difference(startedAt);

  void finish() {
    finishedAt = DateTime.now();
  }

  void setData(String key, dynamic value) {
    data[key] = value;
  }

  void setMeasurement(String key, num value) {
    measurements[key] = value;
  }
}

class PerformanceSpan {
  final String name;
  final DateTime startedAt;
  DateTime? finishedAt;

  PerformanceSpan({required this.name, DateTime? startedAt})
      : startedAt = startedAt ?? DateTime.now();

  Duration? get duration =>
      finishedAt == null ? null : finishedAt!.difference(startedAt);

  void finish() {
    finishedAt = DateTime.now();
  }
}

abstract class PerformanceMonitor {
  Future<void> init();

  PerformanceTransaction startTransaction(String name, String operation);

  PerformanceSpan startSpan(PerformanceTransaction transaction, String name);

  void recordHttpRequest({
    required String url,
    required String method,
    required int statusCode,
    required Duration duration,
    int? requestBodySize,
    int? responseBodySize,
  });

  void recordCustomMetric(String name, num value, {Map<String, String> tags = const {}});

  Future<void> flush();
}

class NoopPerformanceMonitor implements PerformanceMonitor {
  @override
  Future<void> init() async {}

  @override
  PerformanceTransaction startTransaction(String name, String operation) =>
      PerformanceTransaction(name: name, operation: operation);

  @override
  PerformanceSpan startSpan(PerformanceTransaction transaction, String name) =>
      PerformanceSpan(name: name);

  @override
  void recordHttpRequest({
    required String url,
    required String method,
    required int statusCode,
    required Duration duration,
    int? requestBodySize,
    int? responseBodySize,
  }) {}

  @override
  void recordCustomMetric(String name, num value, {Map<String, String> tags = const {}}) {}

  @override
  Future<void> flush() async {}
}

class ConsolePerformanceMonitor implements PerformanceMonitor {
  final void Function(String) _logger;
  final List<PerformanceTransaction> _transactions = [];

  ConsolePerformanceMonitor({void Function(String)? logger})
      : _logger = logger ?? _defaultLogger;

  static void _defaultLogger(String line) {
    // ignore: avoid_print
    print(line);
  }

  List<PerformanceTransaction> get transactions => List.unmodifiable(_transactions);

  @override
  Future<void> init() async {}

  @override
  PerformanceTransaction startTransaction(String name, String operation) {
    final tx = PerformanceTransaction(name: name, operation: operation);
    _transactions.add(tx);
    if (_transactions.length > 200) _transactions.removeAt(0);
    _logger('[Perf] start tx=$name op=$operation');
    return tx;
  }

  @override
  PerformanceSpan startSpan(PerformanceTransaction transaction, String name) {
    return PerformanceSpan(name: name);
  }

  @override
  void recordHttpRequest({
    required String url,
    required String method,
    required int statusCode,
    required Duration duration,
    int? requestBodySize,
    int? responseBodySize,
  }) {
    _logger('[Perf] http $method $url -> $statusCode (${duration.inMilliseconds}ms)');
  }

  @override
  void recordCustomMetric(String name, num value, {Map<String, String> tags = const {}}) {
    _logger('[Perf] metric $name=$value tags=$tags');
  }

  @override
  Future<void> flush() async {}
}

class PerformanceMonitorRegistry {
  PerformanceMonitorRegistry._();
  static final PerformanceMonitorRegistry instance = PerformanceMonitorRegistry._();

  PerformanceMonitor _active = NoopPerformanceMonitor();

  PerformanceMonitor get active => _active;

  void register(PerformanceMonitor monitor) {
    _active = monitor;
  }
}
