class FormatUtils {
  const FormatUtils._();

  static String oversFromBalls(int balls) {
    final int completedOvers = balls ~/ 6;
    final int remainingBalls = balls % 6;
    return '$completedOvers.$remainingBalls';
  }
}
