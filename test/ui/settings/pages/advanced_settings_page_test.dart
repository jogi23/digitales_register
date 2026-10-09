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

import 'package:dr/ui/settings/pages/advanced_settings_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../settings_pump.dart';

void main() {
  testWidgets('offers the diagnostic log instead of the two log pages',
      (tester) async {
    await pumpSettings(tester, const AdvancedSettingsPage());

    expect(find.text('Diagnose-Protokoll'), findsOneWidget);
    expect(find.text('Netzwerkprotokoll'), findsNothing);
    expect(find.text('Debug-Log'), findsNothing);
  });

  testWidgets('the source row shows the external symbol', (tester) async {
    await pumpSettings(tester, const AdvancedSettingsPage());

    expect(find.text('Zum Quellcode'), findsOneWidget);
    expect(find.byIcon(Icons.open_in_new_rounded), findsOneWidget);
  });

  testWidgets('meets tap target guidelines', (tester) async {
    await pumpSettings(tester, const AdvancedSettingsPage());

    await expectMeetsGuidelines(tester);
  });
}
