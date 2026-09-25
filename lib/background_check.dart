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
import 'dart:io';
import 'dart:ui';

import 'package:dr/app_state.dart';
import 'package:dr/calendar_parser.dart';
import 'package:dr/data.dart';
import 'package:dr/debug_log.dart';
import 'package:dr/l10n/l10n.dart';
import 'package:dr/notification_type.dart';
import 'package:dr/notification_visibility.dart';
import 'package:dr/providers/account_profile_provider.dart';
import 'package:dr/system_notifications.dart';
import 'package:dr/utc_date_time.dart';
import 'package:dr/util.dart';
import 'package:dr/wrapper.dart';
import 'package:flutter/foundation.dart' show visibleForTesting;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:workmanager/workmanager.dart';

// Looks for new notifications while the app is closed, on Android only: the
// portal pushes nothing, so every stored account is signed into now and then
// and asked what is unread. What was not there the last time turns into a
// system notification. So does homework that was not there: the portal
// keeps no notification about it (#288).

const _taskName = 'dr.notificationCheck';

/// The ids each account had unread at the last look, by [notificationAccountKey].
const _knownPrefsKey = 'system_notifications_known';

/// The homework each account had this week and the next at the last look,
/// by [notificationAccountKey].
const _knownHomeworkPrefsKey = 'system_notifications_known_homework';

/// The account the app is signed into while it is in use, and since when.
const _appAccountPrefsKey = 'system_notifications_app_account';

/// How long a mark from [markAppAccount] holds at most — for a process
/// that lives on without the app ever saying it left.
const appAccountMarkLifetime = Duration(hours: 3);

/// Settings and aliases, where the app keeps them.
const _settingsPrefsKey = 'settings_global';
const _profilesPrefsKey = 'account_profiles';

typedef StoredAccount = ({String user, String pass, String url});

/// The key an account's notifications are filed under — the same one its
/// alias is stored under, so both are found with one lookup.
String notificationAccountKey(String user, String url) =>
    accountProfileKey(user, fixupUrl(url));

/// The accounts in the stored login that can sign in without anyone typing:
/// the current one and the others, each once, the demo left out — it has
/// nothing to report.
List<StoredAccount> notifiableAccounts(Object? login) {
  if (login is! Map) return const [];
  final entries = [
    login,
    ...?(login['otherAccounts'] as List?)?.whereType<Map<dynamic, dynamic>>(),
  ];
  final seen = <String>{};
  final out = <StoredAccount>[];
  for (final e in entries) {
    final user = getString(e['user']);
    final pass = getString(e['pass']);
    final url = getString(e['url']);
    if (user == null || pass == null || url == null) continue;
    if (isDemoUser(url: url, username: user)) continue;
    if (!seen.add(notificationAccountKey(user, url))) continue;
    out.add((user: user, pass: pass, url: url));
  }
  return out;
}

/// Which of the [unread] notifications deserve a system notification.
///
/// Nothing for an account seen for the first time ([known] is null): what
/// was unread before the check was switched on is old news, and a heap of
/// it all at once would be noise.
List<Notification> freshNotifications({
  required Set<int>? known,
  required List<Notification> unread,
  required SettingsState settings,
}) {
  if (known == null) return const [];
  return unread
      .where((n) => !known.contains(n.id))
      .where((n) => isNotificationTypeEnabled(n, settings))
      .toList();
}

/// A homework or an exam as its system notification tells of it: [date] is
/// the lesson it is entered for.
typedef UpcomingHomework = ({
  int id,
  UtcDateTime date,
  String subject,
  String name,
  String typeName,
});

/// The homework and exams of [days], each once — an entry for a double
/// lesson may stand in both hours.
List<UpcomingHomework> homeworkOf(Iterable<CalendarDay> days) {
  final seen = <int>{};
  return [
    for (final day in days)
      for (final hour in day.hours)
        for (final h in hour.homeworkExams)
          if (seen.add(h.id))
            (
              id: h.id,
              date: day.date,
              subject: hour.subject,
              name: h.name,
              typeName: h.typeName,
            ),
  ];
}

/// Which of [homework] deserves a system notification — the same rules as
/// [freshNotifications], under the setting for homework.
List<UpcomingHomework> freshHomework({
  required Set<int>? known,
  required List<UpcomingHomework> homework,
  required SettingsState settings,
}) {
  if (known == null || !settings.notifyHomework) return const [];
  return homework.where((h) => !known.contains(h.id)).toList();
}

