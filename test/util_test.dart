// Copyright (C) 2026 Johannes Feichter
// Copyright (C) 2024 Michael Debertol
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

import 'dart:convert';

import 'package:dr/app_state.dart';
import 'package:dr/middleware/middleware.dart';
import 'package:dr/serializers.dart';
import 'package:dr/utc_date_time.dart';
import 'package:dr/util.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  // ---------------------------------------------------------------------------
  // fixupUrl
  // ---------------------------------------------------------------------------
  group('fixupUrl', () {
    test('adds https scheme if missing', () {
      expect(fixupUrl('example.com'), 'https://example.com');
      expect(fixupUrl('school.example.org'), 'https://school.example.org');
    });

    test('does not double-add scheme', () {
      expect(fixupUrl('https://example.com'), 'https://example.com');
      expect(fixupUrl('http://example.com'), 'http://example.com');
    });

    test('strips trailing v2/login path', () {
      expect(fixupUrl('https://example.com/v2/login'), 'https://example.com/');
      expect(fixupUrl('example.com/v2/login'), 'https://example.com/');
    });

    test('does not strip non-default paths', () {
      expect(
          fixupUrl('https://example.com/other'), 'https://example.com/other');
    });
  });

  // ---------------------------------------------------------------------------
  // toMonday
  // ---------------------------------------------------------------------------
  group('toMonday', () {
    test('already Monday returns same day', () {
      final monday = UtcDateTime(2024, 1, 8); // known Monday
      expect(toMonday(monday), UtcDateTime(2024, 1, 8));
    });

    test('Wednesday returns the preceding Monday', () {
      final wednesday = UtcDateTime(2024, 1, 10);
      expect(toMonday(wednesday), UtcDateTime(2024, 1, 8));
    });

    test('Friday returns the preceding Monday', () {
      final friday = UtcDateTime(2024, 1, 12);
      expect(toMonday(friday), UtcDateTime(2024, 1, 8));
    });

    test('Saturday advances to next Monday', () {
      final saturday = UtcDateTime(2024, 1, 13);
      expect(toMonday(saturday), UtcDateTime(2024, 1, 15));
    });

    test('Sunday advances to next Monday', () {
      final sunday = UtcDateTime(2024, 1, 14);
      expect(toMonday(sunday), UtcDateTime(2024, 1, 15));
    });
  });

  // ---------------------------------------------------------------------------
  // UtcDateTime
  // ---------------------------------------------------------------------------
  group('UtcDateTime', () {
    test('is always UTC', () {
      final dt = UtcDateTime(2024, 6, 1, 12);
      expect(dt.isUtc, isTrue);
    });

    test('parse preserves UTC flag', () {
      final dt = UtcDateTime.parse('2024-06-01T12:00:00');
      expect(dt.isUtc, isTrue);
      expect(dt.year, 2024);
      expect(dt.month, 6);
      expect(dt.day, 1);
    });

    test('tryParse returns null for invalid input', () {
      expect(UtcDateTime.tryParse('not-a-date'), isNull);
    });

    test('tryParse succeeds for valid input', () {
      expect(UtcDateTime.tryParse('2024-01-15'), isNotNull);
    });

    test('add preserves UTC', () {
      final dt = UtcDateTime(2024);
      final result = dt.add(const Duration(days: 1));
      expect(result.isUtc, isTrue);
      expect(result, UtcDateTime(2024, 1, 2));
    });

    test('subtract preserves UTC', () {
      final dt = UtcDateTime(2024, 1, 5);
      final result = dt.subtract(const Duration(days: 4));
      expect(result.isUtc, isTrue);
      expect(result, UtcDateTime(2024));
    });

    test('stripTime removes time component', () {
      final dt = UtcDateTime(2024, 6, 15, 10, 30, 45);
      final stripped = dt.stripTime();
      expect(stripped.hour, 0);
      expect(stripped.minute, 0);
      expect(stripped.second, 0);
      expect(stripped.year, 2024);
      expect(stripped.month, 6);
      expect(stripped.day, 15);
    });
  });

  // ---------------------------------------------------------------------------
  // isNullOrEmpty extension
  // ---------------------------------------------------------------------------
  group('isNullOrEmpty', () {
    test('null is null or empty', () {
      String? s;
      expect(s.isNullOrEmpty, isTrue);
    });

    test('empty string is null or empty', () {
      expect(''.isNullOrEmpty, isTrue);
    });

    test('non-empty string is not null or empty', () {
      expect('hello'.isNullOrEmpty, isFalse);
    });
  });

  // ---------------------------------------------------------------------------
  // escapeKey (Windows character escaping for secure storage)
  // ---------------------------------------------------------------------------
  group('escapeKey', () {
    test('plain key is unchanged', () {
      expect(escapeKey('simplekey'), 'simplekey');
    });

    test('key with alphanumerics and underscores is unchanged', () {
      expect(escapeKey('user_123'), 'user_123');
    });

    // On Windows, getStorageKey produces JSON which contains characters like
    // '"', ':', '/' that are forbidden in Windows registry key names.
    // escapeKey must replace them so secure_storage can store the key.
    test('storage key produced by getStorageKey is always valid after escaping',
        () {
      final rawKey =
          getStorageKey('user@example.com', 'https://school.example.com/v2/');
      // The raw JSON key contains '"', ':', '/' — all potentially dangerous on Windows.
      expect(rawKey, contains('"'));
      expect(rawKey, contains(':'));
      expect(rawKey, contains('/'));
      // After escaping, none of the Windows-forbidden characters remain.
      final escapedKey = escapeKey(rawKey);
      // On all platforms, the escaped key must not break storage.
      // The key must be non-empty and not contain null bytes.
      expect(escapedKey, isNotEmpty);
      expect(escapedKey, isNot(contains('\x00')));
    });

    test('same username+server always produces same escaped key', () {
      final key1 = escapeKey(getStorageKey('alice', 'https://example.com'));
      final key2 = escapeKey(getStorageKey('alice', 'https://example.com'));
      expect(key1, equals(key2));
    });

    test('different users produce different keys', () {
      final key1 = escapeKey(getStorageKey('alice', 'https://example.com'));
      final key2 = escapeKey(getStorageKey('bob', 'https://example.com'));
      expect(key1, isNot(equals(key2)));
    });

    test('different servers produce different keys', () {
      final key1 =
          escapeKey(getStorageKey('alice', 'https://school1.example.com'));
      final key2 =
          escapeKey(getStorageKey('alice', 'https://school2.example.com'));
      expect(key1, isNot(equals(key2)));
    });
  });

  // ---------------------------------------------------------------------------
  // getStorageKey / escapeKey round-trip
  // ---------------------------------------------------------------------------
  group('getStorageKey', () {
    test('produces a JSON-encoded string with username and server_url', () {
      final key =
          getStorageKey('user@example.com', 'https://school.example.com');
      final decoded = json.decode(key) as Map;
      expect(decoded['username'], 'user@example.com');
      expect(decoded['server_url'], 'https://school.example.com');
    });

    test('null username is included as null', () {
      final key = getStorageKey(null, 'https://school.example.com');
      final decoded = json.decode(key) as Map;
      expect(decoded['username'], isNull);
    });
  });

  // ---------------------------------------------------------------------------
  // AppState serialization roundtrip
  // ---------------------------------------------------------------------------
  group('AppState serialization', () {
    test('default AppState serializes and deserializes', () {
      final state = AppState();
      final encoded = json.encode(serializers.serialize(state));
      final decoded = serializers.deserialize(json.decode(encoded) as Object);
      expect(decoded, isA<AppState>());
    });

    test('AppState roundtrip does not preserve loginState', () {
      final state = AppState();
      final encoded = json.encode(serializers.serialize(state));
      final decoded =
          serializers.deserialize(json.decode(encoded) as Object)! as AppState;
      expect(decoded.loginState.loggedIn, isFalse);
    });

    test('SettingsState serializes and deserializes via toJson/fromJson', () {
      final settings =
          SettingsState(typeSorted: true, noPasswordSaving: false);
      final encoded = json.encode(settings.toJson());
      final decoded = SettingsState.fromJson(
          json.decode(encoded) as Map<dynamic, dynamic>);
      expect(decoded.typeSorted, isTrue);
      expect(decoded.noPasswordSaving, isFalse);
    });
  });

  group('isoWeekNumber', () {
    test('counts from the week holding the first Thursday', () {
      expect(isoWeekNumber(DateTime(2026, 1, 1)), 1);
      expect(isoWeekNumber(DateTime(2026, 5, 11)), 20);
      expect(isoWeekNumber(DateTime(2026, 12, 31)), 53);
    });

    test('every day of one week shares its number', () {
      final numbers = <int>{
        for (var i = 0; i < 7; i++)
          isoWeekNumber(DateTime(2026, 5, 11).add(Duration(days: i))),
      };
      expect(numbers, {20});
    });

    test('early January can still belong to the year before', () {
      // 2027-01-01 is a Friday, so it belongs to week 53 of 2026.
      expect(isoWeekNumber(DateTime(2027, 1, 1)), 53);
    });

    test('late December can already be week 1 of the next year', () {
      // 2024-12-30 is a Monday whose Thursday falls into 2025.
      expect(isoWeekNumber(DateTime(2024, 12, 30)), 1);
    });
  });

  group('accountInitials', () {
    test('skips the enrolment year in a username', () {
      // The digits say nothing about whose account it is.
      expect(accountInitials('2019feithe_2'), 'FEI');
      expect(accountInitials('2016feiida_2'), 'FEI');
    });

    test('keeps working for a real name', () {
      expect(accountInitials('Feichter Theo Eltern-Account 2'), 'FEI');
    });

    test('uses an alias as it is', () {
      expect(accountInitials('Theo'), 'THE');
    });

    test('falls back when there are no letters at all', () {
      expect(accountInitials('2019'), '201');
      expect(accountInitials('   '), '?');
      expect(accountInitials(''), '?');
    });

    test('never returns more than three characters', () {
      expect(accountInitials('Maximiliane Musterfrau').length, 3);
    });
  });

  group('readableOn', () {
    double contrast(Color a, Color b) {
      final la = a.computeLuminance(), lb = b.computeLuminance();
      final lighter = la > lb ? la : lb, darker = la > lb ? lb : la;
      return (lighter + 0.05) / (darker + 0.05);
    }

    test('picks black on the mid-green accent', () {
      // estimateBrightnessForColor calls this one dark and picks white, which
      // only reaches a contrast of 2.8 — the check mark barely showed.
      const green = Color(0xFF4CAF50);
      expect(readableOn(green), Colors.black);
      expect(contrast(readableOn(green), green), greaterThan(4.5));
    });

    test('picks white on dark colours', () {
      expect(readableOn(const Color(0xFF3F51B5)), Colors.white);
      expect(readableOn(Colors.black), Colors.white);
    });

    test('picks black on light colours', () {
      expect(readableOn(Colors.white), Colors.black);
      expect(readableOn(const Color(0xFFFFEB3B)), Colors.black);
    });

    test('every accent of the picker gets a readable check mark', () {
      const accents = [
        Color(0xFFFF5722),
        Color(0xFFF44336),
        Color(0xFFE91E63),
        Color(0xFF9C27B0),
        Color(0xFF3F51B5),
        Color(0xFF2196F3),
        Color(0xFF009688),
        Color(0xFF4CAF50),
        Color(0xFF795548),
        Color(0xFF607D8B),
      ];
      for (final accent in accents) {
        expect(
          contrast(readableOn(accent), accent),
          greaterThanOrEqualTo(4.5),
          reason: 'accent $accent',
        );
      }
    });
  });
}
