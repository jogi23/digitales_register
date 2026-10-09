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
import 'package:dr/ui/settings/settings_category.dart';
import 'package:dr/ui/settings/widgets/settings_page_scaffold.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// The front door of the settings: one row per group, each saying what it is
/// set to.
class SettingsHubPage extends ConsumerStatefulWidget {
  const SettingsHubPage({super.key});

  @override
  ConsumerState<SettingsHubPage> createState() => _SettingsHubPageState();
}

class _SettingsHubPageState extends ConsumerState<SettingsHubPage> {
  Future<void> _open(SettingsCategory category) async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => category.page),
    );
    // The theme is not in the providers; look again at what it says now.
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final settings = ref.watch(settingsProvider);
    return SettingsPageScaffold(
      title: tr(context).settingsTitle,
      root: true,
      children: [
        for (final category in SettingsCategory.values)
          ListTile(
            leading: Icon(category.icon),
            title: Text(category.title(context)),
            subtitle: Text(category.summary(context, settings)),
            trailing: const Icon(Icons.chevron_right_rounded),
            onTap: () => _open(category),
          ),
      ],
    );
  }
}
