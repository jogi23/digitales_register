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

import 'package:dr/ui/help_feedback_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Widget build() => const MaterialApp(home: HelpFeedbackPage());

  testWidgets('shows title and all entries', (tester) async {
    await tester.pumpWidget(build());
    await tester.pumpAndSettle();
    expect(find.text('Hilfe & Feedback'), findsOneWidget);
    expect(find.text('Email schreiben'), findsOneWidget);
    expect(find.text('FAQ'), findsOneWidget);
    expect(find.text('Feature/Idee vorschlagen'), findsOneWidget);
    expect(find.text('Bug/Fehler melden'), findsOneWidget);
  });

  testWidgets('shows an icon for every entry', (tester) async {
    await tester.pumpWidget(build());
    await tester.pumpAndSettle();
    expect(find.byIcon(Icons.email), findsOneWidget);
    expect(find.byIcon(Icons.help_outline), findsOneWidget);
    expect(find.byIcon(Icons.lightbulb_outline), findsOneWidget);
    expect(find.byIcon(Icons.bug_report_outlined), findsOneWidget);
  });
}
