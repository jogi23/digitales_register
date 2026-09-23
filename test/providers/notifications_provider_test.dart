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

import 'dart:async';

import 'package:dr/middleware/middleware.dart';
import 'package:dr/providers/notifications_provider.dart';
import 'package:dr/wrapper.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockWrapper extends Mock implements Wrapper {}

Map<String, Object?> _notification(int id, {int? messageId}) => {
      'id': id,
      'title': 'Eintrag $id',
      'type': messageId == null ? 'grade' : 'message',
      'objectId': messageId ?? id * 10,
      'subTitle': null,
      'timeSent': '2026-09-23 10:00:00',
    };

void main() {
  late ProviderContainer container;

  /// What the portal answers to `api/notification/unread`, next.
  late Future<List<Object?>> Function() unread;

  List<int> shown() =>
      container.read(notificationsProvider).notifications.map((n) => n.id).toList();

  setUp(() {
    wrapper = MockWrapper();
    unread = () async => [];
    when(() => wrapper.send(any(),
        args: any(named: 'args'),
        onError: any(named: 'onError'))).thenAnswer((invocation) async {
      final url = invocation.positionalArguments.first as String;
      return url == 'api/notification/unread' ? unread() : null;
    });
    container = ProviderContainer();
  });

  tearDown(() => container.dispose());

  test('a message read here stays read when a list fetched before comes back',
      () async {
    // The list is on its way while the message is opened — after a tap on a
    // system notification, for one.
    final answer = Completer<List<Object?>>();
    unread = () => answer.future;
    final loading = container.read(notificationsProvider.notifier).load();
    await container.read(notificationsProvider.notifier).markMessageAsRead(5);
    answer.complete([_notification(1, messageId: 5), _notification(2)]);
    await loading;

    expect(shown(), [2]);
  });

  test('a notification read here stays read until the portal agrees',
      () async {
    final notifier = container.read(notificationsProvider.notifier);
    unread = () async => [_notification(1), _notification(2)];
    await notifier.load();
    await notifier.markAsRead(1);

    // The portal has not caught up yet.
    await notifier.load();
    expect(shown(), [2]);

    // It has; should the same id turn up unread once more, it is news again.
    unread = () async => [_notification(2)];
    await notifier.load();
    unread = () async => [_notification(1), _notification(2)];
    await notifier.load();
    expect(shown(), containsAll([1, 2]));
  });

  test('switching accounts forgets what was read in the other one', () async {
    final notifier = container.read(notificationsProvider.notifier);
    await notifier.markAsRead(1);
    notifier.reset();

    unread = () async => [_notification(1)];
    await notifier.load();
    expect(shown(), [1]);
  });
}
