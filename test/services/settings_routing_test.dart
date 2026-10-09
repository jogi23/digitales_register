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

import 'package:dr/main.dart' as app;
import 'package:dr/services/app_router.dart';
import 'package:dr/services/settings_routes.dart';
import 'package:dr/ui/settings/blocks/grades_block.dart';
import 'package:dr/ui/settings/pages/content_settings_page.dart';
import 'package:dr/ui/settings/settings_hub_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../ui/settings/settings_pump.dart';

void main() {
  testWidgets(
    'editing the grades average opens the hub, then the content settings with Noten open; '
    'back returns to the hub',
    (tester) async {
      final key = GlobalKey<NavigatorState>();
      final before = app.navigatorKey;
      app.navigatorKey = key;
      addTearDown(() => app.navigatorKey = before);
      final container = await pumpSettings(
        tester,
        const SizedBox(),
        navigatorKey: key,
        onGenerateRoute: settingsRoute,
      );

      container.read(appRouterProvider).showEditGradesAverageSettings();
      await tester.pumpAndSettle();
      expect(find.byType(ContentSettingsPage), findsOneWidget);
      expect(find.byType(GradesBlock), findsOneWidget);

      key.currentState!.pop();
      await tester.pumpAndSettle();
      expect(find.byType(ContentSettingsPage), findsNothing);
      expect(find.byType(SettingsHubPage), findsOneWidget);

      key.currentState!.pop();
      await tester.pumpAndSettle();
      expect(find.byType(SettingsHubPage), findsNothing);
    },
  );
}
