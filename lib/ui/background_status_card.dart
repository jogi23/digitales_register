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

import 'package:dr/background_check.dart';
import 'package:dr/l10n/l10n.dart';
import 'package:dr/providers/settings_provider.dart';
import 'package:dr/services/background_status.dart';
import 'package:dr/system_notifications.dart';
import 'package:dr/ui/refresh_on_resume.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// How the last round of the background check went.
final backgroundStatusProvider = FutureProvider.autoDispose<BackgroundStatus?>(
    (ref) => readBackgroundStatus());

/// Whether the system lets the app notify; null where that cannot be told.
final notificationPermissionProvider =
    FutureProvider.autoDispose<bool?>((ref) => areSystemNotificationsAllowed());

/// Starts a round of the check; a provider so tests can stand in for it.
final checkBackgroundNowProvider = Provider<Future<void> Function()>(
  (ref) => () => runBackgroundCheckNow(),
);

/// What the last background check found, per account, and whether the system
/// lets the app notify at all (#319). Meant to be read off a screenshot when
/// a notification stays out.
class BackgroundStatusCard extends ConsumerStatefulWidget {
  const BackgroundStatusCard({super.key, bool? isAndroid})
      : _isAndroid = isAndroid;

  final bool? _isAndroid;

  @override
  ConsumerState<BackgroundStatusCard> createState() =>
      _BackgroundStatusCardState();
}

class _BackgroundStatusCardState extends ConsumerState<BackgroundStatusCard>
    with WidgetsBindingObserver, RefreshOnResume {
  @override
  List<ProviderOrFamily> get refreshOnResume =>
      [backgroundStatusProvider, notificationPermissionProvider];

  @override
  Widget build(BuildContext context) {
    final notifications =
        ref.watch(settingsProvider.select((s) => s.notificationsEnabled));
    if (!(widget._isAndroid ?? Platform.isAndroid) || !notifications) {
      return const SizedBox.shrink();
    }
    final l = tr(context);
    final status = ref.watch(backgroundStatusProvider).valueOrNull;
    final permission = ref.watch(notificationPermissionProvider).valueOrNull;
    final text = Theme.of(context).textTheme;
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Semantics(
              header: true,
              child: Text(l.statusTitle, style: text.titleSmall),
            ),
            const SizedBox(height: 8),
            if (status == null)
              Text(l.statusNoRun)
            else ...[
              Text(l.statusLastRun(_time(context, status.finishedAt))),
              if (status.accounts.isEmpty)
                Text(l.statusNoAccounts)
              else
                for (final account in status.accounts)
                  Text(_describe(l, account)),
            ],
            if (permission != null)
              Text(
                permission
                    ? l.statusPermissionGranted
                    : l.statusPermissionDenied,
              ),
            const SizedBox(height: 8),
            Text(l.statusCheckNowHint, style: text.bodySmall),
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton(
                onPressed: () => ref.read(checkBackgroundNowProvider)(),
                child: Text(l.statusCheckNow),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _time(BuildContext context, DateTime time) {
    final dates = MaterialLocalizations.of(context);
    return '${dates.formatShortDate(time)} '
        '${dates.formatTimeOfDay(TimeOfDay.fromDateTime(time), alwaysUse24HourFormat: true)}';
  }

  String _describe(L l, AccountCheckResult a) => switch (a.outcome) {
        AccountCheckOutcome.ok =>
          l.statusAccountOk(a.label, a.unread ?? 0, a.fresh ?? 0),
        AccountCheckOutcome.unreachable => l.statusAccountUnreachable(a.label),
        AccountCheckOutcome.skippedAppSignedIn =>
          l.statusAccountSkipped(a.label),
        AccountCheckOutcome.firstRun =>
          l.statusAccountFirstRun(a.label, a.unread ?? 0),
      };
}
