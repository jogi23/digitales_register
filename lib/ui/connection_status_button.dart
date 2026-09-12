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

import 'package:dr/l10n/l10n.dart';
import 'package:dr/providers/connection_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

/// Says whether the app is talking to the server, on every page that has a
/// title bar.
///
/// Three steps, because that is what the reader needs to tell apart: all is
/// well, what is shown is getting old, and something is in the way. Only the
/// last one is loud — a working connection should not shout.
///
/// Tapping opens the way back: reloading, or a new login when the session is
/// what ran out.
class ConnectionStatusButton extends ConsumerWidget {
  const ConnectionStatusButton({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final connection = ref.watch(connectionProvider);
    final scheme = Theme.of(context).colorScheme;

    if (connection.hasProblem) {
      final label = connection.status == ConnectionStatus.offline
          ? tr(context).noConnection
          : tr(context).connectionSessionExpired;
      return TextButton.icon(
        onPressed: () => unawaited(_showDetails(context, ref)),
        style: TextButton.styleFrom(foregroundColor: scheme.error),
        icon: Icon(
          connection.status == ConnectionStatus.offline
              ? Icons.cloud_off
              : Icons.lock_clock,
          size: 20,
        ),
        label: Text(label),
      );
    }

    if (connection.isStale) {
      return TextButton(
        onPressed: () => unawaited(_showDetails(context, ref)),
        style: TextButton.styleFrom(foregroundColor: scheme.onSurfaceVariant),
        child: Text(_lastUpdateLabel(context, connection)),
      );
    }

    // Nothing is wrong, so this stays a hint rather than a message. Hollow
    // while the server has not answered yet: the data on screen then comes
    // from the last run, and the app bar should not claim otherwise.
    return IconButton(
      onPressed: () => unawaited(_showDetails(context, ref)),
      tooltip: connection.neverLoaded
          ? tr(context).connectionNeverUpdated
          : tr(context).connectionConnected,
      icon: Icon(
        connection.neverLoaded ? Icons.circle_outlined : Icons.circle,
        size: 10,
        color: connection.neverLoaded ? scheme.outline : scheme.primary,
      ),
    );
  }

  /// The time of the last answer, or that there was none yet.
  static String _lastUpdateLabel(
    BuildContext context,
    ConnectionInfo connection,
  ) {
    final last = connection.lastSuccess;
    if (last == null) return tr(context).connectionNeverUpdated;
    return tr(context).connectionLastUpdate(
      DateFormat.Hm(tr(context).localeName).format(last.toLocal()),
    );
  }

  Future<void> _showDetails(BuildContext context, WidgetRef ref) async {
    final reconnect = await showDialog<bool>(
      context: context,
      builder: (context) => const _ConnectionDialog(),
    );
    if (reconnect != true) return;
    await ref.read(connectionProvider.notifier).reconnect();
  }
}

/// What is known about the connection, and the one thing that can be done
/// about it.
class _ConnectionDialog extends ConsumerWidget {
  const _ConnectionDialog();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final connection = ref.watch(connectionProvider);
    final state = switch (connection.status) {
      ConnectionStatus.connected => connection.neverLoaded
          ? tr(context).connectionNeverUpdated
          : connection.isStale
              ? tr(context).connectionOutdated
              : tr(context).connectionConnected,
      ConnectionStatus.offline => tr(context).noConnection,
      ConnectionStatus.sessionExpired => tr(context).connectionSessionExpired,
    };
    final hint = switch (connection.status) {
      ConnectionStatus.connected => null,
      ConnectionStatus.offline => tr(context).connectionOfflineHint,
      ConnectionStatus.sessionExpired =>
        tr(context).connectionSessionExpiredHint,
    };
    return AlertDialog(
      title: Text(tr(context).connectionTitle),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(state, style: Theme.of(context).textTheme.titleMedium),
          // Only when there is one — otherwise it repeats the line above.
          if (!connection.neverLoaded) ...<Widget>[
            const SizedBox(height: 8),
            Text(ConnectionStatusButton._lastUpdateLabel(context, connection)),
          ],
          if (hint != null) ...<Widget>[
            const SizedBox(height: 8),
            Text(hint),
          ],
        ],
      ),
      actions: <Widget>[
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: Text(tr(context).commonClose),
        ),
        FilledButton(
          onPressed: connection.reconnecting
              ? null
              : () => Navigator.of(context).pop(true),
          child: Text(
            connection.reconnecting
                ? tr(context).connectionReconnecting
                : connection.status == ConnectionStatus.sessionExpired
                    ? tr(context).connectionRelogin
                    : tr(context).connectionReconnect,
          ),
        ),
      ],
    );
  }
}
