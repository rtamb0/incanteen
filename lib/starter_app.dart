import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'routes/router.dart';
import 'routes/routes_constants.dart';
import 'themes/themes.dart';

class StarterApp extends StatelessWidget {
  const StarterApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'InCanteen',
      theme: lightTheme,
      initialRoute: RoutesConstants.splashScreenRoute,
      onGenerateRoute: generateRoute,

      // Indonesian only
      locale: const Locale('id'),
      supportedLocales: const [Locale('id')],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
    );
  }
}
