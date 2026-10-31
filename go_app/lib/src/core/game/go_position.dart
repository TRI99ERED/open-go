import 'sgf.dart';

const goColumnLabels = 'ABCDEFGHJKLMNOPQRST';

class GoPosition {
  GoPosition._({
    required this.size,
    required this.stones,
    required this.toMove,
    required this.lastMove,
  });

  factory GoPosition.empty(int size) {
    if (size < 2 || size > 19) {
      throw RangeError.range(size, 2, 19, 'size');
    }
    return GoPosition._(
      size: size,
      stones: List<int>.filled(size * size, 0),
      toMove: 1,
      lastMove: null,
    );
  }

  final int size;
  final List<int> stones;
  final int toMove;
  final int? lastMove;

  GoPosition apply(SgfNode node) {
    final nextStones = List<int>.of(stones);
    for (final (property, color) in [('AB', 1), ('AW', 2), ('AE', 0)]) {
      for (final value in node.values(property)) {
        for (final point in _expandSetup(value)) {
          nextStones[point] = color;
        }
      }
    }

    final blackMove = node.firstValue('B');
    final whiteMove = node.firstValue('W');
    final moveColor = blackMove != null
        ? 1
        : whiteMove != null
        ? 2
        : null;
    final moveValue = blackMove ?? whiteMove;
    int? movePoint;
    var nextPlayer = toMove;
    if (moveColor != null && moveValue != null) {
      movePoint = pointFromSgf(moveValue);
      if (movePoint != null) {
        nextStones[movePoint] = moveColor;
        _removeCapturedGroups(nextStones, moveColor);
      }
      nextPlayer = 3 - moveColor;
    }

    return GoPosition._(
      size: size,
      stones: nextStones,
      toMove: nextPlayer,
      lastMove: movePoint ?? (moveColor == null ? lastMove : null),
    );
  }

  GoPosition withToMove(int color) {
    if (color != 1 && color != 2) throw ArgumentError.value(color, 'color');
    return GoPosition._(
      size: size,
      stones: List<int>.of(stones),
      toMove: color,
      lastMove: lastMove,
    );
  }

  GoPosition play(int point, int color) {
    if (point < 0 || point >= stones.length || stones[point] != 0) {
      throw StateError('That intersection is occupied or outside the board.');
    }
    if (color != 1 && color != 2) throw ArgumentError.value(color, 'color');

    final nextStones = List<int>.of(stones)..[point] = color;
    _removeCapturedGroups(nextStones, color);
    final ownGroup = _groupAt(nextStones, point);
    if (ownGroup.liberties.isEmpty) {
      throw StateError('A move cannot leave its own stones without liberties.');
    }

    return GoPosition._(
      size: size,
      stones: nextStones,
      toMove: 3 - color,
      lastMove: point,
    );
  }

  int? pointFromSgf(String coordinate) {
    if (coordinate.isEmpty || (coordinate == 'tt' && size <= 19)) return null;
    if (coordinate.length != 2) {
      throw FormatException('Invalid SGF board coordinate: $coordinate');
    }
    final column = coordinate.codeUnitAt(0) - 97;
    final row = coordinate.codeUnitAt(1) - 97;
    if (column < 0 || column >= size || row < 0 || row >= size) {
      throw FormatException('SGF coordinate is outside the $size×$size board.');
    }
    return row * size + column;
  }

  String sgfCoordinate(int point) {
    if (point < 0 || point >= stones.length) {
      throw RangeError.index(point, stones);
    }
    final row = point ~/ size;
    final column = point % size;
    return '${String.fromCharCode(column + 97)}${String.fromCharCode(row + 97)}';
  }

  Iterable<int> _expandSetup(String value) sync* {
    final parts = value.split(':');
    if (parts.length == 1) {
      final point = pointFromSgf(value);
      if (point != null) yield point;
      return;
    }
    if (parts.length != 2) {
      throw FormatException('Invalid SGF setup range: $value');
    }
    final first = pointFromSgf(parts[0]);
    final last = pointFromSgf(parts[1]);
    if (first == null || last == null) {
      throw FormatException('Invalid SGF setup range: $value');
    }
    final top = first ~/ size;
    final left = first % size;
    final bottom = last ~/ size;
    final right = last % size;
    if (top > bottom || left > right) {
      throw FormatException('Invalid SGF setup range: $value');
    }
    for (var row = top; row <= bottom; row++) {
      for (var column = left; column <= right; column++) {
        yield row * size + column;
      }
    }
  }

  void _removeCapturedGroups(List<int> board, int playedColor) {
    final opponent = 3 - playedColor;
    final visited = <int>{};
    for (var point = 0; point < board.length; point++) {
      if (board[point] != opponent || visited.contains(point)) continue;
      final group = _groupAt(board, point);
      visited.addAll(group.stones);
      if (group.liberties.isEmpty) {
        for (final stone in group.stones) {
          board[stone] = 0;
        }
      }
    }
  }

  _StoneGroup _groupAt(List<int> board, int start) {
    final color = board[start];
    final stones = <int>{start};
    final liberties = <int>{};
    final pending = <int>[start];
    while (pending.isNotEmpty) {
      final point = pending.removeLast();
      for (final neighbor in _neighbors(point)) {
        if (board[neighbor] == 0) {
          liberties.add(neighbor);
        } else if (board[neighbor] == color && stones.add(neighbor)) {
          pending.add(neighbor);
        }
      }
    }
    return _StoneGroup(stones, liberties);
  }

  Iterable<int> _neighbors(int point) sync* {
    final row = point ~/ size;
    final column = point % size;
    if (row > 0) yield point - size;
    if (row < size - 1) yield point + size;
    if (column > 0) yield point - 1;
    if (column < size - 1) yield point + 1;
  }
}

class _StoneGroup {
  const _StoneGroup(this.stones, this.liberties);

  final Set<int> stones;
  final Set<int> liberties;
}

GoPosition positionAtPath(SgfNode root, List<int> path) {
  final sizeText = root.firstValue('SZ') ?? '19';
  final size = int.tryParse(sizeText);
  if (size == null || size < 2 || size > 19) {
    throw FormatException('Unsupported SGF board size: $sizeText');
  }

  final playerToMove = root.firstValue('PL') == 'W' ? 2 : 1;
  var position = GoPosition.empty(size).apply(root).withToMove(playerToMove);
  var node = root;
  for (final branch in path) {
    if (branch < 0 || branch >= node.children.length) {
      throw RangeError.index(branch, node.children, 'branch');
    }
    node = node.children[branch];
    position = position.apply(node);
  }
  return position;
}
