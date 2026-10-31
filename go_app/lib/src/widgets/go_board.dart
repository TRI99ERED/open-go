import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../core/game/go_position.dart';

class GoBoard extends StatelessWidget {
  final int boardSize;
  final List<int> stones;
  final int? lastMove;
  final ValueChanged<int>? onPlay;

  const GoBoard({
    required this.boardSize,
    required this.stones,
    this.lastMove,
    this.onPlay,
    super.key,
  });

  String get _semanticsLabel {
    String describe(int color) {
      final vertices = <String>[];
      for (var point = 0; point < stones.length; point++) {
        if (stones[point] != color) continue;
        final row = point ~/ boardSize;
        final column = point % boardSize;
        vertices.add('${goColumnLabels[column]}${boardSize - row}');
      }
      return vertices.isEmpty ? 'none' : vertices.join(', ');
    }

    return 'Go board. Black stones: ${describe(1)}. White stones: ${describe(2)}.';
  }

  @override
  Widget build(BuildContext context) => Semantics(
    label: _semanticsLabel,
    child: LayoutBuilder(
      builder: (context, constraints) {
        final dimension = constraints.maxWidth.isFinite
            ? constraints.maxWidth
            : constraints.maxHeight.isFinite
            ? constraints.maxHeight
            : 320.0;
        final size = Size(dimension, dimension);
        return SizedBox.square(
          dimension: dimension,
          child: GestureDetector(
            key: const ValueKey('go-board'),
            behavior: HitTestBehavior.opaque,
            onTapDown: onPlay == null
                ? null
                : (details) {
                    final inset = size.width * 0.075;
                    final spacing = (size.width - inset * 2) / (boardSize - 1);
                    final column = ((details.localPosition.dx - inset) / spacing)
                        .round();
                    final row = ((details.localPosition.dy - inset) / spacing)
                        .round();
                    if (row >= 0 &&
                        row < boardSize &&
                        column >= 0 &&
                        column < boardSize) {
                      onPlay!(row * boardSize + column);
                    }
                  },
            child: CustomPaint(
              painter: _GoBoardPainter(
                boardSize: boardSize,
                stones: stones,
                lastMove: lastMove,
              ),
            ),
          ),
        );
      },
    ),
  );
}

class _GoBoardPainter extends CustomPainter {
  final int boardSize;
  final List<int> stones;
  final int? lastMove;

  const _GoBoardPainter({
    required this.boardSize,
    required this.stones,
    required this.lastMove,
  });

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(
      Offset.zero & size,
      Paint()..color = const Color(0xFFE7BD78),
    );
    final inset = size.width * 0.075;
    final spacing = (size.width - inset * 2) / (boardSize - 1);
    final grid = Paint()
      ..color = const Color(0xFF49351F)
      ..strokeWidth = math.max(1, size.width / 550);

    for (var index = 0; index < boardSize; index++) {
      final coordinate = inset + spacing * index;
      canvas
        ..drawLine(
          Offset(inset, coordinate),
          Offset(size.width - inset, coordinate),
          grid,
        )
        ..drawLine(
          Offset(coordinate, inset),
          Offset(coordinate, size.height - inset),
          grid,
        );
    }

    final starCoordinates = switch (boardSize) {
      9 => const [2, 4, 6],
      13 => const [3, 6, 9],
      _ => const [3, 9, 15],
    };
    final starPaint = Paint()..color = const Color(0xFF49351F);
    for (final row in starCoordinates) {
      for (final column in starCoordinates) {
        canvas.drawCircle(
          Offset(inset + spacing * column, inset + spacing * row),
          size.width / 110,
          starPaint,
        );
      }
    }

    final radius = spacing * 0.46;
    for (var point = 0; point < stones.length; point++) {
      final color = stones[point];
      if (color == 0) continue;
      final row = point ~/ boardSize;
      final column = point % boardSize;
      final center = Offset(inset + spacing * column, inset + spacing * row);
      canvas.drawCircle(
        center,
        radius,
        Paint()..color = color == 1 ? Colors.black : Colors.white,
      );
      if (color == 2) {
        canvas.drawCircle(
          center,
          radius,
          Paint()
            ..color = Colors.black.withValues(alpha: 0.65)
            ..style = PaintingStyle.stroke
            ..strokeWidth = 1,
        );
      }
      if (point == lastMove) {
        canvas.drawCircle(
          center,
          radius * 0.25,
          Paint()..color = color == 1 ? Colors.white : Colors.black,
        );
      }
    }
  }

  @override
  bool shouldRepaint(_GoBoardPainter oldDelegate) =>
      oldDelegate.boardSize != boardSize ||
      oldDelegate.stones != stones ||
      oldDelegate.lastMove != lastMove;
}
