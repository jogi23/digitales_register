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

import 'package:dr/app_state.dart';
import 'package:dr/providers/all_subjects_provider.dart';
import 'package:dr/providers/subject_appearance_provider.dart';
import 'package:dr/ui/dialog.dart';
import 'package:flutter/material.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Lists the current account's subjects with their nickname and color.
/// Nicknames/colors are stored app-wide (shared across every account the
/// subject appears in, and kept even after all accounts are logged out),
/// but only subjects relevant to the currently active account are shown.
class SubjectAppearancePage extends ConsumerStatefulWidget {
  /// If set, immediately opens the nickname editor for the first subject
  /// that doesn't have one yet — used when arriving from the calendar's
  /// "Kürzel bearbeiten" prompt.
  final bool autoEditMissingNick;

  const SubjectAppearancePage({super.key, this.autoEditMissingNick = false});

  @override
  ConsumerState<SubjectAppearancePage> createState() =>
      _SubjectAppearancePageState();
}

class _SubjectAppearancePageState
    extends ConsumerState<SubjectAppearancePage> {
  @override
  void initState() {
    super.initState();
    if (widget.autoEditMissingNick) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        final appearance = ref.read(subjectAppearanceProvider);
        final subjects = ref.read(allSubjectsProvider);
        final missing = subjects
            .where((s) => appearance.nickFor(s) == null)
            .toList();
        if (missing.isNotEmpty) _editNick(missing.first);
      });
    }
  }

  Future<void> _editNick(String subject) async {
    final current = ref.read(subjectAppearanceProvider).nickFor(subject) ?? '';
    final newNick = await showDialog<String>(
      context: context,
      builder: (context) => _EditNickDialog(
        subject: subject,
        initialNick: current,
      ),
    );
    if (newNick != null) {
      await ref
          .read(subjectAppearanceProvider.notifier)
          .setNick(subject, newNick);
    }
  }

  Future<void> _editColor(String subject, SubjectTheme theme) async {
    final color = await showDialog<Color>(
      context: context,
      builder: (context) => _ColorPickerDialog(
        initialColor: Color(theme.color),
      ),
    );
    if (color != null) {
      await ref
          .read(subjectAppearanceProvider.notifier)
          .setTheme(subject, theme.copyWith(color: color.value));
    }
  }

  @override
  Widget build(BuildContext context) {
    final subjects = ref.watch(allSubjectsProvider).toList()..sort();
    final appearance = ref.watch(subjectAppearanceProvider);
    return Scaffold(
      appBar: AppBar(
        title: const Text("Fächer Kürzel und Farben"),
      ),
      body: subjects.isEmpty
          ? const Center(child: Text("Keine Fächer vorhanden"))
          : ListView.builder(
              itemCount: subjects.length,
              itemBuilder: (context, index) {
                final subject = subjects[index];
                final theme = appearance.themeFor(subject);
                final nick = appearance.nickFor(subject);
                return ListTile(
                  leading: GestureDetector(
                    onTap: () => _editColor(subject, theme),
                    child: Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: Color(theme.color),
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
                  title: Text(subject),
                  subtitle: Text(nick ?? "Kein Kürzel"),
                  trailing: IconButton(
                    icon: const Icon(Icons.edit),
                    onPressed: () => _editNick(subject),
                  ),
                );
              },
            ),
    );
  }
}

class _EditNickDialog extends StatefulWidget {
  final String subject;
  final String initialNick;

  const _EditNickDialog({required this.subject, required this.initialNick});

  @override
  State<_EditNickDialog> createState() => _EditNickDialogState();
}

class _EditNickDialogState extends State<_EditNickDialog> {
  late final TextEditingController controller;

  @override
  void initState() {
    super.initState();
    controller = TextEditingController(text: widget.initialNick)
      ..addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return InfoDialog(
      title: Text("Kürzel für ${widget.subject}"),
      content: TextField(
        controller: controller,
        autofocus: true,
        textCapitalization: TextCapitalization.sentences,
        onSubmitted: (_) {
          if (controller.text.isNotEmpty) {
            Navigator.of(context).pop(controller.text);
          }
        },
      ),
      actions: <Widget>[
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text("Abbrechen"),
        ),
        ElevatedButton(
          onPressed: controller.text.isNotEmpty
              ? () => Navigator.of(context).pop(controller.text)
              : null,
          child: const Text("Fertig"),
        ),
      ],
    );
  }
}

class _ColorPickerDialog extends StatefulWidget {
  final Color initialColor;

  const _ColorPickerDialog({required this.initialColor});

  @override
  State<_ColorPickerDialog> createState() => _ColorPickerDialogState();
}

class _ColorPickerDialogState extends State<_ColorPickerDialog> {
  late Color color;

  @override
  void initState() {
    super.initState();
    color = widget.initialColor;
  }

  @override
  Widget build(BuildContext context) {
    return InfoDialog(
      title: const Text("Farbe auswählen"),
      content: SingleChildScrollView(
        child: MaterialPicker(
          pickerColor: color,
          onColorChanged: (pickedColor) {
            setState(() {
              color = pickedColor;
            });
          },
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text("Abbrechen"),
        ),
        ElevatedButton(
          onPressed: color != widget.initialColor
              ? () => Navigator.pop(context, color)
              : null,
          child: const Text("Auswählen"),
        ),
      ],
    );
  }
}
