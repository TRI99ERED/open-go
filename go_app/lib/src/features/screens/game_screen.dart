import 'dart:convert';
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:gnugo_ffi/gnugo_ffi.dart';
import 'package:opengo/l10n/app_localizations.dart';
import 'package:opengo/src/core/game/go_position.dart';
import 'package:opengo/src/core/game/sgf.dart';
import 'package:opengo/src/core/localization/localization.dart';
import 'package:opengo/src/features/themes/app_theme.dart';
import 'package:opengo/src/features/themes/styles.dart';
import 'package:opengo/src/widgets/common/app_accordion.dart';
import 'package:opengo/src/widgets/common/app_button.dart';
import 'package:opengo/src/widgets/common/app_labeled_control.dart';
import 'package:opengo/src/widgets/common/app_nav_bar.dart';
import 'package:opengo/src/widgets/common/app_text_area.dart';
import 'package:opengo/src/widgets/common/app_text_field.dart';
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
  final _status = ValueNotifier('');
  final _error = ValueNotifier<String?>(null);
  final _recordMessage = ValueNotifier<String?>(null);
  final _markingEnabled = ValueNotifier(false);
  final _labels = ValueNotifier<Map<int, String>>({});
  final _blackPlayer = TextEditingController();
  final _whitePlayer = TextEditingController();
  final _gameName = TextEditingController();
  final _gameComment = TextEditingController();
  final _markerLabel = TextEditingController();
  final List<SgfNode> _recordedMoves = [];
  late SgfNode _gameRoot = _createSgfRoot();
  bool _initializedPlayerNames = false;

  int get _aiColor => 3 - _humanColor.value;
  bool get _isAiTurn =>
      _mode.value == GameMode.vsGnuGo && _toMove.value == _aiColor;

  bool _isValidMarkerLabel(String? value) =>
      value != null && RegExp(r'^(?:[A-Z]|[+-]?\d+)$').hasMatch(value);

  @override
  void dispose() {
    _blackPlayer.dispose();
    _whitePlayer.dispose();
    _gameName.dispose();
    _gameComment.dispose();
    _markerLabel.dispose();
    _recordMessage.dispose();
    _markingEnabled.dispose();
    _labels.dispose();
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

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_initializedPlayerNames) {
      _blackPlayer.text = context.l10n.black;
      _whitePlayer.text = context.l10n.white;
      _initializedPlayerNames = true;
    }
  }

  Future<void> _startEngine(int boardSize, int seed) =>
      widget.engineStart?.call(boardSize, seed) ??
      _engine.value.start(boardSize, seed: seed);

  Future<String> _sendCommand(String command) =>
      widget.sendCommand?.call(command) ?? _engine.value.command(command);

  Future<void> _startNewGame() async {
    final l10n = context.l10n;
    _busy.value = true;
    _error.value = null;
    _status.value = l10n.startingGnuGo;

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
      _gameComment.clear();
      _markerLabel.clear();
      _labels.value = {};
      _markingEnabled.value = false;
      _gameRoot = _createSgfRoot();
      _toMove.value = 1;
      _lastMove.value = null;
      _consecutivePasses.value = 0;
      _gameOver.value = false;
      _recordMessage.value = null;
      _status.value = l10n.blackToPlay;

      if (_isAiTurn) {
        await _requestAiMove();
      }
    } on GnuGoException catch (error) {
      _showError(error.message);
    } catch (error) {
      _showError(l10n.couldNotStartGame(error.toString()));
    } finally {
      if (mounted) setState(() => _busy.value = false);
    }
  }

  Future<void> _playAt(int point) async {
    if (_busy.value || _gameOver.value || _isAiTurn) return;
    if (point < 0 || point >= _board.value.length) return;
    if (_board.value[point] != 0) return;

    final l10n = context.l10n;
    _busy.value = true;
    _error.value = null;

    try {
      final row = point ~/ _boardSize.value;
      final column = point % _boardSize.value;
      final vertex = '${goColumnLabels[column]}${_boardSize.value - row}';
      await _sendCommand('play ${_gtpColor(_toMove.value)} $vertex');
      await _commitMove(_toMove.value, point, await _readBoardState());
      if (!_gameOver.value && _isAiTurn) await _requestAiMove();
    } on GnuGoException catch (error) {
      if (mounted) {
        _error.value = _engineErrorMessage(error.message, l10n);
      }
    } catch (error) {
      if (mounted) _error.value = l10n.moveFailed(error.toString());
    } finally {
      if (mounted) _busy.value = false;
    }
  }

  Future<void> _pass() async {
    if (_busy.value || _gameOver.value || _isAiTurn) return;

    final l10n = context.l10n;
    _busy.value = true;
    _error.value = null;

    try {
      await _sendCommand('play ${_gtpColor(_toMove.value)} pass');
      await _commitMove(_toMove.value, null, await _readBoardState());
      if (!_gameOver.value && _isAiTurn) await _requestAiMove();
    } on GnuGoException catch (error) {
      if (mounted) {
        _error.value = _engineErrorMessage(error.message, l10n);
      }
    } catch (error) {
      if (mounted) _error.value = l10n.passFailed(error.toString());
    } finally {
      if (mounted) _busy.value = false;
    }
  }

  Future<void> _requestAiMove() async {
    final l10n = context.l10n;
    final color = _toMove.value;
    final response = await _sendCommand('genmove ${_gtpColor(color)}');
    if (response.toLowerCase() == 'resign') {
      if (mounted) {
        final winner = 3 - color;
        _gameOver.value = true;
        _gameRoot.setValue('RE', '${winner == 1 ? 'B' : 'W'}+R');
        _status.value = l10n.playerResignsWinner(
          _colorName(color, l10n),
          _colorName(winner, l10n),
        );
      }
      return;
    }

    final point = _parseVertex(response);
    await _commitMove(color, point, await _readBoardState());
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

  Future<void> _commitMove(
    int color,
    int? point,
    List<int> boardAfterMove,
  ) async {
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
    if (_gameOver.value) {
      _status.value = context.l10n.bothPlayersPassedScoring;
      await _scoreGame();
    } else {
      _status.value = _toMove.value == 1
          ? context.l10n.blackToPlay
          : context.l10n.whiteToPlay;
    }
  }

  void _markAt(int point) {
    final label = _markerLabel.text;
    if (_busy.value || !_markingEnabled.value || !_isValidMarkerLabel(label)) {
      return;
    }

    final labels = Map<int, String>.of(_labels.value);
    if (labels[point] == label) {
      labels.remove(point);
    } else {
      labels[point] = label;
    }
    _labels.value = labels;
  }

  Future<void> _scoreGame() async {
    final l10n = context.l10n;
    try {
      final result = (await _sendCommand('estimate_score')).trim();
      if (result == '0' || result.toLowerCase() == 'jigo') {
        _gameRoot.setValue('RE', '0');
        _status.value = l10n.draw;
        return;
      }

      final match = RegExp(r'^([BW])\+(\d+(?:\.\d+)?)').firstMatch(result);
      if (match == null) {
        throw GnuGoException(
          'GNU Go returned an invalid score estimate: $result',
        );
      }

      final winner = match.group(1) == 'B' ? 1 : 2;
      final margin = match.group(2)!;
      if (double.parse(margin) == 0) {
        _gameRoot.setValue('RE', '0');
        _status.value = l10n.draw;
        return;
      }
      _gameRoot.setValue('RE', '${match.group(1)}+$margin');
      _status.value = l10n.playerWinsByPoints(_colorName(winner, l10n), margin);
    } on GnuGoException catch (error) {
      _error.value = l10n.couldNotScoreGame(
        _engineErrorMessage(error.message, l10n),
      );
      _status.value = l10n.scoringFailed;
    } catch (error) {
      _error.value = l10n.couldNotScoreGame(error.toString());
      _status.value = l10n.scoringFailed;
    }
  }

  Future<void> _undo() async {
    if (_busy.value || _history.value.isEmpty) return;
    final l10n = context.l10n;
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
      _gameRoot.properties.remove('RE');
      final recordParent = _recordedMoves.isEmpty
          ? _gameRoot
          : _recordedMoves.last;
      recordParent.children.clear();
      _board.value = List<int>.of(snapshot.board);
      _toMove.value = snapshot.toMove;
      _lastMove.value = snapshot.lastMove;
      _consecutivePasses.value = snapshot.consecutivePasses;
      _gameOver.value = false;
      _status.value = _toMove.value == 1 ? l10n.blackToPlay : l10n.whiteToPlay;
      if (_isAiTurn) await _requestAiMove();
    } on GnuGoException catch (error) {
      if (mounted) {
        _error.value = _engineErrorMessage(error.message, l10n);
      }
    } catch (error) {
      if (mounted) _error.value = context.l10n.undoFailed(error.toString());
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
    _error.value = _engineErrorMessage(message, context.l10n);
    _status.value = context.l10n.engineError;
  }

  String _engineErrorMessage(String message, AppLocalizations l10n) {
    final normalized = message.trim().toLowerCase();
    if (normalized == 'illegal move') return l10n.engineIllegalMove;
    if (normalized == 'vertex must not be occupied') {
      return l10n.engineOccupiedPoint;
    }
    if (normalized == 'invalid color or coordinate') {
      return l10n.engineInvalidMove;
    }
    const initializationPrefix = 'GNU Go could not initialize board size ';
    if (message.startsWith(initializationPrefix)) {
      return l10n.engineStartFailed(
        message
            .substring(initializationPrefix.length)
            .replaceFirst(RegExp(r'\.$'), ''),
      );
    }
    if (message == 'GNU Go returned an invalid stone list.') {
      return l10n.engineInvalidBoardState;
    }

    final invalidMovePrefix = 'GNU Go returned an invalid move: ';
    if (message.startsWith(invalidMovePrefix)) {
      return l10n.engineInvalidMoveResponse(
        message.substring(invalidMovePrefix.length),
      );
    }

    final invalidScorePrefix = 'GNU Go returned an invalid score estimate: ';
    if (message.startsWith(invalidScorePrefix)) {
      return l10n.engineInvalidScoreResponse(
        message.substring(invalidScorePrefix.length),
      );
    }

    return l10n.engineUnexpectedError(message);
  }

  String _gtpColor(int color) => color == 1 ? 'black' : 'white';
  String _colorName(int color, AppLocalizations l10n) =>
      color == 1 ? l10n.black : l10n.white;

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
      final comment = _gameComment.text.trim();
      if (comment.isNotEmpty) {
        _gameRoot.setValue('C', comment);
      } else {
        _gameRoot.properties.remove('C');
      }
      final annotationNode = _recordedMoves.isEmpty
          ? _gameRoot
          : _recordedMoves.last;
      if (_labels.value.isNotEmpty) {
        annotationNode.properties['LB'] = [
          for (final entry in _labels.value.entries)
            '${GoPosition.empty(_boardSize.value).sgfCoordinate(entry.key)}:${entry.value}',
        ];
      } else {
        annotationNode.properties.remove('LB');
      }
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
        dialogTitle: context.l10n.exportSgfGame,
      );
      if (!mounted) return;
      _recordMessage.value = uri == null
          ? context.l10n.exportCancelled
          : context.l10n.savedSgfTo(uri);
    } catch (error) {
      if (mounted) {
        _recordMessage.value = context.l10n.couldNotExportSgf(error.toString());
      }
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
    return AnimatedBuilder(
      animation: Listenable.merge([
        _history,
        _lastMove,
        _board,
        _humanColor,
        _mode,
        _boardSize,
        _error,
        _status,
        _busy,
        _gameOver,
        _recordMessage,
        _markingEnabled,
        _labels,
        _markerLabel,
      ]),
      builder: (context, child) {
        final history = _history.value;
        final lastMove = _lastMove.value;
        final board = _board.value;
        final humanColor = _humanColor.value;
        final gameMode = _mode.value;
        final boardSize = _boardSize.value;
        final error = _error.value;
        final status = _status.value.isEmpty
            ? context.l10n.blackToPlay
            : _status.value;
        final busy = _busy.value;
        final gameOver = _gameOver.value;
        final recordMessage = _recordMessage.value;
        final markingEnabled = _markingEnabled.value;
        final canPlay = !busy && !gameOver && !_isAiTurn;
        return Scaffold(
          appBar: AppNavBar(
            title: context.l10n.game,
            rightIcon: Icons.refresh,
            onPressedRight: busy ? null : _startNewGame,
            leftIcon: Icons.arrow_back_ios_new,
            onPressedLeft: () => Navigator.of(context).pop(),
          ),
          body: SafeArea(
            top: false,
            child: Align(
              alignment: Alignment.topCenter,
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 820),
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(
                    spacing20,
                    spacing8,
                    spacing20,
                    spacing24,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                    SizedBox(
                      height: 80,
                      child: Column(
                        children: [
                          Text(
                            status,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: h1Size,
                              fontWeight: h1Weight,
                              color: Theme.of(context)
                                  .extension<AppTheme>()!
                                  .foregroundStrongestColor,
                            ),
                          ),
                          if (busy) ...[
                            const SizedBox(height: spacing8),
                            LinearProgressIndicator(
                              color: Theme.of(context)
                                  .extension<AppTheme>()!
                                  .foregroundStrongestColor,
                              backgroundColor: Theme.of(context)
                                  .extension<AppTheme>()!
                                  .backgroundStrongColor,
                            ),
                          ],
                          if (error != null) ...[
                            const SizedBox(height: spacing8),
                            SelectableText(
                              error,
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: bSSize,
                                fontWeight: bSWeight,
                                color: Theme.of(context)
                                    .extension<AppTheme>()!
                                    .errorDarkColor,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(height: spacing20),
                    Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(
                          maxWidth: goBoardMaxWidth,
                        ),
                        child: AspectRatio(
                          aspectRatio: 1,
                          child: LayoutBuilder(
                            builder: (context, constraints) => GoBoard(
                              boardSize: boardSize,
                              stones: board,
                              lastMove: lastMove,
                              labels: _labels.value,
                              onPlay: busy
                                  ? null
                                  : markingEnabled
                                  ? _markAt
                                  : canPlay
                                  ? _playAt
                                  : null,
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: spacing20),
                    Wrap(
                      alignment: WrapAlignment.center,
                      spacing: 12,
                      runSpacing: 8,
                      children: [
                        AppButtonPrimary(
                          onPressed: canPlay ? _pass : null,
                          leftIcon: Icons.skip_next,
                          text: context.l10n.pass,
                        ),
                        AppButtonSecondary(
                          onPressed: !busy && history.isNotEmpty ? _undo : null,
                          leftIcon: Icons.undo,
                          text: context.l10n.undo,
                        ),
                        AppButtonSecondary(
                          onPressed: busy ? null : _startNewGame,
                          leftIcon: Icons.refresh,
                          text: context.l10n.newGame,
                        ),
                      ],
                    ),
                    AppAccordion(
                      title: context.l10n.setup,
                      startOpen: true,
                      children: [
                        AppLabeledControl(
                          label: context.l10n.board,
                          value: boardSize,
                          items: _boardSizes,
                          itemLabel: (size) => '$size×$size',
                          onSelected: busy
                              ? null
                              : (size) {
                                  if (size == null) {
                                    return;
                                  }
                                  _boardSize.value = size;
                                  _startNewGame();
                                },
                        ),
                        AppLabeledControl(
                          label: context.l10n.gameMode,
                          value: gameMode.index,
                          items: GameMode.values.map((v) => v.index).toList(),
                          itemLabel: (mode) => switch (GameMode.values[mode]) {
                            GameMode.vsGnuGo => context.l10n.vsGnuGo,
                            GameMode.passAndPlay => context.l10n.passAndPlay,
                          },
                          onSelected: busy
                              ? null
                              : (mode) {
                                  if (mode == null) {
                                    return;
                                  }
                                  _mode.value = GameMode.values[mode];

                                  _startNewGame();
                                },
                        ),
                        if (gameMode == GameMode.vsGnuGo)
                          AppLabeledControl(
                            label: context.l10n.youPlay,
                            value: humanColor,
                            items: const [1, 2],
                            itemLabel: (color) =>
                                _colorName(color, context.l10n),
                            onSelected: busy
                                ? null
                                : (color) {
                                    if (color == null) {
                                      return;
                                    }
                                    _humanColor.value = color;

                                    _startNewGame();
                                  },
                          ),
                      ],
                    ),
                    AppAccordion(
                      title: context.l10n.gameAnnotations,
                      children: [
                        AppTextArea(
                          controller: _gameComment,
                          title: context.l10n.gameComment,
                          maxLines: 4,
                        ),
                        const SizedBox(height: spacing12),
                        SizedBox(
                          width: 220,
                          child: AppTextField(
                            controller: _markerLabel,
                            title: context.l10n.markerLabel,
                            validator: (value) => _isValidMarkerLabel(value)
                                ? null
                                : context.l10n.invalidMarkerLabel,
                            autovalidateMode:
                                AutovalidateMode.onUserInteraction,
                          ),
                        ),
                        const SizedBox(height: spacing8),
                        AppAccordionText(context.l10n.markerInstructions),
                        const SizedBox(height: spacing8),
                        Wrap(
                          alignment: WrapAlignment.center,
                          spacing: 12,
                          runSpacing: 8,
                          children: [
                            if (markingEnabled)
                              AppButtonPrimary(
                                onPressed: () => _markingEnabled.value = false,
                                text: context.l10n.disableMarkers,
                              )
                            else
                              AppButtonSecondary(
                                onPressed:
                                    !_isValidMarkerLabel(_markerLabel.text)
                                    ? null
                                    : () => _markingEnabled.value = true,
                                text: context.l10n.enableMarkers,
                              ),
                          ],
                        ),
                        const SizedBox(height: spacing12),
                      ],
                    ),
                    AppAccordion(
                      title: context.l10n.gameRecord,
                      children: [
                        Wrap(
                          alignment: WrapAlignment.center,
                          spacing: 16,
                          runSpacing: 12,
                          children: [
                            SizedBox(
                              width: 180,
                              child: AppTextField(
                                controller: _blackPlayer,
                                title: context.l10n.blackPlayer,
                              ),
                            ),
                            SizedBox(
                              width: 180,
                              child: AppTextField(
                                controller: _whitePlayer,
                                title: context.l10n.whitePlayer,
                              ),
                            ),
                            SizedBox(
                              width: 180,
                              child: AppTextField(
                                controller: _gameName,
                                title: context.l10n.gameNameOptional,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: spacing12),
                        AppButtonSecondary(
                          onPressed: busy ? null : _exportSgf,
                          leftIcon: Icons.save_alt,
                          text: busy
                              ? context.l10n.exporting
                              : context.l10n.exportSgf,
                        ),
                        if (recordMessage != null)
                          Padding(
                            padding: const EdgeInsets.only(top: spacing8),
                            child: Text(
                              recordMessage,
                              textAlign: TextAlign.center,
                            ),
                          ),
                        const SizedBox(height: spacing12),
                      ],
                    ),
                    ],
                  ),
                ),
              ),
            ),
          ),
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
