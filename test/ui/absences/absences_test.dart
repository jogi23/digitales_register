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
import 'package:dr/ui/absence_entry.dart';
import 'package:dr/ui/absences_page.dart';
import 'package:dr/ui/entry_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:golden_toolkit/golden_toolkit.dart';
import 'package:intl/date_symbol_data_local.dart';

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

late AbsencesState _demoAbsencesState;

void main() {
  setUpAll(() async {
    await initializeDateFormatting('de');
    await loadFixtures();

    // Die Fixture enthält bereits einen notJustified- und notYetJustified-Eintrag.
    _demoAbsencesState = parseAbsencesFromJson(
        fixtureFor('api/student/dashboard/absences'));
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

  group('demo data Absenzen', () {
    testWidgets('shows cancel icon for rejected entry', (tester) async {
      await tester.pumpWidget(_buildTestWidget(initialState: _demoAbsencesState));
      await tester.pumpAndSettle();
      expect(find.byIcon(Icons.cancel), findsOneWidget);
    });

    testWidgets('shows pending icon for not-yet-justified entry', (tester) async {
      await tester.pumpWidget(_buildTestWidget(initialState: _demoAbsencesState));
      await tester.pumpAndSettle();
      expect(find.byIcon(Icons.radio_button_unchecked), findsOneWidget);
    });

    testWidgets('shows reason text for rejected entry', (tester) async {
      await tester.pumpWidget(_buildTestWidget(initialState: _demoAbsencesState));
      await tester.pumpAndSettle();
      expect(find.textContaining('Eishockey Training'), findsOneWidget);
    });

    testWidgets('shows reason text for pending entry', (tester) async {
      await tester.pumpWidget(_buildTestWidget(initialState: _demoAbsencesState));
      await tester.pumpAndSettle();
      expect(find.textContaining('Hockey Turnier'), findsOneWidget);
    });

    testGoldens('demo absences golden', (tester) async {
      await tester.pumpWidget(_buildTestWidget(initialState: _demoAbsencesState));
      await tester.pumpAndSettle();
      await expectLater(
        find.byType(AbsencesPageContainer),
        matchesGoldenFile('demo_absences.png'),
      );
    });
  });

  group('display', () {
    Widget seite(EntryDisplayMode mode) => ProviderScope(
          overrides: [
            absencesProvider.overrideWith(
              () => _TestAbsencesNotifier(_demoAbsencesState),
            ),
            noInternetProvider.overrideWith(NoInternetNotifier.new),
          ],
          child: MaterialApp(
            supportedLocales: const [Locale('de', 'DE')],
            localizationsDelegates: const [
              GlobalCupertinoLocalizations.delegate,
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
            ],
            home: Scaffold(
              body: AbsencesBody(
                state: _demoAbsencesState,
                noInternet: false,
                displayMode: mode,
              ),
            ),
          ),
        );

    testWidgets('puts the absences into cards', (tester) async {
      await tester.pumpWidget(seite(EntryDisplayMode.cards));
      await tester.pumpAndSettle();
      expect(find.byType(EntryCard), findsWidgets);
      expect(
        find.descendant(
          of: find.byType(EntryCard),
          matching: find.byIcon(Icons.cancel),
        ),
        findsOneWidget,
      );
    });

    testWidgets('keeps the rows in the list', (tester) async {
      await tester.pumpWidget(seite(EntryDisplayMode.list));
      await tester.pumpAndSettle();
      expect(find.byType(EntryCard), findsNothing);
      expect(find.byIcon(Icons.cancel), findsOneWidget);
    });
  });

  group('Absenzen eintragen', () {
    AbsencesState withRight({required bool canEdit}) =>
        _demoAbsencesState.rebuild((b) => b..canEdit = canEdit);

    /// Absences the register has settled are not up for a reason any more.
    int openAbsences() => _demoAbsencesState.absences
        .where((g) =>
            g.justified != AbsenceJustified.justified &&
            g.justified != AbsenceJustified.forSchool)
        .length;

    testWidgets('mit Schreibrecht führt die Titelzeile zum Melden',
        (tester) async {
      await tester
          .pumpWidget(_buildTestWidget(initialState: withRight(canEdit: true)));
      await tester.pumpAndSettle();
      expect(find.byTooltip('Absenz melden'), findsOneWidget);
    });

    testWidgets('ohne Schreibrecht gibt es keine Knöpfe', (tester) async {
      await tester.pumpWidget(
          _buildTestWidget(initialState: withRight(canEdit: false)));
      await tester.pumpAndSettle();
      expect(find.byTooltip('Absenz melden'), findsNothing);
      expect(find.byIcon(Icons.edit_note), findsNothing);
    });

    testWidgets('nur offene Absenzen bieten eine Begründung an',
        (tester) async {
      await tester
          .pumpWidget(_buildTestWidget(initialState: withRight(canEdit: true)));
      await tester.pumpAndSettle();
      expect(openAbsences(), greaterThan(0));
      expect(find.byIcon(Icons.edit_note), findsNWidgets(openAbsences()));
    });

    testWidgets('der Dialog verlangt Grund und Unterschrift', (tester) async {
      await tester
          .pumpWidget(_buildTestWidget(initialState: withRight(canEdit: true)));
      await tester.pumpAndSettle();
      await tester.tap(find.byIcon(Icons.edit_note).first);
      await tester.pumpAndSettle();
      expect(find.text('Absenz begründen'), findsOneWidget);

      final save = find.widgetWithText(TextButton, 'Speichern');
      final fields = find.byType(TextField);
      await tester.enterText(fields.at(0), '');
      await tester.enterText(fields.at(1), '');
      await tester.pump();
      expect(tester.widget<TextButton>(save).enabled, isFalse);

      await tester.enterText(fields.at(0), 'Grippe');
      await tester.enterText(fields.at(1), 'Demo Elternteil');
      await tester.pump();
      expect(tester.widget<TextButton>(save).enabled, isTrue);
    });
  });

  group('Melde-Formular', () {
    Widget formular({int hourCount = 6, String? signature}) => MaterialApp(
          supportedLocales: const [Locale('de', 'DE')],
          localizationsDelegates: const [
            GlobalCupertinoLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
          ],
          home: FutureAbsencePage(hourCount: hourCount, signature: signature),
        );

    testWidgets('übernimmt die zuletzt genutzte Unterschrift', (tester) async {
      await tester.pumpWidget(formular(signature: 'Demo Elternteil'));
      await tester.pumpAndSettle();
      expect(find.text('Demo Elternteil'), findsOneWidget);
    });

    testWidgets('meldet erst mit Grund und Unterschrift', (tester) async {
      await tester.pumpWidget(formular());
      await tester.pumpAndSettle();
      final send = find.widgetWithText(TextButton, 'Melden');
      expect(tester.widget<TextButton>(send).enabled, isFalse);

      await tester.enterText(find.byType(TextField).at(0), 'Turnier');
      await tester.enterText(find.byType(TextField).at(1), 'Demo Elternteil');
      await tester.pump();
      expect(tester.widget<TextButton>(send).enabled, isTrue);
    });
  });

  group('was gesendet werden darf', () {
    test('ohne Grund oder Unterschrift nicht', () {
      expect(
        absenceReasonComplete(
          reason: '  ',
          signature: 'Demo Elternteil',
          declarationActive: false,
          declarationMandatory: false,
          declarationInput: '',
        ),
        isFalse,
      );
      expect(
        absenceReasonComplete(
          reason: 'Grippe',
          signature: '',
          declarationActive: false,
          declarationMandatory: false,
          declarationInput: '',
        ),
        isFalse,
      );
    });

    test('eine verlangte Selbsterklärung muss gewählt sein', () {
      expect(
        absenceReasonComplete(
          reason: 'Grippe',
          signature: 'Demo Elternteil',
          declarationActive: true,
          declarationMandatory: true,
          declarationInput: '',
        ),
        isFalse,
      );
    });

    test('ein Formular mit Pflichtfeld braucht die Angabe', () {
      final declaration = SelfDeclaration(
        (b) => b
          ..id = 4
          ..title = 'Krankheit ab 4 Tagen'
          ..text = ''
          ..inputMandatory = true
          ..inputExplain = 'Name Arzt/Ärztin',
      );
      expect(
        absenceReasonComplete(
          reason: 'Grippe',
          signature: 'Demo Elternteil',
          declarationActive: true,
          declarationMandatory: true,
          declaration: declaration,
          declarationInput: '',
        ),
        isFalse,
      );
      expect(
        absenceReasonComplete(
          reason: 'Grippe',
          signature: 'Demo Elternteil',
          declarationActive: true,
          declarationMandatory: true,
          declaration: declaration,
          declarationInput: 'Dr. Muster',
        ),
        isTrue,
      );
    });

    test('sind die Formulare aus, zählen sie nicht', () {
      expect(
        absenceReasonComplete(
          reason: 'Grippe',
          signature: 'Demo Elternteil',
          declarationActive: false,
          declarationMandatory: true,
          declarationInput: '',
        ),
        isTrue,
      );
    });

    test('eine Meldung endet nicht vor ihrem Beginn', () {
      expect(
        futureAbsenceComplete(
          startDate: DateTime(2026, 9, 22),
          endDate: DateTime(2026, 9, 21),
          startHour: 1,
          endHour: 6,
          reason: 'Turnier',
          signature: 'Demo Elternteil',
        ),
        isFalse,
      );
    });

    test('am selben Tag muss die Stunde passen', () {
      expect(
        futureAbsenceComplete(
          startDate: DateTime(2026, 9, 21),
          endDate: DateTime(2026, 9, 21),
          startHour: 5,
          endHour: 3,
          reason: 'Turnier',
          signature: 'Demo Elternteil',
        ),
        isFalse,
      );
      expect(
        futureAbsenceComplete(
          startDate: DateTime(2026, 9, 21),
          endDate: DateTime(2026, 9, 21),
          startHour: 3,
          endHour: 5,
          reason: 'Turnier',
          signature: 'Demo Elternteil',
        ),
        isTrue,
      );
    });
  });
}
