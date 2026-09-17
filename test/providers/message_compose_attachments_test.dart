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
import 'package:dr/middleware/middleware.dart' show wrapper;
import 'package:dr/providers/config_provider.dart';
import 'package:dr/providers/message_compose_provider.dart';
import 'package:dr/ui/message_compose.dart' show fileSizeLabel;
import 'package:dr/wrapper.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../fixtures/api_fixtures.dart';

class MockWrapper extends Mock implements Wrapper {}

const _uploadUrl = 'api/message/messageSubmissionUpload';
const _sendUrl = 'api/message/sendMessage';

void main() {
  setUpAll(loadFixtures);

  late MockWrapper mock;
  late ProviderContainer container;
  final sent = <({String url, Map<String, Object?> args})>[];
  final uploads = <({
    String url,
    String path,
    String filename,
    Map<String, Object?> fields
  })>[];

  /// What the portal answers `getTypes` for a parent: one kind, one
  /// permission.
  final types = <String, Object?>{
    'types': [
      <String, Object?>{
        'typeId': 'read',
        'signatureRequired': false,
        'responseRequired': false,
      },
    ],
    'permissions': [
      <String, Object?>{'id': 'me'},
    ],
  };

  /// What the uploader answers, one per call.
  late List<Object?> uploadAnswers;

  MessageComposeNotifier notifier() =>
      container.read(messageComposeProvider.notifier);

  MessageComposeState read() => container.read(messageComposeProvider);

  Future<void> start({int maxItems = 8}) async {
    container = ProviderContainer(overrides: [
      configProvider.overrideWith(
        (ref) => Config(
          (b) => b
            ..userId = 1
            ..autoLogoutSeconds = 300
            ..fullName = 'Demo Elternteil'
            ..imgSource = ''
            ..isStudentOrParent = true
            ..submissionMaxItems = maxItems,
        ),
      ),
    ]);
    // The provider drops itself without a listener.
    container.listen(messageComposeProvider, (_, __) {});
    await notifier().start();
  }

  setUp(() {
    sent.clear();
    uploads.clear();
    uploadAnswers = [
      <String, Object?>{'success': true, 'submissionId': 7},
      <String, Object?>{'success': true, 'submissionId': 8},
    ];
    mock = MockWrapper();
    wrapper = mock;
    when(() => mock.noInternet).thenReturn(false);
    when(() => mock.send(any(),
        args: any(named: 'args'),
        onError: any(named: 'onError'))).thenAnswer((invocation) async {
      final url = invocation.positionalArguments.first as String;
      final args =
          (invocation.namedArguments[#args] as Map<String, Object?>?) ??
              const <String, Object?>{};
      sent.add((url: url, args: args));
      return switch (url) {
        'api/message/getTypes' => types,
        _sendUrl => <String, Object?>{'success': true},
        'api/message/getMyMessages' => fixtureFor('api/message/getMyMessages'),
        _ => null,
      };
    });
    when(() => mock.upload(any(),
        path: any(named: 'path'),
        filename: any(named: 'filename'),
        fields: any(named: 'fields'),
        onError: any(named: 'onError'))).thenAnswer((invocation) async {
      uploads.add((
        url: invocation.positionalArguments.first as String,
        path: invocation.namedArguments[#path] as String,
        filename: invocation.namedArguments[#filename] as String,
        fields: invocation.namedArguments[#fields] as Map<String, Object?>,
      ));
      return uploadAnswers.isEmpty ? null : uploadAnswers.removeAt(0);
    });
  });

  tearDown(() => container.dispose());

  group('putting a file on a message', () {
    test('goes straight to the uploader, which hands out the id', () async {
      await start();
      await notifier().attach(
        path: '/tmp/zeugnis.pdf',
        name: 'zeugnis.pdf',
        size: 2048,
      );

      // The portal asks for a temporary entry only for text and link
      // entries; for a file the upload makes it.
      expect(
        sent.where((r) => r.url.contains('CreateTemporaryEntry')),
        isEmpty,
      );

      expect(uploads, hasLength(1));
      expect(uploads.single.url, _uploadUrl);
      expect(uploads.single.path, '/tmp/zeugnis.pdf');
      expect(uploads.single.filename, 'zeugnis.pdf');
      expect(uploads.single.fields, {'title': 'zeugnis.pdf', 'categoryId': 0});

      final attachment = read().attachments.single;
      expect(attachment.submissionId, 7);
      expect(attachment.uploading, isFalse);
      expect(attachment.sendable, isTrue);
    });

    test('goes out with the message', () async {
      await start();
      await notifier().attach(
        path: '/tmp/zeugnis.pdf',
        name: 'zeugnis.pdf',
        size: 2048,
      );
      final error = await notifier().send(subject: 'Betreff', text: 'Text');
      expect(error, isNull);

      final message = (sent.lastWhere((r) => r.url == _sendUrl).args['message']
          as Map)['submissions'] as List;
      expect(message, [
        {'kind': 'temporary', 'submissionId': 7},
      ]);
    });

    test('a file taken off again does not go out', () async {
      await start();
      await notifier().attach(
        path: '/tmp/zeugnis.pdf',
        name: 'zeugnis.pdf',
        size: 2048,
      );
      notifier().detach(read().attachments.single);
      expect(read().attachments, isEmpty);

      await notifier().send(subject: 'Betreff', text: 'Text');
      final submissions = (sent
          .lastWhere((r) => r.url == _sendUrl)
          .args['message'] as Map)['submissions'] as List;
      expect(submissions, isEmpty);
    });
  });

  group('when it does not work', () {
    test('an answer without an id marks the file failed', () async {
      uploadAnswers = [
        <String, Object?>{'success': true},
      ];
      await start();
      await notifier().attach(path: '/tmp/a.pdf', name: 'a.pdf', size: 10);
      final attachment = read().attachments.single;
      expect(attachment.failed, isTrue);
      expect(attachment.sendable, isFalse);
    });

    test('a refused file is failed even with an id', () async {
      uploadAnswers = [
        <String, Object?>{'submissionId': 7, 'error': 'too_large'},
      ];
      await start();
      await notifier().attach(path: '/tmp/a.pdf', name: 'a.pdf', size: 10);
      expect(read().attachments.single.failed, isTrue);
    });

    test('a failed upload keeps the file out of the message', () async {
      uploadAnswers = [null];
      await start();
      await notifier().attach(path: '/tmp/a.pdf', name: 'a.pdf', size: 10);
      expect(read().attachments.single.failed, isTrue);

      await notifier().send(subject: 'Betreff', text: 'Text');
      final submissions = (sent
          .lastWhere((r) => r.url == _sendUrl)
          .args['message'] as Map)['submissions'] as List;
      expect(submissions, isEmpty);
    });
  });

  group('the id in the portal answers with', () {
    test('comes from submissionId, or entryId in its place', () {
      expect(uploadedId(<String, Object?>{'submissionId': 7}), 7);
      expect(uploadedId(<String, Object?>{'entryId': 9}), 9);
      expect(uploadedId(<String, Object?>{'submissionId': 0, 'entryId': 9}), 9);
      expect(uploadedId(<String, Object?>{'submissionId': 0}), isNull);
      expect(uploadedId(null), isNull);
      expect(uploadedId('nope'), isNull);
    });
  });

  group('how many are allowed', () {
    test('the school\'s limit comes from the config', () async {
      await start(maxItems: 1);
      expect(read().maxAttachments, 1);
      expect(read().canAttach, isTrue);

      await notifier().attach(path: '/tmp/a.pdf', name: 'a.pdf', size: 10);
      expect(read().canAttach, isFalse);

      // One too many is not sent anywhere.
      await notifier().attach(path: '/tmp/b.pdf', name: 'b.pdf', size: 10);
      expect(read().attachments, hasLength(1));
      expect(uploads, hasLength(1));
    });

    test('without a config the portal default stands', () async {
      container = ProviderContainer();
      container.listen(messageComposeProvider, (_, __) {});
      await notifier().start();
      expect(read().maxAttachments, Config.defaultSubmissionMaxItems);
    });
  });

  group('the size next to the name', () {
    test('reads in units a person recognises', () {
      expect(fileSizeLabel(812), '812 B');
      expect(fileSizeLabel(34 * 1024), '34 kB');
      expect(fileSizeLabel((2.1 * 1024 * 1024).round()), '2.1 MB');
    });
  });
}
