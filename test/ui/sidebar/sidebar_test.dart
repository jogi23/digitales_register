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

import 'package:dr/pages.dart';
import 'package:dr/ui/about_hub_page.dart';
import 'package:dr/ui/help_feedback_page.dart';
import 'package:dr/ui/sidebar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:golden_toolkit/golden_toolkit.dart';

// Sidebar requires a non-zero height to render items.
const _testSize = Size(300, 700);

Widget _build({
  Pages current = Pages.homework,
  bool tabletMode = false,
  bool drawerExpanded = true,
  VoidCallback? onGoHome,
  VoidCallback? onShowGrades,
  VoidCallback? onShowAbsences,
  VoidCallback? onShowCalendar,
  VoidCallback? onShowCertificate,
  VoidCallback? onShowClassbook,
  VoidCallback? onShowHomeworkOverview,
  VoidCallback? onShowCourseContent,
  VoidCallback? onShowMessages,
  VoidCallback? onShowSettings,
  VoidCallback? onLogout,
}) {
  return MaterialApp(
    home: MediaQuery(
      data: const MediaQueryData(size: _testSize),
      child: SizedBox(
        width: _testSize.width,
        height: _testSize.height,
        child: Sidebar(
          currentSelected: current,
          tabletMode: tabletMode,
          drawerExpanded: drawerExpanded,
          onDrawerExpansionChange: (_) {},
          goHome: onGoHome ?? () {},
          showGrades: onShowGrades ?? () {},
          showAbsences: onShowAbsences ?? () {},
          showCalendar: onShowCalendar ?? () {},
          showCertificate: onShowCertificate ?? () {},
          showClassbook: onShowClassbook ?? () {},
          showHomeworkOverview: onShowHomeworkOverview ?? () {},
          showCourseContent: onShowCourseContent ?? () {},
          showMessages: onShowMessages ?? () {},
          showSettings: onShowSettings ?? () {},
          logout: onLogout ?? () {},
        ),
      ),
    ),
  );
}

