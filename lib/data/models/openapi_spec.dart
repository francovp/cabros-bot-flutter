class ApiParameter {
  final String name;
  final String paramIn; // 'path' or 'query'
  final bool required;
  final dynamic example;
  final List<dynamic>? enumValues;
  final String? type;
  final String? format;
  final String? description;
  final num? minimum;
  final num? maximum;
  final String? pattern;
  final Map<String, dynamic>? schema;

  ApiParameter({
    required this.name,
    required this.paramIn,
    this.required = false,
    this.example,
    this.enumValues,
    this.type,
    this.format,
    this.description,
    this.minimum,
    this.maximum,
    this.pattern,
    this.schema,
  });

  factory ApiParameter.fromJson(Map<String, dynamic> json, Map<String, dynamic> contract) {
    var resolved = json;
    if (json.containsKey(r'$ref')) {
      final ref = json[r'$ref'] as String;
      resolved = OpenApiSpec.resolveRef(contract, ref) ?? json;
    }

    final rawSchema = resolved['schema'] as Map<String, dynamic>?;
    final schema = rawSchema != null ? OpenApiSpec.schemaFor(contract, rawSchema) : null;
    final example = resolved['example'] ?? schema?['example'] ?? schema?['default'];
    final enumList = (schema?['enum'] as List<dynamic>?) ?? (rawSchema?['enum'] as List<dynamic>?);

    return ApiParameter(
      name: resolved['name']?.toString() ?? '',
      paramIn: resolved['in']?.toString() ?? 'query',
      required: resolved['required'] == true,
      example: example,
      enumValues: enumList,
      type: schema?['type']?.toString() ?? rawSchema?['type']?.toString(),
      format: schema?['format']?.toString() ?? rawSchema?['format']?.toString(),
      description: resolved['description']?.toString() ?? schema?['description']?.toString(),
      minimum: schema?['minimum'] is num ? (schema!['minimum'] as num) : null,
      maximum: schema?['maximum'] is num ? (schema!['maximum'] as num) : null,
      pattern: schema?['pattern']?.toString(),
      schema: schema ?? rawSchema,
    );
  }
}

class ApiOperation {
  final String method;
  final String path;
  final String label;
  final String? description;
  final List<ApiParameter> parameters;
  final dynamic requestBodyExample;
  final Map<String, dynamic>? requestBodySchema;
  final String? confirm;
  final String requiredRole;

