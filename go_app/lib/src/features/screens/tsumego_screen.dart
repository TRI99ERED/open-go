import 'package:flutter/material.dart';
import 'package:opengo/src/core/game/go_position.dart';
import 'package:opengo/src/core/game/sgf.dart';
import 'package:opengo/src/core/widgets/controller_consumer.dart';
import 'package:opengo/src/features/app/app_scope.dart';
import 'package:opengo/src/widgets/common/app_button.dart';
import 'package:opengo/src/widgets/common/app_dropdown.dart';
import 'package:opengo/src/widgets/common/app_nav_bar.dart';
import 'package:opengo/src/widgets/go_board.dart';

class TsumegoScreen extends StatefulWidget {
  final int index;

  const TsumegoScreen({super.key, required this.index});

  @override
  State<TsumegoScreen> createState() => _TsumegoScreenState();
}

class _TsumegoScreenState extends State<TsumegoScreen> {
  late final ValueNotifier<int> _problemIndex = ValueNotifier(widget.index);
  final _cursor = ValueNotifier<SgfNode?>(null);
  final _position = ValueNotifier<GoPosition?>(null);
  final _mistakes = ValueNotifier(0);
  final _status = ValueNotifier('Loading problems…');
  final _solved = ValueNotifier(false);
  bool _initialized = false;
  bool _requestedLoad = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final appState = context.appState;
    final problems = appState.tsumegos.games;

