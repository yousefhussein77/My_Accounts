class AppError {
  const AppError._();

  static String message(Object error, {String fallback = 'حدث خطأ غير متوقع'}) {
    final text = error.toString().trim();
    if (text.isEmpty) return fallback;
    if (text.startsWith('Exception: ')) {
      return text.replaceFirst('Exception: ', '').trim();
    }
    return text;
  }
}
