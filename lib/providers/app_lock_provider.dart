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
import 'dart:io';

import 'package:dr/debug_log.dart';
import 'package:dr/providers/settings_provider.dart';
import 'package:dr/services/device_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// The app lock (#114): with it on, the app shows nothing until the device's
// own lock was passed — at a cold start, and when it comes back after
// longer in the background than the settings allow.

/// What the lock screen has to tell besides "locked".
enum AppLockMessage { lockedOut, error, disabled }

@immutable
class AppLockState {
  const AppLockState({
    required this.locked,
    this.authenticating = false,
    this.covered = false,
    this.message,
  });

  final bool locked;

  /// The app is on its way out and its preview is to show nothing: where
  /// Android cannot hide it by itself.
  final bool covered;

  /// The device's prompt is open.
  final bool authenticating;
  final AppLockMessage? message;

  AppLockState copyWith({
    bool? locked,
    bool? authenticating,
    bool? covered,
    AppLockMessage? Function()? message,
  }) =>
      AppLockState(
        locked: locked ?? this.locked,
        authenticating: authenticating ?? this.authenticating,
        covered: covered ?? this.covered,
        message: message == null ? this.message : message(),
      );
}

/// Whether the lock was on when the app last stored its settings. Overridden
/// in `main()` before `runApp`: the settings load later, and the first frame
/// must already be covered.
final appLockInitiallyEnabledProvider = Provider<bool>((ref) => false);

final appLockClockProvider =
    Provider<DateTime Function()>((ref) => DateTime.now);

/// Whether this platform has a device lock to ask for.
final appLockSupportedProvider =
    Provider<bool>((ref) => Platform.isAndroid || Platform.isIOS);

/// Whether Android hides the app's preview in the recent apps itself
/// (Android 13 on); set by `keepRecentsInSync`.
final recentsHiddenByAndroidProvider = StateProvider<bool>((ref) => false);

final appLockProvider =
    NotifierProvider<AppLockController, AppLockState>(AppLockController.new);

class AppLockController extends Notifier<AppLockState> {
  /// Shown in the device's prompt; set by the lock screen, which knows the
  /// language.
  String unlockReason = '';

  bool _initiallyEnabled = false;
  bool _askedAtStart = false;
  DateTime? _pausedAt;

  @override
  AppLockState build() {
    _initiallyEnabled = ref.read(appLockInitiallyEnabledProvider);
    ref.listen(
      settingsProvider.select((s) => s.appLockEnabled),
      (previous, enabled) {
        if (enabled) return;
        _initiallyEnabled = false;
        _pausedAt = null;
        state = state.copyWith(locked: false);
      },
    );
    return AppLockState(locked: _enabled);
  }

  /// The stored value counts until the settings are loaded and say
  /// otherwise.
  bool get _enabled =>
      ref.read(appLockSupportedProvider) &&
      (_initiallyEnabled || ref.read(settingsProvider).appLockEnabled);

  Duration get _grace =>
      Duration(minutes: ref.read(settingsProvider).appLockGraceMinutes);

  DateTime _now() => ref.read(appLockClockProvider)();

  /// The app is about to leave, or something covers it: hides it from the
  /// preview in the recent apps where Android does not.
  void onInactive() {
    if (state.authenticating || !_enabled) return;
    if (ref.read(recentsHiddenByAndroidProvider)) return;
    state = state.copyWith(covered: true);
  }

  /// The app went to the background. The device's own prompt sends it there
  /// as well; that does not count.
  void onPaused() {
    if (state.authenticating || !_enabled) return;
    _pausedAt = _now();
    if (_grace == Duration.zero && !state.locked) {
      state = state.copyWith(locked: true, message: () => null);
    }
  }

  /// The app is back. Locks when it was away for longer than allowed, and
  /// asks right away.
  void onResumed() {
    if (state.covered) state = state.copyWith(covered: false);
    if (state.authenticating) return;
    final pausedAt = _pausedAt;
    _pausedAt = null;
    if (pausedAt == null || !_enabled) return;
    if (!state.locked && _now().difference(pausedAt) >= _grace) {
      debugLog(LogCategory.appLock, 'gesperrt');
      state = state.copyWith(locked: true, message: () => null);
    }
    if (state.locked) unawaited(unlock(unlockReason));
  }

  /// Asks for the device's lock without touching the lock itself — for
  /// switching it on or off. True when it was passed.
  Future<bool> confirm(String reason) async {
    if (state.authenticating) return false;
    state = state.copyWith(authenticating: true);
    final result = await ref.read(deviceAuthProvider).authenticate(reason);
    state = state.copyWith(authenticating: false);
    return result == DeviceAuthResult.success;
  }

  /// Asks for the device's lock once, when the app starts locked.
  Future<void> unlockAtStart() async {
    if (_askedAtStart || !state.locked) return;
    _askedAtStart = true;
    await unlock(unlockReason);
  }

  /// Asks for the device's lock.
  Future<void> unlock(String reason) async {
    if (state.authenticating) return;
    state = state.copyWith(authenticating: true, message: () => null);
    final result = await ref.read(deviceAuthProvider).authenticate(reason);
    debugLog(LogCategory.appLock, result.name);
    switch (result) {
      case DeviceAuthResult.success:
        state = const AppLockState(locked: false);
      case DeviceAuthResult.cancelled:
        state = state.copyWith(authenticating: false);
      case DeviceAuthResult.lockedOut:
        state = state.copyWith(
          authenticating: false,
          message: () => AppLockMessage.lockedOut,
        );
      case DeviceAuthResult.error:
        state = state.copyWith(
          authenticating: false,
          message: () => AppLockMessage.error,
        );
      case DeviceAuthResult.notAvailable:
        // The device's lock was removed: locked for good otherwise.
        ref.read(settingsProvider.notifier).setAppLockEnabled(false);
        state = const AppLockState(
          locked: false,
          message: AppLockMessage.disabled,
        );
    }
  }
}
