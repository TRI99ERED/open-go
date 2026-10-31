import 'package:flutter/material.dart';
import 'package:opengo/src/features/themes/app_theme.dart';
import 'package:opengo/src/features/themes/styles.dart';

class AppKeyValuePair extends StatelessWidget {
  final String keyStr;
  final String valueStr;

  const AppKeyValuePair({
    super.key,
    required this.keyStr,
    required this.valueStr,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          keyStr,
          style: TextStyle(
            fontSize: h3Size,
            fontWeight: h3Weight,
            color: Theme.of(context)
                .extension<AppTheme>()
                ?.foregroundStrongestColor,
          ),
        ),
        Text(
          valueStr,
          style: TextStyle(
            fontSize: bLSize,
            fontWeight: bLWeight,
            color: Theme.of(context)
                .extension<AppTheme>()
                ?.foregroundStrongestColor,
          ),
        ),
      ],
    );
  }
}