  ApiOperation({
    required this.method,
    required this.path,
    required this.label,
    this.description,
    required this.parameters,
    this.requestBodyExample,
    this.requestBodySchema,
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

        // Extract request body schema & example
        dynamic bodyExample;
        Map<String, dynamic>? bodySchema;
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

            final rawBodySchema = jsonContent['schema'] as Map<String, dynamic>?;
            if (rawBodySchema != null) {
              bodySchema = OpenApiSpec.schemaFor(contract, rawBodySchema);
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
          requestBodySchema: bodySchema,
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

class OpenApiSpec {
  static Map<String, dynamic>? resolveRef(Map<String, dynamic> contract, String ref) {
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
    return current is Map<String, dynamic> ? Map<String, dynamic>.from(current) : null;
  }

  /// Recursively normalizes an OpenAPI 3.1 schema:
  /// - resolves $ref
  /// - flattens allOf / oneOf / anyOf
  /// - tracks variants for oneOf
  /// - normalizes properties and items
  static Map<String, dynamic> schemaFor(
    Map<String, dynamic> contract,
    Map<String, dynamic>? schema, [
    int depth = 0,
  ]) {
    if (schema == null || depth > 20) return {};
    if (schema.containsKey(r'$ref')) {
      final refStr = schema[r'$ref'] as String;
      final target = resolveRef(contract, refStr);
      return schemaFor(contract, target, depth + 1);
    }

    final result = Map<String, dynamic>.from(schema);

    // Variants for oneOf
    if (schema['oneOf'] is List) {
      final oneOfList = schema['oneOf'] as List;
      result['variants'] = oneOfList
          .whereType<Map<String, dynamic>>()
          .map((part) => schemaFor(contract, part, depth + 1))
          .toList();
    }

    // Merge composite schemas (allOf, oneOf, anyOf)
    final composites = <Map<String, dynamic>>[];
    for (final key in ['allOf', 'oneOf', 'anyOf']) {
      if (schema[key] is List) {
        for (final item in schema[key] as List) {
          if (item is Map<String, dynamic>) {
            composites.add(schemaFor(contract, item, depth + 1));
          }
        }
      }
    }

    final existingProps = (result['properties'] as Map<String, dynamic>?) != null
        ? Map<String, dynamic>.from(result['properties'] as Map<String, dynamic>)
        : <String, dynamic>{};

    final requiredSet = Set<String>.from((result['required'] as List<dynamic>?)?.map((e) => e.toString()) ?? []);

    for (final composite in composites) {
      if (composite['properties'] is Map<String, dynamic>) {
        final compProps = composite['properties'] as Map<String, dynamic>;
        for (final entry in compProps.entries) {
          existingProps[entry.key] = entry.value;
        }
      }
      if (composite['required'] is List) {
        for (final req in composite['required'] as List) {
          requiredSet.add(req.toString());
        }
      }
      if (result['type'] == null && composite['type'] != null) {
        result['type'] = composite['type'];
      }
    }

    if (existingProps.isNotEmpty) {
      final normalizedProps = <String, dynamic>{};
      for (final entry in existingProps.entries) {
        if (entry.value is Map<String, dynamic>) {
          normalizedProps[entry.key] = schemaFor(contract, entry.value as Map<String, dynamic>, depth + 1);
        } else {
          normalizedProps[entry.key] = entry.value;
        }
      }
      result['properties'] = normalizedProps;
    }

    if (requiredSet.isNotEmpty) {
      result['required'] = requiredSet.toList();
    }

    if (result['items'] is Map<String, dynamic>) {
      result['items'] = schemaFor(contract, result['items'] as Map<String, dynamic>, depth + 1);
    }

    // Discriminator constants in variants
    if (result['variants'] is List) {
      final variants = result['variants'] as List;
      for (final variantRaw in variants) {
        if (variantRaw is! Map<String, dynamic>) continue;
        final vProps = variantRaw['properties'] as Map<String, dynamic>?;
        if (vProps != null) {
          for (final entry in vProps.entries) {
            final prop = entry.value as Map<String, dynamic>?;
            if (prop != null && prop.containsKey('const')) {
              final constValues = variants
                  .whereType<Map<String, dynamic>>()
                  .map((v) => (v['properties'] as Map<String, dynamic>?)?[entry.key]?['const'])
                  .where((val) => val != null)
                  .toSet()
                  .toList();

              result['properties'] ??= <String, dynamic>{};
              (result['properties'] as Map<String, dynamic>)[entry.key] = {
                'type': 'string',
                'enum': constValues,
              };
            }
          }
        }
      }
    }

    return result;
  }

  /// Determines runtime type category of a schema
  static String typeOf(Map<String, dynamic> schema, [dynamic value]) {
    final rawType = schema['type'];
    if (rawType is List) {
      if (rawType.contains('string')) return 'string';
      final nonNull = rawType.firstWhere((t) => t != 'null', orElse: () => 'string');
      return nonNull.toString();
    }
    if (rawType != null) return rawType.toString();
    if (schema['properties'] != null) return 'object';
    if (value is List) return 'array';
    if (value is Map) return 'object';
    if (value is bool) return 'boolean';
    if (value is num) return 'number';
    return 'string';
  }

  /// Returns typed default initial value for a given schema
  static dynamic initialValue(Map<String, dynamic> schema) {
    if (schema.containsKey('default')) return schema['default'];
    if (schema.containsKey('const')) return schema['const'];
    if (schema['enum'] is List && (schema['enum'] as List).isNotEmpty) {
      return (schema['enum'] as List).first;
    }
    final type = typeOf(schema);
    switch (type) {
      case 'object':
        final props = schema['properties'] as Map<String, dynamic>? ?? {};
        final requiredList = (schema['required'] as List<dynamic>?)?.map((e) => e.toString()).toSet() ?? {};
        final initialObj = <String, dynamic>{};
        for (final reqKey in requiredList) {
          if (props.containsKey(reqKey) && props[reqKey] is Map<String, dynamic>) {
            initialObj[reqKey] = initialValue(props[reqKey] as Map<String, dynamic>);
          }
        }
        return initialObj;
      case 'array':
        return <dynamic>[];
      case 'boolean':
        return false;
      case 'number':
        return 0.0;
      case 'integer':
        return 0;
      case 'string':
      default:
        return '';
    }
  }

  /// Selects active variant schema based on discriminator values
  static Map<String, dynamic> fieldSchema(Map<String, dynamic> schema, dynamic value) {
    final variants = schema['variants'] as List<dynamic>?;
    if (variants == null || variants.isEmpty || value is! Map) return schema;

    Map<String, dynamic>? matched;
    for (final variantRaw in variants) {
      if (variantRaw is! Map<String, dynamic>) continue;
      final vProps = variantRaw['properties'] as Map<String, dynamic>? ?? {};
      final matches = vProps.entries.any(
        (entry) {
          final prop = entry.value as Map<String, dynamic>?;
          return prop != null && prop.containsKey('const') && value[entry.key] == prop['const'];
        },
      );
      if (matches) {
        matched = variantRaw;
        break;
      }
    }

    if (matched == null) return schema;

    final merged = Map<String, dynamic>.from(schema);
    final variantProps = matched['properties'] as Map<String, dynamic>? ?? {};
    final props = Map<String, dynamic>.from(schema['properties'] as Map<String, dynamic>? ?? {});

    for (final entry in variantProps.entries) {
      final prop = entry.value as Map<String, dynamic>?;
      if (prop != null && prop.containsKey('const')) {
        // preserve enum selector from parent schema
        props[entry.key] = schema['properties']?[entry.key] ?? prop;
      } else {
        props[entry.key] = prop ?? {};
      }
    }
    merged['properties'] = props;
    if (matched['required'] is List) {
      merged['required'] = matched['required'];
    }
    return merged;
  }
}
