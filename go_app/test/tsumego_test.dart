import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:opengo/src/core/game/go_position.dart';
import 'package:opengo/src/core/game/sgf.dart';
import 'package:opengo/src/features/app/app_controller/app_controller.dart';
import 'package:opengo/src/features/app/app_scope.dart';
import 'package:opengo/src/features/screens/tsumego_screen.dart';
import 'package:opengo/src/widgets/common/app_dropdown.dart';
import 'package:opengo/src/widgets/go_board.dart';

void main() {
  testWidgets('loads Go Game Guru problems and follows their solution trees', (
    tester,
  ) async {
    final source = await rootBundle.loadString(
      'assets/problems/gogameguru-weekly.sgf',
    );
    final collection = SgfCollection.parse(source);
    expect(collection.games, hasLength(33));
    for (final problem in collection.games) {
      expect(positionAtPath(problem, []).stones, isNotEmpty);
    }
    expect(collection.games.first.firstValue('SO'), 'https://gogameguru.com/');

    final appController = AppController();
    final themeMode = ValueNotifier(ThemeMode.system);
    addTearDown(appController.dispose);
    addTearDown(themeMode.dispose);

    await tester.pumpWidget(
      MaterialApp(
        home: AppScope(
          appController: appController,
          themeMode: themeMode,
          child: const TsumegoScreen(index: 5),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final selector = tester.widget<AppDropdown>(find.byType(AppDropdown));
    expect(selector.items, hasLength(33));
    expect(selector.items[0].label, 'GoGameGuru Easy 01');
    expect(selector.items[32].label, 'GoGameGuru Hard 11');
    expect(selector.selectedIndex, 5);
    expect(selector.text, collection.games[5].firstValue('GN'));

    final selectedBoard = tester.widget<GoBoard>(find.byType(GoBoard));
    expect(
      selectedBoard.stones,
      orderedEquals(positionAtPath(collection.games[5], []).stones),
    );

    selector.onSelected!(('0', 0));
    await tester.pumpAndSettle();
    _playMove(tester, 'aa');
    await tester.pumpAndSettle();
    expect(
      find.text('That move is not in the solution. Try another move.'),
      findsOneWidget,
    );
    _playMove(tester, 'rs');
    await tester.pumpAndSettle();
    expect(find.text('Correct. Continue the sequence.'), findsOneWidget);
  });
}

void _playMove(WidgetTester tester, String coordinate) {
  final board = tester.widget<GoBoard>(find.byType(GoBoard));
  board.onPlay!(GoPosition.empty(board.boardSize).pointFromSgf(coordinate)!);
}
