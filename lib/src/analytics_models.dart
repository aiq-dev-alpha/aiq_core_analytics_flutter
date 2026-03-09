import 'analytics_enums.dart';

class AnalyticsEvent {
  final String id;
  final AnalyticsEventType type;
  final String name;
  final Map<String, dynamic> parameters;
  final String? userId;
  final String? screenName;
  final DateTime timestamp;

  const AnalyticsEvent({
    required this.id, required this.type, required this.name,
    this.parameters = const {}, this.userId, this.screenName, required this.timestamp,
  });

  Map<String, dynamic> toJson() => {
    'id': id, 'type': type.name, 'name': name, 'parameters': parameters,
    'user_id': userId, 'screen_name': screenName, 'timestamp': timestamp.toIso8601String(),
  };

  factory AnalyticsEvent.fromJson(Map<String, dynamic> j) => AnalyticsEvent(
    id: j['id'] ?? '',
    type: AnalyticsEventType.values.firstWhere((t) => t.name == j['type'], orElse: () => AnalyticsEventType.custom),
    name: j['name'] ?? '',
    parameters: j['parameters'] is Map ? Map<String, dynamic>.from(j['parameters']) : {},
    userId: j['user_id'], screenName: j['screen_name'],
    timestamp: DateTime.tryParse(j['timestamp'] ?? '') ?? DateTime.now(),
  );
}

class CrashReport {
  final String id;
  final String message;
  final String? stackTrace;
  final CrashSeverity severity;
  final String? userId;
  final String? screenName;
  final Map<String, dynamic> deviceInfo;
  final Map<String, dynamic> appState;
  final DateTime timestamp;

  const CrashReport({
    required this.id, required this.message, this.stackTrace,
    this.severity = CrashSeverity.nonFatal, this.userId, this.screenName,
    this.deviceInfo = const {}, this.appState = const {}, required this.timestamp,
  });

  Map<String, dynamic> toJson() => {
    'id': id, 'message': message, 'stack_trace': stackTrace, 'severity': severity.name,
    'user_id': userId, 'screen_name': screenName, 'device_info': deviceInfo,
    'app_state': appState, 'timestamp': timestamp.toIso8601String(),
  };

  factory CrashReport.fromJson(Map<String, dynamic> j) => CrashReport(
    id: j['id'] ?? '', message: j['message'] ?? '', stackTrace: j['stack_trace'],
    severity: CrashSeverity.values.firstWhere((s) => s.name == j['severity'], orElse: () => CrashSeverity.nonFatal),
    userId: j['user_id'], screenName: j['screen_name'],
    deviceInfo: j['device_info'] is Map ? Map<String, dynamic>.from(j['device_info']) : {},
    appState: j['app_state'] is Map ? Map<String, dynamic>.from(j['app_state']) : {},
    timestamp: DateTime.tryParse(j['timestamp'] ?? '') ?? DateTime.now(),
  );
}

class EngagementMetrics {
  final int dailyActiveUsers;
  final int monthlyActiveUsers;
  final double dauMauRatio;
  final double day1Retention;
  final double day7Retention;
  final double day30Retention;
  final double avgSessionDuration;
  final double avgSessionsPerDay;
  final DateTime calculatedAt;

  const EngagementMetrics({
    required this.dailyActiveUsers, required this.monthlyActiveUsers, required this.dauMauRatio,
    this.day1Retention = 0, this.day7Retention = 0, this.day30Retention = 0,
    this.avgSessionDuration = 0, this.avgSessionsPerDay = 0, required this.calculatedAt,
  });

  Map<String, dynamic> toJson() => {
    'dau': dailyActiveUsers, 'mau': monthlyActiveUsers, 'dau_mau_ratio': dauMauRatio,
    'day1_retention': day1Retention, 'day7_retention': day7Retention, 'day30_retention': day30Retention,
    'avg_session_duration': avgSessionDuration, 'avg_sessions_per_day': avgSessionsPerDay,
    'calculated_at': calculatedAt.toIso8601String(),
  };
}

