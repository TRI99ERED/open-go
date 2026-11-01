import 'package:flutter/material.dart';
import 'package:opengo/src/core/localization/localization.dart';
import 'package:opengo/src/features/themes/app_theme.dart';
import 'package:opengo/src/features/themes/styles.dart';
import 'package:opengo/src/router/app_navigator.dart';
import 'package:opengo/src/router/app_page.dart';
import 'package:opengo/src/widgets/common/app_button.dart';
import 'package:opengo/src/widgets/common/app_drawer.dart';
import 'package:opengo/src/widgets/common/app_list_item.dart';
import 'package:opengo/src/widgets/common/app_list_title.dart';
import 'package:opengo/src/widgets/common/app_nav_bar.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(kToolbarHeight),
        child: Builder(
          builder: (context) {
            return AppNavBar(
              title: context.l10n.home,
              leftIcon: Icons.menu,
              onPressedLeft: () {
                Scaffold.of(context).openDrawer();
              },
            );
          },
        ),
      ),
      drawer: AppDrawer(
        child: SafeArea(
          child: Column(
            children: [
              AppListTitle(title: '${context.l10n.openGo} v0.1.1'),
              SizedBox(height: spacing8),
              AppListItem(
                title: context.l10n.play,
                icon: Icons.sports_esports,
                onPressed: () {
                  Navigator.of(context).pop();
                  AppNavigator.of(context).push(GamePage());
                },
              ),
              SizedBox(height: spacing8),
              AppListItem(
                title: context.l10n.solve,
                icon: Icons.extension,
                onPressed: () {
                  Navigator.of(context).pop();
                  AppNavigator.of(context).push(const TsumegosPage());
                },
              ),
              SizedBox(height: spacing8),
              AppListItem(
                title: context.l10n.review,
                icon: Icons.menu_book,
                onPressed: () {
                  Navigator.of(context).pop();
                  AppNavigator.of(context).push(const ReviewPage());
                },
              ),
              const Spacer(),
              AppListItem(
                title: context.l10n.settings,
                icon: Icons.settings,
                onPressed: () {
                  Navigator.of(context).pop();
                  AppNavigator.of(context).push(const SettingsPage());
                },
              ),
              SizedBox(height: spacing8),
            ],
          ),
        ),
      ),
      body: SafeArea(
        left: false,
        right: false,
        child: LayoutBuilder(
          builder: (context, constraints) {
            final imageSize = constraints.biggest.shortestSide.clamp(
              0.0,
              1017.0,
            );
            return ListView(
              padding: EdgeInsets.zero,
              children: [
                Center(
                  child: Image.asset(
                    'assets/images/Open-Go.png',
                    width: imageSize,
                    height: imageSize,
                    fit: BoxFit.contain,
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(spacing24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        context.l10n.playGoYourWay,
                        style: TextStyle(
                          fontSize: h1Size,
                          fontWeight: h1Weight,
                          color: Theme.of(context)
                              .extension<AppTheme>()
                              ?.foregroundStrongestColor,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: spacing8),
                      Text(
                        context.l10n.homeDescription,
                        style: TextStyle(
                          fontSize: h5Size,
                          fontWeight: h5Weight,
                          color: Theme.of(context)
                              .extension<AppTheme>()
                              ?.foregroundWeakColor,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: spacing24),
                      AppButtonPrimary(
                        leftIcon: Icons.sports_esports,
                        text: context.l10n.play,
                        onPressed: () {
                          AppNavigator.of(context).push(GamePage());
                        },
                      ),
                      const SizedBox(height: spacing8),
                      AppButtonSecondary(
                        leftIcon: Icons.extension,
                        text: context.l10n.solve,
                        onPressed: () {
                          AppNavigator.of(context).push(TsumegosPage());
                        },
                      ),
                      const SizedBox(height: spacing8),
                      AppButtonSecondary(
                        leftIcon: Icons.menu_book,
                        text: context.l10n.review,
                        onPressed: () {
                          AppNavigator.of(context).push(ReviewPage());
                        },
                      ),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
