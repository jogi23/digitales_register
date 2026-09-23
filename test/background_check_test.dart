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
