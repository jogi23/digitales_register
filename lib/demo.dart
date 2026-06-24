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
import 'package:intl/intl.dart';

// ---------------------------------------------------------------------------
// Capture loading (lazy, once)
// ---------------------------------------------------------------------------

late List<Map<String, dynamic>> _capture;
Future<void>? _loadFuture;

Future<void> _ensureLoaded() => _loadFuture ??= _load();

Future<void> _load() async {
  final raw = await rootBundle.loadString('assets/demo/capture.json');
  final list = json.decode(raw) as List<dynamic>;
  _capture = list.cast<Map<String, dynamic>>();
}

// ---------------------------------------------------------------------------
// Public API (called by SessionManager.send when demoMode == true)
// ---------------------------------------------------------------------------

Future<dynamic> getDemoResponse(String url, dynamic args) async {
  await _ensureLoaded();

  // Write endpoints not in the capture — return minimal synthetic responses
  const synthetic = <String, dynamic>{
    'api/student/dashboard/save_reminder': {
      'id': -1,
      'title': 'Demo-Eintrag',
      'subtitle': 'Demo-Wert',
      'warning': false,
      'deleteable': false,
      'type': 'homework',
    },
    'api/student/dashboard/toggle_reminder': {'success': true},
  };
  if (synthetic.containsKey(url)) return synthetic[url];

  final matches = _capture
      .where((item) => _pathOf(item['address'] as String) == url)
      .toList();

  if (matches.isEmpty) return null;
  if (matches.length == 1) return matches.first['response'];

  // Calendar: shift stored week to the requested week
  if (url == 'api/calendar/student') {
    return _calendarForWeek(matches, args);
  }

  // Multi-match: find by parameter equality
  if (args is Map && args.isNotEmpty) {
    for (final item in matches) {
      final stored = item['parameters'];
      if (stored is Map && _paramsMatch(stored, args)) {
        return item['response'];
      }
    }
  }

  return matches.last['response'];
}

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

String _pathOf(String address) {
  if (!address.startsWith('http')) return address;
  final path = Uri.parse(address).path; // /v2/api/…  or  /v2/?semesterWechsel=…
  const prefix = '/v2/';
  return path.startsWith(prefix) ? path.substring(prefix.length) : path;
}

bool _paramsMatch(
    Map<dynamic, dynamic> stored, Map<dynamic, dynamic> requested) {
  for (final key in requested.keys) {
    if (stored[key]?.toString() != requested[key]?.toString()) return false;
  }
  return true;
}

/// Returns calendar data for the requested week.
/// Picks the closest captured week and shifts all date strings by the offset.
dynamic _calendarForWeek(
    List<Map<String, dynamic>> matches, dynamic args) {
  final requestedStart =
      args is Map ? args['startDate'] as String? : null;
  if (requestedStart == null) return matches.first['response'];

  final requested = DateTime.parse(requestedStart);

  // Find the captured week closest to the requested start date
  Map<String, dynamic>? best;
  int bestDiff = 999999;
  for (final item in matches) {
    final stored = item['parameters'];
    if (stored is Map && stored['startDate'] is String) {
      final diff = DateTime.parse(stored['startDate'] as String)
          .difference(requested)
          .inDays
          .abs();
      if (diff < bestDiff) {
        bestDiff = diff;
        best = item;
      }
    }
  }
  best ??= matches.first;

  final capturedStart =
      (best['parameters'] as Map)['startDate'] as String;
  if (capturedStart == requestedStart) return best['response'];

  // Shift date strings: replace each captured day with the corresponding requested day
  final fmt = DateFormat('yyyy-MM-dd');
  var text = json.encode(best['response']);
  for (var d = 0; d < 7; d++) {
    final from = fmt.format(
        DateTime.parse(capturedStart).add(Duration(days: d)));
    final to =
        fmt.format(requested.add(Duration(days: d)));
    text = text.replaceAll('"$from"', '"$to"');
  }
  return json.decode(text);
}
