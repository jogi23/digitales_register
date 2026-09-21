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
import 'dart:io';

import 'package:dr/ui/photo_crop_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// A 40x20 picture, red on its left half and blue on its right.
final _picture = base64Decode(
  'iVBORw0KGgoAAAANSUhEUgAAACgAAAAUCAIAAABwJOjsAAAAJ0lEQVR42mP4z8BA'
  'NqJA63+GUYtHLR61eNTiUYtHLR61eNTikWMxAGDtHQ7V1k7XAAAAAElFTkSuQmCC',
);

const _imageSize = Size(40, 20);

void main() {
  group('covering the crop window', () {
    test('scales the picture up by its shorter side', () {
      // 20 high to fill 300 means fifteen times, and the width follows.
      expect(coverScale(_imageSize, 300), 15);
      expect(coveredSize(_imageSize, 300), const Size(600, 300));
    });

    test('leaves a picture without pixels alone', () {
      expect(coverScale(Size.zero, 300), 1);
    });
  });

  group('the section the window shows', () {
    /// What the page starts with: the picture centred, not zoomed.
    Offset centred(double window) {
      final covered = coveredSize(_imageSize, window);
      return Offset(
        -(covered.width - window) / 2,
        -(covered.height - window) / 2,
      );
    }

    test('is the middle of the picture before anything is moved', () {
      final rect = visibleSourceRect(
        imageSize: _imageSize,
        window: 300,
        baseScale: coverScale(_imageSize, 300),
        scale: 1,
        offset: centred(300),
      );
      // A square as tall as the picture, taken from its middle.
      expect(rect, const Rect.fromLTWH(10, 0, 20, 20));
    });

    test('halves with every doubling of the zoom', () {
      final rect = visibleSourceRect(
        imageSize: _imageSize,
        window: 300,
        baseScale: coverScale(_imageSize, 300),
        scale: 2,
        offset: Offset.zero,
      );
      expect(rect, const Rect.fromLTWH(0, 0, 10, 10));
    });

    test('follows the picture as it is dragged', () {
      // Dragging the picture 150 points to the left at fifteen times its own
      // size moves the window ten pixels into it.
      final rect = visibleSourceRect(
        imageSize: _imageSize,
        window: 300,
        baseScale: 15,
        scale: 1,
        offset: const Offset(-150, 0),
      );
      expect(rect.left, 10);
      expect(rect.width, 20);
    });

    test('stays inside the picture', () {
      // Rounding must not put the window past the edge: the part outside
      // would be drawn into the photo as empty pixels.
      final rect = visibleSourceRect(
        imageSize: _imageSize,
        window: 300,
        baseScale: 15,
        scale: 1,
        offset: const Offset(-1000, -1000),
      );
      expect(rect.left, 20);
      expect(rect.top, 0);
      expect(rect.right, lessThanOrEqualTo(_imageSize.width));
      expect(rect.bottom, lessThanOrEqualTo(_imageSize.height));
    });

    test('survives a picture of no size', () {
      final rect = visibleSourceRect(
        imageSize: Size.zero,
        window: 300,
        baseScale: 1,
        scale: 0,
        offset: Offset.zero,
      );
      expect(rect, Rect.zero);
    });
  });

  group('the page', () {
    late Directory dir;
    late File source;

    setUp(() {
      dir = Directory.systemTemp.createTempSync('dr_crop_test');
      source = File('${dir.path}/source.png')..writeAsBytesSync(_picture);
    });

    tearDown(() => dir.deleteSync(recursive: true));

    testWidgets('opens with the picture and a way to apply it', (tester) async {
      // Reading and decoding the picture is real file work, which a widget
      // test does not run; what is checked here is the frame around it.
      await tester.pumpWidget(MaterialApp(home: PhotoCropPage(source: source)));
      await tester.pump();

      expect(find.text('Ausschnitt wählen'), findsOneWidget);
      expect(find.text('Übernehmen'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });
}
