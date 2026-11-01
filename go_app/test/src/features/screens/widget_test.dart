import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gnugo_ffi/gnugo_ffi.dart';
import 'package:opengo/l10n/app_localizations.dart';
import 'package:opengo/main.dart';
import 'package:opengo/src/features/screens/game_screen.dart';
import 'package:opengo/src/features/screens/sgf_review_screen.dart';
import 'package:opengo/src/features/themes/app_theme.dart';

void main() {
  testWidgets('home screen opens SGF review', (tester) async {
    await tester.pumpWidget(const App());

    expect(find.text('Play Go your way'), findsOneWidget);
    expect(find.text('Solve'), findsOneWidget);
    expect(find.text('Review'), findsOneWidget);

    await tester.tap(find.text('Review'));
    await tester.pumpAndSettle();
    expect(find.byType(SgfReviewScreen), findsOneWidget);
    expect(
      find.text(
        'Open an SGF file to review its game, comments, and variations.',
      ),
      findsOneWidget,
    );
  });

  testWidgets('starts an offline game and plays a move against GNU Go', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1000, 1000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final commands = <String>[];
    var boardSyncs = 0;

    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        theme: ThemeData(extensions: const [AppTheme()]),
        home: GameScreen(
          engineStart: (boardSize, seed) async {},
          sendCommand: (command) async {
            commands.add(command);
            if (command == 'genmove white') return 'pass';
            if (command == 'list_stones black') {
              boardSyncs++;
              return boardSyncs == 1 ? 'E5' : '';
            }
            if (command == 'list_stones white') {
              return boardSyncs == 2 ? 'E5' : '';
            }
            return '';
          },
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Black to play'), findsOneWidget);
    expect(commands, contains('boardsize 9'));
    expect(commands, contains('clear_board'));
    expect(commands, contains('komi 7.5'));

    final boardFinder = find.byKey(const ValueKey('go-board'));
    final boardRect = tester.getRect(boardFinder);
    await tester.tap(boardFinder);
    await tester.pumpAndSettle();

    expect(tester.getRect(boardFinder), boardRect);
    expect(commands, contains('play black E5'));
    expect(commands, contains('genmove white'));
    expect(
      find.bySemanticsLabel('Go board. Black stones: none. White stones: E5.'),
      findsOneWidget,
    );
    expect(find.text('Black to play'), findsOneWidget);
  });

  testWidgets('shows GNU Go errors instead of hiding them', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        theme: ThemeData(extensions: const [AppTheme()]),
        home: GameScreen(
          engineStart: (boardSize, seed) async {},
          sendCommand: (command) async =>
              throw const GnuGoException('illegal move'),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('illegal move'), findsOneWidget);
    expect(find.text('Engine error'), findsOneWidget);
  });
}
