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

import 'package:dr/app_links.dart';
import 'package:dr/l10n/l10n.dart';
import 'package:dr/ui/diagnostics_settings.dart';
import 'package:dr/ui/settings/widgets/settings_page_scaffold.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

/// What only support and developers need.
class AdvancedSettingsPage extends StatelessWidget {
  const AdvancedSettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final l = tr(context);
    return SettingsPageScaffold(
      title: l.settingsCategoryAdvanced,
      children: [
        const DiagnosticsSettingsTiles(),
        ListTile(
          leading: const Icon(Icons.code_rounded),
          trailing: const Icon(Icons.open_in_new_rounded),
          title: Text(l.settingsSource),
          onTap: () => unawaited(launchUrl(AppLinks.source)),
        ),
      ],
    );
  }
}
