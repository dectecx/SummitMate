/// "13.2 km"
String formatKm(double km) => '${km.toStringAsFixed(1)} km';

/// "2,860 m"
String formatMetres(double m) {
  final s = m.round().abs().toString();
  final grouped = s.replaceAllMapped(RegExp(r'(?<=\d)(?=(\d{3})+$)'), (_) => ',');
  return '${m.round() < 0 ? '-' : ''}$grouped m';
}

/// "312 KB", "3.1 MB"
String formatBytesShort(int bytes) => bytes < 1024 * 1024 ? '${(bytes / 1024).ceil()} KB' : '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';

/// "3 小時 20 分", "45 分"
String formatElapsed(Duration d) {
  final h = d.inHours, m = d.inMinutes % 60;
  return h > 0 ? '$h 小時 $m 分' : '$m 分';
}
