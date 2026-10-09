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

import 'package:dr/app_links.dart';
import 'package:dr/services/changelog.dart';
import 'package:dr/ui/about_page.dart';
import 'package:dr/ui/changelog_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:url_launcher_platform_interface/url_launcher_platform_interface.dart';

import '../../fake_url_launcher.dart';

class _NoChangelog extends Changelog {
  @override
  Future<List<ChangelogEntry>> load() async => const [];
  @override
  Future<String?> previousSeen() async => null;
}

void main() {
  late FakeUrlLauncher launcher;

  setUp(() {
    launcher = FakeUrlLauncher.install();
  });
  tearDown(() => changelog = Changelog());

  Future<void> pumpPage(WidgetTester tester) async {
    await tester.pumpWidget(const MaterialApp(home: AboutPage()));
    await tester.pumpAndSettle();
  }

  Future<void> tapRow(WidgetTester tester, String label) async {
    await tester.scrollUntilVisible(
      find.text(label),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text(label));
    await tester.pumpAndSettle();
  }

  testWidgets('shows the name, a version pill and the independence note',
      (tester) async {
    await pumpPage(tester);
    expect(find.text('DigiReg ST'), findsOneWidget);
    expect(find.text('Version 1.0'), findsOneWidget);
    expect(find.textContaining('unabhängige App'), findsOneWidget);
  });

  testWidgets('reads the app name once, not for the logo as well',
      (tester) async {
    final handle = tester.ensureSemantics();
    await pumpPage(tester);
    expect(find.bySemanticsLabel('DigiReg ST'), findsOneWidget);
    handle.dispose();
  });

  testWidgets('names the three developers', (tester) async {
    await pumpPage(tester);
    await tester.scrollUntilVisible(
      find.text('Simon Wachtler'),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('Johannes Feichter'), findsOneWidget);
    expect(find.text('Michael Debertol'), findsOneWidget);
    expect(find.text('Simon Wachtler'), findsOneWidget);
  });

  testWidgets('opens imprint, terms and privacy from "Rechtliches"',
      (tester) async {
    await pumpPage(tester);
    await tapRow(tester, 'Impressum');
    await tapRow(tester, 'Nutzungsbedingungen');
    await tapRow(tester, 'Datenschutzerklärung');
    expect(launcher.launched, [
      AppLinks.imprint.toString(),
      AppLinks.terms.toString(),
      AppLinks.privacy.toString(),
    ]);
    expect(launcher.lastMode, PreferredLaunchMode.externalApplication);
  });

  testWidgets('opens the source code', (tester) async {
    await pumpPage(tester);
    await tapRow(tester, 'Quellcode (GPL)');
    expect(launcher.launched, [AppLinks.source.toString()]);
  });

  testWidgets('opens the changelog', (tester) async {
    changelog = _NoChangelog();
    await pumpPage(tester);
    await tapRow(tester, 'Neuerungen');
    expect(find.byType(ChangelogPage), findsOneWidget);
  });

  testWidgets('opens the license page', (tester) async {
    await pumpPage(tester);
    await tapRow(tester, 'Open-Source-Lizenzen');
    expect(find.byType(LicensePage), findsOneWidget);
  });
}
