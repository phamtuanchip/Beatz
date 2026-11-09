class TimeUtil {
  /// Converts a duration in milliseconds to `HH:mm:ss` when it is at least
  /// an hour long, otherwise to `mm:ss`.
  static String convertTimeToString(int duration) {
    final d = Duration(milliseconds: duration < 0 ? 0 : duration);
    String two(int n) => n.toString().padLeft(2, '0');
    final minutes = two(d.inMinutes.remainder(60));
    final seconds = two(d.inSeconds.remainder(60));
    if (d.inHours > 0) return '${two(d.inHours)}:$minutes:$seconds';
    return '$minutes:$seconds';
  }
}
