import 'package:gnugo_ffi/gnugo_ffi.dart';
import 'package:test/test.dart';

void main() {
  test('reports native engine errors', () {
    expect(const GnuGoException('invalid move').toString(), 'invalid move');
  });

  test('returns successful GTP responses', () async {
    final engine = GnuGoEngine();
    await engine.start(9, seed: 1);

    expect(await engine.command('protocol_version'), '2');
  });

  test(
    'estimates the score after both players pass on an empty board',
    () async {
      final engine = GnuGoEngine();
      await engine.start(9, seed: 1);
      await engine.command('play black pass');
      await engine.command('play white pass');

      final result = await engine.command('estimate_score');

      expect(result, matches(RegExp(r'^[BW]\+\d+\.\d+ \(upper bound:')));
    },
  );
}
