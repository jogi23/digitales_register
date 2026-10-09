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

import 'package:dr/l10n/l10n.dart';
import 'package:dynamic_theme/dynamic_theme.dart';
import 'package:flutter/material.dart';

enum ThemeChoice { followDevice, light, dark }

/// What the theme is set to right now.
ThemeChoice currentThemeChoice(BuildContext context) {
  final theme = DynamicTheme.of(context)!;
  if (theme.followDevice) return ThemeChoice.followDevice;
  return theme.customBrightness == Brightness.dark
      ? ThemeChoice.dark
      : ThemeChoice.light;
}

String themeChoiceLabel(BuildContext context, ThemeChoice choice) {
  final l = tr(context);
  return switch (choice) {
    ThemeChoice.followDevice => l.settingsThemeFollowDevice,
    ThemeChoice.light => l.settingsThemeLight,
    ThemeChoice.dark => l.settingsThemeDark,
  };
}

/// "Every 30 minutes", "Every 3 hours".
String notificationIntervalLabel(BuildContext context, int minutes) {
  final l = tr(context);
  if (minutes < 60) return l.notificationsEveryMinutes(minutes);
  return l.notificationsEveryHours(minutes ~/ 60);
}
