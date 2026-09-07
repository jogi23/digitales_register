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

import 'package:dr/util.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

double _contrast(Color a, Color b) {
  final la = a.computeLuminance(), lb = b.computeLuminance();
  final lighter = la > lb ? la : lb, darker = la > lb ? lb : la;
  return (lighter + 0.05) / (darker + 0.05);
}

/// The same button the alias row builds.
Widget _confirmButton(Color background) => IconButton.filled(
      onPressed: () {},
      icon: const Icon(Icons.check),
      style: IconButton.styleFrom(
        backgroundColor: background,
        foregroundColor: readableOn(background),
      ),
    );

void main() {
  /// Every accent the settings offer, in both themes.
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

  for (final brightness in Brightness.values) {
    testWidgets('the confirm check stays readable in ${brightness.name} mode',
        (tester) async {
      for (final accent in accents) {
        await tester.pumpWidget(MaterialApp(
          theme: ThemeData(
            useMaterial3: true,
            colorSchemeSeed: accent,
            brightness: brightness,
          ),
          home: Builder(
            builder: (context) => Scaffold(
              body: _confirmButton(Theme.of(context).colorScheme.primary),
            ),
          ),
        ));
        await tester.pumpAndSettle();

        final style = tester.widget<IconButton>(find.byType(IconButton)).style!;
        final background = style.backgroundColor!.resolve({})!;
        final foreground = style.foregroundColor!.resolve({})!;
        expect(
          _contrast(foreground, background),
          greaterThanOrEqualTo(4.5),
          reason: 'accent $accent in ${brightness.name} mode',
        );
      }
    });
  }
}
