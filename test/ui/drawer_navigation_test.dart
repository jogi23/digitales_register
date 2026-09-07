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

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:responsive_scaffold/responsive_scaffold.dart';

/// Stands in for the pages the drawer can reach.
enum _Page { home, settings }

void main() {
  final navKey = GlobalKey<NavigatorState>();

  Widget page() {
    return MaterialApp(
      home: ResponsiveScaffold<_Page>(
        navKey: navKey,
        homeId: _Page.home,
        homeAppBar: AppBar(title: const Text("Mitteilungen")),
        homeBody: const Center(child: Text("Mitteilungen-Inhalt")),
        drawerBuilder: (select, goHome, current, tabletMode) => Drawer(
          child: TextButton(
            onPressed: () => select(
              const Scaffold(body: Center(child: Text("Einstellungen-Inhalt"))),
              _Page.settings,
            ),
            child: const Text("Einstellungen"),
          ),
        ),
      ),
    );
  }

  /// Narrow enough to get the drawer rather than the fixed side bar.
  Widget app() => Center(child: SizedBox(width: 300, child: page()));

  /// The scaffold that actually holds the drawer — there are several.
  ScaffoldState scaffold(WidgetTester tester) => tester.state(
        find.byWidgetPredicate((w) => w is Scaffold && w.drawer != null),
      );

  group('picking a page from the drawer', () {
    testWidgets('closes the drawer and shows the page', (tester) async {
      await tester.pumpWidget(app());
      scaffold(tester).openDrawer();
      await tester.pumpAndSettle();
      expect(scaffold(tester).isDrawerOpen, isTrue);

      await tester.tap(find.text("Einstellungen"));
      await tester.pumpAndSettle();
      expect(find.text("Einstellungen-Inhalt"), findsOneWidget);
      expect(scaffold(tester).isDrawerOpen, isFalse);
    });

    testWidgets('going back lands on the page one came from', (tester) async {
      // The drawer is not a route: popping the navigator to close it took the
      // page down instead, so going back revealed the drawer again.
      await tester.pumpWidget(app());
      scaffold(tester).openDrawer();
      await tester.pumpAndSettle();
      await tester.tap(find.text("Einstellungen"));
      await tester.pumpAndSettle();

      navKey.currentState!.pop();
      await tester.pumpAndSettle();

      expect(find.text("Mitteilungen-Inhalt"), findsOneWidget);
      expect(find.text("Einstellungen-Inhalt"), findsNothing);
      expect(scaffold(tester).isDrawerOpen, isFalse);
    });
  });
}
