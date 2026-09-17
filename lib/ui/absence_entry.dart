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

import 'package:dr/data.dart';
import 'package:dr/l10n/l10n.dart';
import 'package:dr/ui/dialog.dart';
import 'package:dr/ui/layout.dart';
import 'package:flutter/material.dart';
import 'package:flutter_widget_from_html_core/flutter_widget_from_html_core.dart';
import 'package:intl/intl.dart';

/// What the reason dialog collected.
class AbsenceReasonInput {
  final String reason;
  final String signature;

  /// The form the reason was given with; null for none.
  final SelfDeclaration? selfDeclaration;
  final String selfDeclarationInput;

  const AbsenceReasonInput({
    required this.reason,
    required this.signature,
    this.selfDeclaration,
    this.selfDeclarationInput = "",
  });
}

/// What the report form collected.
class FutureAbsenceInput {
  final DateTime startDate;
  final DateTime endDate;

  /// Lesson numbers of the school's time grid, not times of day.
  final int startHour;
  final int endHour;
  final String reason;
  final String signature;
  final String note;

  const FutureAbsenceInput({
    required this.startDate,
    required this.endDate,
    required this.startHour,
    required this.endHour,
    required this.reason,
    required this.signature,
    this.note = "",
  });
}

/// Whether a reason may be sent: the register insists on reason and
/// signature, the school may insist on one of its forms on top of that, and a
/// form may insist on its own free text.
bool absenceReasonComplete({
  required String reason,
  required String signature,
  required bool declarationActive,
  required bool declarationMandatory,
  SelfDeclaration? declaration,
  required String declarationInput,
}) {
  if (reason.trim().isEmpty || signature.trim().isEmpty) return false;
  if (!declarationActive) return true;
  if (declarationMandatory && (declaration == null || declaration.id <= 0)) {
    return false;
  }
  if (declaration != null &&
      declaration.inputMandatory &&
      declarationInput.trim().isEmpty) {
    return false;
  }
  return true;
}

/// Whether a report may be sent. The register takes nothing that ends before
/// it starts, and nothing without reason and signature.
bool futureAbsenceComplete({
  required DateTime startDate,
  required DateTime endDate,
  required int startHour,
  required int endHour,
  required String reason,
  required String signature,
}) {
  if (reason.trim().isEmpty || signature.trim().isEmpty) return false;
  final start = DateTime(startDate.year, startDate.month, startDate.day);
  final end = DateTime(endDate.year, endDate.month, endDate.day);
  if (end.isBefore(start)) return false;
  if (end == start && endHour < startHour) return false;
  return true;
}

/// Asks for the reason of an absence the register still has open.
Future<AbsenceReasonInput?> showAbsenceReasonDialog(
  BuildContext context, {
  required String absence,
  String? reason,
  String? signature,
  required List<SelfDeclaration> declarations,
  required bool declarationActive,
  required bool declarationMandatory,
  SelfDeclaration? declaration,
  String declarationInput = "",
}) {
  return showDialog<AbsenceReasonInput>(
    context: context,
    builder: (context) => _AbsenceReasonDialog(
      absence: absence,
      reason: reason,
      signature: signature,
      declarations: declarations,
      declarationActive: declarationActive,
      declarationMandatory: declarationMandatory,
      declaration: declaration,
      declarationInput: declarationInput,
    ),
  );
}

class _AbsenceReasonDialog extends StatefulWidget {
  final String absence;
  final String? reason;
  final String? signature;
  final List<SelfDeclaration> declarations;
  final bool declarationActive;
  final bool declarationMandatory;
  final SelfDeclaration? declaration;
  final String declarationInput;

  const _AbsenceReasonDialog({
    required this.absence,
    this.reason,
    this.signature,
    required this.declarations,
    required this.declarationActive,
    required this.declarationMandatory,
    this.declaration,
    required this.declarationInput,
  });

  @override
  State<_AbsenceReasonDialog> createState() => _AbsenceReasonDialogState();
}

class _AbsenceReasonDialogState extends State<_AbsenceReasonDialog> {
  late final TextEditingController _reason;
  late final TextEditingController _signature;
  late final TextEditingController _declarationInput;
  SelfDeclaration? _declaration;

