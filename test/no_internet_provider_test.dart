// Copyright (C) 2026 Johannes Feichter
import 'package:dr/providers/dashboard_provider.dart';
import 'package:dr/providers/no_internet_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

// ─── Test doubles ─────────────────────────────────────────────────────────────

class _SpyNoInternetNotifier extends NoInternetNotifier {
  _SpyNoInternetNotifier({this.initialState = false});
  final bool initialState;

  int offlineCalls = 0;
  int onlineCalls = 0;

  @override
  bool build() => initialState;

  @override
  void onGoingOffline() => offlineCalls++;

  @override
  Future<void> onGoingOnline() async => onlineCalls++;
}

class _SpyDashboardNotifier extends DashboardNotifier {
  int refreshCalls = 0;

  @override
  Future<void> refresh() async => refreshCalls++;
}

// ─── Helpers ──────────────────────────────────────────────────────────────────

ProviderContainer _makeContainer({bool startOffline = false}) {
  final spy = _SpyNoInternetNotifier(initialState: startOffline);
  final dashSpy = _SpyDashboardNotifier();
  final c = ProviderContainer(overrides: [
    noInternetProvider.overrideWith(() => spy),
    dashboardProvider.overrideWith(() => dashSpy),
  ]);
  addTearDown(c.dispose);
  return c;
}

// ─── Tests ────────────────────────────────────────────────────────────────────

void main() {
  group('NoInternetNotifier — state transitions', () {
    test('initial state is false (online)', () {
      final c = _makeContainer();
      expect(c.read(noInternetProvider), false);
    });

    test('setNoInternet(true) sets state to true', () {
      final c = _makeContainer();
      c.read(noInternetProvider.notifier).setNoInternet(true);
      expect(c.read(noInternetProvider), true);
    });

    test('setNoInternet(false) after offline sets state to false', () {
      final c = _makeContainer(startOffline: true);
      c.read(noInternetProvider.notifier).setNoInternet(false);
      expect(c.read(noInternetProvider), false);
    });

    test('no-op when value unchanged (true→true)', () {
      final c = _makeContainer(startOffline: true);
      final notifier = c.read(noInternetProvider.notifier) as _SpyNoInternetNotifier;
      c.read(noInternetProvider.notifier).setNoInternet(true);
      expect(notifier.offlineCalls, 0);
      expect(notifier.onlineCalls, 0);
    });

    test('no-op when value unchanged (false→false)', () {
      final c = _makeContainer();
      final notifier = c.read(noInternetProvider.notifier) as _SpyNoInternetNotifier;
      c.read(noInternetProvider.notifier).setNoInternet(false);
      expect(notifier.offlineCalls, 0);
      expect(notifier.onlineCalls, 0);
    });
  });

  group('NoInternetNotifier — side effects', () {
    test('going offline triggers onGoingOffline once', () {
      final c = _makeContainer();
      final notifier = c.read(noInternetProvider.notifier) as _SpyNoInternetNotifier;
      c.read(noInternetProvider.notifier).setNoInternet(true);
      expect(notifier.offlineCalls, 1);
      expect(notifier.onlineCalls, 0);
    });

    test('going online (after offline) triggers onGoingOnline once', () {
      final c = _makeContainer(startOffline: true);
      final notifier = c.read(noInternetProvider.notifier) as _SpyNoInternetNotifier;
      c.read(noInternetProvider.notifier).setNoInternet(false);
      expect(notifier.onlineCalls, 1);
      expect(notifier.offlineCalls, 0);
    });

    test('internet restored: dashboard refresh is triggered', () async {
      // _OnlineOnlySpyNotifier suppresses onGoingOffline but runs the real
      // onGoingOnline, so we can verify dashboard.refresh() is called.
      final container = ProviderContainer(overrides: [
        dashboardProvider.overrideWith(() => _SpyDashboardNotifier()),
        noInternetProvider.overrideWith(() => _OnlineOnlySpyNotifier()),
      ]);
      addTearDown(container.dispose);
      final dashSpy =
          container.read(dashboardProvider.notifier) as _SpyDashboardNotifier;
      container.read(noInternetProvider.notifier).setNoInternet(false);
      await Future<void>.delayed(Duration.zero);
      expect(dashSpy.refreshCalls, 1);
    });
  });
}

/// Starts in offline state; suppresses onGoingOffline side effects so
/// onGoingOnline (real dashboard refresh) can be tested in isolation.
class _OnlineOnlySpyNotifier extends NoInternetNotifier {
  @override
  bool build() => true;

  @override
  void onGoingOffline() {}
}
