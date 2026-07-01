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

import 'package:dr/app_state.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _prefsKey = 'subject_appearance';

const _defaultNicks = <String, String>{
  "deutsch": "Deu",
  "mathematik": "Mat",
  "latein": "Lat",
  "religion": "Rel",
  "englisch": "Eng",
  "naturwissenschaften": "Nat",
  "geschichte": "Gesch",
  "italienisch": "Ita",
  "bewegung und sport": "Sport",
  "recht und wirtschaft": "Rw",
  "griechisch": "Gr",
  "fü": "Fü",
};

const _defaultThick = 2;

final _colors = List.of(Colors.primaries)
  ..removeWhere((c) => _similarColors.contains(c));

final _similarColors = [
  Colors.lime,
  Colors.lightBlue,
  Colors.cyan,
  Colors.amber,
];

/// Case-insensitive key so the same subject (e.g. "Mathematik" vs.
/// "mathematik" across different accounts) always maps to one entry.
String normalizeSubject(String subject) => subject.trim().toLowerCase();

/// App-wide (not per-account) subject nicknames and colors. A subject keeps
/// the same nickname and color across every account it appears in, and the
/// data survives account logout/deletion — it belongs to the person using
/// the app, not to any one school account.
class SubjectAppearanceState {
  final Map<String, SubjectTheme> themes;
  final Map<String, String> nicks;

  const SubjectAppearanceState({
    this.themes = const {},
    this.nicks = const {},
  });

  SubjectAppearanceState copyWith({
    Map<String, SubjectTheme>? themes,
    Map<String, String>? nicks,
  }) =>
      SubjectAppearanceState(
        themes: themes ?? this.themes,
        nicks: nicks ?? this.nicks,
      );

  SubjectTheme themeFor(String subject) =>
      themes[normalizeSubject(subject)] ?? const SubjectTheme();

  String? nickFor(String subject) => nicks[normalizeSubject(subject)];
}

class SubjectAppearanceNotifier extends Notifier<SubjectAppearanceState> {
  @override
  SubjectAppearanceState build() =>
      const SubjectAppearanceState(nicks: _defaultNicks);

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_prefsKey);
    if (raw == null) return;
    final decoded = json.decode(raw) as Map<String, dynamic>;
    state = SubjectAppearanceState(
      themes: (decoded['themes'] as Map<String, dynamic>? ?? {}).map(
        (k, v) => MapEntry(k, SubjectTheme.fromJson(v as Map<String, dynamic>)),
      ),
      nicks: (decoded['nicks'] as Map<String, dynamic>? ?? {})
          .cast<String, String>(),
    );
  }

  Future<void> setTheme(String subject, SubjectTheme theme) async {
    final key = normalizeSubject(subject);
    state = state.copyWith(themes: {...state.themes, key: theme});
    await _persist();
  }

  Future<void> setNick(String subject, String nick) async {
    final key = normalizeSubject(subject);
    state = state.copyWith(nicks: {...state.nicks, key: nick});
    await _persist();
  }

  Future<void> removeNick(String subject) async {
    final key = normalizeSubject(subject);
    state = state.copyWith(nicks: Map.of(state.nicks)..remove(key));
    await _persist();
  }

  /// Ensures every subject in [subjects] has a [SubjectTheme]. New subjects
  /// are assigned an unused color automatically; existing ones are untouched.
  Future<void> ensureThemesFor(List<String> subjects) async {
    final existing = state.themes;
    final newSubjects = subjects
        .map(normalizeSubject)
        .where((s) => !existing.containsKey(s))
        .toSet();
    if (newSubjects.isEmpty) return;

    final updated = Map.of(state.themes);
    for (final subject in newSubjects) {
      final usedColors = updated.values.map((t) => t.color).toSet();
      final color = _colors.firstWhere(
        (c) => !usedColors.contains(c.value),
        orElse: () => _similarColors.firstWhere(
          (c) => !usedColors.contains(c.value),
          orElse: () => (List.of(Colors.primaries)..shuffle()).first,
        ),
      );
      updated[subject] = SubjectTheme(thick: _defaultThick, color: color.value);
    }
    state = state.copyWith(themes: updated);
    await _persist();
  }

  Future<void> _persist() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _prefsKey,
      json.encode({
        'themes': state.themes.map((k, v) => MapEntry(k, v.toJson())),
        'nicks': state.nicks,
      }),
    );
  }
}

final subjectAppearanceProvider =
    NotifierProvider<SubjectAppearanceNotifier, SubjectAppearanceState>(
  SubjectAppearanceNotifier.new,
);
