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

import 'package:dr/providers/message_compose_provider.dart';
import 'package:dr/ui/message_compose.dart';
import 'package:dr/ui/snack_bar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

const _teacherJson = <String, Object?>{
  'type': 'user',
  'id': 7330,
  'name': 'Lechner Silke',
  'contextstr': [
    {'f': 'txt', 'key': 'Lechner Silke ('},
    {'f': 't', 'key': 'message.recipients.teacher'},
    {'f': 'txt', 'key': ')'},
  ],
};

/// A teacher who is not a recipient yet, as the search finds her.
const _otherTeacherJson = <String, Object?>{
  'type': 'user',
  'id': 9001,
  'name': 'Muster Maria',
  'contextstr': [
    {'f': 'txt', 'key': 'Muster Maria ('},
    {'f': 't', 'key': 'message.recipients.teacher'},
    {'f': 'txt', 'key': ')'},
  ],
};

/// Ready to write, with one teacher as recipient — ticked or not.
MessageComposeState _state({bool ticked = true, bool allowed = true}) =>
    MessageComposeState(
      ready: true,
      type: allowed ? const {'typeId': 'read'} : null,
      permission: 'me',
      recipients: const [MessageRecipient(_teacherJson)],
      groups: [
        RecipientGroup(
          const {'type': 'user', 'name': 'Lechner Silke'},
          recipientKey: 'user:7330',
          people: [
            RecipientPerson(
              const {'id': 7330, 'name': 'Lechner Silke'},
              selected: ticked,
            ),
          ],
        ),
      ],
    );

class _Calls {
  final List<String> searches = [];
  final List<MessageRecipient> added = [];
  int sends = 0;
}

Widget _page(
  MessageComposeState state,
  _Calls calls, {
  String? sendResult,
  List<MessageRecipient> hits = const [],
}) {
  scaffoldMessengerKey = GlobalKey<ScaffoldMessengerState>();
  return MaterialApp(
    scaffoldMessengerKey: scaffoldMessengerKey,
    home: Builder(
      builder: (context) => Scaffold(
        body: Center(
          child: TextButton(
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) => MessageComposePage(
                  state: state,
                  noInternet: false,
                  initialSubject: '',
                  onSearch: (filter) async {
                    calls.searches.add(filter);
                    return hits;
                  },
                  onAdd: calls.added.add,
                  onRemove: (_) {},
                  onToggle: (_, __) {},
                  onTickAll: (_) {},
                  onSend: ({required subject, required text}) async {
                    calls.sends++;
                    return sendResult;
                  },
                ),
              ),
            ),
            child: const Text('open'),
          ),
        ),
      ),
    ),
  );
}

Future<void> _open(WidgetTester tester, Widget page) async {
  // Tall enough for the whole form: a ListView does not build what lies
  // beyond the screen, and the send button sits at its end.
  tester.view
    ..physicalSize = const Size(800, 2000)
    ..devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(page);
  await tester.tap(find.text('open'));
  await tester.pumpAndSettle();
}

/// The send button on the page. By predicate: `FilledButton.icon` builds a
/// subclass, which `find.byType` does not match.
FilledButton _sendButton(WidgetTester tester) => tester.widget<FilledButton>(
      find.ancestor(
        of: find.text('Senden'),
        matching: find.byWidgetPredicate((widget) => widget is FilledButton),
      ),
    );

Future<void> _write(WidgetTester tester) async {
  await tester.enterText(find.widgetWithText(TextField, 'Betreff'), 'Ausflug');
  await tester.enterText(find.widgetWithText(TextField, 'Mitteilung'), 'Hallo');
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('sending waits for subject and text', (tester) async {
    await _open(tester, _page(_state(), _Calls()));
    expect(_sendButton(tester).onPressed, isNull);
    await _write(tester);
    expect(_sendButton(tester).onPressed, isNotNull);
  });

  testWidgets('nobody ticked, nothing to send', (tester) async {
    await _open(tester, _page(_state(ticked: false), _Calls()));
    await _write(tester);
    expect(_sendButton(tester).onPressed, isNull);
    expect(find.text('0 von 1 ausgewählt'), findsOneWidget);
  });

  testWidgets('search asks after a pause and adds a hit', (tester) async {
    final calls = _Calls();
    await _open(
      tester,
      _page(_state(), calls, hits: const [MessageRecipient(_otherTeacherJson)]),
    );
    await tester.enterText(
        find.widgetWithText(TextField, 'Empfänger suchen'), 'Mu');
    await tester.pump(const Duration(milliseconds: 100));
    expect(calls.searches, isEmpty);
    await tester.pump(const Duration(milliseconds: 300));
    await tester.pumpAndSettle();
    expect(calls.searches, ['Mu']);
    // The role comes from the translatable part of contextstr.
    expect(find.text('Lehrperson'), findsOneWidget);

    await tester.tap(find.byIcon(Icons.add));
    expect(calls.added.single.id, 9001);
  });

  testWidgets('asks before sending, and cancelling sends nothing',
      (tester) async {
    final calls = _Calls();
    await _open(tester, _page(_state(), calls));
    await _write(tester);
    await tester.ensureVisible(find.text('Senden'));
    await tester.tap(find.text('Senden'));
    await tester.pumpAndSettle();
    expect(find.text('Die Mitteilung geht an 1 Person.'), findsOneWidget);

    await tester.tap(find.text('Abbrechen'));
    await tester.pumpAndSettle();
    expect(calls.sends, 0);
  });

  testWidgets('a sent message closes the page', (tester) async {
    final calls = _Calls();
    await _open(tester, _page(_state(), calls));
    await _write(tester);
    await tester.ensureVisible(find.text('Senden'));
    await tester.tap(find.text('Senden'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, 'Senden').last);
    await tester.pumpAndSettle();
    expect(calls.sends, 1);
    expect(find.byType(MessageComposePage), findsNothing);
    expect(find.text('Mitteilung gesendet'), findsOneWidget);
  });

  testWidgets('a rejected message says so and stays', (tester) async {
    await _open(tester, _page(_state(), _Calls(), sendResult: 'no_recipients'));
    await _write(tester);
    await tester.ensureVisible(find.text('Senden'));
    await tester.tap(find.text('Senden'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, 'Senden').last);
    await tester.pumpAndSettle();
    expect(find.textContaining('abgelehnt (no_recipients)'), findsOneWidget);
    expect(find.byType(MessageComposePage), findsOneWidget);
  });

  testWidgets('back with a draft asks first', (tester) async {
    await _open(tester, _page(_state(), _Calls()));
    await _write(tester);
    final navigator = tester.state<NavigatorState>(find.byType(Navigator));
    await navigator.maybePop();
    await tester.pumpAndSettle();
    expect(find.text('Entwurf verwerfen?'), findsOneWidget);

    await tester.tap(find.text('Verwerfen'));
    await tester.pumpAndSettle();
    expect(find.byType(MessageComposePage), findsNothing);
  });

  testWidgets('an account that may not send is told', (tester) async {
    await _open(tester, _page(_state(allowed: false), _Calls()));
    expect(
      find.text('Dieses Konto darf keine Mitteilungen senden.'),
      findsOneWidget,
    );
  });
}
