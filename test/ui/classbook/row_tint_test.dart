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

import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:built_collection/built_collection.dart';
import 'package:dr/app_state.dart';
import 'package:dr/data.dart';
import 'package:dr/ui/app_theme.dart';
import 'package:dr/ui/classbook_page.dart';
import 'package:dr/ui/lesson_entry_list.dart';
import 'package:dr/utc_date_time.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';

CalendarHour _hour(int fromHour, String subject, String content) => CalendarHour(
      (b) => b
        ..fromHour = fromHour
        ..toHour = fromHour
        ..subject = subject
        ..rooms = ListBuilder<String>()
        ..timeSpans = ListBuilder<TimeSpan>()
        ..homeworkExams = ListBuilder<HomeworkExam>()
        ..teachers = ListBuilder<Teacher>([
          Teacher((t) => t
            ..firstName = 'Anna'
            ..lastName = 'Musterfrau'),
        ])
        ..lessonContents = ListBuilder<LessonContent>([
          LessonContent((c) => c
            ..name = content
            ..typeName = ordinaryLessonType
            ..submissions = ListBuilder<LessonContentSubmission>()),
        ]),
    );

/// Genug Tage und Stunden, dass die Liste weit über den Schirm hinausreicht.
List<CalendarDay> _wochen() => [
      for (var tag = 1; tag <= 8; tag++)
        CalendarDay((b) => b
          ..date = UtcDateTime(2026, 9, tag)
          ..hours = ListBuilder<CalendarHour>([
            _hour(1, 'Mathematik', 'Zahlenmengen'),
            _hour(3, 'Geschichte', 'Nationalismus'),
            _hour(5, 'Deutsch', 'Wortarten'),
            _hour(7, 'Musik', 'Notenlehre'),
            _hour(9, 'Naturkunde', 'Zellen'),
          ])),
    ];

Widget _seite() => MaterialApp(
      theme: appTheme(Brightness.dark, const Color(0xFFE57373)),
      locale: const Locale('de'),
      supportedLocales: const [Locale('de')],
      localizationsDelegates: const [
        GlobalCupertinoLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ],
      home: RepaintBoundary(
        child: Scaffold(
          body: LessonEntryList(
            entries: classbookEntries(_wochen()),
            viewMode: ClassbookViewMode.chronological,
            displayMode: EntryDisplayMode.list,
            selectedSubjects: const [],
            onSelectedSubjectsChanged: (_) {},
            subjectLabel: (subject) => subject.substring(0, 3),
            loadingText: 'lädt',
            emptyText: 'leer',
            ordinaryType: ordinaryLessonType,
          ),
        ),
      ),
    );

/// Die Pixel des Fächer-Filters, also alles oberhalb der Liste.
Future<Uint8List> _filterPixels(WidgetTester tester) async {
  final grenze = tester.getTopLeft(find.byType(CustomScrollView)).dy;
  final boundary = tester.renderObject<RenderRepaintBoundary>(
    find.byType(RepaintBoundary).first,
  );
  // Das Rastern braucht die echte Ereignisschleife, deshalb `runAsync`.
  final daten = await tester.runAsync(() async {
    final bild = await boundary.toImage();
    final bytes = await bild.toByteData(format: ui.ImageByteFormat.rawRgba);
    bild.dispose();
    return bytes;
  });
  final breite = boundary.size.width.round();
  return daten!.buffer.asUint8List(0, (grenze.round() * breite * 4));
}

void main() {
  setUpAll(() async => initializeDateFormatting('de'));

  testWidgets('die Tönung der Zeilen bleibt in der Liste', (tester) async {
    tester.view.physicalSize = const Size(400, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(_seite());
    await tester.pumpAndSettle();
    final ruhend = await _filterPixels(tester);

    // Jede zweite Zeile ist getönt: Nach ein paar Pixeln Scrollen steht eine
    // andere Zeile am oberen Rand der Liste. Über der Liste darf sich davon
    // nichts zeigen - `ListTile.tileColor` malte dort hinein, weil Flutter es
    // auf das Material des Gerüsts legt statt in die Zeile selbst.
    for (final weg in [20.0, 40.0, 60.0, 80.0, 100.0]) {
      await tester.drag(find.byType(CustomScrollView), Offset(0, -weg));
      await tester.pumpAndSettle();
      expect(await _filterPixels(tester), ruhend,
          reason: 'nach $weg Pixeln Scrollen');
    }
  });
}
