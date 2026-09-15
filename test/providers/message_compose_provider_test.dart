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

import 'package:dr/middleware/middleware.dart';
import 'package:dr/providers/message_compose_provider.dart';
import 'package:dr/wrapper.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockWrapper extends Mock implements Wrapper {}

/// The account itself: the portal leaves it out of `getRecipientsDetails`
/// (live capture), so the answer holds fewer groups than asked for.
const _ownAccountId = 9637;

/// What `getTypes` gives a parent account (live capture).
const _types = {
  'types': [
    {
      'id': 'none',
      'typeId': 'read',
      'name': 'Keine',
      'signatureRequired': false,
      'responseRequired': false,
    },
  ],
  'permissions': [
    {'id': 'me', 'name': 'Nur ich'},
  ],
};

Map<String, Object?> _teacher(int id) => {
      'type': 'user',
      'id': id,
      'name': 'Lehrer $id',
      'picture': null,
      'firstname': 'L',
      'lastname': '$id',
      'classname': null,
      'rolle': 2,
      'contextstr': [
        {'f': 'txt', 'key': 'Lehrer $id ('},
        {'f': 't', 'key': 'message.recipients.teacher'},
        {'f': 'txt', 'key': ')'},
      ],
    };

/// Groups of one class share the class id, as in the live capture, and
/// carry its double space.
Map<String, Object?> _group(String type) => {
      'type': type,
      'id': 588,
      'name': 'S5A  $type',
      'contextstr': [
        {'f': 'txt', 'key': 'S5A  '},
      ],
    };

Map<String, Object?> _person(int id) => {
      'id': id,
      'firstName': 'P',
      'lastName': '$id',
      'rolle': 8,
      'className': 'S5A',
      'picture': null,
      'activeFrom': null,
      'activeTo': null,
      'name': 'Person $id',
      'contextstr': <Object?>[],
      'canSignSignatureMessages': true,
      'signatureRequiresGuardian': false,
      'selected': true,
      'disabled': false,
    };

/// The portal's answer for [groups]: a person stands for themselves, a group
/// for three people, everyone ticked.
Map<String, Object?> _details(List<Object?> groups) => {
      'recipientsNumber': 0,
      'recipientsDetails': [
        for (final group in groups.cast<Map<String, Object?>>())
          if (group['id'] != _ownAccountId)
          {
            'type': group['type'],
            'name': group['name'],
            'contextstr': group['contextstr'],
            'details': group['type'] == 'user'
                ? [_person(group['id']! as int)]
                : [for (final id in [1, 2, 3]) _person(id)],
          },
      ],
    };

