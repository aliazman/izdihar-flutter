import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'services/app_store.dart';
import 'ui/theme.dart';
import 'ui/screens.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final store = AppStore();
  runApp(IzdiharApp(store: store));
  await store.initialize();
}

class IzdiharApp extends StatelessWidget {
  const IzdiharApp({super.key, required this.store});
  final AppStore store;

  @override
  Widget build(BuildContext context) => MaterialApp(
    title: 'ازدهار | توكيدات يومية',
    debugShowCheckedModeBanner: false,
    theme: appTheme(),
    locale: const Locale('ar'),
    supportedLocales: const [Locale('ar')],
    localizationsDelegates: const [
      GlobalMaterialLocalizations.delegate,
      GlobalWidgetsLocalizations.delegate,
      GlobalCupertinoLocalizations.delegate,
    ],
    builder: (context, child) => Directionality(
      textDirection: TextDirection.rtl,
      child: child ?? const SizedBox.shrink(),
    ),
    home: AnimatedBuilder(
      animation: store,
      builder: (context, _) => store.ready
          ? AppShell(store: store)
          : const Scaffold(body: Center(child: CircularProgressIndicator())),
    ),
  );
}
