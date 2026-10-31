import 'dart:async';
import 'dart:convert';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:opengo/src/core/game/go_position.dart';
import 'package:opengo/src/core/localization/localization.dart';
import 'package:opengo/src/core/game/sgf.dart';
import 'package:opengo/src/features/themes/app_theme.dart';
import 'package:opengo/src/widgets/common/app_badge.dart';
import 'package:opengo/src/widgets/common/app_dropdown.dart';
import 'package:opengo/src/widgets/common/app_nav_bar.dart';
import 'package:opengo/src/widgets/common/empty_state.dart';
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
        dialogTitle: context.l10n.openSgfGameRecord,
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
      if (mounted) {
        _error.value = context.l10n.couldNotOpenSgf(error.toString());
      }
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
                  subtitle: Text(context.l10n.variation(index + 1)),
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
        ? context.l10n.black
        : node.firstValue('W') != null
        ? context.l10n.white
        : context.l10n.setup;
    final value = node.firstValue('B') ?? node.firstValue('W');
    if (value == null) return color;
    if (value.isEmpty) return context.l10n.playerPasses(color);
    final size = int.tryParse(_root?.firstValue('SZ') ?? '19') ?? 19;
    final point = GoPosition.empty(size).pointFromSgf(value);
    if (point == null) return context.l10n.playerPasses(color);
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

  Map<int, String> _labelsAtPosition(GoPosition position) {
    final labels = <int, String>{};
    for (final value in _currentNode?.values('LB') ?? const <String>[]) {
      final separator = value.indexOf(':');
      if (separator < 0) continue;
      final point = position.pointFromSgf(value.substring(0, separator));
      final label = value.substring(separator + 1);
      if (point != null && label.isNotEmpty) labels[point] = label;
    }
    return labels;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppNavBar(
        title: context.l10n.reviewSgf,
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
                    EmptyState(
                      title: context.l10n.openSgfGameRecord,
                      body: context.l10n.openSgfReviewDescription,
                      buttonText: context.l10n.openSgfGameRecord,
                      onButtonPressed: _openSgf,
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
                              label: context.l10n.gameNumber(index + 1),
                            ),
                        ],
                        onSelected: (v) => _selectGame(v.$2),
                      ),
                    if (sourceName != null) Text(sourceName),
                    if (root != null) _metadata(root),
                    if (position != null) ...[
                      const SizedBox(height: 8),
                      Text(
                        context.l10n.moveProgress(
                          path.length,
                          _mainLineLength(root!),
                          position.toMove == 1
                              ? context.l10n.black
                              : context.l10n.white,
                        ),
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
                              labels: _labelsAtPosition(position),
                            ),
                          ),
                        ),
                      ),
                      Wrap(
                        alignment: WrapAlignment.center,
                        spacing: 12,
                        children: [
                          IconButton(
                            tooltip: context.l10n.previousMove,
                            onPressed: path.isEmpty ? null : _previous,
                            style: IconButton.styleFrom(
                              foregroundColor: Theme.of(context)
                                  .extension<AppTheme>()!
                                  .foregroundMediumColor,
                            ),
                            icon: const Icon(Icons.skip_previous),
                          ),
                          IconButton(
                            tooltip: playback == null
                                ? context.l10n.play
                                : context.l10n.pause,
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
                            tooltip: context.l10n.nextMoveChooseVariation,
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
    final l10n = context.l10n;
    final properties = {
      'GN': l10n.game,
      'PB': l10n.black,
      'PW': l10n.white,
      'DT': l10n.date,
      'RE': l10n.result,
      'KM': l10n.komi,
      'RU': l10n.rules,
      'EV': l10n.event,
    };
    final entries = [
      for (final entry in properties.entries)
        if (root.firstValue(entry.key) case final value? when value.isNotEmpty)
          '${entry.value}: $value',
      l10n.boardSize(int.tryParse(root.firstValue('SZ') ?? '19') ?? 19),
    ];
    return Text(entries.join('  ·  '), textAlign: TextAlign.center);
  }
}
