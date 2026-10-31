import 'package:flutter/material.dart';
import 'package:opengo/src/features/app/app_controller/app_controller.dart';
import 'package:opengo/src/features/app/data/models/user_model.dart';

class AppScope extends StatefulWidget {
  final Widget child;
  final AppController appController;
  final ValueNotifier<ThemeMode> themeMode;
  final ValueNotifier<bool> fullscreenMode;
  final Future<void> Function(bool) onFullscreenModeChanged;

  const AppScope({
    super.key,
    required this.child,
    required this.appController,
    required this.themeMode,
    required this.fullscreenMode,
    required this.onFullscreenModeChanged,
  });

  @override
  State<AppScope> createState() => _AppScopeState();
}

class _AppScopeState extends State<AppScope> {
  late final AppController _appController;
  late AppState _appState;

  User get user => _appState.user;

  @override
  void initState() {
    super.initState();
    _appController = widget.appController;
    _appState = _appController.state;

    _appController.addListener(_onStateChange);
  }

  void _onStateChange() {
    if (mounted) {
      _appState = _appController.state;

      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    return InheritedScopeWidget(
      appController: _appController,
      appState: _appState,
      themeMode: widget.themeMode,
      fullscreenMode: widget.fullscreenMode,
      onFullscreenModeChanged: widget.onFullscreenModeChanged,
      child: widget.child,
    );
  }

  @override
  void dispose() {
    _appController.removeListener(_onStateChange);
    super.dispose();
  }
}

class InheritedScopeWidget extends InheritedWidget {
  final AppController appController;
  final AppState appState;
  final ValueNotifier<ThemeMode> themeMode;
  final ValueNotifier<bool> fullscreenMode;
  final Future<void> Function(bool) onFullscreenModeChanged;
  const InheritedScopeWidget({
    super.key,
    required this.appController,
    required this.appState,
    required this.themeMode,
    required this.fullscreenMode,
    required this.onFullscreenModeChanged,
    required super.child,
  });

  static InheritedScopeWidget? maybeOf(BuildContext context) {
    return context.dependOnInheritedWidgetOfExactType<InheritedScopeWidget>();
  }

  static InheritedScopeWidget of(BuildContext context) {
    final scope = maybeOf(context);
    assert(
      scope != null,
      'No InheritedScopeWidget found in context. Make sure to wrap your widget tree with an InheritedScopeWidget.',
    );
    return scope!;
  }

  @override
  bool updateShouldNotify(InheritedScopeWidget oldWidget) {
    return appState != oldWidget.appState ||
        themeMode != oldWidget.themeMode ||
        fullscreenMode != oldWidget.fullscreenMode ||
        onFullscreenModeChanged != oldWidget.onFullscreenModeChanged;
  }
}

extension AppScopeExtension on BuildContext {
  AppState get appState =>
      dependOnInheritedWidgetOfExactType<InheritedScopeWidget>()!.appState;
  AppController get appController =>
      dependOnInheritedWidgetOfExactType<InheritedScopeWidget>()!.appController;
  ValueNotifier<ThemeMode> get themeMode =>
      dependOnInheritedWidgetOfExactType<InheritedScopeWidget>()!.themeMode;
  ValueNotifier<bool> get fullscreenMode =>
      dependOnInheritedWidgetOfExactType<InheritedScopeWidget>()!.fullscreenMode;
  Future<void> setFullscreenMode(bool value) =>
      dependOnInheritedWidgetOfExactType<InheritedScopeWidget>()!
          .onFullscreenModeChanged(value);
}
