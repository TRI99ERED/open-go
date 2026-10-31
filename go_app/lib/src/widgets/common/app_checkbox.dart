import 'package:flutter/material.dart';
import 'package:opengo/src/features/themes/app_theme.dart';
import 'package:opengo/src/features/themes/styles.dart';

const double checkboxSmallSize = 0.8;
const double checkboxMediumSize = 1.2;
const double checkboxLargeSize = 1.6;

class AppCheckbox extends StatelessWidget {
  final bool value;
  final double size;
  final ValueChanged<bool?>? onChanged;

  const AppCheckbox({
    super.key,
    required this.value,
    this.size = checkboxSmallSize,
    this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Transform.scale(
      scale: size,
      child: Checkbox(
        value: value,
        onChanged: onChanged,
        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
        fillColor: WidgetStateProperty.fromMap(<WidgetStatesConstraint, Color?>{
          WidgetState.disabled: Theme.of(context)
              .extension<AppTheme>()
              ?.backgroundMediumColor,
          WidgetState.selected: Theme.of(context)
              .extension<AppTheme>()
              ?.highlightDarkestColor,
          WidgetState.any: Theme.of(context)
              .extension<AppTheme>()
              ?.backgroundStrongestColor,
        }),
        checkColor: Theme.of(context)
            .extension<AppTheme>()
            ?.backgroundStrongestColor,
        side: BorderSide(
          color:
              Theme.of(context).extension<AppTheme>()?.backgroundWeakestColor ??
              Color(0xFFC5C6CC),
          width: 1.5,
        ),
      ),
    );
  }
}

class AppCheckboxTile extends StatelessWidget {
  final bool value;
  final String title;
  final double buttonSize;
  final bool enabled;
  final ValueChanged<bool?>? onChanged;

  const AppCheckboxTile({
    super.key,
    required this.value,
    required this.title,
    this.buttonSize = checkboxSmallSize,
    this.enabled = true,
    this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return TextButton(
      onPressed: enabled && onChanged != null ? () => onChanged!(value) : null,
      style: TextButton.styleFrom(
        padding: EdgeInsets.symmetric(
          horizontal: spacing16,
          vertical: spacing8,
        ),
        backgroundColor: Theme.of(context)
            .extension<AppTheme>()
            ?.backgroundStrongestColor,
        shape: ContinuousRectangleBorder(borderRadius: BorderRadius.zero),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: h4Size,
              fontWeight: h4Weight,
              color: Theme.of(context)
                  .extension<AppTheme>()
                  ?.foregroundStrongestColor,
              decoration: TextDecoration.none,
            ),
          ),
          AppCheckbox(value: value, size: buttonSize, onChanged: onChanged),
        ],
      ),
    );
  }
}
