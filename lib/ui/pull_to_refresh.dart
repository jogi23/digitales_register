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

import 'package:dr/providers/connection_provider.dart';
import 'package:dr/ui/snack_bar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Pull down from the top to load the page again — the same gesture on every
/// screen that shows server data.
///
/// A bare [RefreshIndicator] failed in three ways, all handled here:
/// - It only hears a scroll view at the very top of its subtree. Pages that
///   fill the height — a spinner, "no connection", the calendar grid — never
///   reported a pull. The child therefore sits in a scroll view of exactly its
///   own height, which always reports one, and vertical pulls from scroll
///   views further down count too.
/// - Its spinner has to wait for the reload. Handing back at once made it
///   vanish before anything had happened, so the pull looked ignored.
/// - Without a connection a reload goes nowhere. The connection is restored
///   first; if that fails, the page is left as it is and a short message
///   says why.
class PullToRefresh extends ConsumerWidget {
  /// Loads the page's data. The spinner stays until this completes.
  final Future<void> Function() onRefresh;
  final Widget child;

  const PullToRefresh({
    super.key,
    required this.onRefresh,
    required this.child,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return RefreshIndicator(
      onRefresh: () => _refresh(ref),
      notificationPredicate: _isVertical,
      child: LayoutBuilder(
        builder: (context, constraints) {
          if (!constraints.hasBoundedHeight) return child;
          return SingleChildScrollView(
            // The page's own list keeps the primary controller, so tapping
            // the status bar still scrolls that list to the top.
            primary: false,
            physics: const AlwaysScrollableScrollPhysics(),
            child: SizedBox(height: constraints.maxHeight, child: child),
          );
        },
      ),
    );
  }

  Future<void> _refresh(WidgetRef ref) async {
    if (ref.read(connectionProvider).hasProblem) {
      await ref.read(connectionProvider.notifier).reconnect();
      final status = ref.read(connectionProvider).status;
      // Still nothing to reach: say so briefly, the way going offline does.
      if (status == ConnectionStatus.offline) showNoConnectionToast();
      if (status != ConnectionStatus.connected) return;
    }
    await onRefresh();
  }

  /// Any vertical scroll view counts, however deep: the page's list sits
  /// below the scroll view added here. Sideways ones — the week pages — do
  /// not.
  static bool _isVertical(ScrollNotification notification) =>
      notification.metrics.axis == Axis.vertical;
}
