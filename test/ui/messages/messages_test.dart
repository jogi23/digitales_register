// Copyright (C) 2021 Michael Debertol
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

import 'package:built_collection/built_collection.dart';
import 'package:dr/app_state.dart';
import 'package:dr/container/messages_container.dart';
import 'package:dr/data.dart';
import 'package:dr/providers/messages_provider.dart';
import 'package:dr/providers/no_internet_provider.dart';
import 'package:dr/utc_date_time.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:golden_toolkit/golden_toolkit.dart';

const _messageText =
    '{"ops":[{"insert":"Sehr geehrte Eltern,\\nliebe Schülerinnen und Schüler,\\nwie Sie aus den Medien erfahren haben, hat die italienische Regierung heute Abend definitiv beschlossen, alle Schulen und Bildungseinrichtungen in Italien bis 15. März zu schließen, um die Ausbreitung des Corona-Virus einzudämmen. \\nAus diesem Grund muss auch "},{"attributes":{"bold":true},"insert":"der Schul- und Internatsbetrieb im Vinzentinum"},{"insert":" "},{"attributes":{"bold":true},"insert":"während dieser Tage eingestellt"},{"insert":" werden. \\nDie Bildungsdirektion bereitet ein Rundschreiben vor mit genaueren Hinweisen darauf, was dies konkret für die Schülerinnen und Schüler bedeutet. Wir werden Sie dann umgehend informieren. \\nWer noch Instrumente und Schulmaterialien abholen möchte, kann sich morgen zwischen 9.00 und 12.30 Uhr an den Heimleiter Paul Felix Rigo wenden.\\nDas "},{"attributes":{"bold":true},"insert":"Schulsekretariat bleibt geöffnet"},{"insert":". Der Schülertransport ist ausgesetzt.\\nChristoph Stragenegg\\nDirektor\\n"}]}';

class _TestMessagesNotifier extends MessagesNotifier {
  final MessagesState initialState;
  _TestMessagesNotifier(this.initialState);

  @override
  MessagesState build() => initialState;
}

MessagesState _buildState({
  required bool downloading,
  required bool fileAvailable,
}) {
  return MessagesState(
    (b) => b.messages = ListBuilder(
      <Message>[
        Message(
          (b) => b
            ..attachments = ListBuilder(
              <MessageAttachmentFile>[
                MessageAttachmentFile(
                  (b) => b
                    ..downloading = downloading
                    ..fileAvailable = fileAvailable
                    ..file = "attachment.png"
                    ..originalName = "Bild.png"
                    ..messageId = 123
                    ..id = 12,
                )
              ],
            )
            ..fromName = "Sender"
            ..recipientString = "Empfänger"
            ..id = 25
            ..subject = "Betreff"
            ..timeSent = UtcDateTime.parse("2020-03-04 20:57:38")
            ..text = _messageText,
        )
      ],
    ),
  );
}

Widget _buildWidget(MessagesState state) {
  return ProviderScope(
    overrides: [
      messagesProvider.overrideWith(() => _TestMessagesNotifier(state)),
      noInternetProvider.overrideWith(NoInternetNotifier.new),
    ],
    child: MaterialApp(
      home: MessagesPageContainer(),
    ),
  );
}


MessagesState _stateWithResponse(MessageResponseInfo? info) {
  return MessagesState(
    (b) => b.messages = ListBuilder(
      <Message>[
        Message(
          (b) => b
            ..fromName = "Sender"
            ..recipientString = "Empfänger"
            ..id = 25
            ..subject = "Betreff"
            ..timeSent = UtcDateTime.parse("2020-03-04 20:57:38")
            ..text = _messageText
            ..responseInfo = info?.toBuilder(),
        )
      ],
    ),
  );
}

MessageResponseInfo _info({
  String type = MessageResponseInfo.typeAgree,
  bool signatureRequired = false,
  bool parentSignatureRequired = false,
  String? givenResponse,
  String? givenSignature,
  String? historyText,
  String? badge,
}) {
  return MessageResponseInfo(
    (b) => b
      ..type = type
      ..responseRequired = type == MessageResponseInfo.typeAgree
      ..signatureRequired = signatureRequired
      ..parentSignatureRequired = parentSignatureRequired
      ..givenResponse = givenResponse
      ..givenSignature = givenSignature
      ..historyText = historyText
      ..badge = badge,
  );
}

/// Opens the single message so the confirmation section is built.
Future<void> _openMessage(WidgetTester tester, MessagesState state) async {
  await tester.pumpWidget(_buildWidget(state));
  await tester.tap(find.text("Betreff"));
  await tester.pumpAndSettle();
}

