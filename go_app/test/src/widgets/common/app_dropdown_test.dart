import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:opengo/src/widgets/common/app_dropdown.dart';

void main() {
  testWidgets('keeps an above-field overlay adjacent to the text field', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(400, 800));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Stack(
            children: [
              Positioned(
                top: 700,
                left: 40,
                child: SizedBox(
                  width: 280,
                  child: AppDropdown(
                    items: const [
                      DropdownMenuEntry(value: 'one', label: 'One'),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );

    await tester.tap(find.byType(TextFormField));
    await tester.pumpAndSettle();

    final textFieldRect = tester.getRect(find.byType(TextFormField));
    final overlayRect = tester.getRect(find.byType(ListView));

    expect(overlayRect.bottom, closeTo(textFieldRect.top - 4, 1));
  });
}
