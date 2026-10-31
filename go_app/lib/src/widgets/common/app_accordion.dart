import 'package:flutter/material.dart';
import 'package:opengo/src/features/themes/app_theme.dart';
import 'package:opengo/src/features/themes/styles.dart';
import 'package:opengo/src/widgets/common/app_badge.dart';
import 'package:opengo/src/widgets/common/app_divider.dart';

class AppAccordion extends StatefulWidget {
  final String title;
  final List<Widget> children;
  final int selectedCount;
  final bool startOpen;
  final ValueChanged<bool>? onExpansionChanged;

  const AppAccordion({
    super.key,
    required this.title,
    required this.children,
    this.selectedCount = 0,
    this.startOpen = false,
    this.onExpansionChanged,
  });

  @override
  State<AppAccordion> createState() => _AppAccordionState();
}

class _AppAccordionState extends State<AppAccordion> {
  void _handleExpansionChanged(bool expanded) {
    if (widget.onExpansionChanged != null) {
      widget.onExpansionChanged!(expanded);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        ExpansionTile(
          title: Text(
            widget.title,
            style: TextStyle(
              fontSize: bMSize,
              fontWeight: bMWeight,
              color: Theme.of(context)
                  .extension<AppTheme>()
                  ?.foregroundStrongestColor,
            ),
          ),
          initiallyExpanded: widget.startOpen,
          shape: ContinuousRectangleBorder(borderRadius: BorderRadius.zero),
          tilePadding: EdgeInsets.zero,
          minTileHeight: 0,
          iconColor: Theme.of(context)
              .extension<AppTheme>()
              ?.foregroundWeakestColor,
          trailing: widget.selectedCount == 0
              ? null
              : AppBadgeSymbol(
                  symbol: widget.selectedCount.toString(),
                  size: 24,
                ),
          onExpansionChanged: _handleExpansionChanged,
          expandedCrossAxisAlignment: CrossAxisAlignment.start,
          expandedAlignment: Alignment.centerLeft,
          childrenPadding: EdgeInsets.zero,
          children: widget.children,
        ),
        const AppDivider(),
      ],
    );
  }
}

class AppAccordionText extends StatelessWidget {
  final String text;

  const AppAccordionText(this.text, {super.key});

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: TextStyle(
        fontSize: bSSize,
        fontWeight: bSWeight,
        color: Theme.of(context).extension<AppTheme>()?.foregroundWeakColor,
      ),
    );
  }
}
