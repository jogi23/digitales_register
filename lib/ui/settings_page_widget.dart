// Copyright (C) 2021 Michael Debertol
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

import 'package:deleteable_tile/deleteable_tile.dart';
import 'package:dr/container/settings_page.dart';
import 'package:dr/ui/autocomplete_options.dart';
import 'package:dr/ui/dialog.dart';
import 'package:dr/ui/debug_log_page.dart';
import 'package:dr/ui/network_protocol_page.dart';
import 'package:dr/ui/subject_appearance_page.dart';
import 'package:flutter/foundation.dart';
import 'package:dynamic_theme/dynamic_theme.dart';
import 'package:flutter/material.dart';
import 'package:responsive_scaffold/responsive_scaffold.dart';
import 'package:scroll_to_index/scroll_to_index.dart';
import 'package:url_launcher/url_launcher.dart';

enum _Theme {
  light,
  dark,
  followDevice,
}

class SettingsPageWidget extends StatefulWidget {
  final OnSettingChanged<bool> onSetNoPassSaving;
  final OnSettingChanged<bool> onSetAskWhenDelete;
  final OnSettingChanged<bool> onSetShowGradesDiagram;
  final OnSettingChanged<bool> onSetShowAllSubjectsAverage;
  final OnSettingChanged<bool> onSetDashboardMarkNewOrChangedEntries;
  final OnSettingChanged<bool> onSetDashboardDeduplicateEntries;
  final OnSettingChanged<bool> onSetDarkMode;
  final OnSettingChanged<bool> onSetFollowDeviceDarkMode;
  final OnSettingChanged<bool> onSetDashboardColorBorders;
  final OnSettingChanged<bool> onSetCalenderColorBackground;
  final OnSettingChanged<bool> onSetDashboardColorTestsInRed;
  final OnSettingChanged<List<String>> onSetIgnoreForGradesAverage;
  final VoidCallback onShowProfile;
  final SettingsViewModel vm;

  const SettingsPageWidget({
    super.key,
    required this.onSetNoPassSaving,
    required this.onSetAskWhenDelete,
    required this.onSetShowGradesDiagram,
    required this.onSetShowAllSubjectsAverage,
    required this.onSetDashboardMarkNewOrChangedEntries,
    required this.onSetDashboardDeduplicateEntries,
    required this.onSetDarkMode,
    required this.vm,
    required this.onSetFollowDeviceDarkMode,
    required this.onShowProfile,
    required this.onSetIgnoreForGradesAverage,
    required this.onSetDashboardColorBorders,
    required this.onSetCalenderColorBackground,
    required this.onSetDashboardColorTestsInRed,
  });

  @override
  _SettingsPageWidgetState createState() => _SettingsPageWidgetState();
}

class _SettingsPageWidgetState extends State<SettingsPageWidget> {
  final controller = AutoScrollController(suggestedRowHeight: 250);

  List<String> get notYetIgnoredForAverageSubjects => widget.vm.allSubjects
      .where((element) => !widget.vm.ignoreForGradesAverage.contains(element))
      .toList();

