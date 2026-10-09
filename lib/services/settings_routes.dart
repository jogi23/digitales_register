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

import 'package:dr/ui/settings/pages/content_settings_page.dart';
import 'package:dr/ui/settings/settings_hub_page.dart';
import 'package:flutter/material.dart';

/// The routes of the settings, or null for a name that is not one of them.
///
/// `/settings` is the hub; `/settingsGrades` is the content page with the
/// grades block open, reached from the grades page.
Route<void>? settingsRoute(RouteSettings settings) => switch (settings.name) {
      '/settings' => MaterialPageRoute<void>(
          settings: settings,
          builder: (_) => const SettingsHubPage(),
          fullscreenDialog: true,
        ),
      '/settingsGrades' => MaterialPageRoute<void>(
          settings: settings,
          builder: (_) => const ContentSettingsPage(
            initiallyExpanded: {ContentBlock.grades},
          ),
        ),
      _ => null,
    };
