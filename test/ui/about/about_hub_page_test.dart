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
import 'package:dr/services/app_sharing.dart';
import 'package:dr/ui/about_hub_page.dart';
import 'package:dr/ui/about_page.dart';
import 'package:dr/util.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:url_launcher_platform_interface/url_launcher_platform_interface.dart';

import '../../fake_url_launcher.dart';
import '../../system_bars.dart';

void main() {
  Widget build() => const MaterialApp(home: AboutHubPage());

  Future<void> pumpPage(WidgetTester tester) async {
    await tester.pumpWidget(build());
    await tester.pumpAndSettle();
  }

  testWidgets(
      'shows the four rows, "Andere Apps" and "Über die App" with a '
      'subtitle', (tester) async {
    await pumpPage(tester);
    expect(find.text('Bei Google Play bewerten'), findsOneWidget);
    expect(find.text('App teilen'), findsOneWidget);
    expect(find.text('Andere Apps von Wertwerk'), findsOneWidget);
    expect(find.text('Weitere Apps im Play Store'), findsOneWidget);
    expect(find.text('Über die App'), findsOneWidget);
    expect(find.text('Version $appVersion'), findsOneWidget);
  });

  testWidgets('every row has a rounded icon and the right trailing symbol',
      (tester) async {
    await pumpPage(tester);
    expect(find.byIcon(Icons.star_rounded), findsOneWidget);
    expect(find.byIcon(Icons.share_rounded), findsOneWidget);
    expect(find.byIcon(Icons.apps_rounded), findsOneWidget);
    expect(find.byIcon(Icons.info_rounded), findsOneWidget);
    expect(find.byIcon(Icons.open_in_new_rounded), findsNWidgets(2));
    expect(find.byIcon(Icons.chevron_right_rounded), findsOneWidget);
  });

  testWidgets('"Bewerten" opens the store listing', (tester) async {
    final launcher = FakeUrlLauncher.install();
    await pumpPage(tester);
    await tester.tap(find.text('Bei Google Play bewerten'));
    await tester.pumpAndSettle();
    expect(launcher.launched, [playStoreAppUri.toString()]);
  });

  testWidgets('"Andere Apps" opens the developer page in the browser',
      (tester) async {
    final launcher = FakeUrlLauncher.install();
    await pumpPage(tester);
    await tester.tap(find.text('Andere Apps von Wertwerk'));
    await tester.pumpAndSettle();
    expect(launcher.launched, [AppLinks.otherApps.toString()]);
    expect(launcher.lastMode, PreferredLaunchMode.externalApplication);
  });

  testWidgets('"Über die App" opens the about page', (tester) async {
    await pumpPage(tester);
    await tester.tap(find.text('Über die App'));
    await tester.pumpAndSettle();
    expect(find.byType(AboutPage), findsOneWidget);
  });

  testWidgets('meets tap target and label guidelines', (tester) async {
    await pumpPage(tester);
    await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
    await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
  });

  for (final holding in Holding.values) {
    testWidgets('the last row stays clear of the bars, ${holding.name}',
        (tester) async {
      holdPhone(tester, holding);
      await pumpPage(tester);
      await scrollToEnd(tester);
      expectClearOfSystemBars(tester, find.byType(ListTile).last);
    });
  }
}