void main() {
  late ProviderContainer container;

  MessageComposeNotifier notifier() =>
      container.read(messageComposeProvider.notifier);
  MessageComposeState state() => container.read(messageComposeProvider);

  void stub(String url, Object? Function(Map<String, Object?>? args) answer) =>
      when(() => wrapper.send(url,
          args: any(named: 'args'),
          onError: any(named: 'onError'))).thenAnswer(
        (invocation) async => answer(
          (invocation.namedArguments[#args] as Map?)?.cast<String, Object?>(),
        ),
      );

  Map<String, Object?> lastArgs(String url) => (verify(() => wrapper.send(url,
              args: captureAny(named: 'args'),
              onError: any(named: 'onError')))
          .captured
          .last as Map)
      .cast<String, Object?>();

  setUp(() {
    wrapper = MockWrapper();
    when(() => wrapper.noInternet).thenReturn(false);
    stub('api/message/getMyMessages', (_) => <Object?>[]);
    stub('api/message/getTypes', (_) => _types);
    stub('api/message/getRecipients',
        (_) => [_teacher(7330), _group('parents'), _group('teachers')]);
    stub(
      'api/message/getInitialRecipients',
      (args) => [_teacher((args!['initialRecipientIds']! as List).single as int)],
    );
    stub('api/message/getRecipientsDetails',
        (args) => _details(args!['recipientGroups']! as List));
    stub('api/message/sendMessage', (_) => {'success': true});
    container = ProviderContainer();
    // Kept alive the way the page keeps it: by listening.
    container.listen(messageComposeProvider, (_, __) {});
  });

  tearDown(() => container.dispose());

  group('start', () {
    test('learns the kind of message the account sends', () async {
      await notifier().start();
      expect(state().ready, isTrue);
      expect(state().allowed, isTrue);
      expect(state().type!['typeId'], 'read');
      expect(state().permission, 'me');
    });

    test('an account offered no kind may not send', () async {
      stub('api/message/getTypes', (_) => {'types': [], 'permissions': []});
      await notifier().start();
      expect(state().ready, isTrue);
      expect(state().allowed, isFalse);
    });

    test('a request that fails is no refusal', () async {
      // What an expired session looks like: every call ends in a 401.
      when(() => wrapper.send('api/message/getTypes',
              args: any(named: 'args'), onError: any(named: 'onError')))
          .thenAnswer((invocation) async {
        (invocation.namedArguments[#onError] as void Function(Object))
            .call(Exception('401'));
        return null;
      });
      await notifier().start();
      expect(state().ready, isTrue);
      expect(state().failed, isTrue);

      // Asking again, once the session is back, recovers.
      stub('api/message/getTypes', (_) => _types);
      await notifier().start();
      expect(state().failed, isFalse);
      expect(state().allowed, isTrue);
    });

    test('an answer starts with the sender as recipient', () async {
      await notifier().start(answerTo: 10630);
      expect(lastArgs('api/message/getInitialRecipients'), {
        'initialRecipientIds': [10630],
      });
      expect(state().recipients.single.id, 10630);
      expect(state().groups.single.people.single.id, 10630);
    });
  });

  group('recipients', () {
    test('search waits for two characters', () async {
      expect(await notifier().search(' a '), isEmpty);
      verifyNever(() => wrapper.send('api/message/getRecipients',
          args: any(named: 'args'), onError: any(named: 'onError')));
    });

    test('search finds people and groups', () async {
      final hits = await notifier().search('5a');
      expect(lastArgs('api/message/getRecipients'), {'filter': '5a'});
      expect(hits.map((h) => (h.type, h.isGroup)), [
        ('user', false),
        ('parents', true),
        ('teachers', true),
      ]);
      expect(hits[1].name, 'S5A parents');
    });

    test('groups of one class are told apart by type', () async {
      await notifier().add(MessageRecipient(_group('parents')));
      await notifier().add(MessageRecipient(_group('teachers')));
      await notifier().add(MessageRecipient(_group('teachers')));
      expect(state().recipients.map((r) => r.type), ['parents', 'teachers']);
    });

    test('the people behind them are asked for with the objects unchanged',
        () async {
      await notifier().add(MessageRecipient(_teacher(7330)));
      expect(lastArgs('api/message/getRecipientsDetails'), {
        'recipientGroups': [_teacher(7330)],
      });
      expect(state().selectedCount, 1);
    });

    test('removing the last recipient leaves nobody to send to', () async {
      final teacher = MessageRecipient(_teacher(7330));
      await notifier().add(teacher);
      await notifier().remove(teacher);
      expect(state().groups, isEmpty);
      expect(state().selectedCount, 0);
    });
  });

  group('an answer leaving a recipient out', () {
    test('matches the groups by type and name, not by position', () async {
      await notifier().add(MessageRecipient(_teacher(_ownAccountId)));
      await notifier().add(MessageRecipient(_teacher(7330)));
      final group = state().groups.single;
      expect(group.recipientKey, 'user:7330');
      expect(group.people.single.id, 7330);
    });

    test('ticks reach the person meant, before and after removal', () async {
      final own = MessageRecipient(_teacher(_ownAccountId));
      final teacher = MessageRecipient(_teacher(7330));
      await notifier().add(own);
      await notifier().add(teacher);
      notifier().toggle(teacher.key, 7330);
      expect(state().selectedCount, 0);

      await notifier().remove(own);
      expect(state().groups.single.people.single.selected, isFalse);
    });
  });

  group('ticks', () {
    test('are kept here and survive another recipient joining', () async {
      final parents = MessageRecipient(_group('parents'));
      await notifier().add(parents);
      notifier().toggle(parents.key, 2);
      expect(state().selectedCount, 2);

      await notifier().add(MessageRecipient(_teacher(7330)));
      expect(state().selectedCount, 3);
      expect(state().peopleCount, 4);
      expect(
        state().groups.first.people.map((p) => (p.id, p.selected)),
        [(1, true), (2, false), (3, true)],
      );
      // Only the two additions asked the portal.
      verify(() => wrapper.send('api/message/getRecipientsDetails',
          args: any(named: 'args'), onError: any(named: 'onError'))).called(2);
    });

    test('none and all', () async {
      await notifier().add(MessageRecipient(_group('parents')));
      notifier().tickAll(false);
      expect(state().selectedCount, 0);
      notifier().tickAll(true);
      expect(state().selectedCount, 3);
    });
  });

  group('send', () {
    test('hands the ticked people and a Quill delta to the portal', () async {
      await notifier().start();
      final parents = MessageRecipient(_group('parents'));
      await notifier().add(parents);
      notifier().toggle(parents.key, 2);

      final error =
          await notifier().send(subject: 'Ausflug', text: 'Hallo\nWelt');

      expect(error, isNull);
      final args = lastArgs('api/message/sendMessage');
      final group = (args['recipientsDetails']! as List).single as Map;
      expect(group['name'], 'S5A  parents');
      expect(
        (group['details'] as List).map((p) => ((p as Map)['id'], p['selected'])),
        [(1, true), (2, false), (3, true)],
      );
      expect(args['message'], {
        'subject': 'Ausflug',
        'text': jsonEncode({
          'ops': [
            {'insert': 'Hallo\nWelt\n'},
          ],
        }),
        'signatureRequired': false,
        'responseRequired': false,
        'responseType': 'read',
        'permission': 'me',
        'submissions': <Object?>[],
      });
      // The portal answers without the list, so it is loaded again.
      verify(() => wrapper.send('api/message/getMyMessages')).called(1);
      expect(state().sending, isFalse);
    });

    test('a rejected message returns the portal error key', () async {
      stub('api/message/sendMessage', (_) => {'error': 'no_recipients'});
      await notifier().start();
      await notifier().add(MessageRecipient(_teacher(7330)));
      expect(await notifier().send(subject: 's', text: 't'), 'no_recipients');
      verifyNever(() => wrapper.send('api/message/getMyMessages'));
    });

    test('a request that never arrives returns an empty key', () async {
      when(() => wrapper.send('api/message/sendMessage',
              args: any(named: 'args'), onError: any(named: 'onError')))
          .thenAnswer((invocation) async {
        (invocation.namedArguments[#onError] as void Function(Object))
            .call(Exception('offline'));
        return null;
      });
      await notifier().start();
      await notifier().add(MessageRecipient(_teacher(7330)));
      expect(await notifier().send(subject: 's', text: 't'), '');
    });
  });

  test('an answer subject starts with RE: once', () {
    expect(answerSubject('Ausflug'), 'RE: Ausflug');
    expect(answerSubject('RE: Ausflug'), 'RE: Ausflug');
    expect(answerSubject('re: Ausflug'), 're: Ausflug');
  });

  test('context fragments keep literal and translatable parts apart', () {
    expect(parseContext(_teacher(1)['contextstr']), [
      (translate: false, text: 'Lehrer 1 ('),
      (translate: true, text: 'message.recipients.teacher'),
      (translate: false, text: ')'),
    ]);
  });
}
