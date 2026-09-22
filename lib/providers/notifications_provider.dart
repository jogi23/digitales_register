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
import 'dart:convert';

import 'package:dr/data.dart';
import 'package:dr/l10n/l10n.dart';
import 'package:dr/middleware/middleware.dart' show secureStorage, wrapper;
import 'package:dr/notification_visibility.dart';
import 'package:dr/providers/login_provider.dart';
import 'package:dr/providers/no_internet_provider.dart';
import 'package:dr/providers/settings_provider.dart';
import 'package:dr/utc_date_time.dart';
import 'package:dr/util.dart';
import 'package:dr/wrapper.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class NotificationsState {
  final List<Notification> notifications;
  final UtcDateTime? lastFetched;

  const NotificationsState({
    this.notifications = const [],
    this.lastFetched,
  });

  NotificationsState copyWith({
    List<Notification>? notifications,
    UtcDateTime? lastFetched,
  }) =>
      NotificationsState(
        notifications: notifications ?? this.notifications,
        lastFetched: lastFetched ?? this.lastFetched,
      );
}

class NotificationsNotifier extends Notifier<NotificationsState> {
  Timer? _pollTimer;
  bool _loading = false;
  final _syntheticAccountById = <int, String>{};
  final _lastSyntheticCounts = <String, int>{};
  final _dismissedSyntheticAccounts = <String>{};

  @override
  NotificationsState build() {
    ref.listen(
      settingsProvider.select(
        (s) => (s.notificationsEnabled, s.notificationPollMinutes),
      ),
      (_, __) => _restartPolling(),
    );
    ref.listen(
      loginProvider.select((s) => s.loggedIn),
      (_, __) => _restartPolling(),
    );
    ref.onDispose(() => _pollTimer?.cancel());
    _restartPolling();
    return const NotificationsState();
  }

  void reset() {
    state = const NotificationsState();
  }

  void restore(NotificationsState saved) => state = saved;

  Future<void> load() async {
    if (_loading) return;
    _loading = true;
    try {
      if (ref.read(noInternetProvider)) return;
      final settings = ref.read(settingsProvider);
      if (!settings.notificationsEnabled) return;
      final dynamic data = await wrapper.send("api/notification/unread");
      final fromCurrent =
          data is List ? _parseNotifications(data) : <Notification>[];
      final fromOthers = await _otherAccountMessageNotifications();
      final parsed = [...fromCurrent, ...fromOthers]
        ..sort((a, b) => b.timeSent.compareTo(a.timeSent));
      state = state.copyWith(
        notifications: parsed,
        lastFetched: UtcDateTime.now(),
      );
    } finally {
      _loading = false;
    }
  }

  Future<void> delete(Notification notification) async {
    state = state.copyWith(
      notifications:
          state.notifications.where((n) => n != notification).toList(),
    );
    if (notification.id < 0) {
      final accountKey = _syntheticAccountById[notification.id];
      if (accountKey != null) _dismissedSyntheticAccounts.add(accountKey);
      return;
    }
    await wrapper.send(
      "api/notification/markAsRead",
      args: {"id": notification.id},
    );
  }

  Future<void> deleteAll() async {
    final messageNotifications = state.notifications
        .where((n) => n.type == "message" && n.objectId != null)
        .toList();
    state = state.copyWith(notifications: []);
    for (final n in messageNotifications) {
      await wrapper.send(
        "api/message/markAsRead",
        args: {"messageId": n.objectId},
      );
    }
    await wrapper.send("api/notification/markAsRead", args: {});
  }

  /// Called when a message is marked as read (cross-feature), so the
  /// corresponding notification badge is removed and the server is informed.
  Future<void> markMessageAsRead(int objectId) async {
    // Only message notifications: a grade can carry the same number as its
    // object id, and reading a message says nothing about that grade.
    bool matches(Notification n) =>
        n.type == "message" && n.objectId == objectId;
    final matching = state.notifications.where(matches).toList();
    state = state.copyWith(
      notifications: state.notifications.where((n) => !matches(n)).toList(),
    );
    for (final n in matching) {
      await wrapper.send("api/notification/markAsRead", args: {"id": n.id});
    }
  }

