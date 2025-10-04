import '../models/trip_model.dart';
import '../services/atlas_ai_service.dart';
import 'package:flutter/material.dart';

import '../utils/theme.dart';

class AtlasAnalysis extends StatefulWidget {
  final TripModel trip;
  final AtlasAIService atlasService;

  const AtlasAnalysis({
    required this.trip,
    required this.atlasService,
  });

  @override
  State<AtlasAnalysis> createState() => _AtlasAnalysisState();
}

class _AtlasAnalysisState extends State<AtlasAnalysis> {
  late final Future<String> _analysisFuture;

  @override
  void initState() {
    super.initState();
    // Call the API only ONCE when widget is created
    _analysisFuture = widget.atlasService.analyzeTripRequest(widget.trip);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return FutureBuilder<String>(
      future: _analysisFuture, // Reuse the same Future
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.atlasGlow.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppColors.atlasGlow),
            ),
            child: Row(
              children: [
                const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(AppColors.atlasGlow),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Atlas AI analyzing...',
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
              color: AppColors.atlasGlow.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppColors.atlasGlow),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.assistant, color: AppColors.atlasGlow),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Atlas AI Recommendation',
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