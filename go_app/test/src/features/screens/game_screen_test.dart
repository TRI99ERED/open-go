import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gnugo_ffi/gnugo_ffi.dart';
import 'package:opengo/l10n/app_localizations.dart';
import 'package:opengo/src/features/screens/game_screen.dart';
import 'package:opengo/src/features/themes/app_theme.dart';
import 'package:opengo/src/widgets/common/app_button.dart';
import 'package:opengo/src/widgets/common/app_dropdown.dart';
import 'package:opengo/src/widgets/common/app_text_field.dart';
import 'package:opengo/src/widgets/go_board.dart';

void main() {
  testWidgets('sends the selected integer board size to GNU Go', (
    tester,
  ) async {
    final commands = <String>[];

    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        theme: ThemeData(extensions: const [AppTheme()]),
        home: GameScreen(
          engineStart: (boardSize, seed) async {},
          sendCommand: (command) async {
            commands.add(command);
            return '';
          },
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(commands, contains('boardsize 9'));
  });

  testWidgets('applies board size and game mode selections', (tester) async {
    final boardSizes = <int>[];
    final commands = <String>[];

    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        theme: ThemeData(extensions: const [AppTheme()]),
        home: GameScreen(
          engineStart: (boardSize, seed) async => boardSizes.add(boardSize),
          sendCommand: (command) async {
            commands.add(command);
            return '';
          },
        ),
      ),
    );
    await tester.pumpAndSettle();

    await _selectOption(tester, 'Board', '13×13');
    expect(boardSizes.last, 13);
    expect(commands, contains('boardsize 13'));

    await _selectOption(tester, 'Game', 'Pass-and-play');
    expect(find.text('You play'), findsNothing);
  });

  testWidgets('can open directly in pass-and-play recording mode', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        theme: ThemeData(extensions: const [AppTheme()]),
        home: const GameScreen(
          autoStart: false,
          initialMode: GameMode.passAndPlay,
        ),
      ),
    );

    expect(find.text('You play'), findsNothing);
    expect(find.text('Game record'), findsOneWidget);
    await tester.ensureVisible(find.text('Game record'));
    await tester.tap(find.text('Game record'));
    await tester.pumpAndSettle();
    expect(find.text('Black player'), findsOneWidget);
    expect(find.text('White player'), findsOneWidget);
    expect(find.text('Export SGF'), findsOneWidget);
  });

  testWidgets('applies, replaces, and removes entered board labels', (
    tester,
  ) async {
    final commands = <String>[];
    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        theme: ThemeData(extensions: const [AppTheme()]),
        home: GameScreen(
          autoStart: false,
          initialMode: GameMode.passAndPlay,
          sendCommand: (command) async {
            commands.add(command);
            return '';
          },
        ),
      ),
    );

    await tester.ensureVisible(find.text('Game annotations'));
    await tester.tap(find.text('Game annotations'));
    await tester.pumpAndSettle();
    final markerField = find.descendant(
      of: find.ancestor(
        of: find.text('Board label'),
        matching: find.byType(AppTextField),
      ),
      matching: find.byType(TextFormField),
    );
    await tester.ensureVisible(markerField);
    await tester.enterText(markerField, '1');
    await tester.pumpAndSettle();
    await tester.tap(find.text('Apply label'));
    await tester.pumpAndSettle();
    await _tapBoardPoint(tester, row: 4, column: 4);
    expect(tester.widget<GoBoard>(find.byType(GoBoard)).labels.values, ['1']);
    await _tapBoardPoint(tester, row: 4, column: 4);
    expect(tester.widget<GoBoard>(find.byType(GoBoard)).labels, isEmpty);
    await _tapBoardPoint(tester, row: 4, column: 4);
    expect(tester.widget<GoBoard>(find.byType(GoBoard)).labels[40], '1');

    await tester.enterText(markerField, 'A');
    await tester.pumpAndSettle();
    await _tapBoardPoint(tester, row: 4, column: 4);
    expect(tester.widget<GoBoard>(find.byType(GoBoard)).labels[40], 'A');
    await _tapBoardPoint(tester, row: 4, column: 4);
    expect(tester.widget<GoBoard>(find.byType(GoBoard)).labels, isEmpty);
    await _tapBoardPoint(tester, row: 4, column: 4);
    await _tapBoardPoint(tester, row: 4, column: 5);

    expect(tester.widget<GoBoard>(find.byType(GoBoard)).labels, {
      40: 'A',
      41: 'A',
    });
    expect(commands, isEmpty);

    await tester.ensureVisible(find.text('Stop marking'));
    await tester.tap(find.text('Stop marking'));
    await _tapBoardPoint(tester, row: 4, column: 6);
    expect(commands, contains('play black G5'));
  });

  testWidgets('validates board labels as uppercase letters or integers', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        theme: ThemeData(extensions: const [AppTheme()]),
        home: const GameScreen(
          autoStart: false,
          initialMode: GameMode.passAndPlay,
        ),
      ),
    );

    await tester.ensureVisible(find.text('Game annotations'));
    await tester.tap(find.text('Game annotations'));
    await tester.pumpAndSettle();
    final markerField = find.descendant(
      of: find.ancestor(
        of: find.text('Board label'),
        matching: find.byType(AppTextField),
      ),
      matching: find.byType(TextFormField),
    );
    final applyButton = find.widgetWithText(AppButtonSecondary, 'Apply label');
    await tester.ensureVisible(markerField);

    for (final invalidLabel in ['a', 'AB', '12.3', '']) {
      await tester.enterText(markerField, invalidLabel);
      await tester.pumpAndSettle();
      expect(
        find.text('Enter one uppercase letter or an integer.'),
        findsWidgets,
      );
      expect(tester.widget<AppButtonSecondary>(applyButton).onPressed, isNull);
    }

    for (final validLabel in ['Z', '123', '-7']) {
      await tester.enterText(markerField, validLabel);
      await tester.pumpAndSettle();
      expect(
        find.text('Enter one uppercase letter or an integer.'),
        findsNothing,
      );
      expect(
        tester.widget<AppButtonSecondary>(applyButton).onPressed,
        isNotNull,
      );
    }
  });

  testWidgets('localizes illegal engine move errors', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('uk'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        theme: ThemeData(extensions: const [AppTheme()]),
        home: GameScreen(
          autoStart: false,
          initialMode: GameMode.passAndPlay,
          sendCommand: (command) async {
            throw const GnuGoException('illegal move');
          },
        ),
      ),
    );

    await tester.tap(find.byKey(const ValueKey('go-board')));
    await tester.pumpAndSettle();

    expect(
      find.text(
        'Цей хід неможливий. Можливо, це самогубний хід або порушення правила ко.',
      ),
      findsOneWidget,
    );
  });

  testWidgets('changing player color starts with the opponent', (tester) async {
    final commands = <String>[];

    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        theme: ThemeData(extensions: const [AppTheme()]),
        home: GameScreen(
          engineStart: (boardSize, seed) async {},
          sendCommand: (command) async {
            commands.add(command);
            return command == 'genmove black' ? 'pass' : '';
          },
        ),
      ),
    );
    await tester.pumpAndSettle();

    await _selectOption(tester, 'You play', 'White');

    expect(commands, contains('genmove black'));
  });

  testWidgets('estimates the score after both players pass', (tester) async {
    final commands = <String>[];

    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        theme: ThemeData(extensions: const [AppTheme()]),
        home: GameScreen(
          initialMode: GameMode.passAndPlay,
          engineStart: (boardSize, seed) async {},
          sendCommand: (command) async {
            commands.add(command);
            return command == 'estimate_score'
                ? 'B+2.5 (upper bound: 3.5, lower: 1.5)'
                : '';
          },
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.ensureVisible(find.text('Pass'));
    await tester.tap(find.text('Pass'));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Pass'));
    await tester.tap(find.text('Pass'));
    await tester.pumpAndSettle();

    expect(commands, contains('estimate_score'));
    expect(commands, isNot(contains('final_score')));
    expect(find.text('Black wins by 2.5 points'), findsOneWidget);
  });

  testWidgets('undo resumes AI when it restored the AI turn', (tester) async {
    final commands = <String>[];

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
            if (command == 'estimate_score') {
              return 'B+2.5 (upper bound: 3.5, lower: 1.5)';
            }
            return '';
          },
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.ensureVisible(find.byKey(const ValueKey('go-board')));
    await tester.tap(find.byKey(const ValueKey('go-board')));
    await tester.pumpAndSettle();
    expect(commands.where((command) => command == 'genmove white').length, 1);
    expect(find.text('Black to play'), findsOneWidget);

    await tester.ensureVisible(find.text('Pass'));
    await tester.tap(find.text('Pass'));
    await tester.pumpAndSettle();
    expect(find.text('Black wins by 2.5 points'), findsOneWidget);

    await tester.ensureVisible(find.text('Undo'));
    await tester.tap(find.text('Undo'));
    await tester.pumpAndSettle();
    expect(commands.where((command) => command == 'genmove white').length, 2);
    expect(find.text('Black to play'), findsOneWidget);

    await tester.ensureVisible(find.text('Pass'));
    await tester.tap(find.text('Pass'));
    await tester.pumpAndSettle();
    expect(commands.where((command) => command == 'estimate_score').length, 2);
  });
}

Future<void> _selectOption(
  WidgetTester tester,
  String controlLabel,
  String option,
) async {
  final control = find.ancestor(
    of: find.text(controlLabel),
    matching: find.byType(AppDropdown),
  );
  final field = find.descendant(
    of: control,
    matching: find.byType(TextFormField),
  );
  await tester.ensureVisible(field);
  await tester.tap(field);
  await tester.pumpAndSettle();
  await tester.tap(find.text(option).last);
  await tester.pumpAndSettle();
}

Future<void> _tapBoardPoint(
  WidgetTester tester, {
  required int row,
  required int column,
}) async {
  await tester.ensureVisible(find.byKey(const ValueKey('go-board')));
  await tester.pumpAndSettle();
  final rect = tester.getRect(find.byKey(const ValueKey('go-board')));
  const insetRatio = 0.075;
  final spacing = rect.width * (1 - 2 * insetRatio) / 8;
  await tester.tapAt(
    Offset(
      rect.left + rect.width * insetRatio + spacing * column,
      rect.top + rect.height * insetRatio + spacing * row,
    ),
  );
  await tester.pumpAndSettle();
}
