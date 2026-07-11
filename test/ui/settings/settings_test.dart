// Copyright (C) 2021 Michael Debertol
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

import 'package:built_collection/built_collection.dart';
import 'package:dr/app_state.dart';
import 'package:dr/container/settings_page.dart';
import 'package:dr/providers/provider_container.dart' as pc;
import 'package:dr/providers/settings_provider.dart';
import 'package:dr/ui/dialog.dart';
import 'package:dr/ui/subject_appearance_page.dart';
import 'package:dynamic_theme/dynamic_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:golden_toolkit/golden_toolkit.dart';

class _TestSettingsNotifier extends SettingsNotifier {
  final SettingsState initial;

  _TestSettingsNotifier(this.initial);

  @override
  SettingsState build() => initial;
}

Future<ProviderContainer> _pumpSettingsPage(
  WidgetTester tester, {
  SettingsState? settings,
}) async {
  final container = ProviderContainer(
    overrides: [
      settingsProvider.overrideWith(
        () => _TestSettingsNotifier(settings ?? SettingsState()),
      ),
    ],
  );
  pc.providerContainer = container;
  final widget = UncontrolledProviderScope(
    container: container,
    child: MaterialApp(
      home: SettingsPageContainer(),
    ),
  );
  await tester.pumpWidget(
    DynamicTheme(
      data: (brightness, overridePlatform, seedColor) {
        return ThemeData(
          primarySwatch: Colors.deepOrange,
          brightness: brightness,
        );
      },
      themedWidgetBuilder: (context, data) => widget,
    ),
  );
  await tester.pumpAndSettle();
  return container;
}

void main() {
  testWidgets(
    'does not show items moved to the hamburger menu',
    (tester) async {
      final container = await _pumpSettingsPage(tester);
      addTearDown(container.dispose);
      expect(find.text('Feedback geben'), findsNothing);
      expect(find.text('Über diese App'), findsNothing);
    },
  );

  testGoldens(
    'scrolls to grades settings',
    (tester) async {
      final container = await _pumpSettingsPage(
        tester,
        settings: SettingsState(scrollToGrades: true),
      );
      addTearDown(container.dispose);

      await expectLater(
        find.byType(SettingsPageContainer),
        matchesGoldenFile("scrolled_to_grades.png"),
      );
    },
  );

  testWidgets(
    'opens the subject appearance screen from "Aussehen"',
    (tester) async {
      final container = await _pumpSettingsPage(tester);
      addTearDown(container.dispose);
      await tester.dragUntilVisible(
        find.text("Fächer Kürzel und Farben"),
        find.byType(Scrollable).first,
        const Offset(0, -300),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text("Fächer Kürzel und Farben"));
      await tester.pumpAndSettle();
      expect(find.byType(SubjectAppearancePage), findsOneWidget);
    },
  );

  group("grades average ignore-list", () {
    testWidgets(
      'adds an item',
      (tester) async {
        final container = await _pumpSettingsPage(tester);
        addTearDown(container.dispose);
        await tester.scrollUntilVisible(
          find.text("Fächer aus dem Notendurchschnitt ausschließen"),
          150,
        );
        await tester.pump();
        await tester.tap(
          find.descendant(
            of: find.ancestor(
                of: find.text("Fächer aus dem Notendurchschnitt ausschließen"),
                matching: find.byType(ListTile)),
            matching: find.byIcon(Icons.add),
          ),
        );
        await tester.pumpAndSettle();

        // a dialog should be opened
        expect(find.byType(InfoDialog), findsOneWidget);
        // the text box should already be focused
        tester.testTextInput.enterText("Fach1");
        await tester.pumpAndSettle();
        expect(
          container.read(settingsProvider).ignoreForGradesAverage,
          <String>[].toBuiltList(),
        );
        await tester.tap(find.text("Fertig"));
        expect(
          container.read(settingsProvider).ignoreForGradesAverage,
          ["Fach1"].toBuiltList(),
        );
      },
    );
    testWidgets(
      'removes an item',
      (tester) async {
        final container = await _pumpSettingsPage(
          tester,
          settings: SettingsState(ignoreForGradesAverage: ["Fach1"]),
        );
        addTearDown(container.dispose);
        await tester.scrollUntilVisible(
          find.text("Fächer aus dem Notendurchschnitt ausschließen"),
          150,
        );
        await tester.pump();
        await tester.tap(
          find.descendant(
            of: find.ancestor(
                of: find.text("Fach1"), matching: find.byType(ListTile)),
            matching: find.byIcon(Icons.close),
          ),
        );
        await tester.pumpAndSettle();

        expect(
          container.read(settingsProvider).ignoreForGradesAverage,
          <String>[].toBuiltList(),
        );
      },
    );
  });
}
