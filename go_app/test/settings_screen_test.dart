import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:opengo/main.dart';
import 'package:opengo/src/widgets/common/app_checkbox.dart';

void main() {
  testWidgets('fullscreen setting updates its checkbox state', (tester) async {
    await tester.pumpWidget(const App());

    await tester.tap(find.byIcon(Icons.menu));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Settings'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Appearance'));
    await tester.pumpAndSettle();

    expect(find.text('Fullscreen'), findsOneWidget);
    expect(tester.widget<AppCheckbox>(find.byType(AppCheckbox)).value, isFalse);

    await tester.tap(find.text('Fullscreen'));
    await tester.pumpAndSettle();

    expect(tester.widget<AppCheckbox>(find.byType(AppCheckbox)).value, isTrue);

    await tester.tap(find.text('Fullscreen'));
    await tester.pumpAndSettle();

    expect(tester.widget<AppCheckbox>(find.byType(AppCheckbox)).value, isFalse);
  });

  testWidgets('fullscreen setting calls the Windows window channel', (
    tester,
  ) async {
    const channel = MethodChannel('opengo/window');
    final calls = <MethodCall>[];
    final messenger = tester.binding.defaultBinaryMessenger;
    messenger.setMockMethodCallHandler(channel, (call) async {
      calls.add(call);
      return null;
    });
    debugDefaultTargetPlatformOverride = TargetPlatform.windows;
    try {
      await tester.pumpWidget(const App());
      await tester.tap(find.byIcon(Icons.menu));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Settings'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Appearance'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Fullscreen'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Fullscreen'));
      await tester.pumpAndSettle();

      expect(calls.map((call) => call.method), everyElement('setFullscreen'));
      expect(calls.map((call) => call.arguments), [true, false]);
    } finally {
      debugDefaultTargetPlatformOverride = null;
      messenger.setMockMethodCallHandler(channel, null);
    }
  });
}
