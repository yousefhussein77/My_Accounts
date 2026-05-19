class AppValidators {
  const AppValidators._();

  static final RegExp _emailRegex = RegExp(
    r"^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$",
  );
  static final RegExp _hasUppercase = RegExp(r'[A-Z]');
  static final RegExp _hasLowercase = RegExp(r'[a-z]');
  static final RegExp _hasDigit = RegExp(r'\d');
  static final RegExp _hasSpecial = RegExp(r'[!@#$%^&*(),.?":{}|<>_\-+=\[\]\\\/`~;]');
  static final RegExp _digitsOnly = RegExp(r'^\d+$');

  static String? name(String? value) {
    final v = value?.trim() ?? '';
    if (v.length < 3) return 'الاسم يجب أن يكون 3 أحرف على الأقل';
    return null;
  }

  static String? email(String? value) {
    final v = value?.trim() ?? '';
    if (!_emailRegex.hasMatch(v)) return 'أدخل بريدًا إلكترونيًا صحيحًا';
    return null;
  }

  static String? passwordStrong(String? value) {
    final v = value ?? '';
    if (v.length < 8) return 'كلمة المرور 8 أحرف على الأقل';
    if (!_hasUppercase.hasMatch(v)) return 'أضف حرفًا كبيرًا واحدًا على الأقل';
    if (!_hasLowercase.hasMatch(v)) return 'أضف حرفًا صغيرًا واحدًا على الأقل';
    if (!_hasDigit.hasMatch(v)) return 'أضف رقمًا واحدًا على الأقل';
    if (!_hasSpecial.hasMatch(v)) return 'أضف رمزًا خاصًا واحدًا على الأقل';
    return null;
  }

  static String? passwordLogin(String? value) {
    final v = value ?? '';
    if (v.length < 8) return 'أدخل كلمة المرور بشكل صحيح';
    return null;
  }

  static String? amount(String? value) {
    final raw = value?.trim() ?? '';
    if (raw.isEmpty) return 'أدخل المبلغ';
    final parsed = double.tryParse(raw);
    if (parsed == null || parsed <= 0) return 'أدخل مبلغًا صحيحًا';
    if (parsed > 1000000000) return 'المبلغ كبير جدًا';
    return null;
  }

  static String? pin(String? value) {
    final v = value?.trim() ?? '';
    if (!_digitsOnly.hasMatch(v)) return 'PIN يجب أن يكون أرقام فقط';
    if (v.length < 4 || v.length > 6) return 'PIN يجب أن يكون بين 4 و6 أرقام';
    return null;
  }
}
