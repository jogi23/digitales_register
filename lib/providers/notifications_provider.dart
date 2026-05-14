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

import 'package:dr/data.dart';
import 'package:dr/middleware/middleware.dart' show wrapper;
import 'package:dr/providers/no_internet_provider.dart';
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
  @override
  NotificationsState build() => const NotificationsState();

  void reset() {
    state = const NotificationsState();
  }

  Future<void> load() async {
    if (ref.read(noInternetProvider)) return;
    final dynamic data = await wrapper.send("api/notification/unread");
    if (data is List) {
      state = state.copyWith(
        notifications: _parseNotifications(data),
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
  /// corresponding notification badge is removed.
  void markMessageAsRead(int objectId) {
    state = state.copyWith(
      notifications:
          state.notifications.where((n) => n.objectId != objectId).toList(),
    );
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
}

final notificationsProvider =
    NotifierProvider<NotificationsNotifier, NotificationsState>(
  NotificationsNotifier.new,
);
