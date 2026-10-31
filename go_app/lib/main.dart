import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:opengo/l10n/app_localizations.dart';

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
      SystemChrome.setPreferredOrientations([.portraitUp]);

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
  final _locale = ValueNotifier<Locale?>(null);
  final _fullscreenMode = ValueNotifier<bool>(false);

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

  Future<void> _setFullscreenMode(bool value) async {
    final previousValue = _fullscreenMode.value;
    _fullscreenMode.value = value;
    try {
      if (defaultTargetPlatform == TargetPlatform.windows) {
        await const MethodChannel('opengo/window')
            .invokeMethod<void>('setFullscreen', value);
      } else {
        await SystemChrome.setEnabledSystemUIMode(
          value ? SystemUiMode.immersiveSticky : SystemUiMode.edgeToEdge,
        );
      }
    } catch (error, stackTrace) {
      _fullscreenMode.value = previousValue;
      Error.throwWithStackTrace(error, stackTrace);
    }
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder(
      valueListenable: _themeMode,
      builder: (context, value, child) {
        return ValueListenableBuilder<Locale?>(
          valueListenable: _locale,
          builder: (context, locale, child) => MaterialApp.router(
            onGenerateTitle: (context) =>
                AppLocalizations.of(context)!.appTitle,
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            locale: locale,
            theme: _lightTheme,
            darkTheme: _darkTheme,
            themeMode: _themeMode.value,
            routerDelegate: _routerDelegate,
            routeInformationParser: _routeParser,
            builder: (context, child) => AppScope(
              appController: _appController,
              themeMode: _themeMode,
              locale: _locale,
              fullscreenMode: _fullscreenMode,
              onFullscreenModeChanged: _setFullscreenMode,
              child: child ?? const SplashScreen(),
            ),
          ),
        );
      },
    );
  }

  @override
  void dispose() {
    _appController.removeListener(_rebuild);
    _appController.dispose();
    _themeMode.dispose();
    _locale.dispose();
    _fullscreenMode.dispose();
    super.dispose();
  }
}
