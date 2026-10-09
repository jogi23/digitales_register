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

import 'package:dr/ui/settings/widgets/settings_choice_tile.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../settings_pump.dart';

const _choices = [
  SettingsChoice(value: 1, label: 'Eins'),
  SettingsChoice(value: 2, label: 'Zwei'),
];

Widget _tile({
  int value = 1,
  required List<int> picked,
  bool enabled = true,
  String? hint,
}) =>
    Scaffold(
      body: SettingsChoiceTile<int>(
        icon: Icons.tune_rounded,
        title: 'Zahl',
        value: value,
        choices: _choices,
        onChanged: picked.add,
        enabled: enabled,
        hint: hint,
      ),
    );

void main() {
  testWidgets('subtitle shows the current label', (tester) async {
    await pumpSettings(tester, _tile(value: 2, picked: []));

    expect(find.text('Zwei'), findsOneWidget);
    expect(find.text('Eins'), findsNothing);
  });

  testWidgets('tapping the title opens the dialog', (tester) async {
    await pumpSettings(tester, _tile(picked: [], hint: 'Ein Hinweis'));

    await tester.tap(find.text('Zahl'));
    await tester.pumpAndSettle();

    expect(find.byType(AlertDialog), findsOneWidget);
    expect(find.text('Ein Hinweis'), findsOneWidget);
    expect(find.byType(RadioListTile<int>), findsNWidgets(2));
  });

  testWidgets('picking another option calls onChanged once and closes',
      (tester) async {
    final picked = <int>[];
    await pumpSettings(tester, _tile(picked: picked));

    await tester.tap(find.text('Zahl'));
    await tester.pumpAndSettle();
    await tester.tap(find.descendant(
      of: find.byType(AlertDialog),
      matching: find.text('Zwei'),
    ));
    await tester.pumpAndSettle();

    expect(picked, [2]);
    expect(find.byType(AlertDialog), findsNothing);
  });

  testWidgets('picking the current option does not call onChanged',
      (tester) async {
    final picked = <int>[];
    await pumpSettings(tester, _tile(picked: picked));

    await tester.tap(find.text('Zahl'));
    await tester.pumpAndSettle();
    await tester.tap(find.descendant(
      of: find.byType(AlertDialog),
      matching: find.text('Eins'),
    ));
    await tester.pumpAndSettle();

    expect(picked, isEmpty);
    expect(find.byType(AlertDialog), findsNothing);
  });

  testWidgets('an unknown value shows an empty subtitle without throwing',
      (tester) async {
    await pumpSettings(tester, _tile(value: 99, picked: []));

    expect(tester.takeException(), isNull);
    expect(find.text('Eins'), findsNothing);
    expect(find.text('Zwei'), findsNothing);
  });

  testWidgets('a disabled tile does not open', (tester) async {
    await pumpSettings(tester, _tile(picked: [], enabled: false));

    await tester.tap(find.text('Zahl'));
    await tester.pumpAndSettle();

    expect(find.byType(AlertDialog), findsNothing);
  });

  testWidgets('text scale 2.0 does not overflow', (tester) async {
    await pumpSettings(tester, _tile(picked: []), textScale: 2);

    expect(tester.takeException(), isNull);
  });
}
