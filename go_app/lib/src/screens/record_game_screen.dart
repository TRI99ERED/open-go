import 'dart:convert';
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

import '../game/go_position.dart';
import '../game/sgf.dart';
import '../widgets/go_board.dart';

class RecordGameScreen extends StatefulWidget {
  const RecordGameScreen({super.key});

  @override
  State<RecordGameScreen> createState() => _RecordGameScreenState();
}

class _RecordGameScreenState extends State<RecordGameScreen> {
  static const _sizes = [9, 13, 19];
  int _size = 19;
  GoPosition _position = GoPosition.empty(19);
  final List<SgfNode> _moveNodes = [];
  final _blackPlayer = TextEditingController(text: 'Black');
  final _whitePlayer = TextEditingController(text: 'White');
  final _gameName = TextEditingController();
  String? _message;
  bool _busy = false;

  @override
  void dispose() {
    _blackPlayer.dispose();
    _whitePlayer.dispose();
    _gameName.dispose();
    super.dispose();
  }

  void _newGame() {
    _gameRoot.children.clear();
    _moveNodes.clear();
    setState(() {
      _position = GoPosition.empty(_size);
      _message = null;
    });
  }

  SgfNode get _root => SgfNode(
    properties: {
      'GM': ['1'],
      'FF': ['4'],
      'CA': ['UTF-8'],
      'AP': ['OpenGo:0.1.0'],
      'SZ': ['$_size'],
      'DT': [DateTime.now().toIso8601String().substring(0, 10)],
      'KM': ['7.5'],
      'PB': [_blackPlayer.text.trim()],
      'PW': [_whitePlayer.text.trim()],
      if (_gameName.text.trim().isNotEmpty) 'GN': [_gameName.text.trim()],
    },
  );

  late final SgfNode _gameRoot = _root;

  void _play(int point) {
    try {
      final nextPosition = _position.play(point, _position.toMove);
      final colorProperty = _position.toMove == 1 ? 'B' : 'W';
      final node = SgfNode(
        properties: {
          colorProperty: [_position.sgfCoordinate(point)],
        },
      );
      final parent = _moveNodes.isEmpty ? _gameRoot : _moveNodes.last;
      parent.children.add(node);
      _moveNodes.add(node);
      setState(() {
        _position = nextPosition;
        _message = null;
      });
    } on StateError catch (error) {
      setState(() => _message = error.message);
    }
  }

  void _pass() {
    final colorProperty = _position.toMove == 1 ? 'B' : 'W';
    final node = SgfNode(
      properties: {
        colorProperty: [''],
      },
    );
    final parent = _moveNodes.isEmpty ? _gameRoot : _moveNodes.last;
    parent.children.add(node);
    _moveNodes.add(node);
    setState(() {
      _position = _position.apply(node);
      _message = '${_colorName(3 - _position.toMove)} passed';
    });
  }

  void _undo() {
    if (_moveNodes.isEmpty) return;
    final node = _moveNodes.removeLast();
    final parent = _moveNodes.isEmpty ? _gameRoot : _moveNodes.last;
    parent.children.remove(node);
    var position = GoPosition.empty(_size);
    for (final move in _moveNodes) {
      position = position.apply(move);
    }
    setState(() {
      _position = position;
      _message = null;
    });
  }

  Future<void> _exportSgf() async {
    setState(() => _busy = true);
    try {
      _gameRoot
        ..setValue('SZ', '$_size')
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
      setState(
        () => _message = uri == null ? 'Export cancelled' : 'Saved SGF to $uri',
      );
    } catch (error) {
      if (mounted) setState(() => _message = 'Could not export SGF: $error');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  String _safeFilename(String value) {
    final normalized = value.trim().replaceAll(RegExp(r'[<>:"/\\|?*]'), '_');
    return normalized.isEmpty ? 'opengo-game' : normalized;
  }

  String _colorName(int color) => color == 1 ? 'Black' : 'White';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Record a Game')),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 820),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                Wrap(
                  alignment: WrapAlignment.center,
                  spacing: 16,
                  runSpacing: 12,
                  children: [
                    SizedBox(
                      width: 130,
                      child: DropdownButtonFormField<int>(
                        initialValue: _size,
                        decoration: const InputDecoration(labelText: 'Board'),
                        items: [
                          for (final size in _sizes)
                            DropdownMenuItem(
                              value: size,
                              child: Text('$size×$size'),
                            ),
                        ],
                        onChanged: _busy
                            ? null
                            : (size) {
                                if (size == null) return;
                                setState(() => _size = size);
                                _newGame();
                              },
                      ),
                    ),
                    SizedBox(
                      width: 180,
                      child: TextField(
                        controller: _blackPlayer,
                        decoration: const InputDecoration(
                          labelText: 'Black player',
                        ),
                      ),
                    ),
                    SizedBox(
                      width: 180,
                      child: TextField(
                        controller: _whitePlayer,
                        decoration: const InputDecoration(
                          labelText: 'White player',
                        ),
                      ),
                    ),
                    SizedBox(
                      width: 180,
                      child: TextField(
                        controller: _gameName,
                        decoration: const InputDecoration(
                          labelText: 'Game name (optional)',
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text('${_colorName(_position.toMove)} to play'),
                if (_message != null) ...[
                  const SizedBox(height: 8),
                  Text(_message!, textAlign: TextAlign.center),
                ],
                const SizedBox(height: 16),
                Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 680),
                    child: AspectRatio(
                      aspectRatio: 1,
                      child: GoBoard(
                        boardSize: _size,
                        stones: _position.stones,
                        lastMove: _position.lastMove,
                        onPlay: _busy ? null : _play,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Wrap(
                  alignment: WrapAlignment.center,
                  spacing: 12,
                  runSpacing: 8,
                  children: [
                    FilledButton.icon(
                      onPressed: _busy ? null : _pass,
                      icon: const Icon(Icons.skip_next),
                      label: const Text('Pass'),
                    ),
                    OutlinedButton.icon(
                      onPressed: _moveNodes.isEmpty || _busy ? null : _undo,
                      icon: const Icon(Icons.undo),
                      label: const Text('Undo'),
                    ),
                    OutlinedButton.icon(
                      onPressed: _busy ? null : _newGame,
                      icon: const Icon(Icons.refresh),
                      label: const Text('New game'),
                    ),
                    FilledButton.icon(
                      onPressed: _busy ? null : _exportSgf,
                      icon: const Icon(Icons.save_alt),
                      label: Text(_busy ? 'Exporting…' : 'Export SGF'),
                    ),
                  ],
                ),
                const Padding(
                  padding: EdgeInsets.only(top: 14),
                  child: Text(
                    'Tap each played intersection to record a game on this device.',
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
