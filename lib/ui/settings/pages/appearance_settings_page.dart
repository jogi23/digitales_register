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
import 'package:dr/providers/settings_provider.dart';
import 'package:dr/ui/settings/widgets/accent_color_picker.dart';
import 'package:dr/ui/settings/widgets/settings_choice_tile.dart';
import 'package:dr/ui/settings/widgets/settings_page_scaffold.dart';
import 'package:dynamic_theme/dynamic_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

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

/// Language, light or dark, and the colours the app wears.
class AppearanceSettingsPage extends ConsumerStatefulWidget {
  const AppearanceSettingsPage({super.key});

  @override
  ConsumerState<AppearanceSettingsPage> createState() =>
      _AppearanceSettingsPageState();
}

class _AppearanceSettingsPageState
    extends ConsumerState<AppearanceSettingsPage> {
  // The theme lives in DynamicTheme, outside the providers, so the row has to
  // be told to look again.
  void _selectTheme(ThemeChoice choice) {
    final theme = DynamicTheme.of(context)!;
    switch (choice) {
      case ThemeChoice.light:
        theme.setFollowDevice(false);
        theme.setBrightness(Brightness.light);
      case ThemeChoice.dark:
        theme.setFollowDevice(false);
        theme.setBrightness(Brightness.dark);
      case ThemeChoice.followDevice:
        theme.setFollowDevice(true);
    }
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final l = tr(context);
    final settings = ref.watch(settingsProvider);
    final notifier = ref.read(settingsProvider.notifier);
    return SettingsPageScaffold(
      title: l.settingsCategoryAppearance,
      children: [
        SettingsChoiceTile<String>(
          icon: Icons.translate_rounded,
          title: l.settingsLanguage,
          // The empty string stands for "follow the device": a choice cannot
          // tell a null value from no value.
          value: settings.language ?? '',
          choices: [
            SettingsChoice(value: '', label: l.settingsLanguageDevice),
            for (final code in supportedLanguages)
              SettingsChoice(value: code, label: languageNames[code]!),
          ],
          onChanged: (value) =>
              notifier.setLanguage(value == '' ? null : value),
        ),
        SettingsChoiceTile<ThemeChoice>(
          icon: Icons.brightness_6_rounded,
          title: l.settingsTheme,
          value: currentThemeChoice(context),
          choices: [
            for (final choice in ThemeChoice.values)
              SettingsChoice(
                value: choice,
                label: themeChoiceLabel(context, choice),
              ),
          ],
          onChanged: _selectTheme,
        ),
        const AccentColorPicker(),
        SwitchListTile.adaptive(
          secondary: const Icon(Icons.format_color_fill_rounded),
          title: Text(l.settingsAccentBackground),
          subtitle: Text(l.settingsAccentBackgroundSubtitle),
          value: settings.accentBackground,
          onChanged: notifier.setAccentBackground,
        ),
      ],
    );
  }
}
