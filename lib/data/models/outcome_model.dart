class OutcomeWindowDetail {
  final String? status;
  final bool? targetHit;
  final bool? stopHit;
  final dynamic returnPercent;
  final dynamic mfePercent;
  final dynamic maePercent;
  final dynamic rMultiple;

  OutcomeWindowDetail({
    this.status,
    this.targetHit,
    this.stopHit,
    this.returnPercent,
    this.mfePercent,
    this.maePercent,
    this.rMultiple,
  });

  factory OutcomeWindowDetail.fromJson(Map<String, dynamic> json) {
    return OutcomeWindowDetail(
      status: json['status']?.toString(),
      targetHit: json['targetHit'] == true,
      stopHit: json['stopHit'] == true,
      returnPercent: json['returnPercent'] ?? json['realizedReturnPercent'],
      mfePercent: json['mfePercent'] ?? json['maxFavorableExcursionPercent'],
      maePercent: json['maePercent'] ?? json['maxAdverseExcursionPercent'],
      rMultiple: json['rMultiple'] ?? json['rScore'],
    );
  }
}

class OutcomeItem {
  final String id;
  final String symbol;
  final String? exchange;
  final String? status;
  final String? receivedAt;
  final dynamic entryPrice;
  final dynamic targetPrice;
  final dynamic stopLossPrice;
  final Map<String, OutcomeWindowDetail> windows;
  final Map<String, dynamic> rawJson;

  OutcomeItem({
    required this.id,
    required this.symbol,
    this.exchange,
    this.status,
    this.receivedAt,
    this.entryPrice,
    this.targetPrice,
    this.stopLossPrice,
    required this.windows,
    required this.rawJson,
  });

  factory OutcomeItem.fromJson(Map<String, dynamic> json) {
    final rawWindows = json['windows'] ?? json['evaluations'];
    final windowDetails = <String, OutcomeWindowDetail>{};

    if (rawWindows is Map) {
      for (final entry in rawWindows.entries) {
        if (entry.value is Map) {
          windowDetails[entry.key.toString()] = OutcomeWindowDetail.fromJson(
            (entry.value as Map).cast<String, dynamic>(),
          );
        }
      }
    } else if (rawWindows is List) {
      for (final item in rawWindows) {
        if (item is Map) {
          final itemMap = item.cast<String, dynamic>();
          final winKey = itemMap['window']?.toString() ?? 'unknown';
          windowDetails[winKey] = OutcomeWindowDetail.fromJson(itemMap);
        }
      }
    }

    return OutcomeItem(
      id: json['id']?.toString() ?? json['signalId']?.toString() ?? '',
      symbol: json['symbol']?.toString() ?? 'Unknown',
      exchange: json['exchange']?.toString(),
      status: json['status']?.toString(),
      receivedAt: json['receivedAt']?.toString(),
      entryPrice: json['entryPrice'],
      targetPrice: json['targetPrice'],
      stopLossPrice: json['stopLossPrice'],
      windows: windowDetails,
      rawJson: json,
    );
  }
}

class OutcomeListResponse {
  final List<OutcomeItem> outcomes;
  final bool hasMore;
  final String? nextBefore;
  final Map<String, dynamic> rawJson;

  OutcomeListResponse({
    required this.outcomes,
    required this.hasMore,
    this.nextBefore,
    required this.rawJson,
  });

  factory OutcomeListResponse.fromJson(dynamic json) {
    if (json is List) {
      final outcomes = json
          .whereType<Map>()
          .map((item) => OutcomeItem.fromJson(item.cast<String, dynamic>()))
          .toList();
      return OutcomeListResponse(
        outcomes: outcomes,
        hasMore: false,
        rawJson: {'outcomes': json},
      );
    }

    if (json is Map) {
      final map = json.cast<String, dynamic>();
      final rawList = map['outcomes'] as List<dynamic>? ?? [];
      final outcomes = rawList
          .whereType<Map>()
          .map((item) => OutcomeItem.fromJson(item.cast<String, dynamic>()))
          .toList();

      final pagination = (map['pagination'] as Map?)?.cast<String, dynamic>();
      return OutcomeListResponse(
        outcomes: outcomes,
        hasMore: pagination?['hasMore'] == true,
        nextBefore: pagination?['nextBefore']?.toString(),
        rawJson: map,
      );
    }

    return OutcomeListResponse(
      outcomes: [],
      hasMore: false,
      rawJson: {},
    );
  }
}

class OutcomeSummaryData {
  final dynamic totalSignals;
  final dynamic totalEligible;
  final dynamic totalEvaluated;
  final dynamic totalPending;
  final dynamic hitRatePercent;
  final dynamic expectancyR;
  final dynamic averageReturnPercent;
  final dynamic averageMfePercent;
  final dynamic averageMaePercent;
  final Map<String, dynamic> windowPerformance;
  final Map<String, dynamic> rawJson;

  OutcomeSummaryData({
    this.totalSignals,
    this.totalEligible,
    this.totalEvaluated,
    this.totalPending,
    this.hitRatePercent,
    this.expectancyR,
    this.averageReturnPercent,
    this.averageMfePercent,
    this.averageMaePercent,
    required this.windowPerformance,
    required this.rawJson,
  });

  factory OutcomeSummaryData.fromJson(dynamic json) {
    final map = json is Map ? json.cast<String, dynamic>() : <String, dynamic>{};
    final summary = map['summary'] is Map ? (map['summary'] as Map).cast<String, dynamic>() : map;
    final rawWindows = summary['windows'] ?? summary['byWindow'];
    final windows = rawWindows is Map ? rawWindows.cast<String, dynamic>() : <String, dynamic>{};

    return OutcomeSummaryData(
      totalSignals: summary['totalSignalsReceived'] ?? summary['totalSignals'] ?? 0,
      totalEligible: summary['totalSignalsEligible'] ?? 0,
      totalEvaluated: summary['totalSignalsEvaluated'] ?? 0,
      totalPending: summary['totalSignalsPending'] ?? 0,
      hitRatePercent: summary['winRatePercent'] ?? summary['overallHitRatePercent'],
      expectancyR: summary['expectancyR'],
      averageReturnPercent: summary['averageReturnPercent'],
      averageMfePercent: summary['averageMfePercent'] ?? summary['avgMfePercent'],
      averageMaePercent: summary['averageMaePercent'] ?? summary['avgMaePercent'],
      windowPerformance: windows,
      rawJson: map,
    );
  }
}
