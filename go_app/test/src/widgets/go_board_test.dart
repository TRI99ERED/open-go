import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:opengo/l10n/app_localizations.dart';
import 'package:opengo/src/features/themes/app_theme.dart';
import 'package:opengo/src/widgets/go_board.dart';

void main() {
  testWidgets('accepts labels for stones and empty intersections', (
    tester,
  ) async {
    const labels = {0: 'A', 1: 'B'};
    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData(extensions: const [AppTheme()]),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: SizedBox(
          width: 320,
          height: 320,
          child: GoBoard(
            boardSize: 9,
            stones: List<int>.generate(81, (point) => point == 0 ? 1 : 0),
            labels: labels,
          ),
        ),
      ),
    );

    expect(tester.widget<GoBoard>(find.byType(GoBoard)).labels, labels);
    expect(tester.takeException(), isNull);
  });
}
