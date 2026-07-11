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
import 'package:dr/ui/help_feedback_page.dart';
import 'package:dr/ui/sidebar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:golden_toolkit/golden_toolkit.dart';

// Sidebar requires a non-zero height to render items.
const _testSize = Size(300, 700);

Widget _build({
  Pages current = Pages.homework,
  String? username = 'max.mustermann',
  String? alias,
  bool tabletMode = false,
  bool drawerExpanded = true,
  VoidCallback? onGoHome,
  VoidCallback? onShowGrades,
  VoidCallback? onShowAbsences,
  VoidCallback? onShowCalendar,
  VoidCallback? onShowCertificate,
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
          username: username,
          alias: alias,
          userIcon: null,
          tabletMode: tabletMode,
          drawerExpanded: drawerExpanded,
          onDrawerExpansionChange: (_) {},
          goHome: onGoHome ?? () {},
          showGrades: onShowGrades ?? () {},
          showAbsences: onShowAbsences ?? () {},
          showCalendar: onShowCalendar ?? () {},
          showCertificate: onShowCertificate ?? () {},
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
    expect(find.text('Einstellungen'), findsOneWidget);
    expect(find.text('Hilfe und Feedback'), findsOneWidget);
    expect(find.text('Über diese App'), findsOneWidget);
    // The sidebar list is scrollable and doesn't build off-screen items
    // eagerly, so the last item needs scrolling into view first.
    await tester.scrollUntilVisible(
      find.text('Abmelden'),
      500,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();
    expect(find.text('Abmelden'), findsOneWidget);
  });

  testWidgets('shows username when no alias', (tester) async {
    await tester.pumpWidget(_build(username: 'max.mustermann', alias: null));
    await tester.pumpAndSettle();
    expect(find.text('max.mustermann'), findsOneWidget);
  });

  testWidgets('shows alias instead of username when both set', (tester) async {
    await tester.pumpWidget(
      _build(username: 'max.mustermann', alias: 'Max M.'),
    );
    await tester.pumpAndSettle();
    expect(find.text('Max M.'), findsOneWidget);
    expect(find.text('max.mustermann'), findsNothing);
  });

  testWidgets('shows placeholder when no username and no alias', (tester) async {
    await tester.pumpWidget(_build(username: null, alias: null));
    await tester.pumpAndSettle();
    expect(find.text('?'), findsOneWidget);
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

    testWidgets('shows about dialog when Über diese App tapped',
        (tester) async {
      await tester.pumpWidget(_build());
      await tester.pumpAndSettle();
      await tester.tap(find.text('Über diese App'));
      await tester.pumpAndSettle();
      expect(find.byType(AboutDialog), findsOneWidget);
    });

    testWidgets(
        'opens help & feedback page when Hilfe und Feedback tapped',
        (tester) async {
      await tester.pumpWidget(_build());
      await tester.pumpAndSettle();
      await tester.tap(find.text('Hilfe und Feedback'));
      await tester.pumpAndSettle();
      expect(find.byType(HelpFeedbackPage), findsOneWidget);
      expect(find.text('Email schreiben'), findsOneWidget);
      expect(find.text('FAQ'), findsOneWidget);
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