  @override
  void initState() {
    if (widget.vm.showGradesSettings) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        controller.scrollToIndex(3, preferPosition: AutoScrollPosition.begin);
      });
    }
    super.initState();
  }

  void _selectTheme(_Theme? theme) {
    setState(() {
      switch (theme!) {
        case _Theme.light:
          widget.onSetFollowDeviceDarkMode(false);
          widget.onSetDarkMode(false);
        case _Theme.dark:
          widget.onSetFollowDeviceDarkMode(false);
          widget.onSetDarkMode(true);
        case _Theme.followDevice:
          widget.onSetFollowDeviceDarkMode(true);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final currentTheme = DynamicTheme.of(context)!.followDevice
        ? _Theme.followDevice
        : DynamicTheme.of(context)!.customBrightness == Brightness.dark
            ? _Theme.dark
            : _Theme.light;
    return Scaffold(
      appBar: const ResponsiveAppBar(
        title: Text("Einstellungen"),
      ),
      body: ListView(
        controller: controller,
        padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewPadding.bottom),
        children: <Widget>[
          if (!widget.vm.demoMode) ...[
            const SizedBox(height: 8),
            ListTile(
              title: Text(
                "Profil",
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              trailing: const Icon(Icons.chevron_right),
              onTap: widget.onShowProfile,
            ),
            const Divider(),
          ],
          AutoScrollTag(
            controller: controller,
            index: 0,
            key: const ObjectKey(0),
            child: ListTile(
              title: Text(
                "Anmeldung",
                style: Theme.of(context).textTheme.headlineSmall,
              ),
            ),
          ),
          SwitchListTile.adaptive(
            title: const Text("Angemeldet bleiben"),
            subtitle: const Text("Deine Zugangsdaten werden lokal gespeichert"),
            onChanged: (bool value) {
              widget.onSetNoPassSaving(!value);
            },
            value: !widget.vm.noPassSaving,
          ),
          const Divider(),
          AutoScrollTag(
            controller: controller,
            index: 1,
            key: const ObjectKey(1),
            child: ListTile(
              title: Text(
                "Aussehen",
                style: Theme.of(context).textTheme.headlineSmall,
              ),
            ),
          ),
          RadioListTile(
            value: _Theme.followDevice,
            groupValue: currentTheme,
            onChanged: _selectTheme,
            title: const Text("Geräte-Theme folgen"),
          ),
          RadioListTile(
            value: _Theme.light,
            groupValue: currentTheme,
            onChanged: _selectTheme,
            title: const Text("Hell"),
          ),
          RadioListTile(
            value: _Theme.dark,
            groupValue: currentTheme,
            onChanged: _selectTheme,
            title: const Text("Dunkel"),
          ),
          const _SeedColorPicker(),
          const Divider(
            indent: 15,
            endIndent: 15,
            height: 0,
          ),
          ListTile(
            title: const Text("Fächer Kürzel und Farben"),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute<void>(
                  builder: (context) => const SubjectAppearancePage(),
                ),
              );
            },
          ),
          SwitchListTile.adaptive(
            title: const Text(
              "Hausaufgaben mit diesen Farben färben",
            ),
            value: widget.vm.dashboardColorBorders,
            onChanged: widget.onSetDashboardColorBorders,
          ),
          SwitchListTile.adaptive(
            title: const Text(
              "Stunden im Kalender mit diesen Farben färben",
            ),
            value: widget.vm.calendarColorBackground,
            onChanged: widget.onSetCalenderColorBackground,
          ),
          SwitchListTile.adaptive(
            title: const Text(
              "Tests immer rot umrahmen",
            ),
            value: widget.vm.dashboardColorTestsInRed,
            onChanged: widget.onSetDashboardColorTestsInRed,
          ),
          const Divider(),
          AutoScrollTag(
            controller: controller,
            index: 2,
            key: const ObjectKey(2),
            child: ListTile(
              title: Text(
                "Merkheft",
                style: Theme.of(context).textTheme.headlineSmall,
              ),
            ),
          ),
          SwitchListTile.adaptive(
            title: const Text("Neue oder geänderte Einträge markieren"),
            onChanged: (bool value) {
              widget.onSetDashboardMarkNewOrChangedEntries(value);
            },
            value: widget.vm.dashboardMarkNewOrChangedEntries,
          ),
          SwitchListTile.adaptive(
            title: const Text("Doppelte Einträge ignorieren"),
            onChanged: (bool value) {
              widget.onSetDashboardDeduplicateEntries(value);
            },
            value: widget.vm.dashboardDeduplicateEntries,
          ),
          SwitchListTile.adaptive(
            title: const Text("Beim Löschen von Erinnerungen fragen"),
            onChanged: (bool value) {
              widget.onSetAskWhenDelete(value);
            },
            value: widget.vm.askWhenDelete,
          ),
          const Divider(),
          AutoScrollTag(
            controller: controller,
            index: 3,
            key: const ObjectKey(3),
            child: ListTile(
              title: Text(
                "Noten",
                style: Theme.of(context).textTheme.headlineSmall,
              ),
            ),
          ),
          SwitchListTile.adaptive(
            title: const Text("Noten in einem Diagramm darstellen"),
            onChanged: (bool value) {
              widget.onSetShowGradesDiagram(value);
            },
            value: widget.vm.showGradesDiagram,
          ),
          SwitchListTile.adaptive(
            title: const Text('Durchschnitt aller Fächer anzeigen'),
            onChanged: (bool value) {
              widget.onSetShowAllSubjectsAverage(value);
            },
            value: widget.vm.showAllSubjectsAverage,
          ),
          ListTile(
            title: const Text("Fächer aus dem Notendurchschnitt ausschließen"),
            trailing: IconButton(
              icon: const Icon(Icons.add),
              onPressed: () async {
                final newSubject = await showDialog<String>(
                  context: context,
                  builder: (context) => AddSubject(
                    availableSubjects: notYetIgnoredForAverageSubjects,
                  ),
                );
                if (newSubject != null) {
                  widget.onSetIgnoreForGradesAverage(
                      widget.vm.ignoreForGradesAverage..add(newSubject));
                }
              },
            ),
          ),
          AnimatedCrossFade(
            duration: const Duration(milliseconds: 250),
            crossFadeState: widget.vm.ignoreForGradesAverage.isEmpty
                ? CrossFadeState.showFirst
                : CrossFadeState.showSecond,
            firstChild: const Padding(
              padding: EdgeInsets.only(left: 16),
              child: ListTile(
                title: Text(
                  "Kein Fach ausgeschlossen",
                  style: TextStyle(color: Colors.grey),
                ),
              ),
            ),
            secondChild: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                for (final subject in widget.vm.ignoreForGradesAverage)
                  Deleteable(
                    // don't show an animation if this is the only item
                    // in that case, the AnimatedCrossFade will do a different animation
                    showExitAnimation:
                        widget.vm.ignoreForGradesAverage.length != 1,
                    showEntryAnimation:
                        widget.vm.ignoreForGradesAverage.length != 1,
                    key: ValueKey(subject),
                    builder: (context, delete) => Padding(
                      padding: const EdgeInsets.only(left: 16),
                      child: ListTile(
                        title: Text(subject),
                        trailing: IconButton(
                          icon: const Icon(
                            Icons.close,
                          ),
                          onPressed: () async {
                            await delete();
                            widget.onSetIgnoreForGradesAverage(
                              widget.vm.ignoreForGradesAverage..remove(subject),
                            );
                          },
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const Divider(),
          AutoScrollTag(
            controller: controller,
            index: 4,
            key: const ObjectKey(4),
            child: ListTile(
              title: Text(
                "Erweitert",
                style: Theme.of(context).textTheme.headlineSmall,
              ),
            ),
          ),
          ListTile(
            title: const Text("Netzwerkprotokoll"),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute<void>(
                  builder: (context) {
                    return const NetworkProtocolPage();
                  },
                ),
              );
            },
          ),
          if (kDebugMode)
            ListTile(
              title: const Text("Debug-Log"),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute<void>(
                    builder: (context) => const DebugLogPage(),
                  ),
                );
              },
            ),
          ListTile(
            leading: const Icon(Icons.code),
            trailing: const Icon(Icons.open_in_new),
            title: const Text("Zum Quellcode"),
            onTap: () => launchUrl(
              Uri.parse("https://github.com/jogi23/digitales_register"),
            ),
          ),
        ],
      ),
    );
  }
}

class AddSubject extends StatefulWidget {
  final List<String>? availableSubjects;

  const AddSubject({super.key, this.availableSubjects});
  @override
  _AddSubjectState createState() => _AddSubjectState();
}

class _AddSubjectState extends State<AddSubject> {
  late TextEditingController subjectNameController;
  late FocusNode focusNode;

  @override
  void initState() {
    super.initState();
    focusNode = FocusNode();
    subjectNameController = TextEditingController()
      ..addListener(
        () {
          setState(() {});
        },
      );
  }

  @override
  void dispose() {
    subjectNameController.dispose();
    focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return InfoDialog(
      title: const Text("Fach hinzufügen"),
      content: RawAutocomplete<String>(
        focusNode: focusNode,
        textEditingController: subjectNameController,
        optionsBuilder: (textEditingValue) {
          return widget.availableSubjects!.where(
            (suggestion) => suggestion
                .toLowerCase()
                .contains(textEditingValue.text.toLowerCase()),
          );
        },
        optionsViewBuilder: (context, onSelected, options) {
          return AutocompleteOptions(
            displayStringForOption: RawAutocomplete.defaultStringForOption,
            onSelected: onSelected,
            options: options,
            maxOptionsHeight: 200,
            // We can't use a LayoutBuilder to get the size inside an AlertDialog,
            // so we hardcode it here.
            // TODO: Remove once https://github.com/flutter/flutter/issues/78746 is fixed.
            width: 233,
          );
        },
        fieldViewBuilder:
            (context, textEditingController, focusNode, onFieldSubmitted) {
          return TextFormField(
            controller: textEditingController,
            focusNode: focusNode,
            onFieldSubmitted: (String value) {
              onFieldSubmitted();
            },
            autofocus: subjectNameController.text.isEmpty,
          );
        },
        onSelected: (_) {
          focusNode.unfocus();
        },
      ),
      actions: <Widget>[
        TextButton(
          onPressed: () {
            Navigator.of(context).pop();
          },
          child: const Text("Abbrechen"),
        ),
        ElevatedButton(
          onPressed: subjectNameController.text != ""
              ? () {
                  Navigator.of(context).pop(subjectNameController.text);
                }
              : null,
          child: const Text("Fertig"),
        ),
      ],
    );
  }
}

class _SeedColorPicker extends StatelessWidget {
  static const _colors = [
    (label: 'Orange', color: Color(0xFFFF5722)),
    (label: 'Rot', color: Color(0xFFF44336)),
    (label: 'Pink', color: Color(0xFFE91E63)),
    (label: 'Lila', color: Color(0xFF9C27B0)),
    (label: 'Indigo', color: Color(0xFF3F51B5)),
    (label: 'Blau', color: Color(0xFF2196F3)),
    (label: 'Türkis', color: Color(0xFF009688)),
    (label: 'Grün', color: Color(0xFF4CAF50)),
    (label: 'Braun', color: Color(0xFF795548)),
    (label: 'Grau', color: Color(0xFF607D8B)),
  ];

  const _SeedColorPicker();

  @override
  Widget build(BuildContext context) {
    final currentSeed = DynamicTheme.of(context)!.seedColor;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Akzentfarbe', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final entry in _colors)
                Tooltip(
                  message: entry.label,
                  child: GestureDetector(
                    onTap: () =>
                        DynamicTheme.of(context)!.setSeedColor(entry.color),
                    child: Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: entry.color,
                        shape: BoxShape.circle,
                        border: entry.color.value == currentSeed.value
                            ? Border.all(
                                color: Theme.of(context).colorScheme.onSurface,
                                width: 3,
                              )
                            : null,
                      ),
                      child: entry.color.value == currentSeed.value
                          ? Icon(
                              Icons.check,
                              size: 18,
                              color: ThemeData.estimateBrightnessForColor(
                                          entry.color) ==
                                      Brightness.dark
                                  ? Colors.white
                                  : Colors.black,
                            )
                          : null,
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
