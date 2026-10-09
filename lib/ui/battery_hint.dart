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

import 'package:dr/app_links.dart';
import 'package:dr/l10n/l10n.dart';
import 'package:dr/providers/settings_provider.dart';
import 'package:dr/services/battery_optimization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

/// Tells that Android may hold back the notifications, and takes the reader
/// to where that can be changed (#318). Gone while notifications are off, once
/// the app is exempt, and where Android cannot tell.
class BatteryOptimizationHint extends ConsumerStatefulWidget {
  const BatteryOptimizationHint({super.key});

  @override
  ConsumerState<BatteryOptimizationHint> createState() =>
      _BatteryOptimizationHintState();
}

class _BatteryOptimizationHintState
    extends ConsumerState<BatteryOptimizationHint> with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  /// Back from the system page: look at what was decided there.
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      ref.invalidate(batteryOptimizationProvider);
    }
  }

  @override
  Widget build(BuildContext context) {
    final notifications =
        ref.watch(settingsProvider.select((s) => s.notificationsEnabled));
    final exempt = ref.watch(batteryOptimizationProvider).valueOrNull;
    if (!notifications || exempt != false) return const SizedBox.shrink();

    final l = tr(context);
    final colors = Theme.of(context).colorScheme;
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: colors.secondaryContainer,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Semantics(
              header: true,
              child: Text(
                l.batteryHintTitle,
                style: Theme.of(context).textTheme.titleSmall,
              ),
            ),
            const SizedBox(height: 8),
            Text(l.batteryHintBody),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: [
                FilledButton(
                  onPressed: ref.read(openBatterySettingsProvider),
                  child: Text(l.batteryHintButton),
                ),
                TextButton(
                  onPressed: () => launchUrl(
                    AppLinks.dontKillMyApp,
                    mode: LaunchMode.externalApplication,
                  ),
                  child: Text(l.batteryHintMore),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
