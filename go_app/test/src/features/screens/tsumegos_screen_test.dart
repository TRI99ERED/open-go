import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:opengo/l10n/app_localizations.dart';
import 'package:opengo/src/features/app/app_controller/app_controller.dart';
import 'package:opengo/src/features/app/app_scope.dart';
import 'package:opengo/src/features/screens/tsumegos_screen.dart';
import 'package:opengo/src/features/themes/app_theme.dart';

void main() {
  testWidgets('renders the tsumego grid without overflow on a compact screen', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(620, 1300);
    tester.view.devicePixelRatio = 1.5;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final appController = AppController();
    final themeMode = ValueNotifier(ThemeMode.system);
    final locale = ValueNotifier<Locale?>(null);
    final fullscreenMode = ValueNotifier(false);
    addTearDown(appController.dispose);
    addTearDown(themeMode.dispose);
    addTearDown(locale.dispose);
    addTearDown(fullscreenMode.dispose);

    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData(extensions: const [appThemeLight]),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: AppScope(
          appController: appController,
          themeMode: themeMode,
          locale: locale,
          fullscreenMode: fullscreenMode,
          onFullscreenModeChanged: (value) async {
            fullscreenMode.value = value;
          },
          child: const TsumegosScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final grid = tester.widget<GridView>(find.byType(GridView));
    expect(
      (grid.gridDelegate as SliverGridDelegateWithFixedCrossAxisCount)
          .crossAxisCount,
      1,
    );
    expect(tester.takeException(), isNull);
  });
}
