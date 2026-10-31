import 'package:flutter/material.dart';
import 'package:opengo/src/features/screens/game_screen.dart';
import 'package:opengo/src/features/screens/home_screen.dart';
import 'package:opengo/src/features/screens/settings_screen.dart';
import 'package:opengo/src/features/screens/sgf_review_screen.dart';
import 'package:opengo/src/features/screens/splash_screen.dart';
import 'package:opengo/src/features/screens/tsumego_screen.dart';
import 'package:opengo/src/features/screens/tsumegos_screen.dart';

/// Type alias for the navigation state, which is a list of [AppPage] instances.
typedef AppNavigationState = List<AppPage>;

/// Base class for all application pages.
///
/// Extends [MaterialPage] directly so each page IS a [Page] — no wrapper
/// needed. Subclasses can override [createRoute] to customise transitions,
/// hero animations, or any per-page routing behaviour.
abstract class AppPage extends MaterialPage<void> {
  const AppPage({
    required super.child,
    required super.key,
    required super.name,
  });

  /// Path representation used for deep-link matching and URL sync.
  String get path;

  @override
  String toString() => 'AppPage($name)';

  static AppPage fromRoute(
    String payload, [
    int homeInitialTab = 0,
    int homeInitialFriendsSection = 0,
    int homeInitialProjectsSection = 0,
  ]) {
    switch (payload) {
      case '/':
        return const HomePage();
      case '/splash':
        return const SplashPage();
      default:
        throw Exception('Unknown route: $payload');
    }
  }
}

// ---------------------------------------------------------------------------
// Splash
// ---------------------------------------------------------------------------

class SplashPage extends AppPage {
  const SplashPage()
    : super(
        key: const ValueKey('SplashPage'),
        name: 'Splash',
        child: const SplashScreen(),
      );

  @override
  String get path => '/splash';
}

// ---------------------------------------------------------------------------
// Main app pages
// ---------------------------------------------------------------------------

class HomePage extends AppPage {
  const HomePage()
    : super(
        key: const ValueKey('HomePage'),
        name: 'Home',
        child: const HomeScreen(),
      );

  @override
  String get path => '/';
}

class SettingsPage extends AppPage {
  const SettingsPage()
    : super(
        key: const ValueKey('SettingsPage'),
        name: 'Settings',
        child: const SettingsScreen(),
      );

  @override
  String get path => '/settings';
}

class GamePage extends AppPage {
  GamePage({GameMode initialMode = GameMode.vsGnuGo})
    : super(
        key: const ValueKey('GamePage'),
        name: 'Game',
        child: GameScreen(initialMode: initialMode),
      );

  @override
  String get path => '/game';
}

class ReviewPage extends AppPage {
  const ReviewPage()
    : super(
        key: const ValueKey('ReviewPage'),
        name: 'Review',
        child: const SgfReviewScreen(),
      );

  @override
  String get path => '/review';
}

class TsumegosPage extends AppPage {
  const TsumegosPage()
    : super(
        key: const ValueKey('TsumegosPage'),
        name: 'Tsumegos',
        child: const TsumegosScreen(),
      );

  @override
  String get path => '/tsumegos';
}

class TsumegoPage extends AppPage {
  final int _index;

  TsumegoPage({required this._index})
    : super(
        key: const ValueKey('TsumegoPage'),
        name: 'Tsumego',
        child: TsumegoScreen(index: _index),
      );

  @override
  String get path => '/tsumegos/$_index';

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is TsumegoPage && _index == other._index;

  @override
  int get hashCode => _index.hashCode;
}
