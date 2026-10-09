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

import 'package:dr/providers/settings_provider.dart';
import 'package:dr/ui/settings/pages/appearance_settings_page.dart';
import 'package:dynamic_theme/dynamic_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../settings_pump.dart';

DynamicThemeState _theme(WidgetTester tester) =>
    DynamicTheme.of(tester.element(find.byType(AppearanceSettingsPage)))!;

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  testWidgets('picking Dunkel sets the brightness and stops following',
      (tester) async {
    await pumpSettings(tester, const AppearanceSettingsPage());

    await chooseInDialog(tester, 'Design', 'Dunkel');

    expect(_theme(tester).followDevice, isFalse);
    expect(_theme(tester).customBrightness, Brightness.dark);
    // The row now says what is set.
    expect(find.text('Dunkel'), findsOneWidget);
  });

  testWidgets('picking the device theme turns followDevice on', (tester) async {
    await pumpSettings(tester, const AppearanceSettingsPage());
    await chooseInDialog(tester, 'Design', 'Hell');
    expect(_theme(tester).followDevice, isFalse);

    await chooseInDialog(tester, 'Design', 'Geräte-Theme folgen');

    expect(_theme(tester).followDevice, isTrue);
  });

  testWidgets('picking a language writes it, the device entry writes null',
      (tester) async {
    final container =
        await pumpSettings(tester, const AppearanceSettingsPage());
    expect(container.read(settingsProvider).language, isNull);

    await chooseInDialog(tester, 'Sprache', 'Italiano');
    expect(container.read(settingsProvider).language, 'it');

    await chooseInDialog(tester, 'Sprache', 'Gerätesprache');
    expect(container.read(settingsProvider).language, isNull);
  });

  testWidgets('switching off the accent background writes the setting',
      (tester) async {
    final container =
        await pumpSettings(tester, const AppearanceSettingsPage());
    expect(container.read(settingsProvider).accentBackground, isTrue);

    await tester.tap(find.text('Hintergrund in Akzentfarbe'));
    await tester.pumpAndSettle();

    expect(container.read(settingsProvider).accentBackground, isFalse);
  });

  testWidgets('meets tap target guidelines', (tester) async {
    await pumpSettings(tester, const AppearanceSettingsPage());

    await expectMeetsGuidelines(tester);
  });
}
