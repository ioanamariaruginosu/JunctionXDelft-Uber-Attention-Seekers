import '../models/trip_model.dart';
import '../services/maskot_ai_service.dart';
import 'package:flutter/material.dart';

import '../utils/theme.dart';

class MaskotAnalysis extends StatefulWidget {
  final TripModel trip;
  final MaskotAIService maskotService;

  const MaskotAnalysis({
    required this.trip,
    required this.maskotService,
  });

  @override
  State<MaskotAnalysis> createState() => _MaskotAnalysisState();
}

class _MaskotAnalysisState extends State<MaskotAnalysis> {
  late final Future<String> _analysisFuture;

  @override
  void initState() {
    super.initState();
    _analysisFuture = widget.maskotService.analyzeTripRequest(widget.trip);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return FutureBuilder<String>(
      future: _analysisFuture, 
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.maskotGlow.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppColors.maskotGlow),
            ),
            child: Row(
              children: [
                const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(AppColors.maskotGlow),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Ube analyzing...',
                    style: TextStyle(
                      color: theme.colorScheme.onSurface,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ),
              ],
            ),
          );
        }

        if (snapshot.hasError) {
          return Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.error.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppColors.error),
            ),
            child: Row(
              children: [
                const Icon(Icons.error_outline, color: AppColors.error),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Analysis failed. Using offline mode.',
                    style: TextStyle(color: theme.colorScheme.onSurface),
                  ),
                ),
              ],
            ),
          );
        }

        if (snapshot.hasData && snapshot.data != null) {
          return Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.maskotGlow.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppColors.maskotGlow),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.assistant, color: AppColors.maskotGlow),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Ube Recommendation',
                        style: TextStyle(
                          color: theme.colorScheme.onSurface,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  snapshot.data!,
                  style: TextStyle(
                    color: theme.colorScheme.onSurface,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          );
        }

        return const SizedBox.shrink();
      },
    );
  }
}
