import 'package:built_collection/built_collection.dart';
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
          {
            'user': 'ben',
            'pass': 'b',
            'url': 'https://schule.digitalesregister.it'
          },
          // The same account once more, as the list may hold it.
          {
            'user': 'anna',
            'pass': 'a',
            'url': 'https://schule.digitalesregister.it'
          },
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
          {
            'user': 'ben',
            'pass': 'b',
            'url': 'https://schule.digitalesregister.it'
          },
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
    const app = 4711;
    final key =
        notificationAccountKey('anna', 'https://schule.digitalesregister.it');

    test('holds for the account the app marked, in its own process', () {
      final mark = appAccountMark(key, now, pid: app);
      expect(appUsesAccount(mark, key, now, pid: app), isTrue);
      expect(
        appUsesAccount(
          mark,
          key,
          now.add(appAccountMarkLifetime - const Duration(seconds: 1)),
          pid: app,
        ),
        isTrue,
      );
    });

    test('not for another account', () {
      final other =
          notificationAccountKey('ben', 'https://schule.digitalesregister.it');
      expect(
        appUsesAccount(appAccountMark(other, now, pid: app), key, now,
            pid: app),
        isFalse,
      );
    });

    test('the same account, typed without the scheme', () {
      // The app marks the address it signs in with, fixed up; the check
      // reads the stored one as typed.
      final mark = appAccountMark(
        notificationAccountKey('anna', 'schule.digitalesregister.it'),
        now,
        pid: app,
      );
      expect(appUsesAccount(mark, key, now, pid: app), isTrue);
    });

    test('not from a process that is gone: the app was swiped away', () {
      // The check runs in the app's process while that lives. Swiped away,
      // the app went to the background and took its mark back — which did
      // not reach the disk before the process ended, and the account in
      // use was left out.
      final mark = appAccountMark(key, now, pid: app);
      expect(appUsesAccount(mark, key, now, pid: app + 1), isFalse);
    });

    test('not once the mark is stale', () {
      final mark = appAccountMark(key, now, pid: app);
      expect(
        appUsesAccount(mark, key, now.add(appAccountMarkLifetime), pid: app),
        isFalse,
      );
    });

    test('not without a mark, nor with one that cannot be read', () {
      expect(appUsesAccount(null, key, now, pid: app), isFalse);
      expect(appUsesAccount('kaputt', key, now, pid: app), isFalse);
      expect(appUsesAccount('{"key": 1}', key, now, pid: app), isFalse);
      // Written before marks named their process.
      final old = '{"key": "$key", "at": ${now.millisecondsSinceEpoch}}';
      expect(appUsesAccount(old, key, now, pid: app), isFalse);
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

  group('homeworkOf', () {
    test('takes each entry once, with the lesson it is entered for', () {
      final monday = UtcDateTime(2026, 9, 28);
      final days = [
        _day(monday, [
          _hour('Italienisch', 1, [_homework(7, 'leggere')]),
          // A double lesson carries its entry in both hours.
          _hour('Mathematik', 2, [_homework(8, 'S. 12'), _homework(9, 'Test')]),
          _hour('Mathematik', 3, [_homework(8, 'S. 12')]),
        ]),
      ];
      final homework = homeworkOf(days);
      expect(homework.map((h) => h.id), [7, 8, 9]);
      expect(homework.first.subject, 'Italienisch');
      expect(homework.first.name, 'leggere');
      expect(homework.first.date, monday);
    });
  });

  group('freshHomework', () {
    final settings = SettingsState();
    final homework = homeworkOf([
      _day(UtcDateTime(2026, 9, 28), [
        _hour('Italienisch', 1, [_homework(7, 'a'), _homework(8, 'b')]),
      ]),
    ]);

    test('announces only what was not there at the last look (#288)', () {
      final fresh = freshHomework(
        known: {7},
        homework: homework,
        settings: settings,
      );
      expect(fresh.map((h) => h.id), [8]);
    });

    test('stays quiet for an account seen for the first time', () {
      expect(
        freshHomework(known: null, homework: homework, settings: settings),
        isEmpty,
      );
    });

    test('stays quiet with homework switched off in the settings', () {
      expect(
        freshHomework(
          known: const {},
          homework: homework,
          settings: settings.copyWith(notifyHomework: false),
        ),
        isEmpty,
      );
    });
  });

  test('homework notifications meet neither portal ids nor the summary', () {
    // Portal ids are positive, the summary of a group is -1, 0 the test.
    final ids = [0, 1, 7, 123456].map(homeworkNotificationId).toList();
    expect(ids, everyElement(lessThan(-1)));
    expect(ids.toSet(), hasLength(ids.length));
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

CalendarDay _day(UtcDateTime date, List<CalendarHour> hours) => CalendarDay(
      (b) => b
        ..date = date
        ..hours = ListBuilder(hours),
    );

CalendarHour _hour(String subject, int hour, List<HomeworkExam> homework) =>
    CalendarHour(
      (b) => b
        ..fromHour = hour
        ..toHour = hour
        ..subject = subject
        ..rooms = ListBuilder()
        ..lessonContents = ListBuilder()
        ..homeworkExams = ListBuilder(homework),
    );

HomeworkExam _homework(int id, String name) => HomeworkExam(
      (b) => b
        ..id = id
        ..name = name
        ..homework = true
        ..online = false
        ..deadline = UtcDateTime(2026, 9, 28)
        ..hasGrades = false
        ..hasGradeGroupSubmissions = false
        ..typeId = 1
        ..typeName = 'Hausaufgabe'
        ..warning = false,
    );
