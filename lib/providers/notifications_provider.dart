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

import 'package:dr/data.dart';
import 'package:dr/middleware/middleware.dart' show wrapper;
import 'package:dr/notification_visibility.dart';
import 'package:dr/providers/login_provider.dart';
import 'package:dr/providers/no_internet_provider.dart';
import 'package:dr/providers/settings_provider.dart';
import 'package:dr/utc_date_time.dart';
import 'package:dr/util.dart';
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

  @override
  NotificationsState build() {
    ref.listen(
      settingsProvider.select(
        (s) => (
          s.notificationsEnabled,
          s.notificationPollMinutes,
          s.notifyClassbook,
          s.notifyMessages,
          s.notifyGrades,
          s.notifyObservations,
          s.notifyHomework,
        ),
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
    if (ref.read(noInternetProvider)) return;
    final settings = ref.read(settingsProvider);
    if (!settings.notificationsEnabled) return;
    final dynamic data = await wrapper.send("api/notification/unread");
    if (data is List) {
      final parsed = _parseNotifications(data)
        ..sort((a, b) => b.timeSent.compareTo(a.timeSent));
      state = state.copyWith(
        notifications: parsed,
        lastFetched: UtcDateTime.now(),
      );
    }
  }

  Future<void> delete(Notification notification) async {
    state = state.copyWith(
      notifications:
          state.notifications.where((n) => n != notification).toList(),
    );
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
    final wasRunning = _pollTimer?.isActive ?? false;
    _pollTimer?.cancel();
    final settings = ref.read(settingsProvider);
    final loggedIn = ref.read(loginProvider).loggedIn;
    if (!settings.notificationsEnabled) return;
    if (!loggedIn) return;
    if (!wasRunning) unawaited(load());
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
