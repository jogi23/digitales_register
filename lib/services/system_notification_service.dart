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
import 'dart:io';

import 'package:dr/app_state.dart' hide LoginState;
import 'package:dr/background_check.dart';
import 'package:dr/debug_log.dart';
import 'package:dr/main.dart' show scaffoldKey;
import 'package:dr/middleware/middleware.dart' show wrapper;
import 'package:dr/notification_type.dart';
import 'package:dr/providers/login_provider.dart';
import 'package:dr/providers/messages_provider.dart';
import 'package:dr/providers/notifications_provider.dart';
import 'package:dr/providers/provider_container.dart';
import 'package:dr/providers/settings_provider.dart';
import 'package:dr/services/app_router.dart';
import 'package:dr/system_notifications.dart';
import 'package:dr/util.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

// The app's side of the system notifications: setting them up, keeping the
// background check in step with the settings, and following a tap.

const _permissionAskedPrefsKey = 'notification_permission_asked';

/// Sets up the system notifications and the background check. Android only.
Future<void> initSystemNotificationService() async {
  if (!Platform.isAndroid) return;
  await initBackgroundCheck();
  await initSystemNotifications(onTap: openSystemNotification);
}

/// Follows the notification the app was started from, if it was.
Future<void> openLaunchNotification() async {
  if (!Platform.isAndroid) return;
  final target = await launchTarget();
  if (target != null) openSystemNotification(target);
}

final _syncing = <ProviderContainer>{};

/// Schedules the background check as the settings say, from now on. Asks
/// for the permission to notify once on the first start, and again whenever
/// the notifications are switched on.
void keepBackgroundCheckInSync(ProviderContainer container) {
  if (!Platform.isAndroid || !_syncing.add(container)) return;
  container.listen<(bool, int)>(
    settingsProvider
        .select((s) => (s.notificationsEnabled, s.notificationPollMinutes)),
    (previous, next) {
      final settings = container.read(settingsProvider);
      unawaited(scheduleBackgroundCheck(settings));
      final switchedOn = previous != null && !previous.$1 && next.$1;
      unawaited(_askPermission(settings, always: switchedOn));
    },
    fireImmediately: true,
  );
}

Future<void> _askPermission(
  SettingsState settings, {
  required bool always,
}) async {
  if (!settings.notificationsEnabled) return;
  final prefs = await SharedPreferences.getInstance();
  if (!always && (prefs.getBool(_permissionAskedPrefsKey) ?? false)) return;
  await prefs.setBool(_permissionAskedPrefsKey, true);
  final granted = await requestSystemNotificationPermission();
  debugLog(
    LogCategory.systemNotification,
    'Berechtigung angefragt: ${granted ? 'erteilt' : 'nicht erteilt'}',
  );
}

/// Opens what a tapped system notification is about — in its own account,
/// switching to it first when another one is in use.
void openSystemNotification(SystemNotificationTarget target) {
  final login = providerContainer.read(loginProvider);
  final notifier = providerContainer.read(loginProvider.notifier);
  debugLog(
    LogCategory.systemNotification,
    'Getippt: ${target.type}, ${accountTag(target.user, target.url)}'
    '${login.loggedIn ? '' : ', wartet auf die Anmeldung'}',
  );
  if (!login.loggedIn) {
    // Started by the tap: the stored account is still signing in. Decided
    // once it has — after the callbacks, which are cleared right after
    // running and would take a switch requested from within them along.
    notifier.addAfterLoginCallback(
      () => scheduleMicrotask(() => openSystemNotification(target)),
    );
    return;
  }
  if (isCurrentAccount(login, target)) {
    debugLog(LogCategory.systemNotification, 'Gleiches Konto, wird geöffnet');
    _open(target);
    return;
  }
  final index = login.otherAccounts.indexWhere(
    (a) => a.username == target.user && sameServer(a.url, target.url),
  );
  debugLog(
    LogCategory.systemNotification,
    index < 0
        ? 'Konto nicht mehr gespeichert'
        : 'Anderes Konto: Index $index von ${login.otherAccounts.length}',
  );
  // The account was removed since the notification came.
  if (index < 0) return;
  notifier.addAfterLoginCallback(() => _open(target));
  notifier.selectAccount(index);
}

