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

import 'package:dr/ui/settings/widgets/settings_headers.dart';
import 'package:dr/ui/settings/widgets/settings_page_scaffold.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:responsive_scaffold/responsive_scaffold.dart';

import '../settings_pump.dart';

void main() {
  testWidgets('section header is a primary titleSmall header', (tester) async {
    await pumpSettings(
        tester, const Scaffold(body: SettingsSectionHeader('Noten')));
    final handle = tester.ensureSemantics();

    final context = tester.element(find.text('Noten'));
    final text = tester.widget<Text>(find.text('Noten'));
    expect(
      text.style?.color,
      Theme.of(context).colorScheme.primary,
    );
    expect(
      text.style?.fontSize,
      Theme.of(context).textTheme.titleSmall?.fontSize,
    );
    expect(
      tester.getSemantics(find.text('Noten')),
      matchesSemantics(label: 'Noten', isHeader: true),
    );
    final padding = tester.widget<Padding>(
      find
          .ancestor(of: find.text('Noten'), matching: find.byType(Padding))
          .first,
    );
    expect(padding.padding, const EdgeInsets.fromLTRB(16, 24, 16, 8));
    handle.dispose();
  });

  testWidgets('subheader uses labelLarge', (tester) async {
    await pumpSettings(
        tester, const Scaffold(body: SettingsSubheader('Anzeige')));

    final context = tester.element(find.text('Anzeige'));
    final text = tester.widget<Text>(find.text('Anzeige'));
    expect(
        text.style?.fontSize, Theme.of(context).textTheme.labelLarge?.fontSize);
  });

  testWidgets('scaffold shows title and children', (tester) async {
    await pumpSettings(
      tester,
      const SettingsPageScaffold(title: 'Titel', children: [Text('Inhalt')]),
    );

    expect(find.text('Titel'), findsOneWidget);
    expect(find.text('Inhalt'), findsOneWidget);
  });

  testWidgets('only the root page carries the menu button bar', (tester) async {
    await pumpSettings(
      tester,
      const SettingsPageScaffold(
        title: 'Wurzel',
        root: true,
        children: [Text('x')],
      ),
    );
    expect(find.byType(ResponsiveAppBar), findsOneWidget);

    await pumpSettings(
      tester,
      const SettingsPageScaffold(title: 'Unterseite', children: [Text('x')]),
    );
    expect(find.byType(ResponsiveAppBar), findsNothing);
    expect(find.byType(AppBar), findsOneWidget);
  });
}
