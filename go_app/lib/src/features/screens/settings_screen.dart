import 'package:flutter/material.dart';
import 'package:opengo/src/core/localization/localization.dart';
import 'package:opengo/src/core/widgets/controller_listener.dart';
import 'package:opengo/src/features/app/app_scope.dart';
import 'package:opengo/src/features/themes/app_theme.dart';
import 'package:opengo/src/features/themes/styles.dart';
import 'package:opengo/src/router/app_navigator.dart';
import 'package:opengo/src/widgets/common/app_accordion.dart';
import 'package:opengo/src/widgets/common/app_checkbox.dart';
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
        final message = switch (current.message) {
          'Could not load tsumegos' => context.l10n.failedToLoadProblems,
          'Could not import tsumegos' => context.l10n.couldNotImportProblems,
          _ => current.message,
        };
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: Theme.of(context)
                .extension<AppTheme>()
                ?.backgroundStrongColor,
            content: Text(
              context.l10n.errorWithMessage(message),
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
          title: context.l10n.settings,
          leftIcon: Icons.arrow_back_ios_new,
          onPressedLeft: () {
            AppNavigator.of(context).pop();
          },
        ),
        body: ListView(
          padding: const EdgeInsets.all(spacing16),
          children: [
            AppAccordion(
              title: context.l10n.appearance,
              children: [
                AppListTitle(title: context.l10n.theme),
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
                            title: context.l10n.system,
                            onChanged: (value) {
                              context.themeMode.value = value;
                            },
                          ),
                          AppRadioTile(
                            value: ThemeMode.light,
                            title: context.l10n.light,
                            onChanged: (value) {
                              context.themeMode.value = value;
                            },
                          ),
                          AppRadioTile(
                            value: ThemeMode.dark,
                            title: context.l10n.dark,
                            onChanged: (value) {
                              context.themeMode.value = value;
                            },
                          ),
                        ],
                      ),
                    );
                  },
                ),
                ValueListenableBuilder<bool>(
                  valueListenable: context.fullscreenMode,
                  builder: (context, value, child) {
                    return AppCheckboxTile(
                      value: value,
                      title: context.l10n.fullscreen,
                      onChanged: (value) async {
                        if (value == null) return;
                        try {
                          await context.setFullscreenMode(value);
                        } catch (error) {
                          if (!context.mounted) return;
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                context.l10n.unableToChangeFullscreen(
                                  error.toString(),
                                ),
                              ),
                            ),
                          );
                        }
                      },
                    );
                  },
                ),
              ],
            ),
            AppAccordion(
              title: context.l10n.language,
              children: [
                ValueListenableBuilder<Locale?>(
                  valueListenable: context.locale,
                  builder: (context, value, child) {
                    return RadioGroup<Locale?>(
                      groupValue: value,
                      onChanged: (locale) {
                        context.locale.value = locale;
                      },
                      child: Column(
                        children: [
                          AppRadioTile<Locale?>(
                            value: null,
                            title: context.l10n.languageSystem,
                            onChanged: (locale) {
                              context.locale.value = locale;
                            },
                          ),
                          AppRadioTile<Locale?>(
                            value: const Locale('en'),
                            title: context.l10n.languageEnglish,
                            onChanged: (locale) {
                              context.locale.value = locale;
                            },
                          ),
                          AppRadioTile<Locale?>(
                            value: const Locale('uk'),
                            title: context.l10n.languageUkrainian,
                            onChanged: (locale) {
                              context.locale.value = locale;
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