Future<Map<String, Set<int>>> _readKnown(
  SharedPreferences prefs, [
  String prefsKey = _knownPrefsKey,
]) async {
  final raw = prefs.getString(prefsKey);
  if (raw == null) return {};
  try {
    final decoded = json.decode(raw) as Map<String, dynamic>;
    return decoded.map(
      (k, v) => MapEntry(k, (v as List).whereType<int>().toSet()),
    );
  } on Object {
    return {};
  }
}

Future<void> _writeKnown(
  SharedPreferences prefs,
  Map<String, Set<int>> known, [
  String prefsKey = _knownPrefsKey,
]) =>
    prefs.setString(
      prefsKey,
      json.encode(known.map((k, v) => MapEntry(k, v.toList()))),
    );

Future<void> _rememberSeen(
  String prefsKey, {
  required String user,
  required String url,
  required Iterable<int> ids,
}) async {
  if (!Platform.isAndroid) return;
  final prefs = await SharedPreferences.getInstance();
  // The background check writes from an isolate of its own.
  await prefs.reload();
  final known = await _readKnown(prefs, prefsKey);
  final key = notificationAccountKey(user, url);
  known[key] = {...?known[key], ...ids};
  await _writeKnown(prefs, known, prefsKey);
}

/// Remembers that the app showed these notifications, so the next check in
/// the background does not announce them again.
Future<void> rememberSeenNotifications({
  required String user,
  required String url,
  required Iterable<int> ids,
}) =>
    _rememberSeen(_knownPrefsKey, user: user, url: url, ids: ids);

/// Remembers that the app loaded this homework, so the next check in the
/// background does not announce it again.
Future<void> rememberSeenHomework({
  required String user,
  required String url,
  required Iterable<int> ids,
}) =>
    _rememberSeen(_knownHomeworkPrefsKey, user: user, url: url, ids: ids);

/// What [markAppAccount] stores: [key] as the account in use since [now].
@visibleForTesting
String appAccountMark(String key, DateTime now, {required int pid}) =>
    json.encode({'key': key, 'at': now.millisecondsSinceEpoch, 'pid': pid});

/// Whether [mark] says the app is signed into the account under [key] —
/// written by the process the check runs in, [pid], and recently enough.
///
/// The check runs in the app's process as long as that lives. A mark from
/// another process is one the app left behind when it was swiped away,
/// crashed or was stopped: taking it back as it went to the background
/// did not reach the disk in time, and the account in use was left out.
@visibleForTesting
bool appUsesAccount(
  String? mark,
  String key,
  DateTime now, {
  required int pid,
}) {
  if (mark == null) return false;
  try {
    final decoded = json.decode(mark) as Map<String, dynamic>;
    final at = DateTime.fromMillisecondsSinceEpoch(decoded['at'] as int);
    return decoded['key'] == key &&
        decoded['pid'] == pid &&
        now.difference(at) < appAccountMarkLifetime;
  } on Object {
    return false;
  }
}

/// Tells the background check which account the app is signed into while it
/// is in use, or with [user] null that it no longer is.
///
/// A check signing into the same account at the same time ended the app's
/// session: its next request found itself logged out (#280). The app asks
/// for that account's notifications itself while it is open, so the check
/// leaves it alone.
Future<void> markAppAccount({String? user, String? url}) async {
  if (!Platform.isAndroid) return;
  final prefs = await SharedPreferences.getInstance();
  if (user == null || url == null) {
    await prefs.remove(_appAccountPrefsKey);
    return;
  }
  await prefs.setString(
    _appAccountPrefsKey,
    appAccountMark(notificationAccountKey(user, url), DateTime.now(), pid: pid),
  );
}

/// Entry point of the background isolate.
@pragma('vm:entry-point')
void backgroundCheckDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    // Plugins written in Dart register themselves only in the main isolate;
    // without this the notifications plugin had no Android side here and
    // showed nothing, without a word.
    DartPluginRegistrant.ensureInitialized();
    await DebugLog.instance.init(isolate: 'Hintergrund');
    try {
      await checkForNewNotifications(
        announceAll: inputData?['announceAll'] == true,
        testNotification: inputData?['testNotification'] == true,
      );
    } on Object catch (e, s) {
      // A failed round is not worth a retry: the next one comes anyway.
      debugLogError('Hintergrundabruf', e, s);
    }
    return true;
  });
}

