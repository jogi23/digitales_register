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
import 'package:dr/ui/account_avatar_button.dart';
import 'package:dr/ui/account_sheet.dart';
import 'package:dr/ui/app_lock_settings.dart';
import 'package:dr/ui/settings/pages/account_settings_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../settings_pump.dart';

void main() {
  testWidgets('the account row opens the account card', (tester) async {
    // Switching accounts used to hide behind the app bar avatar alone.
    await pumpSettings(tester, const AccountSettingsPage());

    expect(find.byType(AccountSettingsTile), findsOneWidget);
    await tester.tap(find.byType(AccountSettingsTile));
    await tester.pumpAndSettle();

    expect(find.byType(AccountSheet), findsOneWidget);
  });

  testWidgets('stay logged in writes noPasswordSaving', (tester) async {
    final container = await pumpSettings(tester, const AccountSettingsPage());
    expect(container.read(settingsProvider).noPasswordSaving, isFalse);

    await tester.tap(find.text('Angemeldet bleiben'));
    await tester.pumpAndSettle();

    expect(container.read(settingsProvider).noPasswordSaving, isTrue);
  });

  testWidgets('the info button explains the two hints', (tester) async {
    await pumpSettings(tester, const AccountSettingsPage());

    await tester.tap(find.byTooltip('Mehr Informationen'));
    await tester.pumpAndSettle();

    expect(find.byType(AlertDialog), findsOneWidget);
    expect(find.textContaining('kein Kontowechsel'), findsOneWidget);
    expect(find.textContaining('SPID/CIE'), findsOneWidget);
  });

  testWidgets('staying on the page when switching accounts can be turned on',
      (tester) async {
    final container = await pumpSettings(tester, const AccountSettingsPage());
    expect(container.read(settingsProvider).keepPageOnAccountSwitch, isFalse);

    await tester.tap(find.text('Beim Kontowechsel auf der Seite bleiben'));
    await tester.pumpAndSettle();

    expect(container.read(settingsProvider).keepPageOnAccountSwitch, isTrue);
  });

  testWidgets('offers the app lock tiles', (tester) async {
    await pumpSettings(tester, const AccountSettingsPage());

    expect(find.byType(AppLockSettingsTiles), findsOneWidget);
  });

  testWidgets('demo mode hides profile, account and keep-page rows',
      (tester) async {
    await pumpSettings(tester, const AccountSettingsPage(), demo: true);

    expect(find.text('Profil'), findsNothing);
    expect(find.byType(AccountSettingsTile), findsNothing);
    expect(find.text('Beim Kontowechsel auf der Seite bleiben'), findsNothing);
    expect(find.text('Angemeldet bleiben'), findsOneWidget);
  });

  testWidgets('meets tap target guidelines', (tester) async {
    await pumpSettings(tester, const AccountSettingsPage());

    await expectMeetsGuidelines(tester);
  });
}
