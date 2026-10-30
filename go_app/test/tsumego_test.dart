import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:opengo/src/game/go_position.dart';
import 'package:opengo/src/game/sgf.dart';
import 'package:opengo/src/screens/tsumego_screen.dart';
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

    await tester.pumpWidget(const MaterialApp(home: TsumegoScreen()));
    await tester.pumpAndSettle();

    final selector = tester.widget<DropdownButton<int>>(
      find.byType(DropdownButton<int>),
    );
    expect(selector.items, hasLength(33));
    expect((selector.items![0].child as Text).data, 'GoGameGuru Easy 01');
    expect((selector.items![32].child as Text).data, 'GoGameGuru Hard 11');

    selector.onChanged!(0);
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
