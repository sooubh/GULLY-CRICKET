class ScoreUtils {
  const ScoreUtils._();

  static int runRate({required int runs, required int balls}) {
    if (balls == 0) {
      return 0;
    }
    return ((runs * 6) / balls).round();
  }
}