  List<Notification> _parseNotifications(List<dynamic> data) {
    return data
        .map<Notification>(
          (dynamic n) => tryParse(
            getMap(n),
            (dynamic n) => Notification(
              (b) => b
                ..id = getInt(n["id"])
                ..title = getString(n["title"])
                ..type = getString(n["type"])
                ..objectId = getInt(n["objectId"])
                ..subTitle = getString(n["subTitle"])
                ..timeSent = UtcDateTime.parse(getString(n["timeSent"])!),
            ),
          ),
        )
        .toList();
  }

  void _restartPolling() {
    _pollTimer?.cancel();
    final settings = ref.read(settingsProvider);
    final loggedIn = ref.read(loginProvider).loggedIn;
    if (!settings.notificationsEnabled) return;
    if (!loggedIn) return;
    unawaited(load());
    _pollTimer = Timer.periodic(
      Duration(minutes: settings.notificationPollMinutes),
      (_) => unawaited(load()),
    );
  }

  Future<List<Notification>> _otherAccountMessageNotifications() async {
    final currentUser = wrapper.user;
    final currentUrl = wrapper.url;
    final accounts = await _storedLogins();
    final otherAccounts = accounts
        .where((a) => a.user != currentUser || a.url != currentUrl)
        .toList();
    _syntheticAccountById.clear();
    final List<Notification> out = [];
    var syntheticId = -1;
    final summaries = await Future.wait(
      otherAccounts.map(_unreadMessageSummaryFor),
    );
    for (var i = 0; i < otherAccounts.length; i++) {
      final account = otherAccounts[i];
      final summary = summaries[i];
      final count = summary.count;
      final accountKey = '${account.user}|${account.url}';
      final previousCount = _lastSyntheticCounts[accountKey];
      _lastSyntheticCounts[accountKey] = count;
      if (count != previousCount) {
        _dismissedSyntheticAccounts.remove(accountKey);
      }
      if (count <= 0) continue;
      if (_dismissedSyntheticAccounts.contains(accountKey)) continue;
      final id = syntheticId--;
      _syntheticAccountById[id] = accountKey;
      out.add(
        Notification(
          (b) => b
            ..id = id
            ..title = trGlobal.notificationsMessagesInAccount(account.user)
            ..subTitle = trGlobal.notificationsUnreadCount(count)
            ..type = 'message'
            ..timeSent = summary.latest ?? UtcDateTime.now(),
        ),
      );
    }
    return out;
  }

  Future<({int count, UtcDateTime? latest})> _unreadMessageSummaryFor(
    ({String user, String pass, String url}) account,
  ) async {
    final temp = Wrapper();
    try {
      await temp.login(
        account.user,
        account.pass,
        null,
        account.url,
        allowInteractive2fa: false,
        logout: () {},
        configLoaded: () {},
        relogin: () {},
        addProtocolItem: (_) {},
      );
      if (!await temp.loggedIn) return (count: 0, latest: null);
      final dynamic data = await temp.send("api/notification/unread");
      if (data is! List) return (count: 0, latest: null);
      final parsed = _parseNotifications(data);
      final messages = parsed
          .where((n) => (n.type ?? '').toLowerCase() == 'message')
          .toList();
      final latest = messages.isEmpty
          ? null
          : messages
              .map((n) => n.timeSent)
              .reduce((a, b) => a.compareTo(b) >= 0 ? a : b);
      return (count: messages.length, latest: latest);
    } on Exception {
      return (count: 0, latest: null);
    } finally {
      temp.logout(hard: true);
    }
  }

  Future<List<({String user, String pass, String url})>> _storedLogins() async {
    try {
      final raw = await secureStorage.read(key: "login");
      final decoded = json.decode(raw ?? "{}");
      final entries = <Map<dynamic, dynamic>>[];
      if (decoded is Map) {
        entries.add(decoded);
        final others = decoded["otherAccounts"];
        if (others is List) {
          for (final dynamic entry in others) {
            if (entry is Map) entries.add(entry);
          }
        }
      }
      final seen = <String>{};
      final out = <({String user, String pass, String url})>[];
      for (final e in entries) {
        final user = getString(e["user"]);
        final pass = getString(e["pass"]);
        final url = getString(e["url"]);
        if (user == null || pass == null || url == null) continue;
        final key = '$user|$url';
        if (!seen.add(key)) continue;
        out.add((user: user, pass: pass, url: url));
      }
      return out;
    } catch (_) {
      return const [];
    }
  }
}

final notificationsProvider =
    NotifierProvider<NotificationsNotifier, NotificationsState>(
  NotificationsNotifier.new,
);
