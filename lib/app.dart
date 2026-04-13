import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'l10n/generated/app_localizations.dart';
import 'package:go_router/go_router.dart';
import 'core/theme.dart';
import 'providers/locale_provider.dart';
import 'screens/main_menu_screen.dart';
import 'screens/hero_select_screen.dart';
import 'screens/main_game_screen.dart';
import 'screens/settings_screen.dart';
import 'screens/battle_screen.dart';

final _router = GoRouter(
  initialLocation: '/',
  routes: [
    GoRoute(
      path: '/',
      builder: (context, state) => const MainMenuScreen(),
    ),
    GoRoute(
      path: '/select',
      builder: (context, state) => const HeroSelectScreen(),
    ),
    GoRoute(
      path: '/game',
      builder: (context, state) => const MainGameScreen(),
    ),
    GoRoute(
      path: '/settings',
      builder: (context, state) => const SettingsScreen(),
    ),
    GoRoute(
      path: '/battle',
      builder: (context, state) => const BattleScreen(),
    ),
  ],
);

class OnuncuDalApp extends ConsumerWidget {
  const OnuncuDalApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final locale = ref.watch(localeProvider);

    return MaterialApp.router(
      title: 'Onuncu Dal',
      debugShowCheckedModeBanner: false,
      theme: buildAppTheme(),
      routerConfig: _router,
      locale: locale,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('tr'),
        Locale('en'),
      ],
    );
  }
}
