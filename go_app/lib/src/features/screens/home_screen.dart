import 'package:flutter/material.dart';
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
  const new({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(kToolbarHeight),
        child: Builder(
          builder: (context) {
            return AppNavBar(
              title: 'Home',
              leftIcon: Icons.menu,
              onPressedLeft: () {
                Scaffold.of(context).openDrawer();
              },
            );
          },
        ),
      ),
      drawer: AppDrawer(
        child: ListView(
          children: [
            const AppListTitle(title: 'OpenGo'),
            AppListItem(
              title: 'Settings',
              icon: Icons.settings,
              onPressed: () {
                Navigator.of(context).pop();
                AppNavigator.of(context).push(const SettingsPage());
              },
            ),
          ],
        ),
      ),
      body: SafeArea(
        child: Center(
          child: ListView(
            padding: const EdgeInsets.all(spacing24),
            children: [
              Text(
                'Play Go your way',
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
                'Play, study problems, review or keep game records.',
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
                text: 'Play',
                onPressed: () {
                  AppNavigator.of(context).push(GamePage());
                },
              ),
              const SizedBox(height: spacing8),
              AppButtonSecondary(
                leftIcon: Icons.extension,
                text: 'Solve',
                onPressed: () {
                  AppNavigator.of(context).push(TsumegosPage());
                },
              ),
              const SizedBox(height: spacing8),
              AppButtonSecondary(
                leftIcon: Icons.menu_book,
                text: 'Review',
                onPressed: () {
                  AppNavigator.of(context).push(ReviewPage());
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
