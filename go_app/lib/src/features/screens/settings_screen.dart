import 'package:flutter/material.dart';
import 'package:opengo/src/core/widgets/controller_listener.dart';
import 'package:opengo/src/features/app/app_scope.dart';
import 'package:opengo/src/features/themes/app_theme.dart';
import 'package:opengo/src/features/themes/styles.dart';
import 'package:opengo/src/router/app_navigator.dart';
import 'package:opengo/src/widgets/common/app_accordion.dart';
import 'package:opengo/src/widgets/common/app_list_title.dart';
import 'package:opengo/src/widgets/common/app_nav_bar.dart';
import 'package:opengo/src/widgets/common/app_radio_button.dart';

class SettingsScreen extends StatelessWidget {
  const new({super.key});

  @override
  Widget build(BuildContext context) {
    return ControllerListener(
      controller: context.appController,
      listenWhen: (previous, current) {
        if (!previous.isFailed && current.isFailed) {
          return true;
        }
        return false;
      },
      listener: (context, previous, current) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: Theme.of(context)
                .extension<AppTheme>()
                ?.backgroundStrongColor,
            content: Text(
              'Error: ${current.message}',
              style: TextStyle(
                fontSize: cMSize,
                fontWeight: cMWeight,
                color: Theme.of(context)
                    .extension<AppTheme>()
                    ?.foregroundStrongestColor,
              ),
            ),
          ),
        );
      },
      child: Scaffold(
        appBar: AppNavBar(
          title: 'Settings',
          leftIcon: Icons.arrow_back_ios_new,
          onPressedLeft: () {
            AppNavigator.of(context).pop();
          },
        ),
        body: ListView(
          padding: const EdgeInsets.all(spacing16),
          children: [
            AppAccordion(
              title: 'Appearance',
              children: [
                const AppListTitle(title: 'Theme'),
                ValueListenableBuilder(
                  valueListenable: context.themeMode,
                  builder: (context, value, child) {
                    return RadioGroup<ThemeMode>(
                      groupValue: context.themeMode.value,
                      onChanged: (value) {
                        if (value != null) {
                          context.themeMode.value = value;
                        }
                      },
                      child: Column(
                        children: [
                          AppRadioTile(
                            value: ThemeMode.system,
                            title: 'System',
                            onChanged: (value) {
                              context.themeMode.value = value;
                            },
                          ),
                          AppRadioTile(
                            value: ThemeMode.light,
                            title: 'Light',
                            onChanged: (value) {
                              context.themeMode.value = value;
                            },
                          ),
                          AppRadioTile(
                            value: ThemeMode.dark,
                            title: 'Dark',
                            onChanged: (value) {
                              context.themeMode.value = value;
                            },
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