void main() {
  testGoldens('with attachment', (WidgetTester tester) async {
    final widget = _buildWidget(
      _buildState(downloading: false, fileAvailable: false),
    );
    await tester.pumpWidget(widget);
    expect(find.text("Betreff"), findsOneWidget);
    await tester.tap(find.text("Betreff"));
    await tester.pumpAndSettle();
    expect(find.textContaining("Sehr geehrte Eltern"), findsOneWidget);
    expect(find.text("Anhang:"), findsOneWidget);
    expect(find.text("Öffnen"), findsOneWidget);
    await expectLater(
      find.byType(MaterialApp),
      matchesGoldenFile("with_attachment.png"),
    );
  });
  testGoldens('downloading attachment', (WidgetTester tester) async {
    final widget = _buildWidget(
      _buildState(downloading: true, fileAvailable: false),
    );
    await tester.pumpWidget(widget);
    expect(find.text("Betreff"), findsOneWidget);
    await tester.tap(find.text("Betreff"));
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));
    expect(find.byType(LinearProgressIndicator), findsOneWidget);
    await expectLater(
      find.byType(MaterialApp),
      matchesGoldenFile("attachment_downloading.png"),
    );
  });
  testGoldens('downloaded attachment', (WidgetTester tester) async {
    final widget = _buildWidget(
      _buildState(downloading: false, fileAvailable: true),
    );
    await tester.pumpWidget(widget);
    expect(find.text("Betreff"), findsOneWidget);
    await tester.tap(find.text("Betreff"));
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));
    await expectLater(
      find.byType(MaterialApp),
      matchesGoldenFile("attachment_downloaded.png"),
    );
  });

  group('confirmation section', () {
    testWidgets('agree message shows both buttons and no signature field',
        (tester) async {
      await _openMessage(tester, _stateWithResponse(_info()));
      expect(find.text("Stimme zu"), findsOneWidget);
      expect(find.text("Stimme nicht zu"), findsOneWidget);
      expect(find.byType(TextField), findsNothing);
    });

    testWidgets('signature message shows a field and one confirm button',
        (tester) async {
      await _openMessage(
        tester,
        _stateWithResponse(
          _info(type: MessageResponseInfo.typeRead, signatureRequired: true),
        ),
      );
      expect(find.byType(TextField), findsOneWidget);
      expect(find.text("Bestätigen"), findsOneWidget);
      expect(find.text("Stimme zu"), findsNothing);
    });

    testWidgets('confirm stays disabled until a name is typed',
        (tester) async {
      await _openMessage(
        tester,
        _stateWithResponse(
          _info(type: MessageResponseInfo.typeRead, signatureRequired: true),
        ),
      );
      FilledButton button() => tester.widget<FilledButton>(
            find.widgetWithText(FilledButton, "Bestätigen"),
          );
      expect(button().onPressed, isNull);

      await tester.enterText(find.byType(TextField), "Max Mustermann");
      await tester.pumpAndSettle();
      expect(button().onPressed, isNotNull);
    });

    testWidgets('whitespace alone does not enable the confirm button',
        (tester) async {
      await _openMessage(
        tester,
        _stateWithResponse(
          _info(type: MessageResponseInfo.typeRead, signatureRequired: true),
        ),
      );
      await tester.enterText(find.byType(TextField), "   ");
      await tester.pumpAndSettle();
      expect(
        tester
            .widget<FilledButton>(
              find.widgetWithText(FilledButton, "Bestätigen"),
            )
            .onPressed,
        isNull,
      );
    });

    testWidgets('an answered message shows the history instead of controls',
        (tester) async {
      await _openMessage(
        tester,
        _stateWithResponse(
          _info(
            type: MessageResponseInfo.typeRead,
            signatureRequired: true,
            givenSignature: "Notburga Mair",
            historyText: "Von Eltern-Account 1 am 05.09.2026 bestätigt.",
          ),
        ),
      );
      expect(
        find.text("Von Eltern-Account 1 am 05.09.2026 bestätigt."),
        findsOneWidget,
      );
      expect(find.text("Bestätigen"), findsNothing);
      expect(find.byType(TextField), findsNothing);
    });

    testWidgets('guardian-only messages offer no controls', (tester) async {
      await _openMessage(
        tester,
        _stateWithResponse(_info(parentSignatureRequired: true)),
      );
      expect(find.textContaining("Erziehungsberechtigten"), findsOneWidget);
      expect(find.text("Stimme zu"), findsNothing);
    });

    testWidgets('an unknown response type points to the browser',
        (tester) async {
      await _openMessage(
        tester,
        _stateWithResponse(_info(type: "poll")),
      );
      expect(find.textContaining("im Browser"), findsOneWidget);
      expect(find.text("Stimme zu"), findsNothing);
      expect(find.text("Bestätigen"), findsNothing);
    });

    testWidgets('a message without confirmation shows no section',
        (tester) async {
      await _openMessage(tester, _stateWithResponse(null));
      expect(find.text("Stimme zu"), findsNothing);
      expect(find.text("Bestätigen"), findsNothing);
      expect(find.byType(TextField), findsNothing);
    });
  });
}
