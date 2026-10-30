import 'package:flutter/material.dart';
import 'package:gnugo_ffi/gnugo_ffi.dart';

import 'src/game/go_position.dart';
import 'src/screens/record_game_screen.dart';
import 'src/screens/sgf_review_screen.dart';
import 'src/screens/tsumego_screen.dart';
import 'src/widgets/go_board.dart';

void main() {
  runApp(const OpenGoApp());
}

enum GameMode { vsGnuGo, passAndPlay }

class OpenGoApp extends StatelessWidget {
  const OpenGoApp({super.key});

  @override
  Widget build(BuildContext context) {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: const Color(0xFF315C47),
    );
    return MaterialApp(
      title: 'OpenGo',
      theme: ThemeData(
        colorScheme: colorScheme,
        useMaterial3: true,
        scaffoldBackgroundColor: const Color(0xFFF7F5EF),
      ),
      home: const OpenGoHome(),
    );
  }
}

class OpenGoHome extends StatelessWidget {
  const OpenGoHome({super.key});

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('OpenGo')),
    body: Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 760),
        child: ListView(
          padding: const EdgeInsets.all(24),
          shrinkWrap: true,
          children: [
            Text(
              'Play Go your way',
              style: Theme.of(context).textTheme.headlineMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Play, study problems, review records, or keep a game record.',
              style: Theme.of(context).textTheme.bodyLarge,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            _HomeFeature(
              title: 'Play',
              subtitle: 'Play GNU Go or pass-and-play locally.',
              icon: Icons.sports_esports,
              onTap: () => _open(context, const GoGamePage()),
            ),
            _HomeFeature(
              title: 'Solve Tsumego',
              subtitle:
                  'Practice Go Game Guru problems or import your own SGF.',
              icon: Icons.extension,
              onTap: () => _open(context, const TsumegoScreen()),
            ),
            _HomeFeature(
              title: 'Review Games',
              subtitle:
                  'Open SGF records, browse variations, and replay moves.',
              icon: Icons.menu_book,
              onTap: () => _open(context, const SgfReviewScreen()),
            ),
            _HomeFeature(
              title: 'Record a Game',
              subtitle:
                  'Use this device as a board and export the game as SGF.',
              icon: Icons.edit_note,
              onTap: () => _open(context, const RecordGameScreen()),
            ),
          ],
        ),
      ),
    ),
  );

  void _open(BuildContext context, Widget page) {
    Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => page));
  }
}

class _HomeFeature extends StatelessWidget {
  const _HomeFeature({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Card(
    child: ListTile(
      leading: Icon(icon, size: 32),
      title: Text(title),
      subtitle: Text(subtitle),
      trailing: const Icon(Icons.chevron_right),
      onTap: onTap,
    ),
  );
}

class GoGamePage extends StatefulWidget {
  const GoGamePage({
    super.key,
    this.autoStart = true,
    this.engineStart,
    this.sendCommand,
  });

  final bool autoStart;
  final Future<void> Function(int boardSize, int seed)? engineStart;
  final Future<String> Function(String command)? sendCommand;

  @override
  State<GoGamePage> createState() => _GoGamePageState();
}

class _GoGamePageState extends State<GoGamePage> {
  static const _boardSizes = [9, 13, 19];

  final GnuGoEngine _engine = GnuGoEngine();
  int _boardSize = 9;
  GameMode _mode = GameMode.vsGnuGo;
  int _humanColor = 1;
  List<int> _board = List<int>.filled(81, 0);
  final List<_GameSnapshot> _history = [];
  int _toMove = 1;
  int? _lastMove;
  int _consecutivePasses = 0;
  bool _gameOver = false;
  bool _busy = false;
  String _status = 'Black to play';
  String? _error;

  int get _aiColor => 3 - _humanColor;
  bool get _isAiTurn => _mode == GameMode.vsGnuGo && _toMove == _aiColor;
  @override
  void initState() {
    super.initState();
    if (widget.autoStart) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _startNewGame());
    }
  }

  Future<void> _startEngine(int boardSize, int seed) =>
      widget.engineStart?.call(boardSize, seed) ??
      _engine.start(boardSize, seed: seed);

  Future<String> _sendCommand(String command) =>
      widget.sendCommand?.call(command) ?? _engine.command(command);

