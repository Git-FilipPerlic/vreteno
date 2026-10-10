/// "pre 5 min", "pre 3 h", "pre 2 d" (srpski, latinica).
String timeAgo(DateTime? t, {DateTime? now}) {
  if (t == null) return '';
  final d = (now ?? DateTime.now().toUtc()).difference(t.toUtc());
  if (d.inMinutes < 1) return 'upravo sada';
  if (d.inMinutes < 60) return 'pre ${d.inMinutes} min';
  if (d.inHours < 24) return 'pre ${d.inHours} h';
  return 'pre ${d.inDays} d';
}
