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

import 'package:dr/ui/help_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Widget build() => const MaterialApp(home: HelpPage());

  const questions = [
    'Wie melde ich mich an?',
    'Warum kommen Benachrichtigungen verspätet?',
    'Wie wechsle ich zwischen Konten?',
    'Wo sehe ich meine Hausaufgaben?',
    'Wie schütze ich die App mit der Gerätesperre?',
  ];

  testWidgets('lists the common questions', (tester) async {
    await tester.pumpWidget(build());
    await tester.pumpAndSettle();
    expect(find.text('Häufige Fragen'), findsOneWidget);
    for (final question in questions) {
      expect(find.text(question), findsOneWidget);
    }
  });

  testWidgets('shows an answer only after the question was tapped',
      (tester) async {
    await tester.pumpWidget(build());
    await tester.pumpAndSettle();
    expect(find.textContaining('Bestätigungscode'), findsNothing);

    await tester.tap(find.text(questions.first));
    await tester.pumpAndSettle();
    expect(find.textContaining('Bestätigungscode'), findsOneWidget);

    await tester.tap(find.text(questions.first));
    await tester.pumpAndSettle();
    expect(find.textContaining('Bestätigungscode'), findsNothing);
  });
}