  Future<void> _startNewGame() async {
    setState(() {
      _busy = true;
      _error = null;
      _status = 'Starting GNU Go…';
    });

    try {
      await _startEngine(
        _boardSize,
        DateTime.now().millisecondsSinceEpoch & 0x7fffffff,
      );
      await _sendCommand('boardsize $_boardSize');
      await _sendCommand('clear_board');
      await _sendCommand('komi 7.5');

      if (!mounted) return;
      setState(() {
        _board = List<int>.filled(_boardSize * _boardSize, 0);
        _history.clear();
        _toMove = 1;
        _lastMove = null;
        _consecutivePasses = 0;
        _gameOver = false;
        _status = 'Black to play';
      });

      if (_isAiTurn) {
        await _requestAiMove();
      }
    } on GnuGoException catch (error) {
      _showError(error.message);
    } catch (error) {
      _showError('Could not start the game: $error');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _playAt(int point) async {
    if (_busy || _gameOver || _isAiTurn) return;
    if (point < 0 || point >= _board.length) return;
    if (_board[point] != 0) return;

    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final row = point ~/ _boardSize;
      final column = point % _boardSize;
      final vertex = '${goColumnLabels[column]}${_boardSize - row}';
      await _sendCommand('play ${_gtpColor(_toMove)} $vertex');
      _commitMove(_toMove, point, await _readBoardState());
      if (!_gameOver && _isAiTurn) await _requestAiMove();
    } on GnuGoException catch (error) {
      if (mounted) setState(() => _error = error.message);
    } catch (error) {
      if (mounted) setState(() => _error = 'Move failed: $error');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _pass() async {
    if (_busy || _gameOver || _isAiTurn) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await _sendCommand('play ${_gtpColor(_toMove)} pass');
      _commitMove(_toMove, null, await _readBoardState());
      if (!_gameOver && _isAiTurn) await _requestAiMove();
    } on GnuGoException catch (error) {
      if (mounted) setState(() => _error = error.message);
    } catch (error) {
      if (mounted) setState(() => _error = 'Pass failed: $error');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _requestAiMove() async {
    final color = _toMove;
    final response = await _sendCommand('genmove ${_gtpColor(color)}');
    if (response.toLowerCase() == 'resign') {
      if (mounted) {
        setState(() {
          _gameOver = true;
          _status = '${_colorName(color)} resigns';
        });
      }
      return;
    }

    final point = _parseVertex(response);
    _commitMove(color, point, await _readBoardState());
  }

  Future<List<int>> _readBoardState() async {
    final blackStones = await _sendCommand('list_stones black');
    final whiteStones = await _sendCommand('list_stones white');
    final board = List<int>.filled(_boardSize * _boardSize, 0);

    void addStones(int color, String vertices) {
      for (final vertex in vertices.split(RegExp(r'\s+'))) {
        if (vertex.isEmpty) continue;
        final point = _parseVertex(vertex);
        if (point == null || board[point] != 0) {
          throw GnuGoException('GNU Go returned an invalid stone list.');
        }
        board[point] = color;
      }
    }

    addStones(1, blackStones);
    addStones(2, whiteStones);
    return board;
  }

  int? _parseVertex(String vertex) {
    if (vertex.toLowerCase() == 'pass') return null;
    if (vertex.length < 2) {
      throw GnuGoException('GNU Go returned an invalid move: $vertex');
    }

    final column = goColumnLabels.indexOf(vertex[0].toUpperCase());
    final rowNumber = int.tryParse(vertex.substring(1));
    if (column < 0 ||
        column >= _boardSize ||
        rowNumber == null ||
        rowNumber < 1 ||
        rowNumber > _boardSize) {
      throw GnuGoException('GNU Go returned an invalid move: $vertex');
    }
    return (_boardSize - rowNumber) * _boardSize + column;
  }

  void _commitMove(int color, int? point, List<int> boardAfterMove) {
    _history.add(_snapshot());
    setState(() {
      _board = boardAfterMove;
      if (point != null) {
        _lastMove = point;
        _consecutivePasses = 0;
      } else {
        _consecutivePasses++;
      }

      _toMove = 3 - color;
      _gameOver = _consecutivePasses >= 2;
      _status = _gameOver
          ? 'Both players passed — game over'
          : '${_colorName(_toMove)} to play';
    });
  }

  Future<void> _undo() async {
    if (_busy || _history.isEmpty) return;
    final moveCount = _mode == GameMode.vsGnuGo && _history.length >= 2 ? 2 : 1;
    final snapshotIndex = _history.length - moveCount;

    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      for (var i = 0; i < moveCount; i++) {
        await _sendCommand('undo');
      }
      final snapshot = _history[snapshotIndex];
      setState(() {
        _history.removeRange(snapshotIndex, _history.length);
        _board = List<int>.of(snapshot.board);
        _toMove = snapshot.toMove;
        _lastMove = snapshot.lastMove;
        _consecutivePasses = snapshot.consecutivePasses;
        _gameOver = false;
        _status = '${_colorName(_toMove)} to play';
      });
    } on GnuGoException catch (error) {
      if (mounted) setState(() => _error = error.message);
    } catch (error) {
      if (mounted) setState(() => _error = 'Undo failed: $error');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  _GameSnapshot _snapshot() => _GameSnapshot(
    board: List<int>.of(_board),
    toMove: _toMove,
    lastMove: _lastMove,
    consecutivePasses: _consecutivePasses,
  );

  void _showError(String message) {
    if (!mounted) return;
    setState(() {
      _error = message;
      _status = 'Engine error';
    });
  }

  String _gtpColor(int color) => color == 1 ? 'black' : 'white';
  String _colorName(int color) => color == 1 ? 'Black' : 'White';

  @override
  Widget build(BuildContext context) {
    final canPlay = !_busy && !_gameOver && !_isAiTurn;
    return Scaffold(
      appBar: AppBar(
        title: const Text('OpenGo'),
        actions: [
          IconButton(
            tooltip: 'New game',
            onPressed: _busy ? null : _startNewGame,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 820),
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  _status,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                if (_busy) ...[
                  const SizedBox(height: 8),
                  const LinearProgressIndicator(),
                ],
                if (_error != null) ...[
                  const SizedBox(height: 8),
                  Text(
                    _error!,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.error,
                    ),
                  ),
                ],
                const SizedBox(height: 20),
                Wrap(
                  alignment: WrapAlignment.center,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  spacing: 14,
                  runSpacing: 10,
                  children: [
                    _LabeledControl<int>(
                      label: 'Board',
                      value: _boardSize,
                      items: _boardSizes,
                      itemLabel: (size) => '$size×$size',
                      onChanged: _busy
                          ? null
                          : (size) {
                              if (size == null) return;
                              setState(() => _boardSize = size);
                              _startNewGame();
                            },
                    ),
                    _LabeledControl<GameMode>(
                      label: 'Game',
                      value: _mode,
                      items: GameMode.values,
                      itemLabel: (mode) => switch (mode) {
                        GameMode.vsGnuGo => 'Vs GNU Go',
                        GameMode.passAndPlay => 'Pass-and-play',
                      },
                      onChanged: _busy
                          ? null
                          : (mode) {
                              if (mode == null) return;
                              setState(() => _mode = mode);
                              _startNewGame();
                            },
                    ),
                    if (_mode == GameMode.vsGnuGo)
                      _LabeledControl<int>(
                        label: 'You play',
                        value: _humanColor,
                        items: const [1, 2],
                        itemLabel: _colorName,
                        onChanged: _busy
                            ? null
                            : (color) {
                                if (color == null) return;
                                setState(() => _humanColor = color);
                                _startNewGame();
                              },
                      ),
                  ],
                ),
                const SizedBox(height: 18),
                Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 680),
                    child: AspectRatio(
                      aspectRatio: 1,
                      child: LayoutBuilder(
                        builder: (context, constraints) => GoBoard(
                          boardSize: _boardSize,
                          stones: _board,
                          lastMove: _lastMove,
                          onPlay: canPlay ? _playAt : null,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Wrap(
                  alignment: WrapAlignment.center,
                  spacing: 12,
                  runSpacing: 8,
                  children: [
                    FilledButton.icon(
                      onPressed: canPlay ? _pass : null,
                      icon: const Icon(Icons.skip_next),
                      label: const Text('Pass'),
                    ),
                    OutlinedButton.icon(
                      onPressed: !_busy && _history.isNotEmpty ? _undo : null,
                      icon: const Icon(Icons.undo),
                      label: const Text('Undo turn'),
                    ),
                    OutlinedButton.icon(
                      onPressed: _busy ? null : _startNewGame,
                      icon: const Icon(Icons.refresh),
                      label: const Text('New game'),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                const Text(
                  'Offline play powered by GNU Go. In pass-and-play, hand the device to the next player after each move.',
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _GameSnapshot {
  const _GameSnapshot({
    required this.board,
    required this.toMove,
    required this.lastMove,
    required this.consecutivePasses,
  });

  final List<int> board;
  final int toMove;
  final int? lastMove;
  final int consecutivePasses;
}

class _LabeledControl<T> extends StatelessWidget {
  const _LabeledControl({
    required this.label,
    required this.value,
    required this.items,
    required this.itemLabel,
    required this.onChanged,
  });

  final String label;
  final T value;
  final List<T> items;
  final String Function(T value) itemLabel;
  final ValueChanged<T?>? onChanged;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text('$label: '),
        DropdownButton<T>(
          value: value,
          onChanged: onChanged,
          items: [
            for (final item in items)
              DropdownMenuItem<T>(value: item, child: Text(itemLabel(item))),
          ],
        ),
      ],
    );
  }
}
