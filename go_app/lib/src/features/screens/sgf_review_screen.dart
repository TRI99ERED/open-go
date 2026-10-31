import 'dart:async';
import 'dart:convert';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:opengo/src/core/game/go_position.dart';
import 'package:opengo/src/core/game/sgf.dart';
import 'package:opengo/src/features/themes/app_theme.dart';
import 'package:opengo/src/widgets/common/app_badge.dart';
import 'package:opengo/src/widgets/common/app_dropdown.dart';
import 'package:opengo/src/widgets/common/app_nav_bar.dart';
import 'package:opengo/src/widgets/go_board.dart';

class SgfReviewScreen extends StatefulWidget {
  const SgfReviewScreen({super.key});

  @override
  State<SgfReviewScreen> createState() => _SgfReviewScreenState();
}

class _SgfReviewScreenState extends State<SgfReviewScreen> {
  final _collection = ValueNotifier<SgfCollection?>(null);
  final _gameIndex = ValueNotifier(0);
  final _path = ValueNotifier<List<int>>([]);
  final _playback = ValueNotifier<Timer?>(null);
  final _sourceName = ValueNotifier<String?>(null);
  final _error = ValueNotifier<String?>(null);

  SgfNode? get _root {
    final collection = _collection;
    if (collection.value == null) return null;
    return collection.value!.games[_gameIndex.value];
  }

  SgfNode? get _currentNode {
    final root = _root;
    if (root == null) return null;
    var node = root;
    for (final branch in _path.value) {
      if (branch >= node.children.length) return null;
      node = node.children[branch];
    }
    return node;
  }

  GoPosition? get _position {
    final root = _root;
    if (root == null) return null;
    return positionAtPath(root, _path.value);
  }

  @override
  void dispose() {
    _playback.value?.cancel();
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

      _collection.value = collection;
      _gameIndex.value = 0;
      _path.value = [];
      _sourceName.value = file.name;
      _error.value = null;
    } catch (error) {
      if (mounted) _error.value = 'Could not open SGF: $error';
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
    _path.value = [..._path.value, branch];
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
    if (_path.value.isEmpty) return;
    _path.value = _path.value.sublist(0, _path.value.length - 1);
  }

  void _selectGame(int? index) {
    if (index == null) return;
    _playback.value?.cancel();

    _gameIndex.value = index;
    _path.value = [];
  }

  void _togglePlayback() {
    if (_playback.value != null) {
      _playback.value!.cancel();
      _playback.value = null;
      setState(() {});
      return;
    }
    _playback.value = Timer.periodic(const Duration(seconds: 1), (_) {
      final node = _currentNode;
      if (!mounted || node == null || node.children.isEmpty) {
        _playback.value?.cancel();
        _playback.value = null;
        return;
      }
      _path.value = [..._path.value, 0];
    });
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
    return Scaffold(
      appBar: AppNavBar(
        title: 'Review SGF',
        rightIcon: Icons.folder_open,
        onPressedRight: _openSgf,
        leftIcon: Icons.arrow_back_ios_new,
        onPressedLeft: () => Navigator.of(context).pop(),
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: AnimatedBuilder(
            animation: Listenable.merge([
              _collection,
              _gameIndex,
              _sourceName,
              _path,
              _playback,
              _error,
            ]),
            builder: (context, child) {
              final collection = _collection.value;
              final gameIndex = _gameIndex.value;
              final sourceName = _sourceName.value;
              final path = _path.value;
              final playback = _playback.value;
              final error = _error.value;
              final root = _root;
              final position = _position;
              final comment = _currentNode?.firstValue('C');

              return Column(
                children: [
                  if (collection == null)
                    const Padding(
                      padding: EdgeInsets.all(24),
                      child: Text(
                        'Open an SGF file to review its game, comments, and variations.',
                        textAlign: TextAlign.center,
                      ),
                    )
                  else ...[
                    if (collection.games.length > 1)
                      AppDropdown(
                        selectedIndex: gameIndex,
                        items: [
                          for (
                            var index = 0;
                            index < collection.games.length;
                            index++
                          )
                            DropdownMenuEntry(
                              value: '$index',
                              label: 'Game ${index + 1}',
                            ),
                        ],
                        onSelected: (v) => _selectGame(v.$2),
                      ),
                    if (sourceName != null) Text(sourceName),
                    if (root != null) _metadata(root),
                    if (position != null) ...[
                      const SizedBox(height: 8),
                      Text(
                        'Move ${path.length} / ${_mainLineLength(root!)}'
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
                      Wrap(
                        alignment: WrapAlignment.center,
                        spacing: 12,
                        children: [
                          IconButton(
                            tooltip: 'Previous move',
                            onPressed: path.isEmpty ? null : _previous,
                            style: IconButton.styleFrom(
                              foregroundColor: Theme.of(context)
                                  .extension<AppTheme>()!
                                  .foregroundMediumColor,
                            ),
                            icon: const Icon(Icons.skip_previous),
                          ),
                          IconButton(
                            tooltip: playback == null ? 'Play' : 'Pause',
                            onPressed: _togglePlayback,
                            style: IconButton.styleFrom(
                              foregroundColor: Theme.of(context)
                                  .extension<AppTheme>()!
                                  .foregroundStrongestColor,
                            ),
                            icon: Icon(
                              playback == null ? Icons.play_arrow : Icons.pause,
                            ),
                          ),
                          IconButton(
                            tooltip: 'Next move / choose variation',
                            onPressed: _currentNode?.children.isEmpty ?? true
                                ? null
                                : _advance,
                            style: IconButton.styleFrom(
                              foregroundColor: Theme.of(context)
                                  .extension<AppTheme>()!
                                  .foregroundMediumColor,
                            ),
                            icon: const Icon(Icons.skip_next),
                          ),
                        ],
                      ),
                      if (comment != null && comment.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.all(12),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const AppBadgeIcon(icon: Icons.comment),
                              const SizedBox(width: 8),
                              Expanded(child: Text(comment)),
                            ],
                          ),
                        ),
                    ],
                  ],
                  if (error != null) ...[
                    const SizedBox(height: 8),
                    Text(
                      error,
                      style: TextStyle(
                        color: Theme.of(context)
                            .extension<AppTheme>()!
                            .errorDarkColor,
                      ),
                    ),
                  ],
                ],
              );
            },
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
