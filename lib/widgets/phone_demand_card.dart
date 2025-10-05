
import 'package:flutter/material.dart';
import '../utils/api_client.dart';

class PhoneDemandCard extends StatefulWidget {
  const PhoneDemandCard({
    super.key,
    required this.userType, 
    required this.cityId,   
    this.at,                
    this.zoneId,            
  });

  final String userType;
  final int cityId;
  final DateTime? at;
  final String? zoneId;

  @override
  State<PhoneDemandCard> createState() => _PhoneDemandCardState();
}

class _PhoneDemandCardState extends State<PhoneDemandCard> {
  late Future<_DemandPair> _future;

  @override
  void initState() {
    super.initState();
    _future = _fetch();
  }

  Future<_DemandPair> _fetch() async {
    final dtIso = (widget.at ?? DateTime.now().toUtc()).toIso8601String();
    final qp = {
      'userType': widget.userType,
      'cityId': widget.cityId.toString(),
      'datetime': dtIso,
    };

    // GET /demand/now
    final nowRes = await ApiClient.get('/demand/now', queryParams: qp);
    if (!nowRes.success || nowRes.dataAsMap == null) {
      throw Exception('Failed to load current demand: ${nowRes.message}');
    }
    final nowMap = nowRes.dataAsMap!;
    final nowZones = _asZones(nowMap['zones']);

    final chosenZoneKey = _chooseZoneKey(
      zones: nowZones,
      userType: widget.userType,
      preferZoneId: widget.zoneId,
    );

    final nowZone = nowZones[chosenZoneKey] ?? <String, dynamic>{};
    final nowLevel = _extractLevel(nowZone, widget.userType);

    // GET /demand/next2h
    final nextRes = await ApiClient.get('/demand/next2h', queryParams: qp);
    if (!nextRes.success || nextRes.dataAsMap == null) {
      throw Exception('Failed to load next2h demand: ${nextRes.message}');
    }
    final nextMap = nextRes.dataAsMap!;
    final nextZones = _asZones(nextMap['zones']);

    final nextZone = nextZones[chosenZoneKey] ?? <String, dynamic>{};
    final nextLevel = _extractLevel(nextZone, widget.userType);
    final message = _extractRecommendation(nextZone);

    return _DemandPair(
      zoneKey: chosenZoneKey,
      now: nowLevel,
      next2h: nextLevel,
      message: message,
    );
  }

  Map<String, Map<String, dynamic>> _asZones(dynamic raw) {
    final out = <String, Map<String, dynamic>>{};
    if (raw is Map) {
      raw.forEach((k, v) {
        if (k is String && v is Map) {
          out[k] = Map<String, dynamic>.from(v as Map);
        }
      });
    }
    return out;
  }

  String _chooseZoneKey({
    required Map<String, Map<String, dynamic>> zones,
    required String userType,
    String? preferZoneId,
  }) {
    if (preferZoneId != null && zones.containsKey(preferZoneId)) {
      return preferZoneId;
    }
    String bestKey = zones.keys.isNotEmpty ? zones.keys.first : 'Unknown';
    double bestScore = -1;

    for (final entry in zones.entries) {
      final score = _extractScore(entry.value, userType) ?? _levelToScore(_extractRawLevel(entry.value, userType));
      if (score > bestScore) {
        bestScore = score;
        bestKey = entry.key;
      }
    }
    return bestKey;
  }

  double? _extractScore(Map<String, dynamic> zone, String userType) {
    if (userType.toLowerCase().startsWith('food') || userType.toLowerCase() == 'eats') {
      final v = zone['eatsScore'];
      if (v is num) return v.toDouble();
    } else {
      final v = zone['ridesScore'];
      if (v is num) return v.toDouble();
    }
    return null;
  }

  String _extractRawLevel(Map<String, dynamic> zone, String userType) {
    final raw = (userType.toLowerCase().startsWith('food') || userType.toLowerCase() == 'eats')
        ? zone['eatsLevel']
        : zone['ridesLevel'];
    return (raw ?? '').toString();
  }

  String _extractLevel(Map<String, dynamic> zone, String userType) {
    final raw = _extractRawLevel(zone, userType).trim().toLowerCase();
    if (raw.startsWith('h')) return 'High';
    if (raw.startsWith('m')) return 'Medium'; 
    if (raw.startsWith('l')) return 'Low';
    return raw.isEmpty ? 'Unknown' : raw[0].toUpperCase() + raw.substring(1);
  }

  String? _extractRecommendation(Map<String, dynamic> zone) {
    final v = zone['recommendation'];
    return v == null ? null : v.toString();
  }

  double _levelToScore(String levelRaw) {
    switch (levelRaw.trim().toLowerCase()) {
      case 'high':
      case 'h':
        return 1.0;
      case 'medium':
      case 'med':
      case 'm':
        return 0.5;
      case 'low':
      case 'l':
        return 0.0;
      default:
        return 0.0;
    }
  }

  Color _levelColor(String level, ThemeData theme) {
    switch (level.toLowerCase()) {
      case 'high':
        return Colors.green;
      case 'medium':
        return Colors.amber;
      case 'low':
        return Colors.grey;
      default:
        return theme.colorScheme.primary;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      elevation: 6,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: FutureBuilder<_DemandPair>(
          future: _future,
          builder: (context, snap) {
            if (snap.connectionState == ConnectionState.waiting) {
              return Row(
                children: [
                  const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                  const SizedBox(width: 12),
                  Text('Loading demand…', style: theme.textTheme.bodyMedium),
                ],
              );
            }

            if (snap.hasError) {
              return Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      'Couldn’t load demand',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.error,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  IconButton(
                    tooltip: 'Retry',
                    icon: const Icon(Icons.refresh),
                    onPressed: () => setState(() => _future = _fetch()),
                  ),
                ],
              );
            }

            final d = snap.data!;
            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.insights, size: 28),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Zone ${d.zoneKey}', style: theme.textTheme.titleMedium),
                      const SizedBox(height: 6),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          _pill('Now: ${d.now}', _levelColor(d.now, theme)),
                          _pill('Next 2h: ${d.next2h}', _levelColor(d.next2h, theme)),
                        ],
                      ),
                      if ((d.message ?? '').isNotEmpty) ...[
                        const SizedBox(height: 8),
                        Text(d.message!, style: theme.textTheme.bodySmall),
                      ],
                    ],
                  ),
                ),
                IconButton(
                  tooltip: 'Refresh',
                  icon: const Icon(Icons.refresh),
                  onPressed: () => setState(() => _future = _fetch()),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _pill(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withOpacity(0.6)),
      ),
      child: Text(
        text,
        style: TextStyle(fontWeight: FontWeight.w600, color: color),
      ),
    );
  }
}

class _DemandPair {
  final String zoneKey; 
  final String now;     
  final String next2h;  
  final String? message;
  _DemandPair({
    required this.zoneKey,
    required this.now,
    required this.next2h,
    this.message,
  });
}
