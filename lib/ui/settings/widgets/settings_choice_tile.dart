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

import 'package:dr/l10n/l10n.dart';
import 'package:flutter/material.dart';

/// One entry of a [SettingsChoiceTile].
class SettingsChoice<T> {
  const SettingsChoice({required this.value, required this.label, this.leading});

  final T value;
  final String label;
  final Widget? leading;
}

/// A setting with one value out of a few: the whole row opens a dialog, and
/// the current value stands under the title.
class SettingsChoiceTile<T> extends StatelessWidget {
  const SettingsChoiceTile({
    super.key,
    required this.icon,
    required this.title,
    required this.value,
    required this.choices,
    required this.onChanged,
    this.hint,
    this.enabled = true,
  });

  final IconData icon;
  final String title;
  final T value;
  final List<SettingsChoice<T>> choices;
  final ValueChanged<T> onChanged;

  /// Shown above the options in the dialog.
  final String? hint;
  final bool enabled;

  String? get _currentLabel {
    for (final choice in choices) {
      if (choice.value == value) return choice.label;
    }
    return null;
  }

  Future<void> _open(BuildContext context) async {
    final picked = await showDialog<T>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        contentPadding: const EdgeInsets.only(top: 12),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (hint != null)
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 0, 24, 8),
                  child: Text(hint!),
                ),
              for (final choice in choices)
                RadioListTile<T>(
                  title: choice.leading == null
                      ? Text(choice.label)
                      : Row(
                          children: [
                            choice.leading!,
                            const SizedBox(width: 8),
                            Flexible(child: Text(choice.label)),
                          ],
                        ),
                  value: choice.value,
                  groupValue: value,
                  // Tapping the chosen entry again closes without a change
                  // (it reports null) instead of leaving the dialog open.
                  toggleable: true,
                  onChanged: (picked) => Navigator.of(context).pop(picked),
                ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(tr(context).commonCancel),
          ),
        ],
      ),
    );
    if (picked != null && picked != value) onChanged(picked);
  }

  @override
  Widget build(BuildContext context) {
    final label = _currentLabel;
    return ListTile(
      enabled: enabled,
      leading: Icon(icon),
      title: Text(title),
      subtitle: label == null ? null : Text(label),
      onTap: enabled ? () => _open(context) : null,
    );
  }
}
