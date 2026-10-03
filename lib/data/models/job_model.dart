class JobProgress {
  final num? current;
  final num? total;
  final String? status;

  JobProgress({this.current, this.total, this.status});

  factory JobProgress.fromJson(Map<String, dynamic>? json) {
    if (json == null) return JobProgress();
    return JobProgress(
      current: json['current'] as num?,
      total: json['total'] as num?,
      status: json['status']?.toString(),
    );
  }

  double get fraction {
    if (total == null || total! <= 0) return 0.0;
    final curr = current ?? 0;
    return (curr / total!).clamp(0.0, 1.0);
  }
}

class JobItem {
  final String jobId;
  final String? type;
  final String status;
  final String? createdAt;
  final String? updatedAt;
  final int? totalDurationMs;
  final JobProgress progress;
  final String? alertText;
  final List<dynamic> results;
  final List<dynamic> scanResults;
  final Map<String, dynamic> deliveryResults;
  final Map<String, dynamic> rawJson;

  JobItem({
    required this.jobId,
    this.type,
    required this.status,
    this.createdAt,
    this.updatedAt,
    this.totalDurationMs,
    required this.progress,
    this.alertText,
    required this.results,
    required this.scanResults,
    required this.deliveryResults,
    required this.rawJson,
  });

  bool get isActive => status == 'pending' || status == 'processing';

  factory JobItem.fromJson(Map<String, dynamic> json) {
    final rawDelivery = json['deliveryResults'];
    final deliveryMap = <String, dynamic>{};
    if (rawDelivery is Map) {
      deliveryMap.addAll(rawDelivery.cast<String, dynamic>());
    } else if (rawDelivery is List) {
      for (var i = 0; i < rawDelivery.length; i++) {
        final item = rawDelivery[i];
        if (item is Map) {
          final key = item['channel']?.toString() ?? '$i';
          deliveryMap[key] = item;
        }
      }
    }

    return JobItem(
      jobId: json['jobId']?.toString() ?? '',
      type: json['type']?.toString(),
      status: json['status']?.toString() ?? 'unknown',
      createdAt: json['createdAt']?.toString(),
      updatedAt: json['updatedAt']?.toString(),
      totalDurationMs: json['totalDurationMs'] as int?,
      progress: JobProgress.fromJson((json['progress'] as Map?)?.cast<String, dynamic>()),
      alertText: json['alertText']?.toString(),
      results: json['results'] as List<dynamic>? ?? [],
      scanResults: json['scanResults'] as List<dynamic>? ?? [],
      deliveryResults: deliveryMap,
      rawJson: json,
    );
  }
}
