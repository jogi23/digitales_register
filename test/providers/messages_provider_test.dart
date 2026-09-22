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

import 'dart:convert';

import 'package:built_collection/built_collection.dart';
import 'package:dr/app_state.dart';
import 'package:dr/data.dart';
import 'package:dr/middleware/middleware.dart';
import 'package:dr/providers/messages_provider.dart';
import 'package:dr/providers/notifications_provider.dart';
import 'package:dr/serializers.dart';
import 'package:dr/utc_date_time.dart';
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
// 39102 is also the one message the demo account sent itself.
const _sentId = _plainId;
const _archivedId = 47363; // the one archived message

void main() {
  setUpAll(loadFixtures);

  late ProviderContainer container;

  Message messageWithId(int id) =>
      container.read(messagesProvider).messages.firstWhere((m) => m.id == id);

  setUp(() async {
    wrapper = MockWrapper();
    when(() => wrapper.noInternet).thenReturn(false);
    when(() => wrapper.send(any(),
            args: any(named: 'args'), onError: any(named: 'onError')))
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

  group('parsing the direction', () {
    test('a message this account sent is marked outgoing', () {
      expect(messageWithId(_sentId).outgoing, isTrue);
    });

    test('a received message is not', () {
      expect(messageWithId(_agreeOpenId).outgoing, isFalse);
      expect(messageWithId(_signedId).outgoing, isFalse);
    });

    test('a sent message is never new, though it carries no timeRead', () {
      final sent = messageWithId(_sentId);
      expect(sent.timeRead, isNull);
      expect(sent.isNew, isFalse);
    });

    test('an unread received message is new', () {
      final received = messageWithId(_agreeOpenId)
          .rebuild((b) => b..timeRead = null);
      expect(received.isNew, isTrue);
    });

    test(
        'a message with an open notification counts as new even though the '
        'server already marked it read (#268)', () async {
      container.read(notificationsProvider.notifier).restore(
        NotificationsState(
          notifications: [
            Notification(
              (b) => b
                ..id = 1
                ..title = 'x'
                ..type = 'message'
                ..objectId = _agreeOpenId
                ..timeSent = UtcDateTime.now(),
            ),
          ],
        ),
      );
      await container.read(messagesProvider.notifier).load();
      expect(messageWithId(_agreeOpenId).isNew, isTrue);
    });
  });

  group('folders', () {
    MessageCategory category() =>
        container.read(messageListProvider).category;

    test('an archived message is marked archived', () {
      expect(messageWithId(_archivedId).archived, isTrue);
      expect(messageWithId(_agreeOpenId).archived, isFalse);
    });

    test('received holds neither sent nor archived messages', () {
      expect(MessageCategory.incoming.includes(messageWithId(_agreeOpenId)),
          isTrue);
      expect(
          MessageCategory.incoming.includes(messageWithId(_sentId)), isFalse);
      expect(MessageCategory.incoming.includes(messageWithId(_archivedId)),
          isFalse);
    });

    test('the list starts on received messages', () {
      expect(category(), MessageCategory.incoming);
    });

    test('opening a sent message switches to sent', () {
      container.read(messagesProvider.notifier).select(_sentId);
      expect(category(), MessageCategory.outgoing);
    });

    test('opening a received message keeps the folder', () {
      container.read(messagesProvider.notifier).select(_agreeOpenId);
      expect(category(), MessageCategory.incoming);
    });

    test('a message opened before the list loads is revealed by the load',
        () async {
      final notifier = container.read(messagesProvider.notifier)
        ..reset()
        ..select(_archivedId);
      expect(category(), MessageCategory.incoming);
      await notifier.load();
      expect(category(), MessageCategory.archived);
    });
  });

  group('archive', () {
    void verifyArchiveRequest(int messageId, int archiveType,
            {int times = 1}) =>
        verify(() => wrapper.send('api/message/archiveMessage',
            args: {'messageId': messageId, 'archiveType': archiveType},
            onError: any(named: 'onError'))).called(times);

    test('the move a message allows comes from archiveMessageEnabled', () {
      expect(messageWithId(_agreeOpenId).canArchive, isTrue);
      expect(messageWithId(_agreeOpenId).canRestore, isFalse);
      expect(messageWithId(_archivedId).canRestore, isTrue);
    });

    test('archiving sends archiveType 1 and loads the list again', () async {
      final allSent = await container
          .read(messagesProvider.notifier)
          .setArchived([_agreeOpenId, _archivedId], archived: true);
      expect(allSent, isTrue);
      verifyArchiveRequest(_agreeOpenId, 1);
      // Already archived: nothing to do for it.
      verifyNever(() => wrapper.send('api/message/archiveMessage',
          args: {'messageId': _archivedId, 'archiveType': 1},
          onError: any(named: 'onError')));
      verify(() => wrapper.send('api/message/getMyMessages')).called(2);
    });

    test('taking out of the archive sends archiveType 2', () async {
      await container
          .read(messagesProvider.notifier)
          .setArchived([_archivedId], archived: false);
      verifyArchiveRequest(_archivedId, 2);
    });

    test('a request that fails is reported', () async {
      when(() => wrapper.send('api/message/archiveMessage',
              args: any(named: 'args'), onError: any(named: 'onError')))
          .thenAnswer((invocation) async {
        (invocation.namedArguments[#onError] as void Function(Object))
            .call(Exception('offline'));
        return null;
      });
      final allSent = await container
          .read(messagesProvider.notifier)
          .setArchived([_agreeOpenId], archived: true);
      expect(allSent, isFalse);
    });
  });

  group('stars', () {
    BuiltSet<int> starred() => container.read(messagesProvider).starred;

    test('toggling sets a star and takes it away again', () {
      final notifier = container.read(messagesProvider.notifier)
        ..toggleStar(_agreeOpenId);
      expect(starred().asSet(), {_agreeOpenId});
      notifier.toggleStar(_agreeOpenId);
      expect(starred(), isEmpty);
    });

    test('a reload keeps the stars', () async {
      final notifier = container.read(messagesProvider.notifier)
        ..toggleStar(_signedId);
      await notifier.load();
      expect(starred().asSet(), {_signedId});
    });

    test('a message gone from the portal takes its star along', () async {
      final notifier = container.read(messagesProvider.notifier)
        ..toggleStar(1);
      await notifier.load();
      expect(starred(), isEmpty);
    });

    test('stars are saved with the account', () {
      final state = AppState((b) => b.messagesState.starred.add(_signedId));
      final decoded = serializers.deserialize(
        json.decode(json.encode(serializers.serialize(state))) as Object,
      )! as AppState;
      expect(decoded.messagesState.starred.asSet(), {_signedId});
    });
  });

  group('order and filters', () {
    Message message(int id, String from, String sent, {bool read = true}) =>
        Message(
          (b) => b
            ..id = id
            ..subject = 'Mitteilung $id'
            ..text = ''
            ..fromName = from
            ..recipientString = ''
            ..timeSent = UtcDateTime.parse(sent)
            ..timeRead = read ? UtcDateTime.parse(sent) : null,
        );
    final oldest = message(1, 'berger', '2026-09-01 08:00:00');
    final unread = message(2, 'Amort', '2026-09-10 08:00:00', read: false);
    final newest = message(3, 'Berger', '2026-09-12 08:00:00');

    List<int> ids(MessageListView view, [Iterable<int> starred = const []]) =>
        view
            .apply([oldest, unread, newest], BuiltSet<int>(starred))
            .map((m) => m.id)
            .toList();

    test('newest first by default', () {
      expect(ids(const MessageListView()), [3, 2, 1]);
    });

    test('oldest first on request', () {
      expect(ids(const MessageListView(sort: MessageSort.oldest)), [1, 2, 3]);
    });

    test('by sender ignores case, newest first within one sender', () {
      expect(ids(const MessageListView(sort: MessageSort.sender)), [2, 3, 1]);
    });

    test('unread only', () {
      expect(ids(MessageListView(keptUnread: BuiltSet<int>())), [2]);
    });

    test('starred only', () {
      expect(ids(const MessageListView(starredOnly: true), [1]), [1]);
    });

    test('a message read under "unread only" stays in the list', () async {
      final notifier = container.read(messagesProvider.notifier)
        ..restore(MessagesState((b) => b.messages.add(unread)));
      container.read(messageListProvider.notifier).showUnreadOnly(true);
      await notifier.markAsRead(unread.id);

      final state = container.read(messagesProvider);
      expect(state.messages.single.isNew, isFalse);
      expect(
        container.read(messageListProvider).apply(state.messages, state.starred),
        hasLength(1),
      );
    });

    test('switching the folder keeps order and filters', () {
      container.read(messageListProvider.notifier)
        ..sortBy(MessageSort.sender)
        ..showStarredOnly(true)
        ..showCategory(MessageCategory.all);
      final view = container.read(messageListProvider);
      expect(view.sort, MessageSort.sender);
      expect(view.starredOnly, isTrue);
    });

    test('opening a message a filter hides drops the filter', () {
      container.read(messageListProvider.notifier).showStarredOnly(true);
      container.read(messagesProvider.notifier).select(_agreeOpenId);
      expect(container.read(messageListProvider).starredOnly, isFalse);
    });
  });

  group('markAllAsRead', () {
    test('leaves sent messages alone', () async {
      await container.read(messagesProvider.notifier).markAllAsRead();
      verifyNever(() => wrapper.send('api/message/markAsRead',
          args: {'messageId': _sentId}, onError: any(named: 'onError')));
      expect(messageWithId(_sentId).timeRead, isNull);
    });
  });

  group('reply', () {
    Map<String, dynamic> capturedArgs() =>
        verify(() => wrapper.send('api/message/reply',
                args: captureAny(named: 'args'),
                onError: any(named: 'onError')))
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

    test('reports the message it answered as answered', () async {
      // The fixture has this one signed already, so the reload the reply
      // triggers finds it answered — which is what the caller asks about.
      final answered = await container
          .read(messagesProvider.notifier)
          .reply(_signedId, signature: 'Max Mustermann');
      expect(answered, isTrue);
    });

    test('an empty answer is no confirmation', () async {
      // What the portal really does: it takes the request and returns
      // nothing. The state has to come from asking again, and an unanswered
      // message must not read as sent.
      when(() => wrapper.send('api/message/reply',
              args: any(named: 'args'), onError: any(named: 'onError')))
          .thenAnswer((_) async => null);
      final answered = await container
          .read(messagesProvider.notifier)
          .reply(_agreeOpenId, response: MessageResponseInfo.answerAgree);
      expect(answered, isFalse);
      verify(() => wrapper.send('api/message/getMyMessages')).called(2);
    });

    test('a failed request is no confirmation', () async {
      when(() => wrapper.send('api/message/reply',
              args: any(named: 'args'),
              onError: any(named: 'onError'))).thenAnswer((invocation) async {
        (invocation.namedArguments[#onError] as void Function(Object))
            .call(Exception('offline'));
        return null;
      });
      final answered = await container
          .read(messagesProvider.notifier)
          .reply(_agreeOpenId, response: MessageResponseInfo.answerAgree);
      expect(answered, isFalse);
      // Nothing is asked either: the request never left.
      verify(() => wrapper.send('api/message/getMyMessages')).called(1);
    });
  });

  group('taking a sent message back', () {
    /// What `getMessage` answers for a sent message.
    Map<String, Object?> detail({int enabled = 1, int deleted = 0}) =>
        <String, Object?>{
          'message': <String, Object?>{
            'id': _sentId,
            'deleteMessageEnabled': enabled,
            'deleted': deleted,
          },
          'userMessage': null,
          'replies': <Object?>[],
        };

    void answerDetail(Object? answer) {
      when(() => wrapper.send('api/message/getMessage',
              args: any(named: 'args'), onError: any(named: 'onError')))
          .thenAnswer((_) async => answer);
    }

    /// The captured list without the message this account sent.
    List<dynamic> listWithoutSent() => (fixtureFor(
          'api/message/getMyMessages',
        ) as List)
            .where((dynamic m) => (m as Map)['id'] != _sentId)
            .toList();

    test('a message inside the window can be taken back', () async {
      answerDetail(detail());
      await container.read(messagesProvider.notifier).loadDetails(_sentId);
      expect(messageWithId(_sentId).canDelete, isTrue);
    });

    test('outside the window it cannot', () async {
      // 2 is what the portal sends once the four hours are up.
      answerDetail(detail(enabled: 2));
      await container.read(messagesProvider.notifier).loadDetails(_sentId);
      expect(messageWithId(_sentId).canDelete, isFalse);
    });

    test('one already taken back is not offered again', () async {
      // The flag stays at 1 after the deletion; only `deleted` says it went.
      answerDetail(detail(deleted: 1));
      await container.read(messagesProvider.notifier).loadDetails(_sentId);
      expect(messageWithId(_sentId).canDelete, isFalse);
    });

    test('a plain sentence instead of JSON is not read as an answer',
        () async {
      // What the portal sends for a message it has nothing to add about.
      answerDetail('glossary.no_need_to_fetch_message');
      await container.read(messagesProvider.notifier).loadDetails(_sentId);
      expect(messageWithId(_sentId).canDelete, isFalse);
    });

    test('a received message is not asked about at all', () async {
      await container.read(messagesProvider.notifier).loadDetails(_agreeOpenId);
      verifyNever(() => wrapper.send('api/message/getMessage',
          args: any(named: 'args'), onError: any(named: 'onError')));
      expect(messageWithId(_agreeOpenId).canDelete, isFalse);
    });

    test('gone from the list is what counts as deleted', () async {
      // The portal answers with an empty body, so the list is the proof.
      when(() => wrapper.send('api/message/deleteMessage',
              args: any(named: 'args'), onError: any(named: 'onError')))
          .thenAnswer((_) async => '');
      when(() => wrapper.send('api/message/getMyMessages',
              args: any(named: 'args'), onError: any(named: 'onError')))
          .thenAnswer((_) async => listWithoutSent());

      final deleted =
          await container.read(messagesProvider.notifier).deleteMessage(_sentId);
      expect(deleted, isTrue);
      expect(
        container.read(messagesProvider).messages.any((m) => m.id == _sentId),
        isFalse,
      );
    });

    test('still in the list means it did not happen', () async {
      when(() => wrapper.send('api/message/deleteMessage',
              args: any(named: 'args'), onError: any(named: 'onError')))
          .thenAnswer((_) async => '');

      final deleted =
          await container.read(messagesProvider.notifier).deleteMessage(_sentId);
      expect(deleted, isFalse);
      expect(messageWithId(_sentId).id, _sentId);
    });
  });
}
