// lib/models/phone_demand.dart
class PhoneDemand {
  final String now;      // e.g. "High" | "Medium" | "Low"
  final String next2h;   // e.g. "High" | "Medium" | "Low"
  final String? message; // optional short text

  PhoneDemand({required this.now, required this.next2h, this.message});

  static String _norm(String s) {
    final t = s.trim().toLowerCase();
    if (t.startsWith('h')) return 'High';
    if (t.startsWith('m')) return 'Medium';
    if (t.startsWith('l')) return 'Low';
    return s.isEmpty ? 'Unknown' : s[0].toUpperCase() + s.substring(1);
  }

  static String _fromNum(num v) {
    if (v >= 0.66) return 'High';
    if (v >= 0.33) return 'Medium';
    return 'Low';
  }

  /// Tolerant decoder: accepts multiple possible key names.
  factory PhoneDemand.fromJson(Map<String, dynamic> json) {
    dynamic nowRaw = json['now'] ??
        json['current'] ??
        json['currentLevel'] ??
        json['demandNow'] ??
        json['level'];

    dynamic nextRaw = json['next2h'] ??
        json['nextTwoHours'] ??
        json['forecast'] ??
        json['demandNext2h'];

    final msg = (json['message'] ?? json['summary'] ?? json['note'])?.toString();

    String now;
    if (nowRaw is num) {
      now = _fromNum(nowRaw);
    } else if (nowRaw is String) {
      now = _norm(nowRaw);
    } else {
      now = 'Unknown';
    }

    String next2h;
    if (nextRaw is num) {
      next2h = _fromNum(nextRaw);
    } else if (nextRaw is String) {
      next2h = _norm(nextRaw);
    } else {
      next2h = 'Unknown';
    }

    return PhoneDemand(now: now, next2h: next2h, message: msg);
  }
}