  @override
  void initState() {
    super.initState();
    _reason = TextEditingController(text: widget.reason ?? "");
    _signature = TextEditingController(text: widget.signature ?? "");
    _declarationInput = TextEditingController(text: widget.declarationInput);
    _declaration = widget.declaration;
  }

  @override
  void dispose() {
    _reason.dispose();
    _signature.dispose();
    _declarationInput.dispose();
    super.dispose();
  }

  bool get _complete => absenceReasonComplete(
        reason: _reason.text,
        signature: _signature.text,
        declarationActive: widget.declarationActive,
        declarationMandatory: widget.declarationMandatory,
        declaration: _declaration,
        declarationInput: _declarationInput.text,
      );

  /// The forms to pick from. Where a school leaves the choice open, nothing
  /// selected is one of the options.
  List<SelfDeclaration?> get _options => [
        if (!widget.declarationMandatory) null,
        ...widget.declarations.where((d) => d.id > 0),
      ];

  void _showDeclarationText(SelfDeclaration declaration) {
    unawaitedShowDialog(
      context,
      InfoDialog(
        title: Text(declaration.title),
        content: SingleChildScrollView(child: HtmlWidget(declaration.text)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l = tr(context);
    final picked = _declaration;
    return AlertDialog(
      title: Text(l.absenceJustifyTitle),
      content: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Text(widget.absence, style: Theme.of(context).textTheme.bodySmall),
            const SizedBox(height: 12),
            TextField(
              controller: _reason,
              autofocus: true,
              textCapitalization: TextCapitalization.sentences,
              decoration: InputDecoration(labelText: l.absenceReasonLabel),
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _signature,
              textCapitalization: TextCapitalization.words,
              decoration: InputDecoration(
                labelText: l.absenceSignatureLabel,
                helperText: l.absenceSignatureHint,
              ),
              onChanged: (_) => setState(() {}),
            ),
            if (widget.declarationActive && _options.isNotEmpty) ...[
              const SizedBox(height: 8),
              DropdownButtonFormField<SelfDeclaration?>(
                initialValue: picked,
                isExpanded: true,
                decoration: InputDecoration(
                  labelText: l.absenceSelfDeclarationLabel,
                ),
                items: [
                  for (final option in _options)
                    DropdownMenuItem<SelfDeclaration?>(
                      value: option,
                      child: Text(
                        option?.title ?? l.absenceSelfDeclarationNone,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                ],
                onChanged: (value) => setState(() {
                  _declaration = value;
                  if (value == null) _declarationInput.clear();
                }),
              ),
              if (picked != null) ...[
                Align(
                  alignment: Alignment.centerLeft,
                  child: TextButton(
                    onPressed: () => _showDeclarationText(picked),
                    child: Text(l.absenceSelfDeclarationShow),
                  ),
                ),
                if (picked.inputMandatory ||
                    picked.inputExplain?.isNotEmpty == true)
                  TextField(
                    controller: _declarationInput,
                    decoration: InputDecoration(
                      labelText: picked.inputExplain?.isNotEmpty == true
                          ? picked.inputExplain
                          : l.absenceSelfDeclarationInput,
                    ),
                    onChanged: (_) => setState(() {}),
                  ),
              ],
            ],
          ],
        ),
      ),
      actions: <Widget>[
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(l.commonCancel),
        ),
        TextButton(
          onPressed: _complete
              ? () => Navigator.of(context).pop(
                    AbsenceReasonInput(
                      reason: _reason.text.trim(),
                      signature: _signature.text.trim(),
                      selfDeclaration: _declaration,
                      selfDeclarationInput: _declarationInput.text.trim(),
                    ),
                  )
              : null,
          child: Text(l.commonSave),
        ),
      ],
    );
  }
}

/// Reports an absence that is still to come: when it starts and ends, and why.
class FutureAbsencePage extends StatefulWidget {
  /// How many lessons a day of this school has, for the lesson pickers.
  final int hourCount;

  /// The name last used to sign, so it does not have to be typed again.
  final String? signature;

  const FutureAbsencePage({
    super.key,
    required this.hourCount,
    this.signature,
  });