const _debugTaskName = 'dr.notificationCheck.now';

/// How long a check started by hand waits: time to leave the app, which
/// then takes back its mark, so the account in use is checked as well.
const debugCheckDelay = Duration(seconds: 10);

/// Runs the check once, after [debugCheckDelay] and in the background
/// isolate — for trying it out in a debug build without waiting for the
/// next round.
/// [announceAll] treats everything unread as new, so there is something to
/// see. [testNotification] shows each account's latest received message
/// instead, whether read or not — for when nothing is unread; nothing is
/// remembered as seen.
Future<void> runBackgroundCheckNow({
  bool announceAll = false,
  bool testNotification = false,
}) {
  debugLog(
    LogCategory.background,
    'Test-Lauf in ${debugCheckDelay.inSeconds} s',
  );
  return Workmanager().registerOneOffTask(
    _debugTaskName,
    _debugTaskName,
    inputData: {
      'announceAll': announceAll,
      'testNotification': testNotification,
    },
    initialDelay: debugCheckDelay,
    // As for the periodic check: without it Android may start the run with
    // no network for the app, as it did after the app was swiped away.
    constraints: Constraints(networkType: NetworkType.connected),
    existingWorkPolicy: ExistingWorkPolicy.replace,
  );
}

/// Starts the scheduler; before [scheduleBackgroundCheck].
Future<void> initBackgroundCheck() async {
  if (!Platform.isAndroid) return;
  await Workmanager().initialize(backgroundCheckDispatcher);
}

/// Runs the check as often as [settings] say, or stops it.
///
/// Android lets a periodic job run no more often than every 15 minutes and
/// shifts it at will to save power; the interval is a wish, not a clock.
Future<void> scheduleBackgroundCheck(SettingsState settings) async {
  if (!Platform.isAndroid) return;
  if (!settings.notificationsEnabled) {
    debugLog(LogCategory.background, 'Abruf abgestellt');
    await Workmanager().cancelByUniqueName(_taskName);
    return;
  }
  debugLog(
    LogCategory.background,
    'Abruf geplant: alle ${settings.notificationPollMinutes} min',
  );
  await Workmanager().registerPeriodicTask(
    _taskName,
    _taskName,
    frequency: Duration(minutes: settings.notificationPollMinutes),
    constraints: Constraints(networkType: NetworkType.connected),
    existingWorkPolicy: ExistingPeriodicWorkPolicy.update,
  );
}

L _translations(SettingsState settings) {
  final device = PlatformDispatcher.instance.locale.languageCode;
  final language = settings.language ??
      (supportedLanguages.contains(device) ? device : supportedLanguages.first);
  return lookupL(Locale(language));
}

