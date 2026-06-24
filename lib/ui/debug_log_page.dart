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

import 'package:dr/debug_log.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

class DebugLogPage extends StatefulWidget {
  const DebugLogPage({super.key});

  @override
  State<DebugLogPage> createState() => _DebugLogPageState();
}

class _DebugLogPageState extends State<DebugLogPage> {
  List<DebugLogEntry> get _entries =>
      DebugLog.instance.entries.reversed.toList();

  void _clear() {
    DebugLog.instance.clear();
    setState(() {});
  }

  Future<void> _share() async {
    final text = DebugLog.instance.export();
    if (text.isEmpty) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Log ist leer')));
      return;
    }

    try {
      final timestamp = DateTime.now()
          .toIso8601String()
          .replaceAll(':', '-')
          .replaceAll('.', '-');
      final dir = await getTemporaryDirectory();
      final file = File('${dir.path}/dr_debug_log_$timestamp.txt');
      await file.writeAsString(text);

      await Share.shareXFiles(
        [XFile(file.path, mimeType: 'text/plain')],
        subject: 'DigiReg Debug-Log',
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Teilen fehlgeschlagen: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final entries = _entries;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Debug-Log'),
        actions: [
          IconButton(
            icon: const Icon(Icons.share),
            tooltip: 'Teilen',
            onPressed: _share,
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline),
            tooltip: 'Löschen',
            onPressed: _clear,
          ),
        ],
      ),
      body: entries.isEmpty
          ? const Center(child: Text('Keine Einträge'))
          : ListView.separated(
              itemCount: entries.length,
              separatorBuilder: (_, __) => const Divider(height: 1),
              itemBuilder: (context, i) => _EntryTile(entry: entries[i]),
            ),
    );
  }
}

class _EntryTile extends StatelessWidget {
  final DebugLogEntry entry;

  const _EntryTile({required this.entry});

  String get _time {
    final t = entry.timestamp;
    return '${t.hour.toString().padLeft(2, '0')}:'
        '${t.minute.toString().padLeft(2, '0')}:'
        '${t.second.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final secondary = TextStyle(
      fontSize: 11,
      color: Theme.of(context).colorScheme.onSurfaceVariant,
      fontFamily: 'monospace',
    );

    if (entry.data == null) {
      return ListTile(
        dense: true,
        leading: _CategoryChip(entry.category),
        title: Text(entry.message),
        subtitle: Text(_time, style: secondary),
      );
    }

    return ExpansionTile(
      leading: _CategoryChip(entry.category),
      title: Text(entry.message),
      subtitle: Text(_time, style: secondary),
      childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      children: [
        GestureDetector(
          onLongPress: () {
            Clipboard.setData(ClipboardData(text: entry.data!));
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Daten in Zwischenablage kopiert')),
            );
          },
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(4),
            ),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Text(
                entry.data!,
                style: secondary.copyWith(fontSize: 12),
              ),
            ),
          ),
        ),
        const SizedBox(height: 4),
        Align(
          alignment: Alignment.centerRight,
          child: Text(
            '${entry.data!.length} Zeichen — lang drücken zum Kopieren',
            style: secondary.copyWith(fontSize: 10),
          ),
        ),
      ],
    );
  }
}

class _CategoryChip extends StatelessWidget {
  final String label;
  const _CategoryChip(this.label);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primaryContainer,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 10,
          color: Theme.of(context).colorScheme.onPrimaryContainer,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
