import 'package:flutter/material.dart';
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppNavBar(
        title: 'Tsumegos',
        leftIcon: Icons.arrow_back_ios_new,
        onPressedLeft: () => Navigator.of(context).pop(),
        rightIcon: Icons.import_export,
        onPressedRight: () => context.appController.importTsumegos(),
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

              return ListView.separated(
                itemCount: tsumegos.games.length,
                separatorBuilder: (_, _) {
                  return SizedBox(height: spacing8);
                },
                itemBuilder: (context, i) {
                  final position = positionAtPath(tsumegos.games[i], []);
                  return Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 400),
                      child: AspectRatio(
                        aspectRatio: 1,
                        child: GoBoard(
                          boardSize: position.size,
                          stones: position.stones,
                          lastMove: position.lastMove,
                          onPlay: (_) {
                            AppNavigator.of(context)
                                .push(TsumegoPage(index: i));
                          },
                        ),
                      ),
                    ),
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
