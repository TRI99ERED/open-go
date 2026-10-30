import 'dart:async';
import 'dart:convert';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

import '../game/go_position.dart';
import '../game/sgf.dart';
import '../widgets/go_board.dart';

class SgfReviewScreen extends StatefulWidget {
  const SgfReviewScreen({super.key});

  @override
  State<SgfReviewScreen> createState() => _SgfReviewScreenState();
}

class _SgfReviewScreenState extends State<SgfReviewScreen> {
  SgfCollection? _collection;
  int _gameIndex = 0;
  List<int> _path = [];
  Timer? _playback;
  String? _sourceName;
  String? _error;

  SgfNode? get _root {
    final collection = _collection;
    if (collection == null) return null;
    return collection.games[_gameIndex];
  }

  SgfNode? get _currentNode {
    final root = _root;
    if (root == null) return null;
    var node = root;
    for (final branch in _path) {
      if (branch >= node.children.length) return null;
      node = node.children[branch];
    }
    return node;
  }

  GoPosition? get _position {
    final root = _root;
    if (root == null) return null;
    return positionAtPath(root, _path);
  }

  @override
  void dispose() {
    _playback?.cancel();
    super.dispose();
  }

  Future<void> _openSgf() async {
    try {
      final file = await FilePicker.pickFile(
        dialogTitle: 'Open SGF game record',
        type: FileType.custom,
        allowedExtensions: const ['sgf'],
      );
      if (file == null) return;
      final source = utf8.decode(await file.readAsBytes());
      final collection = SgfCollection.parse(source);
      setState(() {
        _collection = collection;
        _gameIndex = 0;
        _path = [];
        _sourceName = file.name;
        _error = null;
      });
    } catch (error) {
      if (mounted) setState(() => _error = 'Could not open SGF: $error');
    }
  }

  Future<void> _advance({bool chooseVariation = true}) async {
    final node = _currentNode;
    if (node == null || node.children.isEmpty) return;
    var branch = 0;
    if (chooseVariation && node.children.length > 1) {
      final selected = await showModalBottomSheet<int>(
        context: context,
        builder: (context) => SafeArea(
          child: ListView(
            shrinkWrap: true,
            children: [
              for (var index = 0; index < node.children.length; index++)
                ListTile(
                  leading: const Icon(Icons.alt_route),
                  title: Text(_variationLabel(node.children[index])),
                  subtitle: Text('Variation ${index + 1}'),
                  onTap: () => Navigator.pop(context, index),
                ),
            ],
          ),
        ),
      );
      if (selected == null) return;
      branch = selected;
    }
    setState(() => _path = [..._path, branch]);
  }

  String _variationLabel(SgfNode node) {
    final color = node.firstValue('B') != null
        ? 'Black'
        : node.firstValue('W') != null
        ? 'White'
        : 'Setup';
    final value = node.firstValue('B') ?? node.firstValue('W');
    if (value == null) return color;
    if (value.isEmpty) return '$color passes';
    final size = int.tryParse(_root?.firstValue('SZ') ?? '19') ?? 19;
    final point = GoPosition.empty(size).pointFromSgf(value);
    if (point == null) return '$color passes';
    final row = point ~/ size;
    final column = point % size;
    return '$color ${goColumnLabels[column]}${size - row}';
  }

  void _previous() {
    if (_path.isEmpty) return;
    setState(() => _path = _path.sublist(0, _path.length - 1));
  }

  void _selectGame(int? index) {
    if (index == null) return;
    _playback?.cancel();
    setState(() {
      _gameIndex = index;
      _path = [];
    });
  }

  void _togglePlayback() {
    if (_playback != null) {
      _playback!.cancel();
      _playback = null;
      setState(() {});
      return;
    }
    _playback = Timer.periodic(const Duration(seconds: 1), (_) {
      final node = _currentNode;
      if (!mounted || node == null || node.children.isEmpty) {
        _playback?.cancel();
        _playback = null;
        if (mounted) setState(() {});
        return;
      }
      setState(() => _path = [..._path, 0]);
    });
    setState(() {});
  }

  int _mainLineLength(SgfNode node) {
    var count = 0;
    var current = node;
    while (current.children.isNotEmpty) {
      current = current.children.first;
      count++;
    }
    return count;
  }

  @override
  Widget build(BuildContext context) {
    final root = _root;
    final position = _position;
    final comment = _currentNode?.firstValue('C');
    return Scaffold(
      appBar: AppBar(
        title: const Text('Review SGF'),
        actions: [
          IconButton(
            tooltip: 'Open SGF',
            onPressed: _openSgf,
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
                if (_collection == null)
                  const Padding(
                    padding: EdgeInsets.all(24),
                    child: Text(
                      'Open an SGF file to review its game, comments, and variations.',
                      textAlign: TextAlign.center,
                    ),
                  )
                else ...[
                  if (_collection!.games.length > 1)
                    DropdownButton<int>(
                      value: _gameIndex,
                      items: [
                        for (
                          var index = 0;
                          index < _collection!.games.length;
                          index++
                        )
                          DropdownMenuItem(
                            value: index,
                            child: Text('Game ${index + 1}'),
                          ),
                      ],
                      onChanged: _selectGame,
                    ),
                  if (_sourceName != null) Text(_sourceName!),
                  if (root != null) _metadata(root),
                  if (position != null) ...[
                    const SizedBox(height: 8),
                    Text(
                      'Move ${_path.length} / ${_mainLineLength(root!)}'
                      '${position.toMove == 1 ? ' · Black to play' : ' · White to play'}',
                    ),
                    const SizedBox(height: 16),
                    Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 680),
                        child: AspectRatio(
                          aspectRatio: 1,
                          child: GoBoard(
                            boardSize: position.size,
                            stones: position.stones,
                            lastMove: position.lastMove,
                          ),
                        ),
                      ),
                    ),
                    if (comment != null && comment.isNotEmpty)
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Icon(Icons.comment),
                              const SizedBox(width: 8),
                              Expanded(child: Text(comment)),
                            ],
                          ),
                        ),
                      ),
                    Wrap(
                      alignment: WrapAlignment.center,
                      spacing: 12,
                      children: [
                        IconButton(
                          tooltip: 'Previous move',
                          onPressed: _path.isEmpty ? null : _previous,
                          icon: const Icon(Icons.skip_previous),
                        ),
                        IconButton(
                          tooltip: _playback == null ? 'Play' : 'Pause',
                          onPressed: _togglePlayback,
                          icon: Icon(
                            _playback == null ? Icons.play_arrow : Icons.pause,
                          ),
                        ),
                        IconButton(
                          tooltip: 'Next move / choose variation',
                          onPressed: _currentNode?.children.isEmpty ?? true
                              ? null
                              : _advance,
                          icon: const Icon(Icons.skip_next),
                        ),
                      ],
                    ),
                  ],
                ],
                if (_error != null) ...[
                  const SizedBox(height: 8),
                  Text(
                    _error!,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.error,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _metadata(SgfNode root) {
    const properties = {
      'GN': 'Game',
      'PB': 'Black',
      'PW': 'White',
      'DT': 'Date',
      'RE': 'Result',
      'KM': 'Komi',
      'RU': 'Rules',
      'EV': 'Event',
    };
    final entries = [
      for (final entry in properties.entries)
        if (root.firstValue(entry.key) case final value? when value.isNotEmpty)
          '${entry.value}: $value',
      'Board: ${root.firstValue('SZ') ?? '19'}×${root.firstValue('SZ') ?? '19'}',
    ];
    return Text(entries.join('  ·  '), textAlign: TextAlign.center);
  }
}