/// One round: every stored account, one after the other.
Future<void> checkForNewNotifications({
  bool announceAll = false,
  bool testNotification = false,
}) async {
  await loadPackageInfo();
  await initSystemNotifications();
  final prefs = await SharedPreferences.getInstance();
  await prefs.reload();

  final rawSettings = prefs.getString(_settingsPrefsKey);
  final settings = rawSettings == null
      ? SettingsState()
      : SettingsState().withGlobalJson(
          json.decode(rawSettings) as Map<dynamic, dynamic>,
        );
  if (!settings.notificationsEnabled) {
    debugLog(LogCategory.background, 'Lauf übersprungen: abgestellt');
    return;
  }
  final l = _translations(settings);
  // Flutter's localizations set the dates up in the app, not here.
  await initializeDateFormatting(l.localeName);

  final rawProfiles = prefs.getString(_profilesPrefsKey);
  final profiles = rawProfiles == null
      ? const <String, dynamic>{}
      : json.decode(rawProfiles) as Map<String, dynamic>;

  final accounts = notifiableAccounts(
    json.decode(await const FlutterSecureStorage().read(key: 'login') ?? '{}'),
  );
  final started = DateTime.now();
  debugLog(
    LogCategory.background,
    'Lauf${testNotification ? ' (Test)' : announceAll ? ' (alle melden)' : ''}: '
    '${accounts.length} Konten',
  );
  final atStart = await _readKnown(prefs);
  final known = {
    for (final e in atStart.entries) e.key: {...e.value}
  };
  final homeworkAtStart = await _readKnown(prefs, _knownHomeworkPrefsKey);
  final knownHomework = {
    for (final e in homeworkAtStart.entries) e.key: {...e.value}
  };

  for (final account in accounts) {
    final key = notificationAccountKey(account.user, account.url);
    final tag = accountTag(account.user, account.url);
    // Read again for every account: the app may have signed in meanwhile,
    // and signing in here as well would end its session.
    await prefs.reload();
    if (appUsesAccount(
      prefs.getString(_appAccountPrefsKey),
      key,
      DateTime.now(),
      pid: pid,
    )) {
      debugLog(
        LogCategory.background,
        '$tag: übersprungen, die App ist damit angemeldet',
      );
      continue;
    }
    final result = testNotification
        ? await _fetchLatestMessage(account)
        : await _fetchUnread(account);
    // Not reached, or not without a code: it stays as it was until the
    // next round.
    if (result == null) {
      debugLog(LogCategory.background, '$tag: nicht erreicht');
      continue;
    }
    final alias = (profiles[key] as Map<String, dynamic>?)?['alias'] as String?;
    final fresh = testNotification
        ? result.unread
        : freshNotifications(
            known: announceAll ? const {} : known[key],
            unread: result.unread,
            settings: settings,
          );
    final homework = result.homework;
    final freshHw = homework == null
        ? const <UpcomingHomework>[]
        : freshHomework(
            known: announceAll ? const {} : knownHomework[key],
            homework: homework,
            settings: settings,
          );
    debugLog(
      LogCategory.background,
      testNotification
          ? '$tag: letzte Mitteilung als Test'
          : '$tag: ${result.unread.length} ungelesen, ${fresh.length} neu'
              '${known[key] == null ? ' (zum ersten Mal)' : ''}; '
              '${_homeworkLog(homework, freshHw, knownHomework[key])}',
    );
    await syncAccountNotifications(
      l: l,
      account: NotifiedAccount(
        user: account.user,
        url: account.url,
        name: alias ?? result.fullName ?? account.user,
        key: key,
      ),
      fresh: [
        ...fresh,
        for (final h in freshHw) _homeworkNotification(l, h),
      ],
      unreadIds: {for (final n in result.unread) n.id},
      homeworkIds: homework == null
          ? null
          : {for (final h in homework) homeworkNotificationId(h.id)},
    );
    known[key] = {for (final n in result.unread) n.id};
    if (homework != null) {
      knownHomework[key] = {for (final h in homework) h.id};
    }
  }
  debugLog(
    LogCategory.background,
    'Lauf fertig nach ${DateTime.now().difference(started).inSeconds} s',
  );
  // A test leaves the list of what was seen as it was.
  if (testNotification) return;

  final keys = {
    for (final a in accounts) notificationAccountKey(a.user, a.url),
  };
  known.removeWhere((k, _) => !keys.contains(k));
  knownHomework.removeWhere((k, _) => !keys.contains(k));
  await cancelNotificationsExcept(keys);
  // Read again right before writing: the app may have added what it showed
  // in the meantime.
  await prefs.reload();
  await _writeKnownSince(prefs, _knownPrefsKey, known, atStart);
  await _writeKnownSince(
    prefs,
    _knownHomeworkPrefsKey,
    knownHomework,
    homeworkAtStart,
  );
}

/// Writes what a round found, plus what the app added since [atStart]. Only
/// those additions are kept — the rest of the old list is what this round
/// just replaced.
Future<void> _writeKnownSince(
  SharedPreferences prefs,
  String prefsKey,
  Map<String, Set<int>> known,
  Map<String, Set<int>> atStart,
) async {
  final latest = await _readKnown(prefs, prefsKey);
  await _writeKnown(
    prefs,
    {
      for (final e in known.entries)
        e.key: {
          ...e.value,
          ...?latest[e.key]?.difference(atStart[e.key] ?? const {}),
        },
    },
    prefsKey,
  );
}

String _homeworkLog(
  List<UpcomingHomework>? homework,
  List<UpcomingHomework> fresh,
  Set<int>? known,
) {
  if (homework == null) return 'Aufgaben nicht erreicht';
  return '${homework.length} Aufgaben, ${fresh.length} neu'
      '${known == null ? ' (zum ersten Mal)' : ''}';
}

