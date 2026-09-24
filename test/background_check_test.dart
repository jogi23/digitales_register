import 'package:dr/app_state.dart';
import 'package:dr/background_check.dart';
import 'package:dr/data.dart';
import 'package:dr/providers/account_profile_provider.dart';
import 'package:dr/system_notifications.dart';
import 'package:dr/utc_date_time.dart';
import 'package:flutter_test/flutter_test.dart';

Notification _notification(int id, {String type = 'message'}) => Notification(
      (b) => b
        ..id = id
        ..title = 'Eintrag $id'
        ..type = type
        ..objectId = id * 10
        ..timeSent = UtcDateTime(2026, 9, 23),
    );

void main() {
  group('notifiableAccounts', () {
    test('takes the current account and the others, each once', () {
      final accounts = notifiableAccounts({
        'user': 'anna',
        'pass': 'a',
        'url': 'https://schule.digitalesregister.it',
        'otherAccounts': [
          {'user': 'ben', 'pass': 'b', 'url': 'https://schule.digitalesregister.it'},
          // The same account once more, as the list may hold it.
          {'user': 'anna', 'pass': 'a', 'url': 'https://schule.digitalesregister.it'},
        ],
      });
      expect(accounts.map((a) => a.user), ['anna', 'ben']);
    });

    test('leaves out accounts without a password and the demo', () {
      final accounts = notifiableAccounts({
        'user': 'anna',
        'url': 'https://schule.digitalesregister.it',
        'otherAccounts': [
          {
            'user': 'demo-user-6540',
            'pass': 'x',
            'url': 'https://wertwerk-demo.digitalesregister.it',
          },
          {'user': 'ben', 'pass': 'b', 'url': 'https://schule.digitalesregister.it'},
        ],
      });
      expect(accounts.map((a) => a.user), ['ben']);
    });

    test('copes with nothing stored', () {
      expect(notifiableAccounts(const <String, dynamic>{}), isEmpty);
      expect(notifiableAccounts(null), isEmpty);
    });
  });

  group('appUsesAccount', () {
    final now = DateTime(2026, 9, 24, 12);
    final key =
        notificationAccountKey('anna', 'https://schule.digitalesregister.it');

    test('holds for the account the app marked, while the mark is fresh', () {
      final mark = appAccountMark(key, now);
      expect(appUsesAccount(mark, key, now), isTrue);
      expect(
        appUsesAccount(
          mark,
          key,
          now.add(appAccountMarkLifetime - const Duration(seconds: 1)),
        ),
        isTrue,
      );
    });

    test('not for another account', () {
      final other =
          notificationAccountKey('ben', 'https://schule.digitalesregister.it');
      expect(appUsesAccount(appAccountMark(other, now), key, now), isFalse);
    });

    test('the same account, typed without the scheme', () {
      // The app marks the address it signs in with, fixed up; the check
      // reads the stored one as typed.
      final mark = appAccountMark(
        notificationAccountKey('anna', 'schule.digitalesregister.it'),
        now,
      );
      expect(appUsesAccount(mark, key, now), isTrue);
    });

    test('not once the mark is stale: an app that crashed took nothing back',
        () {
      final mark = appAccountMark(key, now);
      expect(
          appUsesAccount(mark, key, now.add(appAccountMarkLifetime)), isFalse);
    });

    test('is renewed well before it runs out', () {
      // One renewal may come late or be lost; the next must still be in
      // time, or the check signs into the account the app is using.
      expect(appAccountMarkRenewal * 2, lessThan(appAccountMarkLifetime));
    });

    test('runs out within minutes when the app could not take it back', () {
      // Swiped away from the recent apps, the app said nothing: its account
      // went without system notifications for three hours.
      expect(appAccountMarkLifetime,
          lessThanOrEqualTo(const Duration(minutes: 5)));
    });

    test('not without a mark, nor with one that cannot be read', () {
      expect(appUsesAccount(null, key, now), isFalse);
      expect(appUsesAccount('kaputt', key, now), isFalse);
      expect(appUsesAccount('{"key": 1}', key, now), isFalse);
    });
  });

  group('freshNotifications', () {
    final settings = SettingsState();

    test('announces only what was not unread at the last look', () {
      final fresh = freshNotifications(
        known: {1},
        unread: [_notification(1), _notification(2)],
        settings: settings,
      );
      expect(fresh.map((n) => n.id), [2]);
    });

    test('stays quiet for an account seen for the first time', () {
      final fresh = freshNotifications(
        known: null,
        unread: [_notification(1)],
        settings: settings,
      );
      expect(fresh, isEmpty);
    });

    test('leaves out the kinds switched off in the settings', () {
      final fresh = freshNotifications(
        known: const {},
        unread: [_notification(1), _notification(2, type: 'grade')],
        settings: settings.copyWith(notifyGrades: false),
      );
      expect(fresh.map((n) => n.id), [1]);
    });
  });

  test('files notifications under the key the alias is stored under', () {
    // The alias is looked up with the address as the login fixed it up.
    expect(
      notificationAccountKey('anna', 'schule.digitalesregister.it/v2/login'),
      accountProfileKey('anna', 'https://schule.digitalesregister.it/'),
    );
  });

  group('SystemNotificationTarget', () {
    test('comes back from its payload unchanged', () {
      const target = SystemNotificationTarget(
        user: 'anna',
        url: 'https://schule.digitalesregister.it',
        id: 7,
        type: 'grade',
        objectId: 70,
      );
      final back = SystemNotificationTarget.fromPayload(target.toPayload())!;
      expect(back.user, target.user);
      expect(back.url, target.url);
      expect(back.id, target.id);
      expect(back.type, target.type);
      expect(back.objectId, target.objectId);
    });

    test('ignores payloads that are not its own', () {
      expect(SystemNotificationTarget.fromPayload(null), isNull);
      expect(SystemNotificationTarget.fromPayload('kein json'), isNull);
      expect(SystemNotificationTarget.fromPayload('{"id": 1}'), isNull);
    });
  });
}
