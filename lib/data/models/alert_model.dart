class DeliveryResult {
  final bool success;
  final String? messageId;
  final String? error;

  DeliveryResult({
    required this.success,
    this.messageId,
    this.error,
  });

  factory DeliveryResult.fromJson(Map<String, dynamic> json) {
    return DeliveryResult(
      success: json['success'] == true,
      messageId: json['messageId']?.toString(),
      error: json['error']?.toString() ?? json['errorCode']?.toString(),
    );
  }
}

class AlertItem {
  final String id;
  final String text;
  final String? source;
  final String? receivedAt;
  final bool enriched;
  final Map<String, dynamic>? enrichmentData;
  final Map<String, DeliveryResult> deliveryResults;
  final Map<String, dynamic>? tokenUsage;
  final Map<String, dynamic> rawJson;

  AlertItem({
    required this.id,
    required this.text,
    this.source,
    this.receivedAt,
    required this.enriched,
    this.enrichmentData,
    required this.deliveryResults,
    this.tokenUsage,
    required this.rawJson,
  });

  String? get sentiment => enrichmentData?['sentiment']?.toString();
  String? get setupType => enrichmentData?['setup_type']?.toString();
  dynamic get invalidationLevel => enrichmentData?['invalidation_level'];
  dynamic get targetLevel => enrichmentData?['target_level'];
  dynamic get riskRewardRatio => enrichmentData?['risk_reward_ratio'];
  List<dynamic> get insights =>
      enrichmentData?['insights'] is List ? enrichmentData!['insights'] as List : [];
  List<dynamic> get sources =>
      enrichmentData?['sources'] is List ? enrichmentData!['sources'] as List : [];

  factory AlertItem.fromJson(Map<String, dynamic> json) {
    final deliveries = <String, DeliveryResult>{};
    final rawDelivery = json['deliveryResults'];

    if (rawDelivery is Map) {
      for (final entry in rawDelivery.entries) {
        if (entry.value is Map) {
          deliveries[entry.key.toString()] = DeliveryResult.fromJson(
            (entry.value as Map).cast<String, dynamic>(),
          );
        }
      }
    } else if (rawDelivery is List) {
      for (final item in rawDelivery) {
        if (item is Map) {
          final itemMap = item.cast<String, dynamic>();
          final channel = itemMap['channel']?.toString() ?? 'unknown';
          deliveries[channel] = DeliveryResult.fromJson(itemMap);
        }
      }
    }

    return AlertItem(
      id: json['id']?.toString() ?? '',
      text: json['text']?.toString() ?? '',
      source: json['source']?.toString(),
      receivedAt: json['receivedAt']?.toString(),
      enriched: json['enriched'] == true,
      enrichmentData: (json['enrichmentData'] as Map?)?.cast<String, dynamic>(),
      deliveryResults: deliveries,
      tokenUsage: (json['tokenUsage'] as Map?)?.cast<String, dynamic>(),
      rawJson: json,
    );
  }
}

class AlertPagination {
  final bool hasMore;
  final String? nextBefore;

  AlertPagination({
    required this.hasMore,
    this.nextBefore,
  });

  factory AlertPagination.fromJson(Map<String, dynamic>? json) {
    if (json == null) return AlertPagination(hasMore: false);
    return AlertPagination(
      hasMore: json['hasMore'] == true,
      nextBefore: json['nextBefore']?.toString(),
    );
  }
}

class AlertListResponse {
  final List<AlertItem> alerts;
  final AlertPagination pagination;
  final Map<String, dynamic> rawJson;

  AlertListResponse({
    required this.alerts,
    required this.pagination,
    required this.rawJson,
  });

  factory AlertListResponse.fromJson(dynamic json) {
    if (json is List) {
      final alerts = json
          .whereType<Map>()
          .map((item) => AlertItem.fromJson(item.cast<String, dynamic>()))
          .toList();
      return AlertListResponse(
        alerts: alerts,
        pagination: AlertPagination(hasMore: false),
        rawJson: {'alerts': json},
      );
    }

    if (json is Map) {
      final map = json.cast<String, dynamic>();
      final rawAlerts = map['alerts'] as List<dynamic>? ?? [];
      final alerts = rawAlerts
          .whereType<Map>()
          .map((item) => AlertItem.fromJson(item.cast<String, dynamic>()))
          .toList();

      return AlertListResponse(
        alerts: alerts,
        pagination: AlertPagination.fromJson(
          (map['pagination'] as Map?)?.cast<String, dynamic>(),
        ),
        rawJson: map,
      );
    }

    return AlertListResponse(
      alerts: [],
      pagination: AlertPagination(hasMore: false),
      rawJson: {},
    );
  }
}

class AlertSummaryData {
  final dynamic totalAlerts;
  final String? from;
  final String? to;
  final dynamic totalSuccess;
  final dynamic totalFailure;
  final dynamic totalTokens;
  final dynamic totalCost;
  final dynamic enrichedAlerts;
  final dynamic plainAlerts;
  final Map<String, dynamic> deliveryByChannel;
  final Map<String, dynamic> riskCoverageFields;
  final dynamic coverageDenominator;
  final Map<String, dynamic> rawJson;

  AlertSummaryData({
    this.totalAlerts,
    this.from,
    this.to,
    this.totalSuccess,
    this.totalFailure,
    this.totalTokens,
    this.totalCost,
    this.enrichedAlerts,
    this.plainAlerts,
    required this.deliveryByChannel,
    required this.riskCoverageFields,
    this.coverageDenominator,
    required this.rawJson,
  });

  factory AlertSummaryData.fromJson(Map<String, dynamic> json) {
    final summary = (json['summary'] as Map?)?.cast<String, dynamic>() ?? json;
    final window = (summary['window'] as Map?)?.cast<String, dynamic>() ?? {};
    final delivery = (summary['delivery'] as Map?)?.cast<String, dynamic>() ?? {};
    final enrichment = (summary['enrichment'] as Map?)?.cast<String, dynamic>() ?? {};
    final tokenTotals = (enrichment['tokenUsage'] as Map?)?.cast<String, dynamic>() ?? {};
    final coverage = (enrichment['riskMetadataCoverage'] as Map?)?.cast<String, dynamic>() ?? {};

    return AlertSummaryData(
      totalAlerts: summary['totalAlerts'],
      from: window['from']?.toString(),
      to: window['to']?.toString(),
      totalSuccess: delivery['totalSuccess'],
      totalFailure: delivery['totalFailure'],
      totalTokens: tokenTotals['totalTokens'],
      totalCost: tokenTotals['totalCost'],
      enrichedAlerts: enrichment['enrichedAlerts'],
      plainAlerts: enrichment['plainAlerts'],
      deliveryByChannel: (delivery['byChannel'] as Map?)?.cast<String, dynamic>() ?? {},
      riskCoverageFields: (coverage['fields'] as Map?)?.cast<String, dynamic>() ?? {},
      coverageDenominator: coverage['denominator'],
      rawJson: json,
    );
  }
}
