import 'dart:convert';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../game/go_position.dart';
import '../game/sgf.dart';
import '../widgets/go_board.dart';

class TsumegoScreen extends StatefulWidget {
  const TsumegoScreen({super.key});

  @override
  State<TsumegoScreen> createState() => _TsumegoScreenState();
}

class _TsumegoScreenState extends State<TsumegoScreen> {
  final List<SgfNode> _problems = [];
  int _problemIndex = 0;
  SgfNode? _cursor;
  GoPosition? _position;
  int _mistakes = 0;
  String _status = 'Loading problems…';
  bool _solved = false;

  SgfNode? get _problem => _problems.isEmpty ? null : _problems[_problemIndex];

  @override
  void initState() {
    super.initState();
    _loadProblems();
  }

  Future<void> _loadProblems() async {
    try {
      final source = await rootBundle.loadString(
        'assets/problems/gogameguru-weekly.sgf',
      );
      final collection = SgfCollection.parse(source);
      if (!mounted) return;
      setState(() {
        _problems.addAll(collection.games);
        _problemIndex = 0;
      });
      _resetProblem();
    } catch (error) {
      if (mounted) setState(() => _status = 'Could not load problems: $error');
    }
  }

  void _resetProblem() {
    final problem = _problem;
    if (problem == null) {
      setState(() => _status = 'No problems loaded.');
      return;
    }
    try {
      setState(() {
        _cursor = problem;
        _position = positionAtPath(
          problem,
          [],
        ).withToMove(_initialPlayer(problem));
        _mistakes = 0;
        _solved = false;
        _status = 'Find the solution.';
      });
    } catch (error) {
      setState(() => _status = 'Invalid problem SGF: $error');
    }
  }

  Future<void> _importProblems() async {
    try {
      final file = await FilePicker.pickFile(
        dialogTitle: 'Import tsumego SGF',
        type: FileType.custom,
        allowedExtensions: const ['sgf'],
      );
      if (file == null) return;
      final source = utf8.decode(await file.readAsBytes());
      final collection = SgfCollection.parse(source);
      setState(() {
        _problems.addAll(collection.games);
        _problemIndex = _problems.length - collection.games.length;
      });
      _resetProblem();
    } catch (error) {
      if (mounted) setState(() => _status = 'Could not import SGF: $error');
    }
  }

  void _selectProblem(int? index) {
    if (index == null) return;
    setState(() => _problemIndex = index);
    _resetProblem();
  }

  void _tryMove(int point) {
    final position = _position;
    final cursor = _cursor;
    if (position == null || cursor == null || _solved) return;

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
      setState(() {
        _mistakes++;
        _status = 'That move is not in the solution. Try another move.';
      });
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
    setState(() {
      _cursor = nextCursor;
      _position = nextPosition;
      _solved = solved;
      _status = solved
          ? 'Solved! You found the solution.'
          : 'Correct. Continue the sequence.';
    });
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
    final position = _position;
    final problem = _problem;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Solve Tsumego'),
        actions: [
          IconButton(
            tooltip: 'Import problem SGF',
            onPressed: _importProblems,
            icon: const Icon(Icons.folder_open),
          ),
        ],
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 820),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                if (_problems.isNotEmpty)
                  DropdownButton<int>(
                    value: _problemIndex,
                    items: [
                      for (var index = 0; index < _problems.length; index++)
                        DropdownMenuItem(
                          value: index,
                          child: Text(_problemLabel(_problems[index], index)),
                        ),
                    ],
                    onChanged: _selectProblem,
                  ),
                if (problem?.firstValue('C') case final description?
                    when description.isNotEmpty)
                  Text(description, textAlign: TextAlign.center),
                const SizedBox(height: 8),
                if (position != null)
                  Text('${position.toMove == 1 ? 'Black' : 'White'} to play'),
                Text(_status, textAlign: TextAlign.center),
                if (_mistakes > 0) Text('Incorrect attempts: $_mistakes'),
                if (position != null) ...[
                  const SizedBox(height: 14),
                  Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 680),
                      child: AspectRatio(
                        aspectRatio: 1,
                        child: GoBoard(
                          boardSize: position.size,
                          stones: position.stones,
                          lastMove: position.lastMove,
                          onPlay: _solved ? null : _tryMove,
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
                    OutlinedButton.icon(
                      onPressed: _resetProblem,
                      icon: const Icon(Icons.refresh),
                      label: const Text('Try again'),
                    ),
                    TextButton.icon(
                      onPressed: _importProblems,
                      icon: const Icon(Icons.file_open),
                      label: const Text('Import SGF problems'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