    if (problems.isNotEmpty && !_initialized) {
      _initialized = true;
      if (widget.index < 0 || widget.index >= problems.length) {
        _status.value = 'Problem ${widget.index + 1} is unavailable.';
      } else {
        _resetProblem(widget.index);
      }
    } else if (problems.isEmpty && appState.isFailed) {
      _status.value = 'Could not load problems: ${appState.error}';
    } else if (problems.isEmpty && !appState.isProcessing && !_requestedLoad) {
      _requestedLoad = true;
      context.appController.loadTsumegos();
    }
  }

  void _resetProblem([int? selectedIndex]) {
    final problems = context.appState.tsumegos.games;
    final index = selectedIndex ?? _problemIndex.value;
    if (index < 0 || index >= problems.length) {
      _position.value = null;
      _cursor.value = null;
      _status.value = 'Problem ${index + 1} is unavailable.';
      return;
    }

    final problem = problems[index];
    _problemIndex.value = index;
    try {
      _cursor.value = problem;
      _position.value = positionAtPath(
        problem,
        [],
      ).withToMove(_initialPlayer(problem));
      _mistakes.value = 0;
      _solved.value = false;
      _status.value = 'Find the solution.';
    } catch (error) {
      _status.value = 'Invalid problem SGF: $error';
    }
  }

  void _selectProblem(int? index) {
    if (index == null) return;
    _resetProblem(index);
  }

  void _tryMove(int point) {
    final position = _position.value;
    final cursor = _cursor.value;
    if (position == null || cursor == null || _solved.value) return;

    SgfNode? matchingMove;
    for (final continuation in cursor.children) {
      if (!_containsAcceptedSolution(continuation)) continue;
      final moveColor = continuation.firstValue('B') != null
          ? 1
          : continuation.firstValue('W') != null
          ? 2
          : 0;
      if (moveColor != position.toMove) continue;
      final value = continuation.firstValue(moveColor == 1 ? 'B' : 'W');
      if (value == null || value.isEmpty) continue;
      try {
        if (position.pointFromSgf(value) == point) {
          matchingMove = continuation;
          break;
        }
      } on FormatException {
        continue;
      }
    }

    if (matchingMove == null) {
      _mistakes.value++;
      _status.value = 'That move is not in the solution. Try another move.';
      return;
    }

    var nextCursor = matchingMove;
    var nextPosition = position.apply(matchingMove);
    final userColor = position.toMove;
    var guard = 0;
    while (!_isAcceptedSolution(nextCursor) &&
        nextCursor.children.isNotEmpty &&
        guard++ < 100) {
      final viableReplies = nextCursor.children
          .where(_containsAcceptedSolution)
          .toList();
      if (viableReplies.isEmpty) break;
      final reply = viableReplies.first;
      final replyColor = reply.firstValue('B') != null
          ? 1
          : reply.firstValue('W') != null
          ? 2
          : 0;
      if (replyColor == userColor) break;
      nextPosition = nextPosition.apply(reply);
      nextCursor = reply;
    }

    final canContinue = nextCursor.children.any(
      (child) =>
          child.firstValue(userColor == 1 ? 'B' : 'W') != null &&
          _containsAcceptedSolution(child),
    );
    final solved = _isAcceptedSolution(nextCursor) || !canContinue;
    _cursor.value = nextCursor;
    _position.value = nextPosition;
    _solved.value = solved;
    _status.value = solved
        ? 'Solved! You found the solution.'
        : 'Correct. Continue the sequence.';
  }

  bool _containsAcceptedSolution(SgfNode node) =>
      _isAcceptedSolution(node) || node.children.any(_containsAcceptedSolution);

  bool _isAcceptedSolution(SgfNode node) => RegExp(
    r'\b(RIGHT|CORRECT)\b',
    caseSensitive: false,
  ).hasMatch(node.firstValue('C') ?? '');

  int _initialPlayer(SgfNode problem) {
    final player = problem.firstValue('PL');
    if (player == 'B') return 1;
    if (player == 'W') return 2;

    var node = problem;
    while (node.children.isNotEmpty) {
      node = node.children.first;
      if (node.firstValue('B') != null) return 1;
      if (node.firstValue('W') != null) return 2;
    }
    return 1;
  }

  String _problemLabel(SgfNode problem, int index) {
    final name = problem.firstValue('GN');
    final category = problem.firstValue('GE');
    final rank = problem.firstValue('DI');
    final details = [
      if (category != null && category.isNotEmpty) category,
      if (rank != null && rank.isNotEmpty) rank,
    ].join(' · ');
    if (name != null && name.isNotEmpty) {
      return '$name${details.isEmpty ? '' : ' · $details'}';
    }
    return 'Problem ${index + 1}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppNavBar(
        title: 'Tsumegos',
        leftIcon: Icons.arrow_back_ios_new,
        onPressedLeft: () => Navigator.of(context).pop(),
      ),
      body: SafeArea(
        child: ControllerConsumer(
          controller: context.appController,
          listenWhen: (previous, current) =>
              previous.isProcessing != current.isProcessing,
          listener: (context, previous, current) {},
          builder: (context, current) {
            final problems = current.tsumegos.games;
            return Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 820),
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: AnimatedBuilder(
                    animation: Listenable.merge([
                      _problemIndex,
                      _position,
                      _status,
                      _mistakes,
                      _solved,
                    ]),
                    builder: (context, child) {
                      final index = _problemIndex.value;
                      final position = _position.value;
                      final status = _status.value;
                      final mistakes = _mistakes.value;
                      final solved = _solved.value;
                      final hasSelectedProblem =
                          index >= 0 && index < problems.length;
                      return Column(
                        children: [
                          if (problems.isNotEmpty)
                            AppDropdown(
                              selectedIndex: index,
                              text: hasSelectedProblem
                                  ? _problemLabel(problems[index], index)
                                  : null,
                              items: [
                                for (var i = 0; i < problems.length; i++)
                                  DropdownMenuEntry(
                                    value: '$i',
                                    label: _problemLabel(problems[i], i),
                                  ),
                              ],
                              onSelected: (selection) =>
                                  _selectProblem(selection.$2),
                            ),
                          const SizedBox(height: 8),
                          if (problems.isEmpty)
                            Text(status, textAlign: TextAlign.center),
                          if (position != null)
                            Text(
                              '${position.toMove == 1 ? 'Black' : 'White'} to play',
                            ),
                          if (problems.isNotEmpty)
                            Text(status, textAlign: TextAlign.center),
                          if (mistakes > 0)
                            Text('Incorrect attempts: $mistakes'),
                          if (position != null) ...[
                            const SizedBox(height: 14),
                            Center(
                              child: ConstrainedBox(
                                constraints: const BoxConstraints(
                                  maxWidth: 680,
                                ),
                                child: AspectRatio(
                                  aspectRatio: 1,
                                  child: GoBoard(
                                    boardSize: position.size,
                                    stones: position.stones,
                                    lastMove: position.lastMove,
                                    onPlay: solved ? null : _tryMove,
                                  ),
                                ),
                              ),
                            ),
                          ],
                          const SizedBox(height: 12),
                          Wrap(
                            alignment: WrapAlignment.center,
                            spacing: 12,
                            children: [
                              AppButtonSecondary(
                                leftIcon: Icons.refresh,
                                text: 'Try again',
                                onPressed: _resetProblem,
                              ),
                              if (context.appState.tsumegos.games.length >
                                  index + 1)
                                AppButtonPrimary(
                                  leftIcon: Icons.navigate_next,
                                  text: 'Next',
                                  onPressed: () {
                                    _problemIndex.value++;
                                    _selectProblem(_problemIndex.value);
                                  },
                                ),
                            ],
                          ),
                        ],
                      );
                    },
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  @override
  void dispose() {
    _problemIndex.dispose();
    _cursor.dispose();
    _position.dispose();
    _mistakes.dispose();
    _status.dispose();
    _solved.dispose();
    super.dispose();
  }
}
