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
import 'package:dr/providers/app_lock_provider.dart';
import 'package:dr/services/app_lock_platform.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// The lock screen of the app lock (#114). It lies over the whole app rather
// than being a page of its own: the pages underneath keep their state, and
// whatever a notification opens waits there until the app is unlocked.

/// Puts the lock screen over [child] — the whole app — while it is locked,
/// and a plain cover while it is leaving.
class AppLockScope extends ConsumerWidget {
  const AppLockScope({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final (locked, covered) =
        ref.watch(appLockProvider.select((s) => (s.locked, s.covered)));
    return Stack(
      children: [
        // Built on, so nothing is lost; but neither read out nor tappable.
        ExcludeSemantics(excluding: locked || covered, child: child),
        if (locked)
          const Positioned.fill(child: AppLockOverlay())
        else if (covered)
          Positioned.fill(
            child: ColoredBox(color: Theme.of(context).colorScheme.surface),
          ),
      ],
    );
  }
}

class AppLockOverlay extends ConsumerStatefulWidget {
  const AppLockOverlay({super.key});

  @override
  ConsumerState<AppLockOverlay> createState() => _AppLockOverlayState();
}

class _AppLockOverlayState extends ConsumerState<AppLockOverlay> {
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    ref.read(appLockProvider.notifier).unlockReason = tr(context).appLockReason;
  }

  @override
  void initState() {
    super.initState();
    // After returning from the background the controller asks by itself;
    // this is for the cold start.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      unawaited(ref.read(appLockProvider.notifier).unlockAtStart());
    });
  }

  @override
  Widget build(BuildContext context) {
    final lock = ref.watch(appLockProvider);
    final l = tr(context);
    final theme = Theme.of(context);
    final message = switch (lock.message) {
      AppLockMessage.lockedOut => l.appLockLockedOut,
      AppLockMessage.error => l.appLockError,
      AppLockMessage.disabled => l.appLockDisabled,
      null => null,
    };
    return ColoredBox(
      color: theme.colorScheme.surface,
      child: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Image(
                  image: AssetImage('assets/icon_foreground.png'),
                  width: 120,
                  height: 120,
                ),
                Semantics(
                  liveRegion: true,
                  child:
                      Text(l.appLockTitle, style: theme.textTheme.titleLarge),
                ),
                if (message != null) ...[
                  const SizedBox(height: 12),
                  Text(message, textAlign: TextAlign.center),
                ],
                const SizedBox(height: 24),
                FilledButton.icon(
                  style: FilledButton.styleFrom(
                    minimumSize: const Size(160, 48),
                  ),
                  onPressed: lock.authenticating
                      ? null
                      : () => unawaited(
                            ref
                                .read(appLockProvider.notifier)
                                .unlock(l.appLockReason),
                          ),
                  icon: const Icon(Icons.lock_open),
                  label: Text(l.appLockUnlock),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Lets "back" leave the app while it is locked, instead of closing the
/// pages under the lock screen. Register before `runApp`: the binding asks
/// its observers in order, and the app's own one pops pages.
WidgetsBindingObserver installAppLockBackHandler(
  ProviderContainer container, {
  bool? isAndroid,
}) {
  final observer = _AppLockBackObserver(container, isAndroid);
  WidgetsBinding.instance.addObserver(observer);
  return observer;
}

class _AppLockBackObserver with WidgetsBindingObserver {
  _AppLockBackObserver(this.container, this.isAndroid);

  final ProviderContainer container;
  final bool? isAndroid;

  @override
  Future<bool> didPopRoute() async {
    if (!container.read(appLockProvider).locked) return false;
    await moveTaskToBack(isAndroid: isAndroid);
    return true;
  }
}
