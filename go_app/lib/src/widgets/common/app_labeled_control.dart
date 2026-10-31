import 'package:flutter/material.dart';
import 'package:opengo/src/widgets/common/app_dropdown.dart';

class AppLabeledControl extends StatelessWidget {
  final String label;
  final int value;
  final List<int> items;
  final String Function(int value) itemLabel;
  final ValueChanged<int?>? onSelected;

  const AppLabeledControl({
    super.key,
    required this.label,
    required this.value,
    required this.items,
    required this.itemLabel,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return AppDropdown(
      title: label,
      selectedIndex: items.indexOf(value),
      text: itemLabel(value),
      onSelected: (selection) => onSelected?.call(int.parse(selection.$1)),
      items: [
        for (final item in items)
          DropdownMenuEntry(value: '$item', label: itemLabel(item)),
      ],
    );
  }
}
