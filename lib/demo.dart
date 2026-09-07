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

import 'package:collection/collection.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

// ---------------------------------------------------------------------------
// Capture loading (lazy, once)
// ---------------------------------------------------------------------------

late List<Map<String, dynamic>> _capture;
Future<void>? _loadFuture;

Future<void> _ensureLoaded() => _loadFuture ??= _load();

int _demoUserId = 0;

Future<void> _load() async {
  final raw = await rootBundle.loadString('assets/demo/capture.json');
  final list = json.decode(raw) as List<dynamic>;
  _capture = list.cast<Map<String, dynamic>>();
  _demoUserId = _parseUserId();
}

int _parseUserId() {
  for (final item in _capture) {
    final resp = item['response'];
    if (resp is! String) continue;
    const needle = 'currentUserId=';
    final idx = resp.indexOf(needle);
    if (idx < 0) continue;
    final after = resp.substring(idx + needle.length);
    final semi = after.indexOf(';');
    if (semi < 0) continue;
    final id = int.tryParse(after.substring(0, semi).trim());
    if (id != null) return id;
  }
  return 0;
}

// ---------------------------------------------------------------------------
// Public API (called by SessionManager.send when demoMode == true)
// ---------------------------------------------------------------------------

Future<int> getDemoUserId() async {
  await _ensureLoaded();
  return _demoUserId;
}

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

  if (url == _replyUrl) return _demoReply(args);

  final matches = _capture
      .where((item) => _pathOf(item['address'] as String) == url)
      .toList();

  if (matches.isEmpty) return null;

  // Messages carry the confirmations sent during this demo session.
  if (url == _myMessagesUrl) {
    final stored = matches.first['response'];
    return stored is List ? _withDemoReplies(stored) : stored;
  }

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
// Message confirmations
// ---------------------------------------------------------------------------

const _myMessagesUrl = 'api/message/getMyMessages';
const _replyUrl = 'api/message/reply';

/// Confirmations sent while the demo runs. The capture is read-only, so the
/// answers live here and are merged into every message list.
final Map<int, Map<String, dynamic>> _demoReplies = <int, Map<String, dynamic>>{};

/// Applies [_demoReplies] on top of the captured messages.
List<dynamic> _withDemoReplies(List<dynamic> messages) {
  if (_demoReplies.isEmpty) return messages;
  return <dynamic>[
    for (final message in messages)
      if (message is Map && _demoReplies.containsKey(message['id']))
        <String, dynamic>{
          ...message.cast<String, dynamic>(),
          ..._demoReplies[message['id']]!,
        }
      else
        message,
  ];
}

/// Records a confirmation and answers like the server does: with the full,
/// updated message list.
dynamic _demoReply(dynamic args) {
  final stored = _capture
      .where((item) => _pathOf(item['address'] as String) == _myMessagesUrl)
      .map((item) => item['response'])
      .whereType<List<dynamic>>()
      .firstOrNull;
  if (stored == null) return null;

  final id = args is Map ? args['messageId'] : null;
  final response = args is Map && args['response'] is Map
      ? (args['response'] as Map).cast<String, dynamic>()
      : const <String, dynamic>{};

  if (id is int) {
    _demoReplies[id] = <String, dynamic>{
      'response': response['response'],
      'responseSignature': response['signature'],
      'needsResponse': false,
      'needsSignature': false,
      'replied': true,
      'badge': null,
      'historyString': 'Von Eltern-Account Demo am '
          '${DateFormat('dd.MM.yyyy').format(DateTime.now())} bestätigt. ',
    };
  }
  return _withDemoReplies(stored);
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
