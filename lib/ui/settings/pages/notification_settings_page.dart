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

import 'package:dr/app_state.dart';
import 'package:dr/background_check.dart';
import 'package:dr/l10n/l10n.dart';
import 'package:dr/providers/settings_provider.dart';
import 'package:dr/ui/background_status_card.dart';
import 'package:dr/ui/battery_hint.dart';
import 'package:dr/ui/settings/widgets/settings_choice_tile.dart';
import 'package:dr/ui/settings/widgets/settings_headers.dart';
import 'package:dr/ui/settings/widgets/settings_page_scaffold.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Whether and how often the app looks for news in the background, and which
/// kinds of news are announced.
class NotificationSettingsPage extends ConsumerWidget {
  const NotificationSettingsPage({super.key});

  String _intervalLabel(BuildContext context, int minutes) {
    final l = tr(context);
    if (minutes < 60) return l.notificationsEveryMinutes(minutes);
    return l.notificationsEveryHours(minutes ~/ 60);
  }

  /// One kind of news; locked while notifications as a whole are off.
  Widget _typeSwitch({
    required IconData icon,
    required String title,
    required bool value,
    required bool enabled,
    required ValueChanged<bool> onChanged,
  }) =>
      SwitchListTile.adaptive(
        secondary: Icon(icon),
        title: Text(title),
        value: value,
        onChanged: enabled ? onChanged : null,
      );

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = tr(context);
    final s = ref.watch(settingsProvider);
    final notifier = ref.read(settingsProvider.notifier);
    final on = s.notificationsEnabled;
    return SettingsPageScaffold(
      title: l.settingsCategoryNotifications,
      children: [
        SwitchListTile.adaptive(
          secondary: const Icon(Icons.notifications_active_rounded),
          title: Text(l.settingsNotificationsEnable),
          // Still a switch without a stored password: it also governs the
          // list inside the app, which works either way. Only the system
          // notifications need to sign in on their own.
          subtitle: Text(
            s.noPasswordSaving && Platform.isAndroid
                ? l.settingsNotificationsNeedStayLoggedIn
                : l.settingsNotificationsEnableSubtitle,
          ),
          value: on,
          onChanged: notifier.setNotificationsEnabled,
        ),
        const BatteryOptimizationHint(),
        const BackgroundStatusCard(),
        SettingsChoiceTile<int>(
          icon: Icons.schedule_rounded,
          title: l.settingsNotificationsInterval,
          hint: l.settingsNotificationsIntervalSubtitle,
          enabled: on,
          value: s.notificationPollMinutes,
          choices: [
            for (final minutes in allowedNotificationPollMinutes)
              SettingsChoice(
                value: minutes,
                label: _intervalLabel(context, minutes),
              ),
          ],
          onChanged: notifier.setNotificationPollMinutes,
        ),
        // Only in debug builds: one round right away, in the background
        // isolate, instead of waiting for the next one.
        if (kDebugMode && Platform.isAndroid)
          ListTile(
            enabled: on && !s.noPasswordSaving,
            leading: const Icon(Icons.bug_report_outlined),
            title: const Text('Jetzt im Hintergrund prüfen (Debug)'),
            subtitle: Text(
              'Lang drücken: alle Ungelesenen melden. Startet nach '
              '${debugCheckDelay.inSeconds} s – App verlassen, damit '
              'auch dieses Konto dabei ist',
            ),
            onTap: () => unawaited(runBackgroundCheckNow()),
            onLongPress: () =>
                unawaited(runBackgroundCheckNow(announceAll: true)),
          ),
        if (kDebugMode && Platform.isAndroid)
          ListTile(
            enabled: on && !s.noPasswordSaving,
            leading: const Icon(Icons.bug_report_outlined),
            title: const Text('Test-Benachrichtigung zeigen (Debug)'),
            subtitle: Text(
              'Neueste empfangene Mitteilung jedes Kontos, auch gelesene. '
              'Startet nach ${debugCheckDelay.inSeconds} s – App '
              'verlassen, damit auch dieses Konto dabei ist',
            ),
            onTap: () =>
                unawaited(runBackgroundCheckNow(testNotification: true)),
          ),
        SettingsSectionHeader(l.settingsNotificationsTypes),
        _typeSwitch(
          icon: Icons.menu_book_rounded,
          title: l.settingsNotificationsTypeClassbook,
          value: s.notifyClassbook,
          enabled: on,
          onChanged: notifier.setNotifyClassbook,
        ),
        _typeSwitch(
          icon: Icons.mail_outline_rounded,
          title: l.settingsNotificationsTypeMessages,
          value: s.notifyMessages,
          enabled: on,
          onChanged: notifier.setNotifyMessages,
        ),
        _typeSwitch(
          icon: Icons.grade_rounded,
          title: l.settingsNotificationsTypeGrades,
          value: s.notifyGrades,
          enabled: on,
          onChanged: notifier.setNotifyGrades,
        ),
        _typeSwitch(
          icon: Icons.visibility_outlined,
          title: l.settingsNotificationsTypeObservations,
          value: s.notifyObservations,
          enabled: on,
          onChanged: notifier.setNotifyObservations,
        ),
        _typeSwitch(
          icon: Icons.assignment_rounded,
          title: l.settingsNotificationsTypeHomework,
          value: s.notifyHomework,
          enabled: on,
          onChanged: notifier.setNotifyHomework,
        ),
        _typeSwitch(
          icon: Icons.hotel_rounded,
          title: l.settingsNotificationsTypeAbsences,
          value: s.notifyAbsences,
          enabled: on,
          onChanged: notifier.setNotifyAbsences,
        ),
      ],
    );
  }
}
