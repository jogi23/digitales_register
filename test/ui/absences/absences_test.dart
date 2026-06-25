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
import 'package:dr/container/absences_page_container.dart';
import 'package:dr/data.dart';
import 'package:dr/providers/absences_provider.dart';
import 'package:dr/providers/no_internet_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:golden_toolkit/golden_toolkit.dart';

import '../../fixtures/api_fixtures.dart';

class _TestAbsencesNotifier extends AbsencesNotifier {
  _TestAbsencesNotifier(this._initialState);
  final AbsencesState _initialState;
  @override
  AbsencesState build() => _initialState;
}

Widget _buildTestWidget({required AbsencesState initialState}) {
  return ProviderScope(
    overrides: [
      absencesProvider.overrideWith(
        () => _TestAbsencesNotifier(initialState),
      ),
      noInternetProvider.overrideWith(NoInternetNotifier.new),
    ],
    child: const MaterialApp(
      supportedLocales: [
        Locale('de', 'DE'),
      ],
      localizationsDelegates: [
        GlobalCupertinoLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ],
      home: AbsencesPageContainer(),
    ),
  );
}

void main() {
  setUpAll(() async {
    await loadFixtures();
  });

  testGoldens('simple absences', (WidgetTester tester) async {
    final parsedState = parseAbsencesFromJson(
        fixtureFor('api/student/dashboard/absences'));

    final widget = _buildTestWidget(initialState: parsedState);
    await tester.pumpWidget(widget);
    await tester.pumpAndSettle();
    await expectLater(
      find.byType(AbsencesPageContainer),
      matchesGoldenFile("absences.png"),
    );
  });

  testGoldens('no absences', (WidgetTester tester) async {
    final widget = _buildTestWidget(
      initialState: AbsencesState(
        (b) => b
          ..absences = ListBuilder()
          ..statistic = AbsenceStatisticBuilder(),
      ),
    );
    await tester.pumpWidget(widget);
    expect(find.text("Noch keine Absenzen"), findsOneWidget);
    await expectLater(
      find.byType(AbsencesPageContainer),
      matchesGoldenFile("no_absences.png"),
    );
  });
}