class RevenueMetrics {
  final double totalRevenue;
  final double arpu;
  final double arppu;
  final double ltv;
  final double conversionRate;
  final int totalPurchases;
  final int uniquePayers;
  final Map<String, double> revenueByProduct;
  final DateTime calculatedAt;

  const RevenueMetrics({
    required this.totalRevenue, required this.arpu, required this.arppu,
    this.ltv = 0, this.conversionRate = 0, required this.totalPurchases,
    required this.uniquePayers, this.revenueByProduct = const {}, required this.calculatedAt,
  });

  Map<String, dynamic> toJson() => {
    'total_revenue': totalRevenue, 'arpu': arpu, 'arppu': arppu, 'ltv': ltv,
    'conversion_rate': conversionRate, 'total_purchases': totalPurchases,
    'unique_payers': uniquePayers, 'revenue_by_product': revenueByProduct,
    'calculated_at': calculatedAt.toIso8601String(),
  };
}

class AbTest {
  final String id;
  final String name;
  final String description;
  final Map<AbTestVariant, double> variantWeights;
  final AbTestVariant? assignedVariant;
  final bool isActive;
  final DateTime startDate;
  final DateTime? endDate;
  final Map<AbTestVariant, Map<String, dynamic>> variantResults;

  const AbTest({
    required this.id, required this.name, this.description = '',
    this.variantWeights = const {AbTestVariant.control: 0.5, AbTestVariant.variantA: 0.5},
    this.assignedVariant, this.isActive = true, required this.startDate,
    this.endDate, this.variantResults = const {},
  });

  Map<String, dynamic> toJson() => {
    'id': id, 'name': name, 'description': description,
    'variant_weights': variantWeights.map((k, v) => MapEntry(k.name, v)),
    'assigned_variant': assignedVariant?.name, 'is_active': isActive,
    'start_date': startDate.toIso8601String(), 'end_date': endDate?.toIso8601String(),
  };

  factory AbTest.fromJson(Map<String, dynamic> j) => AbTest(
    id: j['id'] ?? '', name: j['name'] ?? '', description: j['description'] ?? '',
    assignedVariant: j['assigned_variant'] != null
      ? AbTestVariant.values.firstWhere((v) => v.name == j['assigned_variant'], orElse: () => AbTestVariant.control)
      : null,
    isActive: j['is_active'] ?? true,
    startDate: DateTime.tryParse(j['start_date'] ?? '') ?? DateTime.now(),
    endDate: j['end_date'] != null ? DateTime.tryParse(j['end_date']) : null,
  );
}

class FunnelAnalysis {
  final String funnelName;
  final Map<FunnelStep, int> stepCounts;
  final Map<FunnelStep, double> conversionRates;
  final FunnelStep? biggestDropoff;
  final DateTime analyzedAt;

  const FunnelAnalysis({
    required this.funnelName, required this.stepCounts, required this.conversionRates,
    this.biggestDropoff, required this.analyzedAt,
  });

  Map<String, dynamic> toJson() => {
    'funnel_name': funnelName,
    'step_counts': stepCounts.map((k, v) => MapEntry(k.name, v)),
    'conversion_rates': conversionRates.map((k, v) => MapEntry(k.name, v)),
    'biggest_dropoff': biggestDropoff?.name, 'analyzed_at': analyzedAt.toIso8601String(),
  };
}

class ErrorLogEntry {
  final String id;
  final String message;
  final String? source;
  final String level;
  final Map<String, dynamic> context;
  final DateTime timestamp;

  const ErrorLogEntry({
    required this.id, required this.message, this.source, this.level = 'error',
    this.context = const {}, required this.timestamp,
  });

  Map<String, dynamic> toJson() => {
    'id': id, 'message': message, 'source': source, 'level': level,
    'context': context, 'timestamp': timestamp.toIso8601String(),
  };
}
