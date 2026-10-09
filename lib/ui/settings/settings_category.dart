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

import 'dart:io';

import 'package:dr/app_state.dart';
import 'package:dr/l10n/l10n.dart';
import 'package:dr/ui/settings/pages/account_settings_page.dart';
import 'package:dr/ui/settings/pages/advanced_settings_page.dart';
import 'package:dr/ui/settings/pages/appearance_settings_page.dart';
import 'package:dr/ui/settings/pages/content_settings_page.dart';
import 'package:dr/ui/settings/pages/notification_settings_page.dart';
import 'package:dr/ui/settings/settings_labels.dart';
import 'package:flutter/material.dart';

/// The groups the settings hub offers, in the order it lists them.
enum SettingsCategory {
  account(Icons.manage_accounts_rounded),
  notifications(Icons.notifications_active_rounded),
  appearance(Icons.palette_rounded),
  content(Icons.dashboard_customize_rounded),
  advanced(Icons.tune_rounded);

  const SettingsCategory(this.icon);

  final IconData icon;

  String title(BuildContext context) {
    final l = tr(context);
    return switch (this) {
      account => l.settingsCategoryAccount,
      notifications => l.settingsCategoryNotifications,
      appearance => l.settingsCategoryAppearance,
      content => l.settingsCategoryContent,
      advanced => l.settingsCategoryAdvanced,
    };
  }

  /// One line that says what the group is set to, or what is in it.
  ///
  /// Without a stored password only the app itself notifies on Android, and
  /// the line says so; [isAndroid] defaults to the platform it runs on.
  String summary(BuildContext context, SettingsState s, {bool? isAndroid}) {
    final l = tr(context);
    return switch (this) {
      account => s.appLockEnabled
          ? l.settingsSummaryAppLockOn
          : l.settingsSummaryAppLockOff,
      notifications => !s.notificationsEnabled
          ? l.settingsSummaryNotificationsOff
          : s.noPasswordSaving && (isAndroid ?? Platform.isAndroid)
              ? l.settingsSummaryNotificationsInAppOnly
              : l.settingsSummaryNotificationsOn(
                  notificationIntervalLabel(context, s.notificationPollMinutes),
                ),
      appearance => l.settingsSummaryAppearance(
          themeChoiceLabel(context, currentThemeChoice(context)),
          // A code this version does not know reads as the device language.
          languageNames[s.language] ?? l.settingsLanguageDevice,
        ),
      content => l.settingsSummaryContent,
      advanced => s.diagnosticsEnabled
          ? l.settingsSummaryDiagnosticsOn
          : l.settingsSummaryDiagnosticsOff,
    };
  }

  Widget get page => switch (this) {
        account => const AccountSettingsPage(),
        notifications => const NotificationSettingsPage(),
        appearance => const AppearanceSettingsPage(),
        content => const ContentSettingsPage(),
        advanced => const AdvancedSettingsPage(),
      };
}
