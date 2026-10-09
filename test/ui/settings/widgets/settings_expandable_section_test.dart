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

import 'package:dr/ui/settings/widgets/settings_expandable_section.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../settings_pump.dart';

Widget _section(String title, {bool open = false}) => SettingsExpandableSection(
      title: title,
      summary: 'Kurztext $title',
      initiallyExpanded: open,
      children: [Text('Inhalt $title')],
    );

Widget _page(List<Widget> sections) =>
    Scaffold(body: SingleChildScrollView(child: Column(children: sections)));

void main() {
  testWidgets('is closed by default and shows the summary', (tester) async {
    await pumpSettings(tester, _page([_section('Eins')]));

    expect(find.text('Eins'), findsOneWidget);
    expect(find.text('Kurztext Eins'), findsOneWidget);
    expect(find.text('Inhalt Eins'), findsNothing);
  });

  testWidgets('tapping the header opens and closes it', (tester) async {
    await pumpSettings(tester, _page([_section('Eins')]));

    await tester.tap(find.text('Eins'));
    await tester.pumpAndSettle();
    expect(find.text('Inhalt Eins'), findsOneWidget);

    await tester.tap(find.text('Eins'));
    await tester.pumpAndSettle();
    expect(find.text('Inhalt Eins'), findsNothing);
  });

  testWidgets('initiallyExpanded starts open', (tester) async {
    await pumpSettings(tester, _page([_section('Eins', open: true)]));

    expect(find.text('Inhalt Eins'), findsOneWidget);
  });

  testWidgets('several sections can be open at once', (tester) async {
    await pumpSettings(tester, _page([_section('Eins'), _section('Zwei')]));

    await tester.tap(find.text('Eins'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Zwei'));
    await tester.pumpAndSettle();

    expect(find.text('Inhalt Eins'), findsOneWidget);
    expect(find.text('Inhalt Zwei'), findsOneWidget);
  });

  testWidgets('closed content is out of the semantics tree', (tester) async {
    await pumpSettings(tester, _page([_section('Eins')]));
    final handle = tester.ensureSemantics();

    expect(find.bySemanticsLabel('Inhalt Eins'), findsNothing);

    await tester.tap(find.text('Eins'));
    await tester.pumpAndSettle();
    expect(find.bySemanticsLabel('Inhalt Eins'), findsOneWidget);
    handle.dispose();
  });

  testWidgets('text scale 2.0 does not overflow', (tester) async {
    await pumpSettings(tester, _page([_section('Eins')]), textScale: 2);

    expect(tester.takeException(), isNull);
  });

  testWidgets('meets tap target guidelines', (tester) async {
    await pumpSettings(tester, _page([_section('Eins', open: true)]));

    await expectMeetsGuidelines(tester);
  });
}
