import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:opengo/src/features/screens/game_screen.dart';
import 'package:opengo/src/features/themes/app_theme.dart';
import 'package:opengo/src/widgets/common/app_dropdown.dart';

void main() {
  testWidgets('sends the selected integer board size to GNU Go', (
    tester,
  ) async {
    final commands = <String>[];

    await tester.pumpWidget(
      MaterialApp(
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

  testWidgets('changing player color starts with the opponent', (tester) async {
    final commands = <String>[];

    await tester.pumpWidget(
      MaterialApp(
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
  await tester.tap(
    find.descendant(of: control, matching: find.byType(TextFormField)),
  );
  await tester.pumpAndSettle();
  await tester.tap(find.text(option).last);
  await tester.pumpAndSettle();
}
