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

import 'package:dr/app_state.dart';
import 'package:dr/ui/settings/widgets/view_option_tiles.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../settings_pump.dart';

Widget _display({
  EntryDisplayMode value = EntryDisplayMode.list,
  required List<EntryDisplayMode> picked,
  bool offerTimeline = false,
  bool timelineEnabled = true,
}) =>
    Scaffold(
      body: SingleChildScrollView(
        child: DisplayModeTiles(
          value: value,
          onChanged: picked.add,
          offerTimeline: offerTimeline,
          timelineEnabled: timelineEnabled,
        ),
      ),
    );

void main() {
  testWidgets('list and cards are offered, the timeline only on request',
      (tester) async {
    await pumpSettings(tester, _display(picked: []));
    expect(find.text('Liste'), findsOneWidget);
    expect(find.text('Karten'), findsOneWidget);
    expect(find.text('Zeitleiste'), findsNothing);

    await pumpSettings(tester, _display(picked: [], offerTimeline: true));
    expect(find.text('Zeitleiste'), findsOneWidget);
  });

  testWidgets('the timeline is disabled with the reason when it cannot apply',
      (tester) async {
    final picked = <EntryDisplayMode>[];
    await pumpSettings(
      tester,
      _display(picked: picked, offerTimeline: true, timelineEnabled: false),
    );

    expect(find.text('Nur bei Anordnung nach Tagen'), findsOneWidget);
    await tester.tap(find.text('Zeitleiste'));
    await tester.pumpAndSettle();
    expect(picked, isEmpty);
  });

  testWidgets('picking cards reports EntryDisplayMode.cards', (tester) async {
    final picked = <EntryDisplayMode>[];
    await pumpSettings(tester, _display(picked: picked));

    await tester.tap(find.text('Karten'));
    await tester.pumpAndSettle();

    expect(picked, [EntryDisplayMode.cards]);
  });

  testWidgets('arrangement offers by day and by subject and reports the pick',
      (tester) async {
    final picked = <ClassbookViewMode>[];
    await pumpSettings(
      tester,
      Scaffold(
        body: ArrangementTiles(
          value: ClassbookViewMode.chronological,
          onChanged: picked.add,
        ),
      ),
    );
    expect(find.text('Nach Tagen'), findsOneWidget);

    await tester.tap(find.text('Nach Fach'));
    await tester.pumpAndSettle();

    expect(picked, [ClassbookViewMode.bySubject]);
  });
}
