import 'package:flutter/material.dart';
import 'package:opengo/src/features/themes/app_theme.dart';
import 'package:opengo/src/features/themes/styles.dart';
import 'package:opengo/src/widgets/common/app_button.dart';

class EmptyState extends StatelessWidget {
  final String title;
  final String? body;
  final String? buttonText;
  final VoidCallback? onButtonPressed;

  const EmptyState({
    super.key,
    required this.title,
    this.body,
    this.buttonText,
    this.onButtonPressed,
  }) : assert(
         (buttonText == null && onButtonPressed == null) ||
             (buttonText != null && onButtonPressed != null),
         'buttonText and onButtonPressed must both be provided or both be null',
       );

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        spacing: spacing32,
        children: [
          Column(
            spacing: spacing8,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: h2Size,
                  fontWeight: h2Weight,
                  color: Theme.of(context)
                      .extension<AppTheme>()
                      ?.foregroundStrongestColor,
                ),
              ),
              if (body != null)
                Text(
                  body!,
                  style: TextStyle(
                    fontSize: bMSize,
                    fontWeight: bMWeight,
                    color: Theme.of(context)
                        .extension<AppTheme>()
                        ?.foregroundWeakColor,
                  ),
                  textAlign: TextAlign.center,
                ),
            ],
          ),
          if (buttonText != null && onButtonPressed != null)
            AppButtonPrimary(onPressed: onButtonPressed, text: buttonText!),
        ],
      ),
    );
  }
}
