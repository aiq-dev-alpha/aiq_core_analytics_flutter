import 'dart:async';
import 'dart:collection';

class AnalyticsEventRecord {
  final String name;
  final Map<String, dynamic> properties;
  final DateTime timestamp;
  final String? userId;
  final String? sessionId;

  const AnalyticsEventRecord({
    required this.name,
    required this.properties,
    required this.timestamp,
    this.userId,
    this.sessionId,
  });

  Map<String, dynamic> toMap() => {
        'event': name,
        'properties': properties,
        'timestamp': timestamp.toIso8601String(),
        if (userId != null) 'user_id': userId,
        if (sessionId != null) 'session_id': sessionId,
      };
}

abstract class AnalyticsTracker {
  Future<void> init();

  void track(String event, {Map<String, dynamic> properties = const {}});

  void identify(String userId, {Map<String, dynamic> traits = const {}});

  void alias(String alias);

  void group(String groupId, {Map<String, dynamic> traits = const {}});

  void screen(String name, {Map<String, dynamic> properties = const {}});

  void timeEvent(String event);

  void reset();

  Future<void> flush();
}

class NoopAnalyticsTracker implements AnalyticsTracker {
  @override
  Future<void> init() async {}

  @override
  void track(String event, {Map<String, dynamic> properties = const {}}) {}

  @override
  void identify(String userId, {Map<String, dynamic> traits = const {}}) {}

  @override
  void alias(String alias) {}

  @override
  void group(String groupId, {Map<String, dynamic> traits = const {}}) {}

  @override
  void screen(String name, {Map<String, dynamic> properties = const {}}) {}

  @override
  void timeEvent(String event) {}

  @override
  void reset() {}

  @override
  Future<void> flush() async {}
}

class ConsoleAnalyticsTracker implements AnalyticsTracker {
  final void Function(String) _logger;
  final List<AnalyticsEventRecord> _buffer = [];
  String? _userId;

  ConsoleAnalyticsTracker({void Function(String)? logger})
      : _logger = logger ?? _defaultLogger;

  static void _defaultLogger(String line) {
    // ignore: avoid_print
    print(line);
  }

  List<AnalyticsEventRecord> get buffer => UnmodifiableListView(_buffer);

  @override
  Future<void> init() async {}

  @override
  void track(String event, {Map<String, dynamic> properties = const {}}) {
    final record = AnalyticsEventRecord(
      name: event,
      properties: properties,
      timestamp: DateTime.now(),
      userId: _userId,
    );
    _buffer.add(record);
    if (_buffer.length > 1000) _buffer.removeAt(0);
    _logger('[Analytics] track event=$event props=$properties user=$_userId');
  }

  @override
  void identify(String userId, {Map<String, dynamic> traits = const {}}) {
    _userId = userId;
    _logger('[Analytics] identify user=$userId traits=$traits');
  }

  @override
  void alias(String alias) {
    _logger('[Analytics] alias $alias for user=$_userId');
  }

  @override
  void group(String groupId, {Map<String, dynamic> traits = const {}}) {
    _logger('[Analytics] group $groupId traits=$traits');
  }

  @override
  void screen(String name, {Map<String, dynamic> properties = const {}}) {
    track('screen_view', properties: {'screen': name, ...properties});
  }

  @override
  void timeEvent(String event) {
    _logger('[Analytics] time_event $event');
  }

  @override
  void reset() {
    _userId = null;
    _logger('[Analytics] reset');
  }

  @override
  Future<void> flush() async {
    _buffer.clear();
  }
}

class PostHogAnalyticsTracker implements AnalyticsTracker {
  final String apiKey;
  final String host;

  PostHogAnalyticsTracker({required this.apiKey, this.host = 'https://app.posthog.com'});

  @override
  Future<void> init() async {}

  @override
  void track(String event, {Map<String, dynamic> properties = const {}}) {}

  @override
  void identify(String userId, {Map<String, dynamic> traits = const {}}) {}

  @override
  void alias(String alias) {}

  @override
  void group(String groupId, {Map<String, dynamic> traits = const {}}) {}

  @override
  void screen(String name, {Map<String, dynamic> properties = const {}}) {}

  @override
  void timeEvent(String event) {}

  @override
  void reset() {}

  @override
  Future<void> flush() async {}
}

class FanOutAnalyticsTracker implements AnalyticsTracker {
  final List<AnalyticsTracker> _trackers;

  FanOutAnalyticsTracker(List<AnalyticsTracker> trackers) : _trackers = trackers;

  @override
  Future<void> init() async {
    for (final t in _trackers) {
      try {
        await t.init();
      } catch (_) {}
    }
  }

  @override
  void track(String event, {Map<String, dynamic> properties = const {}}) {
    for (final t in _trackers) {
      try {
        t.track(event, properties: properties);
      } catch (_) {}
    }
  }

  @override
  void identify(String userId, {Map<String, dynamic> traits = const {}}) {
    for (final t in _trackers) {
      try {
        t.identify(userId, traits: traits);
      } catch (_) {}
    }
  }

  @override
  void alias(String alias) {
    for (final t in _trackers) {
      try {
        t.alias(alias);
      } catch (_) {}
    }
  }

  @override
  void group(String groupId, {Map<String, dynamic> traits = const {}}) {
    for (final t in _trackers) {
      try {
        t.group(groupId, traits: traits);
      } catch (_) {}
    }
  }

  @override
  void screen(String name, {Map<String, dynamic> properties = const {}}) {
    for (final t in _trackers) {
      try {
        t.screen(name, properties: properties);
      } catch (_) {}
    }
  }

  @override
  void timeEvent(String event) {
    for (final t in _trackers) {
      try {
        t.timeEvent(event);
      } catch (_) {}
    }
  }

  @override
  void reset() {
    for (final t in _trackers) {
      try {
        t.reset();
      } catch (_) {}
    }
  }

  @override
  Future<void> flush() async {
    for (final t in _trackers) {
      try {
        await t.flush();
      } catch (_) {}
    }
  }
}

class AnalyticsTrackerRegistry {
  AnalyticsTrackerRegistry._();
  static final AnalyticsTrackerRegistry instance = AnalyticsTrackerRegistry._();

  AnalyticsTracker _active = NoopAnalyticsTracker();

  AnalyticsTracker get active => _active;

  void register(AnalyticsTracker tracker) {
    _active = tracker;
  }
}
