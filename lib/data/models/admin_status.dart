class ServiceInfo {
  final String name;
  final String version;
  final String environment;
  final String? commit;

  ServiceInfo({
    required this.name,
    required this.version,
    required this.environment,
    this.commit,
  });

  factory ServiceInfo.fromJson(Map<String, dynamic>? json) {
    if (json == null) {
      return ServiceInfo(
        name: 'Unknown service',
        version: '—',
        environment: 'Unknown',
      );
    }
    return ServiceInfo(
      name: json['name'] as String? ?? 'Unknown service',
      version: json['version'] as String? ?? '—',
      environment: json['environment'] as String? ?? 'Unknown',
      commit: json['commit'] as String?,
    );
  }
}

class StatusDetail {
  final String status;
  final String? provider;
  final String? reason;

  StatusDetail({
    required this.status,
    this.provider,
    this.reason,
  });

  factory StatusDetail.fromJson(Map<String, dynamic>? json) {
    if (json == null) return StatusDetail(status: 'unknown');
    return StatusDetail(
      status: json['status'] as String? ?? 'unknown',
      provider: json['provider'] as String?,
      reason: json['reason'] as String?,
    );
  }
}

class AdminStatus {
  final ServiceInfo service;
  final Map<String, bool> featureFlags;
  final Map<String, StatusDetail> deliveryChannels;
  final Map<String, StatusDetail> dependencies;
  final Map<String, dynamic> rawJson;

  AdminStatus({
    required this.service,
    required this.featureFlags,
    required this.deliveryChannels,
    required this.dependencies,
    required this.rawJson,
  });

  factory AdminStatus.fromJson(Map<String, dynamic> json) {
    final service = ServiceInfo.fromJson(json['service'] as Map<String, dynamic>?);

    final rawFlags = json['featureFlags'] as Map<String, dynamic>? ?? {};
    final flags = <String, bool>{};
    for (final entry in rawFlags.entries) {
      if (entry.value is bool) {
        flags[entry.key] = entry.value as bool;
      }
    }

    final rawChannels = json['deliveryChannels'] as Map<String, dynamic>? ?? {};
    final channels = <String, StatusDetail>{};
    for (final entry in rawChannels.entries) {
      if (entry.value is Map<String, dynamic>) {
        channels[entry.key] = StatusDetail.fromJson(entry.value as Map<String, dynamic>);
      }
    }

    final rawDeps = json['dependencies'] as Map<String, dynamic>? ?? {};
    final deps = <String, StatusDetail>{};
    for (final entry in rawDeps.entries) {
      if (entry.value is Map<String, dynamic>) {
        deps[entry.key] = StatusDetail.fromJson(entry.value as Map<String, dynamic>);
      }
    }

    return AdminStatus(
      service: service,
      featureFlags: flags,
      deliveryChannels: channels,
      dependencies: deps,
      rawJson: json,
    );
  }
}
