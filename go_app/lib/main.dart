import 'dart:async';

import 'package:flutter/material.dart';

import 'src/features/app/app_controller/app_controller.dart';
import 'src/features/app/app_scope.dart';
import 'src/features/screens/splash_screen.dart';
import 'src/features/themes/app_theme.dart';
import 'src/features/themes/styles.dart';
import 'src/router/app_page.dart';
import 'src/router/app_router.dart';
import 'src/core/utils/logger.dart';

void main() {
  runZonedGuarded(
    () async {
      WidgetsFlutterBinding.ensureInitialized();

      runApp(const App());
    },
    (error, stackTrace) {
      Logger.e('Uncaught error', 'Main', error, stackTrace);
    },
  );
}

class App extends StatefulWidget {
  const App({super.key});

  @override
  State<App> createState() => _AppState();
}

class _AppState extends State<App> {
  static const _routeParser = AppRouteInformationParser();

  final ThemeData _lightTheme = ThemeData(
    brightness: Brightness.light,
    extensions: [appThemeLight],
    scaffoldBackgroundColor: appThemeLight.backgroundStrongestColor,
    visualDensity: VisualDensity.adaptivePlatformDensity,
    snackBarTheme: SnackBarThemeData(
      backgroundColor: appThemeLight.backgroundStrongColor,
      contentTextStyle: TextStyle(
        color: appThemeLight.foregroundStrongestColor,
        fontSize: cMSize,
        fontWeight: cMWeight,
      ),
    ),
  );
  final ThemeData _darkTheme = ThemeData(
    brightness: Brightness.dark,
    extensions: [appThemeDark],
    scaffoldBackgroundColor: appThemeDark.backgroundStrongestColor,
    visualDensity: VisualDensity.adaptivePlatformDensity,
    snackBarTheme: SnackBarThemeData(
      backgroundColor: appThemeDark.backgroundStrongColor,
      contentTextStyle: TextStyle(
        color: appThemeDark.foregroundStrongestColor,
        fontSize: cMSize,
        fontWeight: cMWeight,
      ),
    ),
  );
  final _themeMode = ValueNotifier<ThemeMode>(ThemeMode.system);

  late final AppController _appController;
  late final AppRouterDelegate _routerDelegate;

  @override
  void initState() {
    super.initState();
    _appController = AppController();
    _appController.addListener(_rebuild);
    _routerDelegate = AppRouterDelegate(
      initialPages: const [HomePage()],
      guards: [],
    );
  }

  void _rebuild() {
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder(
      valueListenable: _themeMode,
      builder: (context, value, child) {
        return MaterialApp.router(
          title: 'Open Go',
          theme: _lightTheme,
          darkTheme: _darkTheme,
          themeMode: _themeMode.value,
          routerDelegate: _routerDelegate,
          routeInformationParser: _routeParser,
          builder: (context, child) => AppScope(
            appController: _appController,
            themeMode: _themeMode,
            child: child ?? const SplashScreen(),
          ),
        );
      },
    );
  }

  @override
  void dispose() {
    _appController.removeListener(_rebuild);
    _appController.dispose();
    super.dispose();
  }
}
