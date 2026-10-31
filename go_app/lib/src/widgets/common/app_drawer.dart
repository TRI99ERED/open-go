import 'package:flutter/material.dart';
import 'package:opengo/src/features/themes/app_theme.dart';

class AppDrawer extends StatelessWidget {
  final Widget? child;

  const AppDrawer({super.key, this.child});

  @override
  Widget build(BuildContext context) {
    return Drawer(
      backgroundColor: Theme.of(context)
          .extension<AppTheme>()
          ?.backgroundStrongestColor,
      elevation: 0,
      shadowColor: Colors.black.withAlpha(216),
      shape: const ContinuousRectangleBorder(borderRadius: BorderRadius.zero),
      child: child,
    );
  }
}
