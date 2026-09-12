class ScannerPreset {
  final String id;
  final String name;
  final String? description;
  final List<String> symbols;
  final List<String> scans;
  final String? interval;
  final Map<String, dynamic> rawJson;

  ScannerPreset({
    required this.id,
    required this.name,
    this.description,
    required this.symbols,
    required this.scans,
    this.interval,
    required this.rawJson,
  });

  factory ScannerPreset.fromJson(Map<String, dynamic> json) {
    final rawSymbols = json['symbols'] as List<dynamic>? ?? [];
    final symbols = rawSymbols.map((e) => e.toString()).toList();

    final rawScans = (json['scans'] ?? json['scanTypes']) as List<dynamic>? ?? [];
    final scans = rawScans.map((e) => e.toString()).toList();

    return ScannerPreset(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? 'Unnamed preset',
      description: json['description']?.toString(),
      symbols: symbols,
      scans: scans,
      interval: json['interval']?.toString() ?? json['timeframe']?.toString(),
      rawJson: json,
    );
  }
}