  @override
  State<FutureAbsencePage> createState() => _FutureAbsencePageState();
}

class _FutureAbsencePageState extends State<FutureAbsencePage> {
  late DateTime _startDate;
  late DateTime _endDate;
  int _startHour = 1;
  late int _endHour;
  late final TextEditingController _reason;
  late final TextEditingController _signature;
  late final TextEditingController _note;

  @override
  void initState() {
    super.initState();
    final today = DateTime.now();
    _startDate = DateTime(today.year, today.month, today.day);
    _endDate = _startDate;
    // The whole day by default: a day off is more common than single lessons.
    _endHour = widget.hourCount;
    _reason = TextEditingController();
    _signature = TextEditingController(text: widget.signature ?? "");
    _note = TextEditingController();
  }

  @override
  void dispose() {
    _reason.dispose();
    _signature.dispose();
    _note.dispose();
    super.dispose();
  }

  bool get _complete => futureAbsenceComplete(
        startDate: _startDate,
        endDate: _endDate,
        startHour: _startHour,
        endHour: _endHour,
        reason: _reason.text,
        signature: _signature.text,
      );

  Future<void> _pickDate({required bool start}) async {
    final today = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: start ? _startDate : _endDate,
      // The register takes nothing that lies in the past.
      firstDate:
          start ? DateTime(today.year, today.month, today.day) : _startDate,
      lastDate: DateTime(today.year + 2),
    );
    if (picked == null) return;
    setState(() {
      if (start) {
        _startDate = picked;
        if (_endDate.isBefore(picked)) _endDate = picked;
      } else {
        _endDate = picked;
      }
    });
  }

  Widget _dateTile(String label, DateTime date, {required bool start}) {
    return ListTile(
      title: Text(label),
      trailing: Text(
        DateFormat("EE d.M.yyyy", tr(context).localeName).format(date),
      ),
      onTap: () => _pickDate(start: start),
    );
  }

  Widget _hourTile(String label, int value, ValueChanged<int> onChanged) {
    return ListTile(
      title: Text(label),
      trailing: DropdownButton<int>(
        value: value,
        items: [
          for (var hour = 1; hour <= widget.hourCount; hour++)
            DropdownMenuItem(value: hour, child: Text("$hour.")),
        ],
        onChanged: (picked) {
          if (picked != null) onChanged(picked);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l = tr(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(l.absenceReportTitle),
        actions: <Widget>[
          TextButton(
            onPressed: _complete
                ? () => Navigator.of(context).pop(
                      FutureAbsenceInput(
                        startDate: _startDate,
                        endDate: _endDate,
                        startHour: _startHour,
                        endHour: _endHour,
                        reason: _reason.text.trim(),
                        signature: _signature.text.trim(),
                        note: _note.text.trim(),
                      ),
                    )
                : null,
            child: Text(l.absenceReportSend),
          ),
        ],
      ),
      body: ListView(
        padding: context.systemInsets + const EdgeInsets.only(bottom: 24),
        children: <Widget>[
          _dateTile(l.absenceDateFrom, _startDate, start: true),
          _dateTile(l.absenceDateTo, _endDate, start: false),
          _hourTile(l.absenceHourFrom, _startHour, (picked) {
            setState(() {
              _startHour = picked;
              if (_endDate == _startDate && _endHour < picked) {
                _endHour = picked;
              }
            });
          }),
          _hourTile(l.absenceHourTo, _endHour, (picked) {
            setState(() => _endHour = picked);
          }),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: TextField(
              controller: _reason,
              textCapitalization: TextCapitalization.sentences,
              decoration: InputDecoration(labelText: l.absenceReasonLabel),
              onChanged: (_) => setState(() {}),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: TextField(
              controller: _signature,
              textCapitalization: TextCapitalization.words,
              decoration: InputDecoration(
                labelText: l.absenceSignatureLabel,
                helperText: l.absenceSignatureHint,
              ),
              onChanged: (_) => setState(() {}),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: TextField(
              controller: _note,
              textCapitalization: TextCapitalization.sentences,
              decoration: InputDecoration(labelText: l.absenceNoteLabel),
            ),
          ),
        ],
      ),
    );
  }
}

/// Shows [dialog] without waiting for it: the caller carries on.
void unawaitedShowDialog(BuildContext context, Widget dialog) {
  showDialog<void>(context: context, builder: (_) => dialog);
}
