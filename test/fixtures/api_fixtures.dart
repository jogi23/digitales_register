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

import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

List<Map<String, dynamic>>? _capture;

/// Call once in [setUpAll] before using any fixture function.
Future<void> loadFixtures() async {
  if (_capture != null) return;
  TestWidgetsFlutterBinding.ensureInitialized();
  final raw = await rootBundle.loadString('assets/demo/capture.json');
  _capture = (json.decode(raw) as List).cast<Map<String, dynamic>>();
}

/// Returns the stored API response for the first capture entry whose URL path
/// matches [path].
///
/// [path] is matched against the path component of the stored URL, after
/// stripping the `/v2/` prefix (e.g. `'api/student/dashboard/absences'` or
/// `'api/calendar/student'`).
///
/// If [params] is provided, the entry whose stored `parameters` map contains
/// all key-value pairs from [params] is returned (partial match — extra keys in
/// the stored params are allowed). Falls back to the first matching entry when
/// no params match.
dynamic fixtureFor(String path, {Map<String, dynamic>? params}) {
  assert(
    _capture != null,
    'Call loadFixtures() in setUpAll before using fixtureFor()',
  );
  final items = _capture!
      .where((item) => _pathOf(item['address'] as String) == path)
      .toList();
  assert(items.isNotEmpty, 'No fixture found for path: $path');
  if (params == null || params.isEmpty) return items.first['response'];
  for (final item in items) {
    final stored = item['parameters'];
    if (stored is Map && _paramsMatch(stored, params)) return item['response'];
  }
  return items.first['response'];
}

String _pathOf(String address) {
  if (!address.startsWith('http')) return address;
  final path = Uri.parse(address).path;
  const prefix = '/v2/';
  return path.startsWith(prefix) ? path.substring(prefix.length) : path;
}

bool _paramsMatch(Map stored, Map requested) {
  for (final key in requested.keys) {
    if (stored[key]?.toString() != requested[key]?.toString()) return false;
  }
  return true;
}