/// Whether [target] belongs to the account the app is in.
///
/// Asked of the login state, not of the session: after a start by the tap
/// the app shows the stored account before it has signed in online, and the
/// session knew no user yet — the account in use was looked for among the
/// others, and nothing opened (#284).
@visibleForTesting
bool isCurrentAccount(LoginState login, SystemNotificationTarget target) =>
    login.username == target.user && sameServer(login.url, target.url);

/// Runs [tellPortal] once the app has signed in online — right away if it
/// has. Before that, as after a start by the tap, requests are dropped;
/// [thenReload] then fetches what the stored state could not show.
void _whenSignedIn(void Function() tellPortal, {void Function()? thenReload}) {
  if (wrapper.user != null) {
    tellPortal();
    return;
  }
  debugLog(
    LogCategory.systemNotification,
    'Portal erfährt es nach der Anmeldung',
  );
  providerContainer.read(loginProvider.notifier).addAfterLoginCallback(() {
    tellPortal();
    thenReload?.call();
  });
}

/// After an account switch the home page is built anew and may not stand
/// yet; this waits a few frames for it.
void _open(SystemNotificationTarget target, {int framesLeft = 10}) {
  if (scaffoldKey?.currentState == null) {
    if (framesLeft == 0) {
      debugLog(
        LogCategory.systemNotification,
        'Startseite steht nicht: nichts geöffnet',
      );
    }
    if (framesLeft > 0) {
      WidgetsBinding.instance.addPostFrameCallback(
        (_) => _open(target, framesLeft: framesLeft - 1),
      );
    }
    return;
  }
  final router = providerContainer.read(appRouterProvider);
  final notifications = providerContainer.read(notificationsProvider.notifier);
  final objectId = target.objectId;
  // Id 0 is the test notification of debug builds, negative ids are homework
  // found by the check itself: no notification on the portal stands behind
  // them, so there is nothing to mark there.
  final fromPortal = target.id > 0;
  debugLog(
    LogCategory.systemNotification,
    'Öffnet ${target.type} ${objectId ?? '-'}${target.id == 0 ? ' (Test)' : ''}',
  );
  switch (normalizedNotificationType(target.type)) {
    case notificationTypeMessage || notificationTypeMessageShared
        when objectId != null:
      router.showMessage(objectId);
      _whenSignedIn(
        () {
          // Both: the list may not have been loaded yet after a cold start.
          if (fromPortal) unawaited(notifications.markAsRead(target.id));
          unawaited(notifications.markMessageAsRead(objectId));
        },
        // A message newer than the stored list shows once it is loaded.
        thenReload: () => unawaited(
          providerContainer.read(messagesProvider.notifier).load(),
        ),
      );
    case notificationTypeGrade when objectId != null:
      router.revealGrade(objectId);
      _whenSignedIn(() {
        if (fromPortal) unawaited(notifications.markAsRead(target.id));
      });
    case notificationTypeHomework || notificationTypeExam:
      // The overview loads the weeks itself, the new entry among them.
      router.showHomeworkOverview();
      _whenSignedIn(() {
        if (fromPortal) unawaited(notifications.markAsRead(target.id));
      });
    case notificationTypeAbsence ||
          notificationTypeAbsenceReason ||
          notificationTypeAbsenceAdvance ||
          notificationTypeAbsenceReasonAdvanceForClass:
      router.showAbsences();
      _whenSignedIn(() {
        if (fromPortal) unawaited(notifications.markAsRead(target.id));
      });
    default:
      router.showNotifications();
  }
}
