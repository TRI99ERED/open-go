import 'dart:convert';
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:gnugo_ffi/gnugo_ffi.dart';
import 'package:opengo/src/core/game/go_position.dart';
import 'package:opengo/src/core/game/sgf.dart';
import 'package:opengo/src/features/themes/app_theme.dart';
import 'package:opengo/src/features/themes/styles.dart';
import 'package:opengo/src/widgets/common/app_accordion.dart';
import 'package:opengo/src/widgets/common/app_button.dart';
import 'package:opengo/src/widgets/common/app_labeled_control.dart';
import 'package:opengo/src/widgets/common/app_nav_bar.dart';
import 'package:opengo/src/widgets/go_board.dart';

enum GameMode { vsGnuGo, passAndPlay }

class GameScreen extends StatefulWidget {
  const GameScreen({
    super.key,
    this.autoStart = true,
    this.initialMode = GameMode.vsGnuGo,
    this.engineStart,
    this.sendCommand,
  });

  final bool autoStart;
  final GameMode initialMode;
  final Future<void> Function(int boardSize, int seed)? engineStart;
  final Future<String> Function(String command)? sendCommand;

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> {
  static const _boardSizes = [9, 13, 19];

  final _engine = ValueNotifier(GnuGoEngine());
  final _boardSize = ValueNotifier(9);
  final _mode = ValueNotifier(GameMode.vsGnuGo);
  final _humanColor = ValueNotifier(1);
  final _board = ValueNotifier(List<int>.filled(81, 0));
  final _history = ValueNotifier<List<_GameSnapshot>>([]);
  final _toMove = ValueNotifier(1);
  final _lastMove = ValueNotifier<int?>(null);
  final _consecutivePasses = ValueNotifier(0);
  final _gameOver = ValueNotifier(false);
  final _busy = ValueNotifier(false);
  final _status = ValueNotifier('Black to play');
  final _error = ValueNotifier<String?>(null);
  final _recordMessage = ValueNotifier<String?>(null);
  final _blackPlayer = TextEditingController(text: 'Black');
  final _whitePlayer = TextEditingController(text: 'White');
  final _gameName = TextEditingController();
  final List<SgfNode> _recordedMoves = [];
  late SgfNode _gameRoot = _createSgfRoot();

  int get _aiColor => 3 - _humanColor.value;
  bool get _isAiTurn =>
      _mode.value == GameMode.vsGnuGo && _toMove.value == _aiColor;

  @override
  void dispose() {
    _blackPlayer.dispose();
    _whitePlayer.dispose();
    _gameName.dispose();
    _recordMessage.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _mode.value = widget.initialMode;
    if (widget.autoStart) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _startNewGame());
    }
  }

  Future<void> _startEngine(int boardSize, int seed) =>
      widget.engineStart?.call(boardSize, seed) ??
      _engine.value.start(boardSize, seed: seed);

  Future<String> _sendCommand(String command) =>
      widget.sendCommand?.call(command) ?? _engine.value.command(command);

  Future<void> _startNewGame() async {
    _busy.value = true;
    _error.value = null;
    _status.value = 'Starting GNU Go…';

    try {
      await _startEngine(
        _boardSize.value,
        DateTime.now().millisecondsSinceEpoch & 0x7fffffff,
      );
      await _sendCommand('boardsize ${_boardSize.value}');
      await _sendCommand('clear_board');
      await _sendCommand('komi 7.5');

      if (!mounted) return;
      _board.value = List<int>.filled(_boardSize.value * _boardSize.value, 0);
      _history.value.clear();
      _recordedMoves.clear();
      _gameRoot = _createSgfRoot();
      _toMove.value = 1;
      _lastMove.value = null;
      _consecutivePasses.value = 0;
      _gameOver.value = false;
      _recordMessage.value = null;
      _status.value = 'Black to play';

      if (_isAiTurn) {
        await _requestAiMove();
      }
    } on GnuGoException catch (error) {
      _showError(error.message);
    } catch (error) {
      _showError('Could not start the game: $error');
    } finally {
      if (mounted) setState(() => _busy.value = false);
    }
  }

  Future<void> _playAt(int point) async {
    if (_busy.value || _gameOver.value || _isAiTurn) return;
    if (point < 0 || point >= _board.value.length) return;
    if (_board.value[point] != 0) return;

    _busy.value = true;
    _error.value = null;

    try {
      final row = point ~/ _boardSize.value;
      final column = point % _boardSize.value;
      final vertex = '${goColumnLabels[column]}${_boardSize.value - row}';
      await _sendCommand('play ${_gtpColor(_toMove.value)} $vertex');
      _commitMove(_toMove.value, point, await _readBoardState());
      if (!_gameOver.value && _isAiTurn) await _requestAiMove();
    } on GnuGoException catch (error) {
      if (mounted) _error.value = error.message;
    } catch (error) {
      if (mounted) _error.value = 'Move failed: $error';
    } finally {
      if (mounted) _busy.value = false;
    }
  }

  Future<void> _pass() async {
    if (_busy.value || _gameOver.value || _isAiTurn) return;

    _busy.value = true;
    _error.value = null;

    try {
      await _sendCommand('play ${_gtpColor(_toMove.value)} pass');
      _commitMove(_toMove.value, null, await _readBoardState());
      if (!_gameOver.value && _isAiTurn) await _requestAiMove();
    } on GnuGoException catch (error) {
      if (mounted) _error.value = error.message;
    } catch (error) {
      if (mounted) _error.value = 'Pass failed: $error';
    } finally {
      if (mounted) _busy.value = false;
    }
  }

  Future<void> _requestAiMove() async {
    final color = _toMove.value;
    final response = await _sendCommand('genmove ${_gtpColor(color)}');
    if (response.toLowerCase() == 'resign') {
      if (mounted) {
        _gameOver.value = true;
        _status.value = '${_colorName(color)} resigns';
      }
      return;
    }

    final point = _parseVertex(response);
    _commitMove(color, point, await _readBoardState());
  }

  Future<List<int>> _readBoardState() async {
    final blackStones = await _sendCommand('list_stones black');
    final whiteStones = await _sendCommand('list_stones white');
    final board = List<int>.filled(_boardSize.value * _boardSize.value, 0);

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
        column >= _boardSize.value ||
        rowNumber == null ||
        rowNumber < 1 ||
        rowNumber > _boardSize.value) {
      throw GnuGoException('GNU Go returned an invalid move: $vertex');
    }
    return (_boardSize.value - rowNumber) * _boardSize.value + column;
  }

  void _commitMove(int color, int? point, List<int> boardAfterMove) {
    _history.value.add(_snapshot());
    final moveNode = SgfNode(
      properties: {
        color == 1 ? 'B' : 'W': [
          point == null
              ? ''
              : GoPosition.empty(_boardSize.value).sgfCoordinate(point),
        ],
      },
    );
    final parent = _recordedMoves.isEmpty ? _gameRoot : _recordedMoves.last;
    parent.children.add(moveNode);
    _recordedMoves.add(moveNode);
    _board.value = boardAfterMove;
    if (point != null) {
      _lastMove.value = point;
      _consecutivePasses.value = 0;
    } else {
      _consecutivePasses.value++;
    }

    _toMove.value = 3 - color;
    _gameOver.value = _consecutivePasses.value >= 2;
    _status.value = _gameOver.value
        ? 'Both players passed — game over'
        : '${_colorName(_toMove.value)} to play';
  }

  Future<void> _undo() async {
    if (_busy.value || _history.value.isEmpty) return;
    final moveCount =
        _mode.value == GameMode.vsGnuGo && _history.value.length >= 2 ? 2 : 1;
    final snapshotIndex = _history.value.length - moveCount;

    _busy.value = true;
    _error.value = null;

    try {
      for (var i = 0; i < moveCount; i++) {
        await _sendCommand('undo');
      }
      final snapshot = _history.value[snapshotIndex];
      _history.value.removeRange(snapshotIndex, _history.value.length);
      _recordedMoves.removeRange(snapshotIndex, _recordedMoves.length);
      final recordParent = _recordedMoves.isEmpty
          ? _gameRoot
          : _recordedMoves.last;
      recordParent.children.clear();
      _board.value = List<int>.of(snapshot.board);
      _toMove.value = snapshot.toMove;
      _lastMove.value = snapshot.lastMove;
      _consecutivePasses.value = snapshot.consecutivePasses;
      _gameOver.value = false;
      _status.value = '${_colorName(_toMove.value)} to play';
    } on GnuGoException catch (error) {
      if (mounted) _error.value = error.message;
    } catch (error) {
      if (mounted) _error.value = 'Undo failed: $error';
    } finally {
      if (mounted) _busy.value = false;
    }
  }

  _GameSnapshot _snapshot() => _GameSnapshot(
    board: List<int>.of(_board.value),
    toMove: _toMove.value,
    lastMove: _lastMove.value,
    consecutivePasses: _consecutivePasses.value,
  );

  void _showError(String message) {
    if (!mounted) return;
    _error.value = message;
    _status.value = 'Engine error';
  }

  String _gtpColor(int color) => color == 1 ? 'black' : 'white';
  String _colorName(int color) => color == 1 ? 'Black' : 'White';

  SgfNode _createSgfRoot() => SgfNode(
    properties: {
      'GM': ['1'],
      'FF': ['4'],
      'CA': ['UTF-8'],
      'AP': ['OpenGo:0.1.0'],
      'SZ': ['${_boardSize.value}'],
      'DT': [DateTime.now().toIso8601String().substring(0, 10)],
      'KM': ['7.5'],
      'PB': [_blackPlayer.text.trim()],
      'PW': [_whitePlayer.text.trim()],
      if (_gameName.text.trim().isNotEmpty) 'GN': [_gameName.text.trim()],
    },
  );

  Future<void> _exportSgf() async {
    if (_busy.value) return;
    _busy.value = true;
    _recordMessage.value = null;

    try {
      _gameRoot
        ..setValue('SZ', '${_boardSize.value}')
        ..setValue('PB', _blackPlayer.text.trim())
        ..setValue('PW', _whitePlayer.text.trim());
      if (_gameName.text.trim().isNotEmpty) {
        _gameRoot.setValue('GN', _gameName.text.trim());
      } else {
        _gameRoot.properties.remove('GN');
      }

      final data = SgfCollection([_gameRoot]).write();
      final uri = await FilePicker.saveFile(
        fileName: '${_safeFilename(_gameName.text)}.sgf',
        bytes: Uint8List.fromList(utf8.encode(data)),
        mimeType: 'application/x-go-sgf',
        dialogTitle: 'Export SGF game',
      );
      if (!mounted) return;
      _recordMessage.value = uri == null
          ? 'Export cancelled'
          : 'Saved SGF to $uri';
    } catch (error) {
      if (mounted) _recordMessage.value = 'Could not export SGF: $error';
    } finally {
      if (mounted) _busy.value = false;
    }
  }

  String _safeFilename(String value) {
    final normalized = value.trim().replaceAll(RegExp(r'[<>:"/\\|?*]'), '_');
    return normalized.isEmpty ? 'opengo-game' : normalized;
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder(
      valueListenable: _history,
      builder: (context, history, child) {
        return ValueListenableBuilder(
          valueListenable: _lastMove,
          builder: (context, lastMove, child) {
            return ValueListenableBuilder(
              valueListenable: _board,
              builder: (context, board, child) {
                return ValueListenableBuilder(
                  valueListenable: _humanColor,
                  builder: (context, humanColor, child) {
                    return ValueListenableBuilder(
                      valueListenable: _mode,
                      builder: (context, gameMode, child) {
                        return ValueListenableBuilder(
                          valueListenable: _boardSize,
                          builder: (context, boardSize, child) {
                            return ValueListenableBuilder(
                              valueListenable: _error,
                              builder: (context, error, child) {
                                return ValueListenableBuilder(
                                  valueListenable: _status,
                                  builder: (context, status, child) {
                                    return ValueListenableBuilder(
                                      valueListenable: _busy,
                                      builder: (context, busy, child) {
                                        return ValueListenableBuilder(
                                          valueListenable: _gameOver,
                                          builder: (context, gameOver, widget) {
                                            final canPlay =
                                                !busy &&
                                                !gameOver &&
                                                !_isAiTurn;
                                            return Scaffold(
                                              appBar: AppNavBar(
                                                title: 'Game',
                                                rightIcon: Icons.refresh,
                                                onPressedRight: busy
                                                    ? null
                                                    : _startNewGame,
                                                leftIcon:
                                                    Icons.arrow_back_ios_new,
                                                onPressedLeft: () =>
                                                    Navigator.of(context).pop(),
                                              ),
                                              body: Center(
                                                child: ConstrainedBox(
                                                  constraints:
                                                      const BoxConstraints(
                                                        maxWidth: 820,
                                                      ),
                                                  child: SingleChildScrollView(
                                                    padding:
                                                        const EdgeInsets.fromLTRB(
                                                          spacing20,
                                                          spacing8,
                                                          spacing20,
                                                          spacing24,
                                                        ),
                                                    child: Column(
                                                      crossAxisAlignment:
                                                          CrossAxisAlignment
                                                              .stretch,
                                                      children: [
                                                        SizedBox(
                                                          height: 80,
                                                          child: Column(
                                                            children: [
                                                              Text(
                                                                status,
                                                                textAlign:
                                                                    TextAlign
                                                                        .center,
                                                                style: TextStyle(
                                                                  fontSize:
                                                                      h1Size,
                                                                  fontWeight:
                                                                      h1Weight,
                                                                  color: Theme.of(context)
                                                                      .extension<
                                                                        AppTheme
                                                                      >()!
                                                                      .foregroundStrongestColor,
                                                                ),
                                                              ),
                                                              if (busy) ...[
                                                                const SizedBox(
                                                                  height:
                                                                      spacing8,
                                                                ),
                                                                LinearProgressIndicator(
                                                                  color: Theme.of(context)
                                                                      .extension<
                                                                        AppTheme
                                                                      >()!
                                                                      .foregroundStrongestColor,
                                                                  backgroundColor:
                                                                      Theme.of(
                                                                            context,
                                                                          )
                                                                          .extension<
                                                                            AppTheme
                                                                          >()!
                                                                          .backgroundStrongColor,
                                                                ),
                                                              ],
                                                            ],
                                                          ),
                                                        ),
                                                        if (error != null) ...[
                                                          const SizedBox(
                                                            height: spacing8,
                                                          ),
                                                          SelectableText(
                                                            error,
                                                            textAlign: TextAlign
                                                                .center,
                                                            style: TextStyle(
                                                              fontSize: bSSize,
                                                              fontWeight:
                                                                  bSWeight,
                                                              color:
                                                                  Theme.of(
                                                                        context,
                                                                      )
                                                                      .extension<
                                                                        AppTheme
                                                                      >()!
                                                                      .errorDarkColor,
                                                            ),
                                                          ),
                                                        ],
                                                        const SizedBox(
                                                          height: spacing20,
                                                        ),
                                                        Wrap(
                                                          alignment:
                                                              WrapAlignment
                                                                  .center,
                                                          crossAxisAlignment:
                                                              WrapCrossAlignment
                                                                  .center,
                                                          spacing: 14,
                                                          runSpacing: 10,
                                                          children: [
                                                            AppLabeledControl(
                                                              label: 'Board',
                                                              value: boardSize,
                                                              items:
                                                                  _boardSizes,
                                                              itemLabel: (
                                                                size,
                                                              ) => '$size×$size',
                                                              onSelected: busy
                                                                  ? null
                                                                  : (size) {
                                                                      if (size ==
                                                                          null) {
                                                                        return;
                                                                      }
                                                                      _boardSize
                                                                              .value =
                                                                          size;
                                                                      _startNewGame();
                                                                    },
                                                            ),
                                                            AppLabeledControl(
                                                              label: 'Game',
                                                              value: gameMode
                                                                  .index,
                                                              items: GameMode
                                                                  .values
                                                                  .map(
                                                                    (v) =>
                                                                        v.index,
                                                                  )
                                                                  .toList(),
                                                              itemLabel: (mode) =>
                                                                  switch (GameMode
                                                                      .values[mode]) {
                                                                    GameMode
                                                                        .vsGnuGo =>
                                                                      'Vs GNU Go',
                                                                    GameMode
                                                                        .passAndPlay =>
                                                                      'Pass-and-play',
                                                                  },
                                                              onSelected: busy
                                                                  ? null
                                                                  : (mode) {
                                                                      if (mode ==
                                                                          null) {
                                                                        return;
                                                                      }
                                                                      _mode.value =
                                                                          GameMode
                                                                              .values[mode];

                                                                      _startNewGame();
                                                                    },
                                                            ),
                                                            if (gameMode ==
                                                                GameMode
                                                                    .vsGnuGo)
                                                              AppLabeledControl(
                                                                label:
                                                                    'You play',
                                                                value:
                                                                    humanColor,
                                                                items: const [
                                                                  1,
                                                                  2,
                                                                ],
                                                                itemLabel:
                                                                    _colorName,
                                                                onSelected: busy
                                                                    ? null
                                                                    : (color) {
                                                                        if (color ==
                                                                            null) {
                                                                          return;
                                                                        }
                                                                        _humanColor.value =
                                                                            color;

                                                                        _startNewGame();
                                                                      },
                                                              ),
                                                          ],
                                                        ),
                                                        const SizedBox(
                                                          height: spacing20,
                                                        ),
                                                        Center(
                                                          child: ConstrainedBox(
                                                            constraints:
                                                                const BoxConstraints(
                                                                  maxWidth: 680,
                                                                ),
                                                            child: AspectRatio(
                                                              aspectRatio: 1,
                                                              child: LayoutBuilder(
                                                                builder:
                                                                    (
                                                                      context,
                                                                      constraints,
                                                                    ) => GoBoard(
                                                                      boardSize:
                                                                          boardSize,
                                                                      stones:
                                                                          board,
                                                                      lastMove:
                                                                          lastMove,
                                                                      onPlay:
                                                                          canPlay
                                                                          ? _playAt
                                                                          : null,
                                                                    ),
                                                              ),
                                                            ),
                                                          ),
                                                        ),
                                                        const SizedBox(
                                                          height: spacing20,
                                                        ),
                                                        Wrap(
                                                          alignment:
                                                              WrapAlignment
                                                                  .center,
                                                          spacing: 12,
                                                          runSpacing: 8,
                                                          children: [
                                                            AppButtonPrimary(
                                                              onPressed: canPlay
                                                                  ? _pass
                                                                  : null,
                                                              leftIcon: Icons
                                                                  .skip_next,
                                                              text: 'Pass',
                                                            ),
                                                            AppButtonSecondary(
                                                              onPressed:
                                                                  !busy &&
                                                                      history
                                                                          .isNotEmpty
                                                                  ? _undo
                                                                  : null,
                                                              leftIcon:
                                                                  Icons.undo,
                                                              text: 'Undo',
                                                            ),
                                                            AppButtonSecondary(
                                                              onPressed: busy
                                                                  ? null
                                                                  : _startNewGame,
                                                              leftIcon:
                                                                  Icons.refresh,
                                                              text: 'New game',
                                                            ),
                                                          ],
                                                        ),
                                                        AppAccordion(
                                                          title: 'Game record',
                                                          children: [
                                                            Wrap(
                                                              alignment:
                                                                  WrapAlignment
                                                                      .center,
                                                              spacing: 16,
                                                              runSpacing: 12,
                                                              children: [
                                                                SizedBox(
                                                                  width: 180,
                                                                  child: TextField(
                                                                    controller:
                                                                        _blackPlayer,
                                                                    decoration:
                                                                        const InputDecoration(
                                                                          labelText: 'Black player',
                                                                        ),
                                                                  ),
                                                                ),
                                                                SizedBox(
                                                                  width: 180,
                                                                  child: TextField(
                                                                    controller:
                                                                        _whitePlayer,
                                                                    decoration:
                                                                        const InputDecoration(
                                                                          labelText: 'White player',
                                                                        ),
                                                                  ),
                                                                ),
                                                                SizedBox(
                                                                  width: 180,
                                                                  child: TextField(
                                                                    controller:
                                                                        _gameName,
                                                                    decoration:
                                                                        const InputDecoration(
                                                                          labelText: 'Game name (optional)',
                                                                        ),
                                                                  ),
                                                                ),
                                                              ],
                                                            ),
                                                            const SizedBox(
                                                              height: spacing12,
                                                            ),
                                                            AppButtonSecondary(
                                                              onPressed: busy
                                                                  ? null
                                                                  : _exportSgf,
                                                              leftIcon: Icons
                                                                  .save_alt,
                                                              text: busy
                                                                  ? 'Exporting…'
                                                                  : 'Export SGF',
                                                            ),
                                                            ValueListenableBuilder(
                                                              valueListenable:
                                                                  _recordMessage,
                                                              builder:
                                                                  (
                                                                    context,
                                                                    message,
                                                                    child,
                                                                  ) => message == null
                                                                  ? const SizedBox.shrink()
                                                                  : Padding(
                                                                      padding:
                                                                          const EdgeInsets.only(
                                                                            top:
                                                                                spacing8,
                                                                          ),
                                                                      child: Text(
                                                                        message,
                                                                        textAlign:
                                                                            TextAlign.center,
                                                                      ),
                                                                    ),
                                                            ),
                                                            const SizedBox(
                                                              height: spacing12,
                                                            ),
                                                          ],
                                                        ),
                                                      ],
                                                    ),
                                                  ),
                                                ),
                                              ),
                                            );
                                          },
                                        );
                                      },
                                    );
                                  },
                                );
                              },
                            );
                          },
                        );
                      },
                    );
                  },
                );
              },
            );
          },
        );
      },
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
