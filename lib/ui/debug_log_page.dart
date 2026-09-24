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
import 'package:dr/l10n/l10n.dart';
import 'package:dr/ui/layout.dart';
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
  /// Newest first.
  List<DebugLogEntry> _entries = const [];
  bool _loading = true;

  /// The category shown, or null for all.
  String? _category;

  @override
  void initState() {
    super.initState();
    _reload();
  }

  Future<void> _reload() async {
    final entries = await DebugLog.instance.readAll();
    if (!mounted) return;
    setState(() {
      _entries = entries.reversed.toList();
      _loading = false;
    });
  }

  List<DebugLogEntry> get _shown => _category == null
      ? _entries
      : _entries.where((e) => e.category == _category).toList();

  Future<void> _clear() async {
    await DebugLog.instance.clear();
    await _reload();
  }

  Future<void> _share() async {
    final text = DebugLog.export(_shown.reversed);
    if (text.isEmpty) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(tr(context).debugLogEmpty)));
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

      await SharePlus.instance.share(
        ShareParams(
          files: [XFile(file.path, mimeType: 'text/plain')],
          subject: 'DigiReg Debug-Log',
        ),
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
    final entries = _shown;
    final categories = {for (final e in _entries) e.category};
    return Scaffold(
      appBar: AppBar(
        title: Text(tr(context).settingsDebugLog),
        actions: [
          IconButton(
            icon: const Icon(Icons.share),
            tooltip: tr(context).commonShare,
            onPressed: _share,
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline),
            tooltip: tr(context).commonDelete,
            onPressed: _clear,
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                if (categories.length > 1)
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    child: Row(
                      children: [
                        for (final category
                            in LogCategory.values.where(categories.contains))
                          Padding(
                            padding: const EdgeInsets.all(4),
                            child: FilterChip(
                              label: Text(category),
                              selected: _category == category,
                              onSelected: (on) => setState(
                                () => _category = on ? category : null,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                Expanded(
                  child: RefreshIndicator(
                    onRefresh: _reload,
                    child: entries.isEmpty
                        ? ListView(
                            children: [
                              Padding(
                                padding: const EdgeInsets.all(32),
                                child: Center(
                                  child: Text(tr(context).debugLogEmpty),
                                ),
                              ),
                            ],
                          )
                        : ListView.separated(
                            padding: context.systemInsets,
                            itemCount: entries.length,
                            separatorBuilder: (_, __) =>
                                const Divider(height: 1),
                            itemBuilder: (context, i) =>
                                _EntryTile(entry: entries[i]),
                          ),
                  ),
                ),
              ],
            ),
    );
  }
}

class _EntryTile extends StatelessWidget {
  final DebugLogEntry entry;

  const _EntryTile({required this.entry});

  String get _time {
    final t = entry.timestamp;
    final time = '${t.hour.toString().padLeft(2, '0')}:'
        '${t.minute.toString().padLeft(2, '0')}:'
        '${t.second.toString().padLeft(2, '0')}';
    return entry.isolate == null ? time : '$time · ${entry.isolate}';
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
              SnackBar(content: Text(tr(context).debugLogCopied)),
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
