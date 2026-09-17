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
    // Attachments go nowhere in the demo, but the wizard needs an id to
    // carry on with.
    'api/message/messageSubmissionUpload': {
      'success': true,
      'submissionId': -1
    },
  };
  if (synthetic.containsKey(url)) return synthetic[url];

  if (url == _replyUrl) return _demoReply(args);
  if (_composeUrls.contains(url)) return _demoCompose(url, args);
  if (url == _absenceReasonUrl) return _demoAbsenceReason(args);
  if (url == _absenceFutureUrl) return _demoFutureAbsence(args);
  if (url == _removeAbsenceFutureUrl) return _demoRemoveFutureAbsence(args);

  final matches = _capture
      .where((item) => _pathOf(item['address'] as String) == url)
      .toList();

  if (matches.isEmpty) return null;

  // Messages carry the confirmations sent during this demo session.
  if (url == _myMessagesUrl) {
    final stored = matches.first['response'];
    return stored is List ? _withDemoReplies(stored) : stored;
  }

  // Absences carry the reasons and reports entered during this demo session.
  if (url == _absencesUrl) {
    final stored = matches.first['response'];
    return stored is Map ? _withDemoAbsences(stored) : stored;
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

const _absencesUrl = 'api/student/dashboard/absences';
const _absenceReasonUrl = 'api/student/dashboard/absence_reason';
const _absenceFutureUrl = 'api/student/dashboard/absence_future';
const _removeAbsenceFutureUrl = 'api/student/dashboard/remove_absence_future';

/// The reasons the demo account gave in this session, by absence.
final _demoAbsenceReasons = <String, Map<String, dynamic>>{};

/// The absences the demo account reported in advance in this session.
final _demoFutureAbsences = <Map<String, dynamic>>[];

/// The captured absences with what the demo account entered on top: a reason
/// keeps showing after it was given, a report stays in the list.
Map<String, dynamic> _withDemoAbsences(Map<dynamic, dynamic> stored) {
  final copy = json.decode(json.encode(stored)) as Map<String, dynamic>;
  for (final group in ((copy['absences'] as List?) ?? const [])
      .whereType<Map<String, dynamic>>()) {
    final key = _demoAbsenceKey(group);
    final entered = key == null ? null : _demoAbsenceReasons[key];
    if (entered == null) continue;
    group.addAll(entered);
    // The register repeats the reason on every single absence of a group.
    for (final absence in ((group['group'] as List?) ?? const [])
        .whereType<Map<String, dynamic>>()) {
      absence.addAll(entered);
    }
  }
  copy['futureAbsences'] = <dynamic>[
    ...((copy['futureAbsences'] as List?) ?? const []),
    ..._demoFutureAbsences,
  ];
  return copy;
}

/// Day and lesson of a group's first absence — enough to find it again.
String? _demoAbsenceKey(Map<String, dynamic> group) {
  final first = ((group['group'] as List?) ?? const [])
      .whereType<Map<String, dynamic>>()
      .firstOrNull;
  if (first == null) return null;
  return '${first['date']}#${first['hour']}';
}

dynamic _demoAbsenceReason(dynamic args) {
  final group = args is Map ? args['absenceGroup'] : null;
  if (group is Map) {
    final key = _demoAbsenceKey(group.cast<String, dynamic>());
    if (key != null) {
      _demoAbsenceReasons[key] = <String, dynamic>{
        'reason': group['reason'],
        'reason_signature': group['reason_signature'],
        'reason_timestamp':
            DateFormat('yyyy-MM-dd HH:mm:ss').format(DateTime.now()),
        'selfdecl_id': group['selfdecl_id'],
        'selfdecl_input': group['selfdecl_input'],
        // Given, but nobody at the school has approved it yet.
        'justified': 1,
      };
    }
  }
  return {'success': true};
}

dynamic _demoFutureAbsence(dynamic args) {
  final absence = args is Map ? args['futureAbsence'] : null;
  if (absence is Map) {
    _demoFutureAbsences.add(<String, dynamic>{
      ...absence.cast<String, dynamic>(),
      // Negative ids cannot clash with anything the capture holds.
      'id': -(_demoFutureAbsences.length + 1),
      'justified': 1,
      'reason_timestamp':
          DateFormat('yyyy-MM-dd HH:mm:ss').format(DateTime.now()),
    });
  }
  return {'success': true};
}

dynamic _demoRemoveFutureAbsence(dynamic args) {
  final absence = args is Map ? args['futureAbsence'] : null;
  if (absence is Map) {
    _demoFutureAbsences.removeWhere((a) => a['id'] == absence['id']);
  }
  return {'success': true};
}

const _myMessagesUrl = 'api/message/getMyMessages';
const _replyUrl = 'api/message/reply';

/// Confirmations sent while the demo runs. The capture is read-only, so the
/// answers live here and are merged into every message list.
final Map<int, Map<String, dynamic>> _demoReplies =
    <int, Map<String, dynamic>>{};

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
// Writing messages
// ---------------------------------------------------------------------------

const _composeUrls = {
  'api/message/getTypes',
  'api/message/getRecipients',
  'api/message/getInitialRecipients',
  'api/message/getRecipientsDetails',
  'api/message/sendMessage',
};

/// People and a group the demo account can write to, in the portal's format.
const _demoRecipients = <Map<String, Object?>>[
  {
    'type': 'user',
    'id': 9001,
    'name': 'Muster Maria',
    'picture': null,
    'firstname': 'Maria',
    'lastname': 'Muster',
    'classname': null,
    'rolle': 2,
    'contextstr': [
      {'f': 'txt', 'key': 'Muster Maria ('},
      {'f': 't', 'key': 'message.recipients.teacher'},
      {'f': 'txt', 'key': ')'},
    ],
  },
  {
    'type': 'user',
    'id': 9002,
    'name': 'Beispiel Berta',
    'picture': null,
    'firstname': 'Berta',
    'lastname': 'Beispiel',
    'classname': null,
    'rolle': 3,
    'contextstr': [
      {'f': 'txt', 'key': 'Beispiel Berta ('},
      {'f': 't', 'key': 'message.recipients.secretary'},
      {'f': 'txt', 'key': ')'},
    ],
  },
  {
    'type': 'parents',
    'id': 500,
    'name': '1A Erziehungsberechtigte',
    'contextstr': [
      {'f': 'txt', 'key': '1A '},
    ],
  },
];

/// The people behind the demo group.
const _demoParents = ['Huber Anna', 'Moser Paul', 'Gruber Lena'];

/// Answers the calls of the message form. The demo takes a message without
/// keeping it: the list stays as captured.
dynamic _demoCompose(String url, dynamic args) {
  Map<String, Object?> person(int id, String name, int rolle) => {
        'id': id,
        'firstName': name.split(' ').last,
        'lastName': name.split(' ').first,
        'rolle': rolle,
        'className': null,
        'picture': null,
        'activeFrom': null,
        'activeTo': null,
        'name': name,
        'contextstr': const <Object?>[],
        'canSignSignatureMessages': true,
        'signatureRequiresGuardian': false,
        'selected': true,
        'disabled': false,
      };

  switch (url) {
    case 'api/message/getTypes':
      return {
        'types': [
          {
            'id': 'none',
            'typeId': 'read',
            'name': 'Keine',
            'signatureRequired': false,
            'responseRequired': false,
          },
        ],
        'permissions': [
          {'id': 'me', 'name': 'Nur ich'},
        ],
      };
    case 'api/message/getRecipients':
      final filter = args is Map ? '${args['filter']}'.toLowerCase() : '';
      return [
        for (final recipient in _demoRecipients)
          if ('${recipient['name']}'.toLowerCase().contains(filter)) recipient,
      ];
    case 'api/message/getInitialRecipients':
      // The capture has its senders blanked, so every answer goes to the
      // demo teacher.
      return [_demoRecipients.first];
    case 'api/message/getRecipientsDetails':
      final groups = switch (args) {
        {'recipientGroups': final List groups} => groups,
        _ => const <Object?>[],
      };
      final details = [
        for (final group in groups)
          if (group is Map)
            {
              'type': group['type'],
              'name': group['name'],
              'contextstr': group['contextstr'],
              'details': group['type'] == 'user'
                  ? [
                      person(
                        switch (group['id']) { final int id => id, _ => 0 },
                        '${group['name']}',
                        switch (group['rolle']) { final int r => r, _ => 2 },
                      ),
                    ]
                  : [
                      for (final (i, name) in _demoParents.indexed)
                        person(9100 + i, name, 8),
                    ],
            },
      ];
      return {
        'recipientsNumber': details.fold<int>(
          0,
          (n, group) => n + ((group['details'] as List?)?.length ?? 0),
        ),
        'recipientsDetails': details,
      };
    case 'api/message/sendMessage':
      return {'success': true};
  }
  return null;
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
dynamic _calendarForWeek(List<Map<String, dynamic>> matches, dynamic args) {
  final requestedStart = args is Map ? args['startDate'] as String? : null;
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

  final capturedStart = (best['parameters'] as Map)['startDate'] as String;
  if (capturedStart == requestedStart) return best['response'];

  // Shift date strings: replace each captured day with the corresponding requested day
  final fmt = DateFormat('yyyy-MM-dd');
  var text = json.encode(best['response']);
  for (var d = 0; d < 7; d++) {
    final from =
        fmt.format(DateTime.parse(capturedStart).add(Duration(days: d)));
    final to = fmt.format(requested.add(Duration(days: d)));
    text = text.replaceAll('"$from"', '"$to"');
  }
  return json.decode(text);
}
