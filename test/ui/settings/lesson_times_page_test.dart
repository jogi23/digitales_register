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

import 'package:dr/app_state.dart';
import 'package:dr/lesson_times.dart';
import 'package:dr/providers/lesson_times_provider.dart';
import 'package:dr/providers/login_provider.dart';
import 'package:dr/providers/settings_provider.dart';
import 'package:dr/ui/lesson_times_page.dart';
import 'package:dr/util.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'settings_pump.dart';

const _url = 'https://a.example.it/';
const _portal = {
  1: LessonTime(480, 530),
  2: LessonTime(535, 585),
};

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  Future<ProviderContainer> pump(
    WidgetTester tester, {
    LessonTimes? custom,
    LessonTimes portal = _portal,
  }) async {
    final c = await pumpSettings(
      tester,
      const LessonTimesPage(),
      settings: SettingsState(
        lessonTimes: {if (custom != null) serverKey(_url): custom},
      ),
      overrides: [portalLessonTimesProvider.overrideWithValue(portal)],
    );
    c.read(loginProvider.notifier).setUrl(_url);
    await tester.pump();
    return c;
  }

  testWidgets('lists every hour with the portal times', (tester) async {
    await pump(tester);
    expect(find.text('1. Stunde'), findsOneWidget);
    expect(find.text('08:00 – 08:50'), findsOneWidget);
    expect(find.text('2. Stunde'), findsOneWidget);
    expect(find.text('08:55 – 09:45'), findsOneWidget);
    expect(find.byTooltip('1. Stunde zurücksetzen'), findsNothing);
  });

  testWidgets('names the school the times apply to', (tester) async {
    await pump(tester);
    expect(find.text('Gilt für alle Konten an a.example.it'), findsOneWidget);
  });

  testWidgets('an own time shows next to the portal\'s and can be reset',
      (tester) async {
    final c = await pump(tester, custom: {1: const LessonTime(490, 540)});
    expect(find.textContaining('08:10 – 09:00 · Angepasst'), findsOneWidget);
    expect(find.textContaining('Zeiten des Portals: 08:00 – 08:50'),
        findsOneWidget);

    await tester.tap(find.byTooltip('1. Stunde zurücksetzen'));
    await tester.pump();

    expect(c.read(settingsProvider).lessonTimes, isEmpty);
    expect(find.text('08:00 – 08:50'), findsOneWidget);
  });

  testWidgets('reset all clears every hour of the school', (tester) async {
    final c = await pump(tester, custom: {
      1: const LessonTime(490, 540),
      2: const LessonTime(545, 595),
    });
    await tester.tap(find.text('Alle zurücksetzen'));
    await tester.pump();
    expect(c.read(settingsProvider).lessonTimes, isEmpty);
  });

  testWidgets('tapping an hour asks for its start, the end button for its end',
      (tester) async {
    await pump(tester);
    await tester.tap(find.text('1. Stunde'));
    await tester.pumpAndSettle();
    expect(find.text('Beginn der 1. Stunde'), findsOneWidget);
    await tester.tap(find.text('Abbrechen'));
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('Ende der 1. Stunde'));
    await tester.pumpAndSettle();
    expect(find.text('Ende der 1. Stunde'), findsOneWidget);
  });

  testWidgets('says so while no hour is known', (tester) async {
    await pump(tester, portal: const {});
    expect(find.textContaining('Keine Stunden bekannt'), findsOneWidget);
  });
}
