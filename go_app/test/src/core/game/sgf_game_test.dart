import 'package:flutter_test/flutter_test.dart';
import 'package:opengo/src/core/game/go_position.dart';
import 'package:opengo/src/core/game/sgf.dart';

void main() {
  group('SGF collection', () {
    test('parses collections, escaped values, and variations', () {
      final collection = SgfCollection.parse(
        r'(;GM[1]C[Line \] and slash \\])(;SZ[9];B[aa](;W[bb])(;W[cc]))',
      );

      expect(collection.games, hasLength(2));
      expect(collection.games.first.firstValue('C'), 'Line ] and slash \\');
      final root = collection.games.last;
      expect(root.children.single.children, hasLength(2));

      final reparsed = SgfCollection.parse(collection.write());
      expect(reparsed.games, hasLength(2));
      expect(reparsed.games.last.children.single.children, hasLength(2));
      expect(reparsed.games.first.firstValue('C'), 'Line ] and slash \\');
    });

    test('rejects malformed SGF instead of silently ignoring it', () {
      expect(
        () => SgfCollection.parse('(;GM[1]'),
        throwsA(isA<FormatException>()),
      );
    });
  });

  group('GoPosition', () {
    test('expands setup ranges and recognizes legacy pass coordinates', () {
      final root = SgfCollection.parse('(;SZ[9]AB[aa:bb])').games.single;
      final position = positionAtPath(root, []);

      expect(position.stones[0], 1);
      expect(position.stones[1], 1);
      expect(position.stones[9], 1);
      expect(position.stones[10], 1);
      expect(position.pointFromSgf(''), isNull);
      expect(position.pointFromSgf('tt'), isNull);
    });

    test('replays a move that captures a surrounded stone', () {
      final root = SgfCollection.parse(
        '(;SZ[9]PL[B]AB[de][fe][ef]AW[ee];B[ed])',
      ).games.single;
      final position = positionAtPath(root, [0]);

      expect(position.stones[position.pointFromSgf('ee')!], 0);
      expect(position.stones[position.pointFromSgf('ed')!], 1);
      expect(position.toMove, 2);
    });
  });
}
