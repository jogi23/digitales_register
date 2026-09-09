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

import 'package:dr/data.dart';
import 'package:dr/middleware/middleware.dart';
import 'package:dr/providers/messages_provider.dart';
import 'package:dr/wrapper.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../fixtures/api_fixtures.dart';

class MockWrapper extends Mock implements Wrapper {}

/// Ids from the demo capture, one per confirmation case.
const _agreeOpenId = 58317; // responseType agree, unanswered
const _signedId = 31241; // signatureRequired, already signed
const _plainId = 39102; // read without signature -> no confirmation

void main() {
  setUpAll(loadFixtures);

  late ProviderContainer container;

  Message messageWithId(int id) =>
      container.read(messagesProvider).messages.firstWhere((m) => m.id == id);

  setUp(() async {
    wrapper = MockWrapper();
    when(() => wrapper.noInternet).thenReturn(false);
    when(() => wrapper.send(any(), args: any(named: 'args')))
        .thenAnswer((_) async => fixtureFor('api/message/getMyMessages'));
    container = ProviderContainer();
    await container.read(messagesProvider.notifier).load();
  });

  tearDown(() => container.dispose());

  group('parsing confirmations', () {
    test('agree message exposes two buttons and no signature field', () {
      final info = messageWithId(_agreeOpenId).responseInfo;
      expect(info, isNotNull);
      expect(info!.type, MessageResponseInfo.typeAgree);
      expect(info.showAgreeButtons, isTrue);
      expect(info.showConfirmButton, isFalse);
      expect(info.showSignatureField, isFalse);
      expect(info.unsupported, isFalse);
      expect(info.answered, isFalse);
      expect(info.badge, 'Nicht beantwortet');
    });

    test('signature message exposes a field and a single confirm button', () {
      final info = messageWithId(_signedId).responseInfo;
      expect(info, isNotNull);
      expect(info!.showSignatureField, isTrue);
      expect(info.showConfirmButton, isTrue);
      expect(info.showAgreeButtons, isFalse);
    });

    test('a confirmation by the other guardian counts as answered', () {
      final info = messageWithId(_signedId).responseInfo!;
      expect(info.answered, isTrue);
      expect(info.givenSignature, isNotNull);
      expect(info.historyText, isNotNull);
    });

    test('message without confirmation has no responseInfo', () {
      expect(messageWithId(_plainId).responseInfo, isNull);
    });
  });

  group('reply', () {
    Map<String, dynamic> capturedArgs() =>
        verify(() => wrapper.send('api/message/reply',
                args: captureAny(named: 'args')))
            .captured
            .single as Map<String, dynamic>;

    test('nests the answer and omits the signature key', () async {
      await container.read(messagesProvider.notifier).reply(
            _agreeOpenId,
            response: MessageResponseInfo.answerAgree,
          );
      expect(capturedArgs(), {
        'messageId': _agreeOpenId,
        'response': {'response': 'agree'},
      });
    });

    test('sends not_agree verbatim', () async {
      await container.read(messagesProvider.notifier).reply(
            _agreeOpenId,
            response: MessageResponseInfo.answerNotAgree,
          );
      expect(
        (capturedArgs()['response'] as Map)['response'],
        'not_agree',
      );
    });

    test('a plain signature omits the response key', () async {
      await container
          .read(messagesProvider.notifier)
          .reply(_signedId, signature: 'Max Mustermann');
      expect(capturedArgs(), {
        'messageId': _signedId,
        'response': {'signature': 'Max Mustermann'},
      });
    });

    test('adopts the message list the server replies with', () async {
      await container
          .read(messagesProvider.notifier)
          .reply(_agreeOpenId, response: MessageResponseInfo.answerAgree);
      expect(container.read(messagesProvider).messages, isNotEmpty);
    });
  });
}
