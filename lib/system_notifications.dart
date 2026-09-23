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

import 'package:dr/data.dart';
import 'package:dr/l10n/l10n.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

// The system's own notifications on Android — as opposed to the list inside
// the app. Every account gets a group of its own: the notifications carry
// the account's tag, and one summary per account holds the group together.

/// Where a system notification leads when it is tapped.
class SystemNotificationTarget {
  final String user;
  final String url;

  /// The id of the notification on the portal.
  final int id;
  final String? type;
  final int? objectId;

  const SystemNotificationTarget({
    required this.user,
    required this.url,
    required this.id,
    this.type,
    this.objectId,
  });

  String toPayload() => json.encode({
        'user': user,
        'url': url,
        'id': id,
        if (type != null) 'type': type,
        if (objectId != null) 'objectId': objectId,
      });

  /// Null for a payload that is not one of ours — the summary of a group,
  /// for instance, which leads nowhere in particular.
  static SystemNotificationTarget? fromPayload(String? payload) {
    if (payload == null) return null;
    try {
      final decoded = json.decode(payload);
      if (decoded is! Map) return null;
      final user = decoded['user'];
      final url = decoded['url'];
      final id = decoded['id'];
      if (user is! String || url is! String || id is! int) return null;
      return SystemNotificationTarget(
        user: user,
        url: url,
        id: id,
        type: decoded['type'] as String?,
        objectId: decoded['objectId'] as int?,
      );
    } on FormatException {
      return null;
    }
  }
}

/// An account as its notifications show it: [name] is the alias, else the
/// name the portal knows it by.
class NotifiedAccount {
  final String user;
  final String url;
  final String name;

  /// Tags the account's notifications; the same key the aliases use.
  final String key;

  const NotifiedAccount({
    required this.user,
    required this.url,
    required this.name,
    required this.key,
  });
}

const _channelId = 'register_notifications';

/// Portal ids are positive; the summary of a group never meets one of them.
const _summaryId = -1;

final _plugin = FlutterLocalNotificationsPlugin();

AndroidFlutterLocalNotificationsPlugin? get _android =>
    _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();

Future<void> initSystemNotifications({
  void Function(SystemNotificationTarget target)? onTap,
}) async {
  await _plugin.initialize(
    settings: const InitializationSettings(
      android: AndroidInitializationSettings('ic_notification'),
    ),
    onDidReceiveNotificationResponse: onTap == null
        ? null
        : (response) {
            final target =
                SystemNotificationTarget.fromPayload(response.payload);
            if (target != null) onTap(target);
          },
  );
}

/// The notification the app was started from, if it was.
Future<SystemNotificationTarget?> launchTarget() async {
  final details = await _plugin.getNotificationAppLaunchDetails();
  if (details == null || !details.didNotificationLaunchApp) return null;
  return SystemNotificationTarget.fromPayload(
    details.notificationResponse?.payload,
  );
}

/// Asks for the permission Android 13 and later want before anything shows.
/// Older versions grant it with the installation.
Future<bool> requestSystemNotificationPermission() async =>
    await _android?.requestNotificationsPermission() ?? false;

AndroidNotificationDetails _details(
  L l,
  NotifiedAccount account, {
  bool summary = false,
  StyleInformation? style,
  int? when,
}) =>
    AndroidNotificationDetails(
      _channelId,
      l.systemNotificationsChannel,
      channelDescription: l.systemNotificationsChannelDescription,
      importance: Importance.defaultImportance,
      groupKey: 'dr.account.${account.key}',
      setAsGroupSummary: summary,
      // Only what is new makes a sound; the summary is shown again after
      // every check and would otherwise ring each time.
      groupAlertBehavior: GroupAlertBehavior.children,
      tag: account.key,
      subText: account.name,
      styleInformation: style,
      when: when,
      showWhen: when != null,
      category: AndroidNotificationCategory.message,
    );

/// Brings the account's system notifications in line with the portal: shows
/// [fresh], takes back those no longer in [unreadIds] and keeps a summary on
/// top of whatever is left.
Future<void> syncAccountNotifications({
  required L l,
  required NotifiedAccount account,
  required List<Notification> fresh,
  required Set<int> unreadIds,
}) async {
  final android = _android;
  if (android == null) return;
  for (final n in fresh) {
    final text = [n.title, if (n.subTitle?.isNotEmpty ?? false) n.subTitle!]
        .join('\n');
    await _plugin.show(
      id: n.id,
      title: account.name,
      body: n.title,
      notificationDetails: NotificationDetails(
        android: _details(
          l,
          account,
          style: BigTextStyleInformation(text),
          when: n.timeSent.millisecondsSinceEpoch,
        ),
      ),
      payload: SystemNotificationTarget(
        user: account.user,
        url: account.url,
        id: n.id,
        type: n.type,
        objectId: n.objectId,
      ).toPayload(),
    );
  }

  final shown = <int, String>{
    for (final a in await android.getActiveNotifications())
      if (a.tag == account.key && a.id != null && a.id != _summaryId)
        a.id!: a.body ?? '',
  };
  for (final n in fresh) {
    shown[n.id] = n.title;
  }
  for (final id in shown.keys.toList()) {
    if (unreadIds.contains(id)) continue;
    await android.cancel(id: id, tag: account.key);
    shown.remove(id);
  }

  if (shown.isEmpty) {
    await android.cancel(id: _summaryId, tag: account.key);
    return;
  }
  final count = l.systemNotificationsCount(shown.length);
  await _plugin.show(
    id: _summaryId,
    title: account.name,
    body: count,
    notificationDetails: NotificationDetails(
      android: _details(
        l,
        account,
        summary: true,
        style: InboxStyleInformation(
          shown.values.toList(),
          contentTitle: account.name,
          summaryText: count,
        ),
      ),
    ),
  );
}

/// Takes back the notifications of accounts that are no longer stored.
Future<void> cancelNotificationsExcept(Set<String> accountKeys) async {
  final android = _android;
  if (android == null) return;
  for (final a in await android.getActiveNotifications()) {
    final tag = a.tag;
    if (a.id == null || tag == null || accountKeys.contains(tag)) continue;
    await android.cancel(id: a.id!, tag: tag);
  }
}
