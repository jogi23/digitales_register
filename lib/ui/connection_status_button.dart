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
import 'package:dr/ui/snack_bar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

/// Says whether the app is talking to the server, on every page that has a
/// title bar — as a cloud whose shape and colour follow the state.
///
/// No words in the bar, whatever the state. A working connection should not
/// shout, and a lost one is announced once by a short message
/// ([showNoConnectionToast]) while the crossed-out cloud stays. The words are
/// in the tooltip and in the dialog a tap opens, which also offers the way
/// back: reloading, or a new login when the session is what ran out.
class ConnectionStatusButton extends ConsumerStatefulWidget {
  const ConnectionStatusButton({super.key});

  @override
  ConsumerState<ConnectionStatusButton> createState() =>
      _ConnectionStatusButtonState();
}

class _ConnectionStatusButtonState
    extends ConsumerState<ConnectionStatusButton> {
  /// Redraws once a minute, so fresh data turns stale on its own instead of
  /// waiting for the page to be rebuilt for some other reason.
  late final Timer _ticker;

  @override
  void initState() {
    super.initState();
    _ticker = Timer.periodic(const Duration(minutes: 1), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _ticker.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final look = _lookOf(context, ref.watch(connectionProvider));
    return IconButton(
      onPressed: () => unawaited(_showDetails()),
      tooltip: look.label,
      icon: Icon(look.icon, color: look.color),
    );
  }

  Future<void> _showDetails() async {
    final reconnect = await showDialog<bool>(
      context: context,
      builder: (context) => const _ConnectionDialog(),
    );
    if (reconnect != true || !mounted) return;
    await ref.read(connectionProvider.notifier).reconnect();
    if (!mounted) return;
    // Still nothing to reach: say so, the same way going offline does.
    if (ref.read(connectionProvider).status == ConnectionStatus.offline) {
      showNoConnectionToast();
    }
  }
}

/// One state as the reader sees it: the cloud, its colour, and in words.
typedef _Look = ({IconData icon, Color color, String label});

_Look _lookOf(BuildContext context, ConnectionInfo connection) {
  final scheme = Theme.of(context).colorScheme;
  final l = tr(context);
  if (connection.reconnecting) {
    return (
      icon: Icons.cloud_sync,
      color: scheme.primary,
      label: l.connectionReconnecting,
    );
  }
  return switch (connection.status) {
    ConnectionStatus.offline => (
        icon: Icons.cloud_off,
        color: scheme.error,
        label: l.noConnection,
      ),
    ConnectionStatus.sessionExpired => (
        icon: Icons.cloud,
        color: scheme.error,
        label: l.connectionSessionExpired,
      ),
    // Hollow while nothing has come back yet: the data on screen is then
    // from the last run, and the bar should not claim otherwise.
    ConnectionStatus.connected when connection.neverLoaded => (
        icon: Icons.cloud_queue,
        color: scheme.outline,
        label: l.connectionNeverUpdated,
      ),
    ConnectionStatus.connected when connection.isStale => (
        icon: Icons.cloud_download,
        color: scheme.tertiary,
        label: l.connectionOutdated,
      ),
    ConnectionStatus.connected => (
        icon: Icons.cloud_done,
        color: scheme.primary,
        label: l.connectionConnected,
      ),
  };
}

/// The time of the last answer, for the dialog.
///
/// [UtcDateTime] already holds the local wall-clock time; `toLocal()` would
/// add the zone offset a second time.
String _lastUpdateLabel(BuildContext context, ConnectionInfo connection) {
  final last = connection.lastSuccess;
  if (last == null) return tr(context).connectionNeverUpdated;
  return tr(context).connectionLastUpdate(
    DateFormat.Hm(tr(context).localeName).format(last),
  );
}

/// What is known about the connection, and the one thing that can be done
/// about it.
class _ConnectionDialog extends ConsumerWidget {
  const _ConnectionDialog();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final connection = ref.watch(connectionProvider);
    final look = _lookOf(context, connection);
    final hint = switch (connection.status) {
      ConnectionStatus.connected => null,
      ConnectionStatus.offline => tr(context).connectionOfflineHint,
      ConnectionStatus.sessionExpired =>
        tr(context).connectionSessionExpiredHint,
    };
    return AlertDialog(
      icon: Icon(look.icon, color: look.color),
      title: Text(tr(context).connectionTitle),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(look.label, style: Theme.of(context).textTheme.titleMedium),
          // Only when there is one — otherwise it repeats the line above.
          if (!connection.neverLoaded) ...<Widget>[
            const SizedBox(height: 8),
            Text(_lastUpdateLabel(context, connection)),
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
