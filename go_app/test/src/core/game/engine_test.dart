import 'package:flutter_test/flutter_test.dart';
import 'package:gnugo_ffi/gnugo_ffi.dart';

void main() {
  test('plays a move and generates a legal reply through GNU Go', () async {
    final engine = GnuGoEngine();
    await engine.start(9, seed: 1);
    await engine.command('boardsize 9');
    await engine.command('clear_board');
    await engine.command('komi 7.5');
    await engine.command('play black E5');

    final response = await engine.command('genmove white');
    expect(response, isNotEmpty);
    expect(response.toLowerCase(), isNot('resign'));
  });

  test('removes a captured stone from GNU Go board state', () async {
    final engine = GnuGoEngine();
    await engine.start(9, seed: 1);
    await engine.command('boardsize 9');
    await engine.command('clear_board');

    for (final move in [
      'black E5',
      'white D5',
      'black A1',
      'white F5',
      'black A2',
      'white E4',
      'black B1',
      'white E6',
    ]) {
      await engine.command('play $move');
    }

    final blackStones = await engine.command('list_stones black');
    final whiteStones = await engine.command('list_stones white');
    expect(blackStones.split(RegExp(r'\s+')), isNot(contains('E5')));
    expect(
      whiteStones.split(RegExp(r'\s+')),
      containsAll(['D5', 'F5', 'E4', 'E6']),
    );
  });
}
