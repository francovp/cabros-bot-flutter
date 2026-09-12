class ApiParameter {
  final String name;
  final String paramIn; // 'path' or 'query'
  final bool required;
  final dynamic example;
  final List<dynamic>? enumValues;

  ApiParameter({
    required this.name,
    required this.paramIn,
    this.required = false,
    this.example,
    this.enumValues,
  });

  factory ApiParameter.fromJson(Map<String, dynamic> json, Map<String, dynamic> contract) {
    var resolved = json;
    if (json.containsKey(r'$ref')) {
      final ref = json[r'$ref'] as String;
      resolved = _resolveRef(contract, ref) ?? json;
    }

    final schema = resolved['schema'] as Map<String, dynamic>?;
    final example = resolved['example'] ?? schema?['example'] ?? schema?['default'];
    final enumList = schema?['enum'] as List<dynamic>?;

    return ApiParameter(
      name: resolved['name']?.toString() ?? '',
      paramIn: resolved['in']?.toString() ?? 'query',
      required: resolved['required'] == true,
      example: example,
      enumValues: enumList,
    );
  }

  static Map<String, dynamic>? _resolveRef(Map<String, dynamic> contract, String ref) {
    if (!ref.startsWith('#/')) return null;
    final parts = ref.substring(2).split('/');
    dynamic current = contract;
    for (final part in parts) {
      if (current is Map<String, dynamic>) {
        current = current[part];
      } else {
        return null;
      }
    }
    return current is Map<String, dynamic> ? current : null;
  }
}

class ApiOperation {
  final String method;
  final String path;
  final String label;
  final String? description;
  final List<ApiParameter> parameters;
  final dynamic requestBodyExample;
  final String? confirm;
  final String requiredRole;

  ApiOperation({
    required this.method,
    required this.path,
    required this.label,
    this.description,
    required this.parameters,
    this.requestBodyExample,
    this.confirm,
    required this.requiredRole,
  });

  List<String> get pathVariableNames {
    final matches = RegExp(r'\{([^}]+)\}').allMatches(path);
    return matches.map((m) => m.group(1)!).toList();
  }

  List<ApiParameter> get queryParameters =>
      parameters.where((p) => p.paramIn == 'query').toList();

  static const Map<String, String> confirmationMap = {
    'POST /api/alerts/{alertId}/replay': 'Replay this alert?',
    'POST /api/scanner-presets/{id}/run': 'Run this scanner preset?',
    'DELETE /api/scanner-presets/{id}': 'Delete this scanner preset?',
    'POST /api/jobs/{jobId}/cancel': 'Cancel this job?',
    'POST /api/jobs/{jobId}/retry': 'Retry this job?',
    'POST /api/jobs/{jobId}/retry-failed': 'Retry failed items for this job?',
  };

  static List<ApiOperation> extractOperations(Map<String, dynamic> contract) {
    final paths = contract['paths'] as Map<String, dynamic>? ?? {};
    final operations = <ApiOperation>[];

    for (final pathEntry in paths.entries) {
      final path = pathEntry.key;
      final pathItem = pathEntry.value as Map<String, dynamic>? ?? {};

      for (final methodEntry in pathItem.entries) {
        final method = methodEntry.key.toUpperCase();
        if (!['GET', 'POST', 'PUT', 'PATCH', 'DELETE'].contains(method)) continue;

        final opJson = methodEntry.value as Map<String, dynamic>? ?? {};
        final summary = opJson['summary']?.toString() ?? '$method $path';
        final desc = opJson['description']?.toString();

        // Extract parameters
        final rawParams = opJson['parameters'] as List<dynamic>? ?? [];
        final params = rawParams
            .whereType<Map<String, dynamic>>()
            .map((p) => ApiParameter.fromJson(p, contract))
            .toList();

        // Extract request body example
        dynamic bodyExample;
        final requestBody = opJson['requestBody'] as Map<String, dynamic>?;
        if (requestBody != null) {
          final content = requestBody['content'] as Map<String, dynamic>?;
          final jsonContent = content?['application/json'] as Map<String, dynamic>?;
          if (jsonContent != null) {
            bodyExample = jsonContent['example'];
            if (bodyExample == null && jsonContent['examples'] is Map<String, dynamic>) {
              final examples = jsonContent['examples'] as Map<String, dynamic>;
              if (examples.isNotEmpty) {
                final first = examples.values.first as Map<String, dynamic>?;
                bodyExample = first?['value'];
              }
            }
          }
        }

        final key = '$method $path';
        final confirm = confirmationMap[key];
        final requiredRole = opJson['x-admin-role']?.toString() ??
            (method == 'GET' ? 'admin.viewer' : 'admin.operator');

        operations.add(ApiOperation(
          method: method,
          path: path,
          label: summary,
          description: desc,
          parameters: params,
          requestBodyExample: bodyExample,
          confirm: confirm,
          requiredRole: requiredRole,
        ));
      }
    }

    operations.sort((a, b) {
      final p = a.path.compareTo(b.path);
      if (p != 0) return p;
      return a.method.compareTo(b.method);
    });

    return operations;
  }
}
