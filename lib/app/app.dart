import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'router.dart';
import 'theme.dart';

class DarBelAmriApp extends ConsumerWidget {
  const DarBelAmriApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(goRouterProvider);

    return MaterialApp.router(
      title: 'دار بلعمري',
      debugShowCheckedModeBanner: false,

      // Arabic RTL locale
      locale: const Locale('ar'),
      supportedLocales: const [
        Locale('ar'), // Arabic (RTL) — main UI language
        Locale('fr'), // French — used internally for PDF generation
        Locale('en'), // English — fallback
      ],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],

      // Force RTL globally
      builder: (context, child) {
        return Directionality(
          textDirection: TextDirection.rtl,
          child: child!,
        );
      },

      theme: AppTheme.darkTheme,
      routerConfig: router,
    );
  }
}
