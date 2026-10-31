import 'package:flutter/material.dart';
import 'package:opengo/src/core/localization/localization.dart';
import 'package:opengo/src/features/themes/app_theme.dart';
import 'package:opengo/src/features/themes/styles.dart';
import 'package:opengo/src/widgets/common/app_accordion.dart';
import 'package:opengo/src/widgets/common/app_button.dart';
import 'package:opengo/src/widgets/common/app_divider.dart';
import 'package:opengo/src/widgets/common/app_nav_bar.dart';
import 'package:opengo/src/widgets/common/app_tag.dart';

enum SortOrder { descending, ascending }

class AppSort extends StatelessWidget {
  final bool showIcon;
  final SortOrder sortOrder;
  final VoidCallback? onPressed;

  const AppSort({
    super.key,
    this.showIcon = true,
    this.sortOrder = SortOrder.descending,
    this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return TextButton(
      style: TextButton.styleFrom(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(
            color:
                Theme.of(context)
                    .extension<AppTheme>()
                    ?.backgroundWeakestColor ??
                const Color(0xC5C6CCFF),
            width: 0.5,
          ),
        ),
      ),
      onPressed: onPressed,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (showIcon)
            Icon(
              Icons.sort,
              size: 12,
              color: Theme.of(context)
                  .extension<AppTheme>()
                  ?.backgroundWeakestColor,
            ),
          if (showIcon) SizedBox(width: spacing8),
          Text(
            'Sort',
            style: TextStyle(
              fontSize: bSSize,
              fontWeight: bSWeight,
              color: Theme.of(context)
                  .extension<AppTheme>()
                  ?.foregroundStrongestColor,
            ),
          ),
          SizedBox(width: spacing12),
          Icon(
            sortOrder == SortOrder.ascending
                ? Icons.arrow_drop_up
                : Icons.arrow_drop_down,
            size: 10,
            color: Theme.of(context)
                .extension<AppTheme>()
                ?.backgroundWeakestColor,
          ),
        ],
      ),
    );
  }
}

class AppSortMenu extends StatefulWidget {
  final ValueNotifier<SortOrder> sortOrder;
  final ValueNotifier<String> sortOption;
  final Map<String, String> sortOptions;
  final String defaultSortOption;

  const AppSortMenu({
    super.key,
    required this.sortOrder,
    required this.sortOption,
    required this.sortOptions,
    required this.defaultSortOption,
  });

  static void show(
    BuildContext context, {
    required ValueNotifier<SortOrder> sortOrder,
    required ValueNotifier<String> sortOption,
    required Map<String, String> sortOptions,
    required String defaultSortOption,
  }) {
    showDialog(
      context: context,
      barrierColor: Colors.transparent,
      builder: (context) {
        return AppSortMenu(
          sortOrder: sortOrder,
          sortOption: sortOption,
          sortOptions: sortOptions,
          defaultSortOption: defaultSortOption,
        );
      },
    );
  }

  @override
  State<AppSortMenu> createState() => _AppSortMenuState();
}

class _AppSortMenuState extends State<AppSortMenu> {
  final ValueNotifier<String> _internalSortOption = ValueNotifier<String>('');
  final ValueNotifier<SortOrder> _internalSortOrder = ValueNotifier<SortOrder>(
    SortOrder.descending,
  );

  @override
  void initState() {
    super.initState();
    _internalSortOption.value = widget.sortOption.value;
    _internalSortOrder.value = widget.sortOrder.value;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppNavBar(
        title: context.l10n.sort,
        leftText: context.l10n.cancel,
        rightText: context.l10n.defaultAction,
        onPressedLeft: () {
          Navigator.of(context).pop();
        },
        onPressedRight: () {
          _internalSortOption.value = widget.defaultSortOption;
          _internalSortOrder.value = SortOrder.descending;
        },
      ),
      body: Container(
        color: Theme.of(context)
            .extension<AppTheme>()
            ?.backgroundStrongestColor,
        padding: const EdgeInsets.symmetric(
          horizontal: spacing16,
          vertical: spacing24,
        ),
        child: Column(
          children: [
            Expanded(
              child: ListView(
                children: [
                  Text(
                    context.l10n.sortOrder,
                    style: TextStyle(
                      fontSize: bMSize,
                      fontWeight: bMWeight,
                      color: Theme.of(context)
                          .extension<AppTheme>()
                          ?.foregroundStrongestColor,
                    ),
                  ),
                  const SizedBox(height: spacing8),
                  ValueListenableBuilder(
                    valueListenable: _internalSortOrder,
                    builder: (context, value, child) {
                      return Wrap(
                        spacing: spacing8,
                        runSpacing: spacing8,
                        children: [
                          AppTag(
                            text: context.l10n.descending,
                            isSelected:
                                _internalSortOrder.value ==
                                SortOrder.descending,
                            onChanged: (value) {
                              if (value) {
                                _internalSortOrder.value = SortOrder.descending;
                              }
                            },
                          ),
                          AppTag(
                            text: context.l10n.ascending,
                            isSelected:
                                _internalSortOrder.value == SortOrder.ascending,
                            onChanged: (value) {
                              if (value) {
                                _internalSortOrder.value = SortOrder.ascending;
                              }
                            },
                          ),
                        ],
                      );
                    },
                  ),
                  const AppDivider(),
                  const SizedBox(height: spacing16),
                  ValueListenableBuilder(
                    valueListenable: _internalSortOption,
                    builder: (context, value, child) {
                      return AppAccordion(
                        title: context.l10n.sortBy,
                        children: [
                          Wrap(
                            spacing: spacing8,
                            runSpacing: spacing8,
                            children: List.generate(widget.sortOptions.length, (
                              index,
                            ) {
                              final option = widget.sortOptions.keys.elementAt(
                                index,
                              );
                              final displayText =
                                  widget.sortOptions[option] ?? option;
                              return AppTag(
                                text: displayText.toUpperCase(),
                                isSelected: _internalSortOption.value == option,
                                onChanged: (value) {
                                  if (value) {
                                    _internalSortOption.value = option;
                                  }
                                },
                              );
                            }),
                          ),
                        ],
                      );
                    },
                  ),
                ],
              ),
            ),
            Padding(
              padding: EdgeInsets.all(spacing24),
              child: SizedBox(
                width: double.infinity,
                child: AppButtonPrimary(
                  text: context.l10n.applySort,
                  onPressed: () {
                    widget.sortOption.value = _internalSortOption.value;
                    widget.sortOrder.value = _internalSortOrder.value;
                    Navigator.of(context).pop();
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _internalSortOption.dispose();
    _internalSortOrder.dispose();
    super.dispose();
  }
}