/// [h] as a system notification: what is to be done, and for when.
Notification _homeworkNotification(L l, UpcomingHomework h) => Notification(
      (b) => b
        ..id = homeworkNotificationId(h.id)
        ..title = '${h.subject}: ${h.name}'
        ..subTitle = l.systemNotificationsHomeworkDue(
          h.typeName,
          DateFormat.MMMMEEEEd(l.localeName).format(h.date),
        )
        ..type = notificationTypeHomework
        ..objectId = h.id
        ..timeSent = UtcDateTime.now(),
    );

/// What an account has to tell. [homework] is null when its weeks could not
/// be fetched: then what was known of them stays as it was.
typedef _Found = ({
  List<Notification> unread,
  List<UpcomingHomework>? homework,
});

typedef _Fetched = ({
  List<Notification> unread,
  List<UpcomingHomework>? homework,
  String? fullName,
});

Future<_Fetched?> _fetchUnread(StoredAccount account) =>
    _inSession(account, (session) async {
      final dynamic data = await session.send("api/notification/unread");
      if (data is! List) return null;
      return (
        unread: parseNotifications(data),
        homework: await _fetchHomework(session, account),
      );
    });

/// The homework of this week and the next — what is due is mostly ahead.
Future<List<UpcomingHomework>?> _fetchHomework(
  Wrapper session,
  StoredAccount account,
) async {
  final monday = toMonday(now);
  final days = <CalendarDay>[];
  try {
    for (final week in [monday, monday.add(const Duration(days: 7))]) {
      final dynamic data = await session.send(
        "api/calendar/student",
        args: {"startDate": DateFormat("yyyy-MM-dd").format(week)},
      );
      if (data is! Map<String, dynamic>) return null;
      days.addAll(parseCalendarWeek(data).values);
    }
  } on Object catch (e, s) {
    debugLogError(
      'Hintergrundabruf Aufgaben, ${accountTag(account.user, account.url)}',
      e,
      s,
    );
    return null;
  }
  return homeworkOf(days);
}

/// The account's latest received message, dressed up as a notification
/// about it. For [runBackgroundCheckNow]'s test only: it has no notification
/// on the portal behind it, hence the id 0.
Future<_Fetched?> _fetchLatestMessage(StoredAccount account) =>
    _inSession(account, (session) async {
      final dynamic data = await session.send("api/message/getMyMessages");
      if (data is! List) return null;
      final received = data
          .whereType<Map<dynamic, dynamic>>()
          .where((m) => getBool(m["label_outgoing"]) != true)
          .where((m) => getString(m["timeSent"]) != null)
          .toList()
        ..sort(
          (a, b) =>
              getString(b["timeSent"])!.compareTo(getString(a["timeSent"])!),
        );
      if (received.isEmpty) {
        return (unread: const <Notification>[], homework: null);
      }
      final latest = received.first;
      return (
        homework: null,
        unread: [
          Notification(
            (b) => b
              ..id = 0
              ..title = "Test · ${getString(latest["subject"]) ?? ""}"
              ..subTitle = getString(latest["fromName"])
              ..type = notificationTypeMessage
              ..objectId = getInt(latest["id"])
              ..timeSent = UtcDateTime.parse(getString(latest["timeSent"])!),
          ),
        ],
      );
    });

/// Signs into [account] on a session of its own, runs [fetch] and signs out
/// again. Null when the account cannot be reached or signed into.
Future<_Fetched?> _inSession(
  StoredAccount account,
  Future<_Found?> Function(Wrapper session) fetch,
) async {
  final session = Wrapper();
  try {
    await session.login(
      account.user,
      account.pass,
      null,
      fixupUrl(account.url),
      allowInteractive2fa: false,
      logout: () {},
      configLoaded: () {},
      relogin: () {},
      addProtocolItem: (_) {},
    );
    if (!await session.loggedIn) return null;
    final found = await fetch(session);
    if (found == null) return null;
    return (
      unread: found.unread,
      homework: found.homework,
      fullName: session.config?.fullName,
    );
  } on Object catch (e, s) {
    debugLogError(
      'Hintergrundabruf, ${accountTag(account.user, account.url)}',
      e,
      s,
    );
    return null;
  } finally {
    session.logout(hard: true);
  }
}
