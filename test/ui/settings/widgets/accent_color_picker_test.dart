// Copyright (C) 2026 Johannes Feichter
//
// This file is part of digitales_register.
//
// digitales_register is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.
//
// digitales_register is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.
//
// You should have received a copy of the GNU General Public License
// along with digitales_register.  If not, see <http://www.gnu.org/licenses/>.

import 'package:dr/ui/settings/widgets/accent_color_picker.dart';
import 'package:dynamic_theme/dynamic_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../settings_pump.dart';

const _orange = Color(0xFFFF5722);
const _teal = Color(0xFF009688);

Future<void> _pumpPicker(WidgetTester tester) => pumpSettings(
      tester,
      const Scaffold(body: SingleChildScrollView(child: AccentColorPicker())),
    );

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  testWidgets('every swatch has a tap target of at least 48x48',
      (tester) async {
    await _pumpPicker(tester);

    final targets = find.byType(InkResponse);
    expect(targets, findsNWidgets(10));
    for (final target in targets.evaluate()) {
      final size = tester.getSize(find.byElementPredicate((e) => e == target));
      expect(size.width, greaterThanOrEqualTo(48));
      expect(size.height, greaterThanOrEqualTo(48));
    }
  });

  testWidgets('the selected swatch is announced as selected', (tester) async {
    await _pumpPicker(tester);
    final handle = tester.ensureSemantics();
    final context = tester.element(find.byType(AccentColorPicker));
    expect(DynamicTheme.of(context)!.seedColor, _orange);

    bool selected(String label) => tester
        .getSemantics(find.bySemanticsLabel(label))
        // ignore: deprecated_member_use
        .hasFlag(SemanticsFlag.isSelected);

    expect(selected('Orange'), isTrue);
    expect(selected('Türkis'), isFalse);
    handle.dispose();
  });

  testWidgets('tapping a swatch sets the seed colour', (tester) async {
    await _pumpPicker(tester);

    await tester.tap(find.bySemanticsLabel('Türkis'));
    await tester.pumpAndSettle();

    final context = tester.element(find.byType(AccentColorPicker));
    expect(DynamicTheme.of(context)!.seedColor, _teal);
  });

  testWidgets('meets tap target guidelines', (tester) async {
    await _pumpPicker(tester);

    await expectMeetsGuidelines(tester);
  });
}
