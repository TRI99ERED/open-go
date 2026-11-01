import 'package:flutter/material.dart';
import 'package:opengo/src/core/game/sgf.dart';
import 'package:opengo/src/core/localization/localization.dart';
import 'package:opengo/src/core/game/go_position.dart';
import 'package:opengo/src/core/widgets/controller_consumer.dart';
import 'package:opengo/src/features/app/app_scope.dart';
import 'package:opengo/src/features/themes/app_theme.dart';
import 'package:opengo/src/features/themes/styles.dart';
import 'package:opengo/src/router/app_navigator.dart';
import 'package:opengo/src/router/app_page.dart';
import 'package:opengo/src/widgets/common/app_nav_bar.dart';
import 'package:opengo/src/widgets/go_board.dart';

class TsumegosScreen extends StatefulWidget {
  const TsumegosScreen({super.key});

  @override
  State<TsumegosScreen> createState() => _TsumegosScreenState();
}

class _TsumegosScreenState extends State<TsumegosScreen> {
  bool _hasLoadedTsumegos = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_hasLoadedTsumegos) {
      _hasLoadedTsumegos = true;
      context.appController.loadTsumegos();
    }
  }

  Future<void> _refresh() async {
    await context.appController.loadTsumegos();
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
    return context.l10n.problemNumber(index + 1);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppNavBar(
        title: context.l10n.tsumegos,
        leftIcon: Icons.arrow_back_ios_new,
        onPressedLeft: () => Navigator.of(context).pop(),
        rightIcon: Icons.folder_open,
        onPressedRight: () => context.appController.importTsumegos(
          dialogTitle: context.l10n.importTsumegoSgf,
        ),
      ),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _refresh,
          color: Theme.of(context).extension<AppTheme>()?.highlightDarkestColor,
          backgroundColor: Theme.of(context)
              .extension<AppTheme>()
              ?.backgroundStrongestColor,
          child: ControllerConsumer(
            controller: context.appController,
            listenWhen: (previous, current) =>
                previous.isProcessing != current.isProcessing,
            listener: (context, previous, current) {},
            builder: (context, current) {
              final tsumegos = context.appState.tsumegos;
              return LayoutBuilder(
                builder: (context, constraints) {
                  final crossAxisCount = constraints.maxWidth < 600
                      ? 1
                      : constraints.maxWidth < 1000
                      ? 3
                      : 5;
                  return GridView.builder(
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: crossAxisCount,
                    ),
                    padding: EdgeInsets.all(spacing40),
                    itemCount: tsumegos.games.length,
                    itemBuilder: (context, i) {
                      final position = positionAtPath(tsumegos.games[i], []);
                      return Center(
                        child: TextButton(
                          style: TextButton.styleFrom(
                            foregroundColor: Theme.of(context)
                                .extension<AppTheme>()!
                                .foregroundStrongestColor,
                            shape: ContinuousRectangleBorder(),
                          ),
                          onPressed: () {
                            AppNavigator.of(context)
                                .push(TsumegoPage(index: i));
                          },
                          child: Column(
                            children: [
                              SizedBox(height: spacing16),
                              SizedBox(
                                height: bSSize * 3,
                                child: Text(
                                  _problemLabel(tsumegos.games[i], i),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontSize: bSSize,
                                    fontWeight: bSWeight,
                                    color: Theme.of(context)
                                        .extension<AppTheme>()!
                                        .foregroundStrongestColor,
                                  ),
                                ),
                              ),
                              SizedBox(height: spacing8),
                              Expanded(
                                child: Center(
                                  child: ConstrainedBox(
                                    constraints: BoxConstraints(maxHeight: 400),
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
                              ),
                              SizedBox(height: spacing16),
                            ],
                          ),
                        ),
                      );
                    },
                  );
                },
              );
            },
          ),
        ),
      ),
    );
  }
}
