import 'package:flutter/material.dart';
import 'package:cabros_bot_flutter/data/services/api_client.dart';
import 'package:cabros_bot_flutter/ui/core/widgets/structured_response_viewer.dart';

class ResponseBlock extends StatelessWidget {
  final ApiResponse? response;
  final String? customText;
  final bool isLoading;

  const ResponseBlock({
    super.key,
    this.response,
    this.customText,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    return StructuredResponseViewer(
      response: response,
      customText: customText,
      isLoading: isLoading,
    );
  }
}