void main() {
  testWidgets('shows all navigation items', (tester) async {
    await tester.pumpWidget(_build());
    await tester.pumpAndSettle();
    expect(find.text('Merkheft'), findsOneWidget);
    expect(find.text('Absenzen'), findsOneWidget);
    expect(find.text('Kalender'), findsOneWidget);
    expect(find.text('Bewertungen'), findsOneWidget);
    expect(find.text('Mitteilungen'), findsOneWidget);
    expect(find.text('Zeugnis'), findsOneWidget);
    expect(find.text('Klassenbuch'), findsOneWidget);
    expect(find.text('Einstellungen'), findsOneWidget);
    expect(find.text('Hilfe und Feedback'), findsOneWidget);
    expect(find.text('Hausaufgaben'), findsOneWidget);
    // The sidebar list is scrollable and doesn't build off-screen items
    // eagerly, so the ones further down need scrolling into view first.
    await tester.scrollUntilVisible(
      find.text('Abmelden'),
      500,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();
    expect(find.text('Über'), findsOneWidget);
    expect(find.text('Abmelden'), findsOneWidget);
  });

  testWidgets('lists the entries in the standard order', (tester) async {
    // Hilfe, dann Über (Bewerten, Teilen, Andere Apps liegen auf dessen
    // Seite); Abmelden bleibt der letzte Punkt.
    await tester.pumpWidget(_build());
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.text('Abmelden'),
      500,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();

    const order = [
      'Einstellungen',
      'Hilfe und Feedback',
      'Über',
      'Abmelden',
    ];
    final ys = [for (final t in order) tester.getCenter(find.text(t)).dy];
    expect(ys, orderedEquals([...ys]..sort()));
    expect(ys.toSet().length, order.length);
  });

  testWidgets('fits 13 entries without overflow', (tester) async {
    await tester.pumpWidget(_build());
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });

  testWidgets('has no "Neuigkeiten" entry: the changelog is in the about page',
      (tester) async {
    await tester.pumpWidget(_build());
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.text('Abmelden'),
      500,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('Neuigkeiten'), findsNothing);
  });

  testWidgets('has no entries for rating, sharing or other apps',
      (tester) async {
    await tester.pumpWidget(_build());
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.text('Abmelden'),
      500,
      scrollable: find.byType(Scrollable).first,
    );
    for (final gone in [
      'Bei Google Play bewerten',
      'App teilen',
      'Andere Apps von Wertwerk',
    ]) {
      expect(find.text(gone), findsNothing, reason: gone);
    }
  });

  testWidgets('every entry has its own rounded icon', (tester) async {
    await tester.pumpWidget(_build());
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.text('Abmelden'),
      500,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();
    final icons = [
      for (final e in tester.widgetList<Icon>(find.byType(Icon)))
        e.icon!.codePoint,
    ];
    expect(icons.toSet().length, icons.length, reason: 'icons repeat');
  });

  group('callbacks', () {
    testWidgets('goHome fires', (tester) async {
      var called = false;
      // Use a different page as current so Merkheft is not already selected;
      // some CollapsibleSidebar implementations suppress onPressed for the
      // already-selected item.
      await tester.pumpWidget(
        _build(current: Pages.grades, onGoHome: () => called = true),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Merkheft'));
      await tester.pump();
      expect(called, isTrue);
    });

    testWidgets('showGrades fires', (tester) async {
      var called = false;
      await tester.pumpWidget(_build(onShowGrades: () => called = true));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Bewertungen'));
      await tester.pump();
      expect(called, isTrue);
    });

    testWidgets('showCalendar fires', (tester) async {
      var called = false;
      await tester.pumpWidget(_build(onShowCalendar: () => called = true));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Kalender'));
      await tester.pump();
      expect(called, isTrue);
    });

    testWidgets('showCertificate fires', (tester) async {
      var called = false;
      await tester.pumpWidget(
        _build(onShowCertificate: () => called = true),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Zeugnis'));
      await tester.pump();
      expect(called, isTrue);
    });

    testWidgets('opens the about page when Über tapped', (tester) async {
      await tester.pumpWidget(_build());
      await tester.pumpAndSettle();
      await tester.scrollUntilVisible(
        find.text('Über'),
        500,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Über'));
      await tester.pumpAndSettle();
      expect(find.byType(AboutHubPage), findsOneWidget);
    });

    testWidgets('opens help & feedback page when Hilfe und Feedback tapped',
        (tester) async {
      await tester.pumpWidget(_build());
      await tester.pumpAndSettle();
      await tester.scrollUntilVisible(
        find.text('Hilfe und Feedback'),
        500,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Hilfe und Feedback'));
      await tester.pumpAndSettle();
      expect(find.byType(HelpFeedbackPage), findsOneWidget);
      expect(find.text('Email schreiben'), findsOneWidget);
      expect(find.text('Häufige Fragen'), findsOneWidget);
      expect(find.text('Feature/Idee vorschlagen'), findsOneWidget);
      expect(find.text('Bug/Fehler melden'), findsOneWidget);
    });

    testWidgets('logout fires', (tester) async {
      var called = false;
      await tester.pumpWidget(_build(onLogout: () => called = true));
      await tester.pumpAndSettle();
      await tester.scrollUntilVisible(
        find.text('Abmelden'),
        500,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Abmelden'));
      await tester.pump();
      expect(called, isTrue);
    });
  });

  group('golden', () {
    testGoldens('homework selected', (tester) async {
      await tester.pumpWidget(_build(current: Pages.homework));
      await tester.pumpAndSettle();
      await expectLater(
        find.byType(MaterialApp),
        matchesGoldenFile('sidebar_homework.png'),
      );
    });

    testGoldens('certificate selected', (tester) async {
      await tester.pumpWidget(_build(current: Pages.certificate));
      await tester.pumpAndSettle();
      await expectLater(
        find.byType(MaterialApp),
        matchesGoldenFile('sidebar_certificate.png'),
      );
    });
  });
}
