# My Accounts

My Accounts هو تطبيق Flutter لإدارة الحسابات والديون الشخصية محليًا. يساعدك على إضافة الأشخاص، تسجيل الديون والمدفوعات، متابعة الرصيد لكل شخص، عرض سجل العمليات، وقراءة تقرير شهري واضح.

## التشغيل

```bash
flutter pub get
flutter run
```

ملاحظة: التطبيق يستخدم SQLite عبر `sqflite`، لذلك التشغيل الأنسب حاليًا هو Android/iOS. تشغيل Web يحتاج طبقة تخزين مختلفة أو إعداد SQLite خاص بالويب.

للتحقق:

```bash
flutter analyze
flutter test
```

## الخصائص

- Splash و Onboarding.
- تسجيل دخول، إنشاء حساب، واستعادة كلمة مرور Mock Auth.
- Dashboard للرصيد المفتوح وإجمالي الديون والمدفوعات.
- CRUD للأشخاص والعمليات.
- SQLite عبر `sqflite`.
- Repository layer لتسهيل الربط لاحقًا بـ Firebase أو API.
- بحث، فلترة، ترتيب، ومفضلة.
- سجل عمليات وتقارير شهرية.
- تنبيهات Mock للديون المستحقة.
- Profile و Settings.
- Light/Dark Mode محفوظ محليًا.
- Empty states و Loading states و Snackbars و Confirmation dialogs.

## الهيكلة

```text
lib/
  config/          Theme و GoRouter
  core/            ثوابت، أدوات، Widgets مشتركة
  data/            SQLite database و repositories
  domain/          Models و repository contracts
  presentation/    الشاشات و Riverpod providers
```

## المعمارية المعتمدة

المشروع يعتمد الآن نمط MVC بشكل تدريجي وواضح:

- `models` عبر `lib/mvc/models/models.dart`
- `views` عبر `lib/mvc/views/views.dart`
- `controllers` عبر `lib/mvc/controllers/controllers.dart`
- `services` عبر `lib/mvc/services/services.dart`

نقطة الدخول الموحدة:

- `lib/mvc/app_mvc.dart`

دليل التطبيق العملي:

- `lib/mvc/MVC_GUIDE.md`

## الحزم

- `flutter_riverpod`
- `go_router`
- `sqflite`
- `path`
- `shared_preferences`
- `intl`
- `flutter_animate`
- `lucide_icons`
- `uuid`

بيانات الدخول التجريبية:

```text
demo@myaccounts.local
12345678
```
