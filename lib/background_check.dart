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
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:workmanager/workmanager.dart';

// Looks for new notifications while the app is closed, on Android only: the
// portal pushes nothing, so every stored account is signed into now and then
// and asked what is unread. What was not there the last time turns into a
// system notification.

const _taskName = 'dr.notificationCheck';

/// The ids each account had unread at the last look, by [notificationAccountKey].
const _knownPrefsKey = 'system_notifications_known';

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

Future<Map<String, Set<int>>> _readKnown(SharedPreferences prefs) async {
  final raw = prefs.getString(_knownPrefsKey);
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
  Map<String, Set<int>> known,
) =>
    prefs.setString(
      _knownPrefsKey,
      json.encode(known.map((k, v) => MapEntry(k, v.toList()))),
    );

/// Remembers that the app showed these notifications, so the next check in
/// the background does not announce them again.
Future<void> rememberSeenNotifications({
  required String user,
  required String url,
  required Iterable<int> ids,
}) async {
  if (!Platform.isAndroid) return;
  final prefs = await SharedPreferences.getInstance();
  // The background check writes from an isolate of its own.
  await prefs.reload();
  final known = await _readKnown(prefs);
  final key = notificationAccountKey(user, url);
  known[key] = {...?known[key], ...ids};
  await _writeKnown(prefs, known);
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

/// Runs the check once, right away and in the background isolate — for
/// trying it out in a debug build without waiting for the next round.
/// [announceAll] treats everything unread as new, so there is something to
/// see. [testNotification] shows each account's latest received message
/// instead, whether read or not — for when nothing is unread; nothing is
/// remembered as seen.
Future<void> runBackgroundCheckNow({
  bool announceAll = false,
  bool testNotification = false,
}) =>
    Workmanager().registerOneOffTask(
      _debugTaskName,
      _debugTaskName,
      inputData: {
        'announceAll': announceAll,
        'testNotification': testNotification,
      },
      existingWorkPolicy: ExistingWorkPolicy.replace,
    );

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

  for (final account in accounts) {
    final key = notificationAccountKey(account.user, account.url);
    final result = testNotification
        ? await _fetchLatestMessage(account)
        : await _fetchUnread(account);
    // Not reached, or not without a code: it stays as it was until the
    // next round.
    final tag = accountTag(account.user, account.url);
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
    debugLog(
      LogCategory.background,
      testNotification
          ? '$tag: letzte Mitteilung als Test'
          : '$tag: ${result.unread.length} ungelesen, ${fresh.length} neu'
              '${known[key] == null ? ' (zum ersten Mal)' : ''}',
    );
    await syncAccountNotifications(
      l: l,
      account: NotifiedAccount(
        user: account.user,
        url: account.url,
        name: alias ?? result.fullName ?? account.user,
        key: key,
      ),
      fresh: fresh,
      unreadIds: {for (final n in result.unread) n.id},
    );
    known[key] = {for (final n in result.unread) n.id};
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
  await cancelNotificationsExcept(keys);
  // Read again right before writing: the app may have added what it showed
  // in the meantime. Only those additions are kept — the rest of the old
  // list is what this round just replaced.
  await prefs.reload();
  final latest = await _readKnown(prefs);
  await _writeKnown(prefs, {
    for (final e in known.entries)
      e.key: {
        ...e.value,
        ...?latest[e.key]?.difference(atStart[e.key] ?? const {}),
      },
  });
}

typedef _Fetched = ({List<Notification> unread, String? fullName});

Future<_Fetched?> _fetchUnread(StoredAccount account) =>
    _inSession(account, (session) async {
      final dynamic data = await session.send("api/notification/unread");
      return data is List ? parseNotifications(data) : null;
    });

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
      if (received.isEmpty) return const [];
      final latest = received.first;
      return [
        Notification(
          (b) => b
            ..id = 0
            ..title = "Test · ${getString(latest["subject"]) ?? ""}"
            ..subTitle = getString(latest["fromName"])
            ..type = notificationTypeMessage
            ..objectId = getInt(latest["id"])
            ..timeSent = UtcDateTime.parse(getString(latest["timeSent"])!),
        ),
      ];
    });

/// Signs into [account] on a session of its own, runs [fetch] and signs out
/// again. Null when the account cannot be reached or signed into.
Future<_Fetched?> _inSession(
  StoredAccount account,
  Future<List<Notification>?> Function(Wrapper session) fetch,
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
    final notifications = await fetch(session);
    if (notifications == null) return null;
    return (unread: notifications, fullName: session.config?.fullName);
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
