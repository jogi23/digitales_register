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
import 'package:dr/providers/network_protocol_provider.dart';
import 'package:dr/providers/settings_provider.dart';
import 'package:dr/services/diagnostics_export.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// The switch for the diagnostic log (#325) and, while it is on, the entry
/// that shares what it recorded.
class DiagnosticsSettingsTiles extends ConsumerWidget {
  const DiagnosticsSettingsTiles({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final enabled =
        ref.watch(settingsProvider.select((s) => s.diagnosticsEnabled));
    final l = tr(context);
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SwitchListTile.adaptive(
          title: Text(l.settingsDiagnostics),
          subtitle: Text(l.settingsDiagnosticsSubtitle),
          value: enabled,
          onChanged: ref.read(settingsProvider.notifier).setDiagnosticsEnabled,
        ),
        if (enabled)
          ListTile(
            leading: const Icon(Icons.share),
            title: Text(l.diagnosticsShare),
            onTap: () => _share(context, ref),
          ),
      ],
    );
  }

  /// Asks first: the protocol holds what the portal answered.
  Future<void> _share(BuildContext context, WidgetRef ref) async {
    final l = tr(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l.diagnosticsShareWarningTitle),
        content: Text(l.diagnosticsShareWarningBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(l.commonCancel),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(l.commonShare),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;
    final result = await ref
        .read(diagnosticsExportProvider)
        .share(ref.read(networkProtocolProvider));
    if (result == DiagnosticsExportResult.empty && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l.diagnosticsNothingRecorded)),
      );
    }
  }
}
