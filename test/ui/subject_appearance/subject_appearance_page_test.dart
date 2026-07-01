// Copyright (C) 2026 Johannes Feichter
import 'package:dr/providers/all_subjects_provider.dart';
import 'package:dr/providers/subject_appearance_provider.dart';
import 'package:dr/ui/dialog.dart';
import 'package:dr/ui/subject_appearance_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

class _TestSubjectAppearanceNotifier extends SubjectAppearanceNotifier {
  final SubjectAppearanceState initial;
  _TestSubjectAppearanceNotifier(this.initial);
  @override
  SubjectAppearanceState build() => initial;
}

Future<ProviderContainer> _pumpPage(
  WidgetTester tester, {
  List<String> subjects = const ['Mathematik', 'Deutsch'],
  SubjectAppearanceState? appearance,
  bool autoEditMissingNick = false,
}) async {
  final container = ProviderContainer(
    overrides: [
      allSubjectsProvider.overrideWithValue(subjects),
      subjectAppearanceProvider.overrideWith(
        () => _TestSubjectAppearanceNotifier(
          appearance ?? const SubjectAppearanceState(),
        ),
      ),
    ],
  );
  addTearDown(container.dispose);
  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: MaterialApp(
        home: SubjectAppearancePage(autoEditMissingNick: autoEditMissingNick),
      ),
    ),
  );
  await tester.pumpAndSettle();
  return container;
}

void main() {
  testWidgets('shows every subject of the current account', (tester) async {
    await _pumpPage(tester);
    expect(find.text('Deutsch'), findsOneWidget);
    expect(find.text('Mathematik'), findsOneWidget);
  });

  testWidgets('shows the nickname when one is set', (tester) async {
    await _pumpPage(
      tester,
      appearance: const SubjectAppearanceState(nicks: {'mathematik': 'Mat'}),
    );
    expect(find.text('Mat'), findsOneWidget);
    expect(find.text('Kein Kürzel'), findsOneWidget); // Deutsch has none
  });

  testWidgets('edits a nickname', (tester) async {
    final container = await _pumpPage(tester);
    await tester.tap(find.byIcon(Icons.edit).first);
    await tester.pumpAndSettle();
    expect(find.byType(InfoDialog), findsOneWidget);
    await tester.enterText(find.byType(TextField), 'Deu');
    await tester.pumpAndSettle();
    await tester.tap(find.text('Fertig'));
    await tester.pumpAndSettle();
    expect(container.read(subjectAppearanceProvider).nickFor('Deutsch'), 'Deu');
  });

  testWidgets(
    'auto-opens the nickname dialog for the first subject without one',
    (tester) async {
      await _pumpPage(
        tester,
        appearance: const SubjectAppearanceState(nicks: {'deutsch': 'Deu'}),
        autoEditMissingNick: true,
      );
      expect(find.byType(InfoDialog), findsOneWidget);
      expect(find.text('Kürzel für Mathematik'), findsOneWidget);
    },
  );

  testWidgets(
    'does not open a dialog when every subject already has a nick',
    (tester) async {
      await _pumpPage(
        tester,
        appearance: const SubjectAppearanceState(
          nicks: {'deutsch': 'Deu', 'mathematik': 'Mat'},
        ),
        autoEditMissingNick: true,
      );
      expect(find.byType(InfoDialog), findsNothing);
    },
  );
}
