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

import 'dart:io';

import 'package:dr/ui/account_avatar_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Widget _avatar(String? photoPath) => MaterialApp(
      home: Scaffold(
        body: ProfileAvatar(
          photoPath: photoPath,
          name: 'Anna Berger',
          radius: 24,
          initialsScale: 0.6,
        ),
      ),
    );

void main() {
  testWidgets('without a photo it shows the initials', (tester) async {
    await tester.pumpWidget(_avatar(null));
    expect(find.text('ANN'), findsOneWidget);
  });

  testWidgets('a photo whose file is gone shows the initials', (tester) async {
    await tester.pumpWidget(_avatar('/nowhere/photo.png'));
    expect(find.text('ANN'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('a photo removed after the avatar was built is no error (#286)',
      (tester) async {
    // What happened when a photo was removed or replaced: the avatar still
    // held the old file, and loading it found nothing there.
    final dir = Directory.systemTemp.createTempSync('dr_avatar_test');
    addTearDown(() => dir.deleteSync(recursive: true));
    final file = File('${dir.path}/photo.png')..writeAsBytesSync([0]);

    // Built while the file was there; loading happens once it is gone.
    // Real time, or the file is never read.
    await tester.runAsync(() async {
      await tester.pumpWidget(_avatar(file.path));
      file.deleteSync();
      await Future<void>.delayed(const Duration(milliseconds: 200));
    });
    await tester.pump();

    expect(tester.takeException(), isNull);
    expect(find.text('ANN'), findsOneWidget);
  });
}
