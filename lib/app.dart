import 'package:flutter/cupertino.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'ui/coop_home_page.dart';

class PqrCooperativeApp extends StatelessWidget {
  const PqrCooperativeApp({super.key});

  @override
  Widget build(BuildContext context) {
    return CupertinoApp(
      debugShowCheckedModeBanner: false,
      title: 'PQR Cooperative',
      theme: const CupertinoThemeData(
        primaryColor: Color(0xFF0A84FF),
        scaffoldBackgroundColor: Color(0xFFF7F8FA),
      ),
      localizationsDelegates: const <LocalizationsDelegate<dynamic>>[
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ],
      supportedLocales: const <Locale>[Locale('en', 'US')],
      home: const CoopHomePage(),
    );
  }
}
