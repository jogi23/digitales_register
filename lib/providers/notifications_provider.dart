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

import 'package:dr/background_check.dart';
import 'package:dr/data.dart';
import 'package:dr/debug_log.dart';
import 'package:dr/middleware/middleware.dart' show wrapper;
import 'package:dr/notification_type.dart';
import 'package:dr/providers/login_provider.dart';
import 'package:dr/providers/no_internet_provider.dart';
import 'package:dr/providers/settings_provider.dart';
import 'package:dr/utc_date_time.dart';
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

  /// Read here, but perhaps not yet on the portal: a list fetched before the
  /// portal heard of it would bring them back. Kept out until the portal no
  /// longer lists them. By notification id, and for messages by message id —
  /// a message may be read before its notification was in the list.
  final _readHere = <int>{};
  final _messagesReadHere = <int>{};

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
    _readHere.clear();
    _messagesReadHere.clear();
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
      final fetched =
          data is List ? parseNotifications(data) : <Notification>[];
      _readHere.retainAll(fetched.map((n) => n.id));
      _messagesReadHere.retainAll(
        fetched.where((n) => n.type == "message").map((n) => n.objectId),
      );
      final parsed = fetched
          .where((n) => !_readHere.contains(n.id))
          .where(
            (n) =>
                n.type != "message" || !_messagesReadHere.contains(n.objectId),
          )
          .toList()
        ..sort((a, b) => b.timeSent.compareTo(a.timeSent));
      // Seen here, so the background check does not bring them up again as
      // a system notification.
      final user = wrapper.user;
      final url = wrapper.url;
      if (data is List && user != null && url != null) {
        unawaited(rememberSeenNotifications(
          user: user,
          url: url,
          ids: fetched.map((n) => n.id),
        ));
      }
      debugLog(
        LogCategory.notifications,
        'Geladen: ${fetched.length}, davon ${fetched.length - parsed.length} '
        'in dieser Sitzung gelesen und zurückgehalten',
      );
      state = state.copyWith(
        notifications: parsed,
        lastFetched: UtcDateTime.now(),
      );
    } finally {
      _loading = false;
    }
  }

  Future<void> delete(Notification notification) async {
    debugLog(LogCategory.notifications, 'Gelesen: ${notification.id}');
    _readHere.add(notification.id);
    state = state.copyWith(
      notifications:
          state.notifications.where((n) => n != notification).toList(),
    );
    await wrapper.send(
      "api/notification/markAsRead",
      args: {"id": notification.id},
    );
  }

  /// Marks the notification with [id] as read, whether or not it is in the
  /// list yet — a tapped system notification may have come before the list.
  Future<void> markAsRead(int id) async {
    debugLog(LogCategory.notifications, 'Gelesen: $id');
    _readHere.add(id);
    state = state.copyWith(
      notifications: state.notifications.where((n) => n.id != id).toList(),
    );
    await wrapper.send("api/notification/markAsRead", args: {"id": id});
  }

  Future<void> deleteAll() async {
    debugLog(
      LogCategory.notifications,
      'Alle gelesen: ${state.notifications.length}',
    );
    final messageNotifications = state.notifications
        .where((n) => n.type == "message" && n.objectId != null)
        .toList();
    _readHere.addAll(state.notifications.map((n) => n.id));
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
    _messagesReadHere.add(objectId);
    final matching = state.notifications.where(matches).toList();
    state = state.copyWith(
      notifications: state.notifications.where((n) => !matches(n)).toList(),
    );
    for (final n in matching) {
      await wrapper.send("api/notification/markAsRead", args: {"id": n.id});
    }
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
}

final notificationsProvider =
    NotifierProvider<NotificationsNotifier, NotificationsState>(
  NotificationsNotifier.new,
);
