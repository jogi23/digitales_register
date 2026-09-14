// Copyright (C) 2026 Johannes Feichter
import 'package:dr/ui/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const seed = Colors.green;

  group('with the accent background', () {
    test('is the theme the app always had', () {
      // Default an: niemand soll nach dem Update eine andere App vorfinden.
      final before = ThemeData(
        useMaterial3: true,
        colorSchemeSeed: seed,
        brightness: Brightness.light,
      );
      final now = appTheme(Brightness.light, seed);
      expect(now.colorScheme, before.colorScheme);
      expect(now.scaffoldBackgroundColor, before.scaffoldBackgroundColor);
    });
  });

  group('without the accent background', () {
    test('puts the pages on white in light mode', () {
      final theme = appTheme(Brightness.light, seed, accentBackground: false);
      expect(theme.colorScheme.surface, Colors.white);
      expect(theme.scaffoldBackgroundColor, Colors.white);
    });

    test('puts the pages on plain dark in dark mode', () {
      final theme = appTheme(Brightness.dark, seed, accentBackground: false);
      expect(theme.colorScheme.surface, neutralDarkBackground);
      expect(theme.scaffoldBackgroundColor, neutralDarkBackground);
    });

    test('keeps the accent colour everywhere else', () {
      final tinted = appTheme(Brightness.light, seed);
      final plain = appTheme(Brightness.light, seed, accentBackground: false);
      expect(plain.colorScheme.primary, tinted.colorScheme.primary);
      expect(plain.colorScheme.secondaryContainer,
          tinted.colorScheme.secondaryContainer);
    });
  });
}
