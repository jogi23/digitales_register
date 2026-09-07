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

import 'package:dr/demo.dart';
import 'package:flutter_test/flutter_test.dart';

const _agreeOpenId = 58317;

Future<Map<String, dynamic>> _message(int id) async {
  final messages = await getDemoResponse('api/message/getMyMessages', null);
  return (messages as List)
      .cast<Map<String, dynamic>>()
      .firstWhere((m) => m['id'] == id);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('demo capture has an unanswered agree message', () async {
    final message = await _message(_agreeOpenId);
    expect(message['responseType'], 'agree');
    expect(message['needsResponse'], isTrue);
    expect(message['response'], isNull);
  });

  test('replying in demo mode answers the message for the whole session',
      () async {
    final replied = await getDemoResponse('api/message/reply', {
      'messageId': _agreeOpenId,
      'response': {'response': 'agree'},
    });

    // The endpoint answers with the full list, like the real server does.
    expect(replied, isA<List<dynamic>>());
    final fromReply = (replied as List)
        .cast<Map<String, dynamic>>()
        .firstWhere((m) => m['id'] == _agreeOpenId);
    expect(fromReply['response'], 'agree');
    expect(fromReply['needsResponse'], isFalse);
    expect(fromReply['historyString'], contains('bestätigt'));

    // And the answer survives into later message loads.
    final fromList = await _message(_agreeOpenId);
    expect(fromList['response'], 'agree');
  });
}
