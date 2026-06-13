// Copyright (C) 2026 Johannes Feichter
import 'package:dr/providers/login_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

ProviderContainer _makeContainer() {
  final c = ProviderContainer();
  addTearDown(c.dispose);
  return c;
}

void main() {
  group('LoginNotifier — state transitions', () {
    test('initial state is empty / not logged in', () {
      final c = _makeContainer();
      final s = c.read(loginProvider);
      expect(s.loggedIn, false);
      expect(s.loading, false);
      expect(s.errorMsg, null);
      expect(s.username, null);
      expect(s.url, null);
    });

    test('setLoggingIn sets loading and clears errorMsg', () {
      final c = _makeContainer();
      c.read(loginProvider.notifier).setLoginFailed(cause: 'bad pw');
      c.read(loginProvider.notifier).setLoggingIn();
      final s = c.read(loginProvider);
      expect(s.loading, true);
      expect(s.errorMsg, null);
      expect(s.loggedIn, false);
    });

    test('setLoggedIn marks logged in and clears error', () {
      final c = _makeContainer();
      c.read(loginProvider.notifier).setLoginFailed(cause: 'err');
      c.read(loginProvider.notifier).setLoggedIn(username: 'alice');
      final s = c.read(loginProvider);
      expect(s.loggedIn, true);
      expect(s.loading, false);
      expect(s.username, 'alice');
      expect(s.errorMsg, null);
    });

    test('setLoggedIn with keepLoading keeps loading flag', () {
      final c = _makeContainer();
      c.read(loginProvider.notifier).setLoggedIn(username: 'alice', keepLoading: true);
      expect(c.read(loginProvider).loading, true);
    });

    test('setLoginFailed clears loggedIn and sets errorMsg', () {
      final c = _makeContainer();
      c.read(loginProvider.notifier).setLoggedIn(username: 'alice');
      c.read(loginProvider.notifier).setLoginFailed(cause: 'wrong password', username: 'alice');
      final s = c.read(loginProvider);
      expect(s.loggedIn, false);
      expect(s.loading, false);
      expect(s.errorMsg, 'wrong password');
      expect(s.username, 'alice');
    });

    test('reset restores initial state', () {
      final c = _makeContainer();
      c.read(loginProvider.notifier).setLoggedIn(username: 'alice');
      c.read(loginProvider.notifier).setUrl('https://example.com');
      c.read(loginProvider.notifier).reset();
      final s = c.read(loginProvider);
      expect(s.loggedIn, false);
      expect(s.username, null);
      expect(s.url, null);
    });

    test('setChangePassword sets changePassword and clears loading', () {
      final c = _makeContainer();
      c.read(loginProvider.notifier).setLoggingIn();
      c.read(loginProvider.notifier).setChangePassword(mustChange: true);
      final s = c.read(loginProvider);
      expect(s.changePassword, true);
      expect(s.mustChangePassword, true);
      expect(s.loading, false);
    });

    test('showLogin clears changePassword', () {
      final c = _makeContainer();
      c.read(loginProvider.notifier).setChangePassword(mustChange: false);
      c.read(loginProvider.notifier).showLogin();
      expect(c.read(loginProvider).changePassword, false);
    });
  });

  group('LoginNotifier — logout', () {
    test('hard logout clears loggedIn, username, url', () {
      final c = _makeContainer();
      c.read(loginProvider.notifier).setLoggedIn(username: 'alice');
      c.read(loginProvider.notifier).setUrl('https://example.com');
      c.read(loginProvider.notifier).logout(hard: true);
      final s = c.read(loginProvider);
      expect(s.loggedIn, false);
      expect(s.username, null);
      expect(s.url, null);
    });

    test('soft logout leaves state unchanged', () {
      final c = _makeContainer();
      c.read(loginProvider.notifier).setLoggedIn(username: 'alice');
      c.read(loginProvider.notifier).setUrl('https://example.com');
      c.read(loginProvider.notifier).logout(hard: false);
      final s = c.read(loginProvider);
      expect(s.loggedIn, true);
      expect(s.username, 'alice');
      expect(s.url, 'https://example.com');
    });

    test('hard logout preserves otherAccounts', () {
      final c = _makeContainer();
      c.read(loginProvider.notifier).setLoggedIn(username: 'alice');
      c.read(loginProvider.notifier).setOtherAccounts([
        OtherAccount(username: 'bob', url: 'https://example.com'),
        OtherAccount(username: 'carol', url: 'https://example.com'),
      ]);
      c.read(loginProvider.notifier).logout(hard: true);
      final accounts = c.read(loginProvider).otherAccounts;
      expect(accounts.map((a) => a.username).toList(), ['bob', 'carol']);
    });
  });

  group('LoginNotifier — callAfterLogin', () {
    test('executeAfterLoginCallbacks calls all registered callbacks', () {
      final c = _makeContainer();
      final log = <int>[];
      c.read(loginProvider.notifier).addAfterLoginCallback(() => log.add(1));
      c.read(loginProvider.notifier).addAfterLoginCallback(() => log.add(2));
      c.read(loginProvider.notifier).addAfterLoginCallback(() => log.add(3));
      c.read(loginProvider.notifier).executeAfterLoginCallbacks();
      expect(log, [1, 2, 3]);
    });

    test('executeAfterLoginCallbacks clears list after execution', () {
      final c = _makeContainer();
      int calls = 0;
      c.read(loginProvider.notifier).addAfterLoginCallback(() => calls++);
      c.read(loginProvider.notifier).executeAfterLoginCallbacks();
      c.read(loginProvider.notifier).executeAfterLoginCallbacks();
      expect(calls, 1);
    });

    test('clearAfterLoginCallbacks prevents execution', () {
      final c = _makeContainer();
      int calls = 0;
      c.read(loginProvider.notifier).addAfterLoginCallback(() => calls++);
      c.read(loginProvider.notifier).clearAfterLoginCallbacks();
      c.read(loginProvider.notifier).executeAfterLoginCallbacks();
      expect(calls, 0);
    });

    test('callback added during execute is not called in same execution', () {
      // executeAfterLoginCallbacks uses List.of() snapshot — late additions skip.
      // The trailing _callAfterLogin.clear() also removes them, so they are lost.
      final c = _makeContainer();
      final log = <String>[];
      c.read(loginProvider.notifier).addAfterLoginCallback(() {
        log.add('first');
        c.read(loginProvider.notifier).addAfterLoginCallback(() => log.add('added-during'));
      });
      c.read(loginProvider.notifier).executeAfterLoginCallbacks();
      expect(log, ['first']);
      // second execute: list was cleared (including the callback added during execute)
      c.read(loginProvider.notifier).executeAfterLoginCallbacks();
      expect(log, ['first']);
    });
  });
}
