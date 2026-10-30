import 'package:gnugo_ffi/gnugo_ffi.dart';
import 'package:test/test.dart';

void main() {
  test('reports native engine errors', () {
    expect(const GnuGoException('invalid move').toString(), 'invalid move');
  });
}
