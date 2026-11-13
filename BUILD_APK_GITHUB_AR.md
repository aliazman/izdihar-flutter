# إنشاء APK لتطبيق ازدهار دون تثبيت Flutter

هذا المشروع يتضمن ملف `.github/workflows/build-apk.yml` للبناء الآلي في GitHub Actions. **هذا الملف لا يحتوي على APK جاهز**، بل يطلب من GitHub بناءه عند رفع المشروع إلى مستودع GitHub.

## الخطوات من الحاسوب

1. فك ضغط ملف `izdihar_flutter_build_ready.zip` إلى مجلد `izdihar_flutter`.
2. افتح [GitHub](https://github.com/new) وسجّل الدخول، ثم أنشئ مستودعًا (Repository) جديدًا، واختر اسمه `izdihar-flutter` واجعله خاصًّا (Private) إن أردت.
3. ارفع **محتويات المجلد المفكوك** إلى المستودع، لا ترفع ZIP نفسه. احرص على وجود ملف `.github/workflows/build-apk.yml` داخل المستودع. يمكنك استخدام GitHub Desktop أو Git، أو الرفع من واجهة الموقع (الملفات المخفية قد لا تظهر افتراضيًا في بعض مستعرضات الملفات).
4. افتح تبويب `Actions` في المستودع واختر `Build Izdihar Android APK` ثم `Run workflow`، إن لم يبدأ تلقائيًا بعد الرفع.
5. بعد نجاح البناء، افتح صفحة التشغيل، ثم ضمن `Artifacts` حمّل `Izdihar-Android-APK`.
6. فك ضغط ملف Artifact الناتج؛ ستجد `app-release.apk`، انقله إلى هاتف Android وثبّته بعد السماح بتثبيت تطبيقات من هذا المصدر عند الحاجة.

## طريقة بديلة للمطور عبر Git

```bash
git init
git add .
git commit -m "Izdihar Android app"
git branch -M main
git remote add origin https://github.com/USERNAME/izdihar-flutter.git
git push -u origin main
```

استبدل `USERNAME` باسم مستخدم GitHub الذي أنشأ المستودع. يجب أن يكون المستودع موجودًا مسبقًا ويستلزم الأمر مصادقة GitHub.

## ما يفعله البناء الآلي

- يثبّت Flutter وAndroid SDK وJava.
- ينشئ ملفات Android المطلوبة للمشروع ويضبط إذن الإشعارات.
- يشغّل اختبار المحتوى.
- ينفّذ `flutter build apk --release`.
- يرفع ملف APK من مخرجات البناء إلى Artifacts.

**ملاحظة:** هذا سير عمل أُعدَّ دون إمكانية إجراء بناء فعلي في هذه البيئة (Flutter SDK وAndroid SDK غير متاحين هنا). يُمكن أن تظهر أخطاء عند أول بناء؛ راجع سجل Actions لمعرفة السبب. ملف APK الناتج مناسب للاختبار والتثبيت الشخصي؛ يتطلب التوزيع الرسمي/النشر إعداد توقيع نشر خاص وآمن.
