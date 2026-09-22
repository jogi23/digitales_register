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
import 'package:dr/app_state.dart';
import 'package:dr/container/settings_page.dart';
import 'package:dr/ui/account_avatar_button.dart';
import 'package:dr/ui/autocomplete_options.dart';
import 'package:dr/ui/connection_status_button.dart';
import 'package:dr/ui/dialog.dart';
import 'package:dr/ui/debug_log_page.dart';
import 'package:dr/ui/layout.dart';
import 'package:dr/ui/network_protocol_page.dart';
import 'package:dr/ui/star_rating.dart';
import 'package:dr/ui/subject_appearance_page.dart';
import 'package:dr/l10n/l10n.dart';
import 'package:dr/util.dart';
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
  final OnSettingChanged<bool> onSetKeepPageOnAccountSwitch;
  final OnSettingChanged<bool> onSetAccentBackground;
  final OnSettingChanged<bool> onSetAskWhenDelete;
  final OnSettingChanged<bool> onSetShowGradesDiagram;
  final OnSettingChanged<bool> onSetShowAllSubjectsAverage;
  final OnSettingChanged<bool> onSetShowSubjectAverage;
  final OnSettingChanged<bool> onSetDashboardMarkNewOrChangedEntries;
  final OnSettingChanged<bool> onSetDashboardDeduplicateEntries;
  final OnSettingChanged<bool> onSetDarkMode;
  final OnSettingChanged<bool> onSetFollowDeviceDarkMode;
  final OnSettingChanged<bool> onSetDashboardColorBorders;
  final OnSettingChanged<bool> onSetCalenderColorBackground;
  final OnSettingChanged<bool> onSetCalendarShowTimes;
  final OnSettingChanged<bool> onSetCalendarShowAllDetails;
  final void Function(DashboardViewMode mode) onSetDashboardViewMode;
  final void Function(ClassbookViewMode mode) onSetClassbookViewMode;
  final void Function(EntryDisplayMode mode) onSetClassbookDisplayMode;
  final void Function(ClassbookViewMode mode) onSetHomeworkViewMode;
  final void Function(EntryDisplayMode mode) onSetHomeworkDisplayMode;
  final void Function(EntryDisplayMode mode) onSetAbsencesDisplayMode;
  final void Function(EntryDisplayMode mode) onSetGradesDisplayMode;
  final OnSettingChanged<bool> onSetDashboardColorTestsInRed;
  final OnSettingChanged<String> onSetStarColor;
  final OnSettingChanged<String?> onSetLanguage;
  final OnSettingChanged<List<String>> onSetIgnoreForGradesAverage;
  final OnSettingChanged<bool> onSetNotificationsEnabled;
  final OnSettingChanged<int> onSetNotificationPollMinutes;
  final OnSettingChanged<bool> onSetNotifyClassbook;
  final OnSettingChanged<bool> onSetNotifyMessages;
  final OnSettingChanged<bool> onSetNotifyGrades;
  final OnSettingChanged<bool> onSetNotifyObservations;
  final OnSettingChanged<bool> onSetNotifyHomework;
  final VoidCallback onShowProfile;
  final SettingsViewModel vm;

  const SettingsPageWidget({
    super.key,
    required this.onSetNoPassSaving,
    required this.onSetKeepPageOnAccountSwitch,
    required this.onSetAccentBackground,
    required this.onSetAskWhenDelete,
    required this.onSetShowGradesDiagram,
    required this.onSetShowAllSubjectsAverage,
    required this.onSetShowSubjectAverage,
    required this.onSetDashboardMarkNewOrChangedEntries,
    required this.onSetDashboardDeduplicateEntries,
    required this.onSetDarkMode,
    required this.vm,
    required this.onSetFollowDeviceDarkMode,
    required this.onShowProfile,
    required this.onSetIgnoreForGradesAverage,
    required this.onSetDashboardColorBorders,
    required this.onSetCalenderColorBackground,
    required this.onSetCalendarShowTimes,
    required this.onSetCalendarShowAllDetails,
    required this.onSetDashboardViewMode,
    required this.onSetClassbookViewMode,
    required this.onSetClassbookDisplayMode,
    required this.onSetHomeworkViewMode,
    required this.onSetHomeworkDisplayMode,
    required this.onSetAbsencesDisplayMode,
    required this.onSetGradesDisplayMode,
    required this.onSetDashboardColorTestsInRed,
    required this.onSetStarColor,
    required this.onSetLanguage,
    required this.onSetNotificationsEnabled,
    required this.onSetNotificationPollMinutes,
    required this.onSetNotifyClassbook,
    required this.onSetNotifyMessages,
    required this.onSetNotifyGrades,
    required this.onSetNotifyObservations,
    required this.onSetNotifyHomework,
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

  /// One palette entry, shown as a star in the colour it stands for so the
  /// choice can be made without applying it first.
  DropdownMenuItem<String> _starColorItem(
    BuildContext context, {
    required String id,
  }) {
    return DropdownMenuItem(
      value: id,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.star, color: resolveStarColor(context, id), size: 20),
          const SizedBox(width: 8),
          Text(starColorName(context, id)),
        ],
      ),
    );
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

  Widget _heading(BuildContext context, String text) => ListTile(
        title: Text(text, style: Theme.of(context).textTheme.headlineSmall),
      );

  Widget _subheading(BuildContext context, String text) => ListTile(
        dense: true,
        title: Text(text, style: Theme.of(context).textTheme.titleSmall),
      );

  String _intervalLabel(BuildContext context, int minutes) {
    if (minutes < 60) return tr(context).notificationsEveryMinutes(minutes);
    final hours = minutes ~/ 60;
    return tr(context).notificationsEveryHours(hours);
  }

  /// By day or by subject — classbook and homework each have their own.
  List<Widget> _arrangementTiles(
    BuildContext context, {
    required ClassbookViewMode value,
    required void Function(ClassbookViewMode mode) onChanged,
  }) =>
      [
        _subheading(context, tr(context).settingsClassbookView),
        for (final entry in <ClassbookViewMode, String>{
          ClassbookViewMode.chronological:
              tr(context).classbookViewChronological,
          ClassbookViewMode.bySubject: tr(context).classbookViewBySubject,
        }.entries)
          RadioListTile<ClassbookViewMode>(
            title: Text(entry.value),
            value: entry.key,
            groupValue: value,
            onChanged: (mode) {
              if (mode != null) onChanged(mode);
            },
          ),
      ];

  /// List, cards and — where [offerTimeline] — the timeline. With
  /// [timelineEnabled] false it stays visible but cannot be picked, and says
  /// why, rather than vanishing when the arrangement changes.
  List<Widget> _displayModeTiles(
    BuildContext context, {
    required EntryDisplayMode value,
    required void Function(EntryDisplayMode mode) onChanged,
    bool offerTimeline = false,
    bool timelineEnabled = true,
  }) =>
      [
        _subheading(context, tr(context).settingsDisplay),
        for (final entry in <EntryDisplayMode, String>{
          EntryDisplayMode.list: tr(context).displayList,
          EntryDisplayMode.cards: tr(context).displayCards,
          if (offerTimeline)
            EntryDisplayMode.timeline: tr(context).displayTimeline,
        }.entries)
          RadioListTile<EntryDisplayMode>(
            title: Text(entry.value),
            subtitle: entry.key == EntryDisplayMode.timeline && !timelineEnabled
                ? Text(tr(context).displayTimelineOnlyByDay)
                : null,
            value: entry.key,
            groupValue: value,
            onChanged: entry.key == EntryDisplayMode.timeline && !timelineEnabled
                ? null
                : (mode) {
                    if (mode != null) onChanged(mode);
                  },
          ),
      ];

  @override
  Widget build(BuildContext context) {
    final currentTheme = DynamicTheme.of(context)!.followDevice
        ? _Theme.followDevice
        : DynamicTheme.of(context)!.customBrightness == Brightness.dark
            ? _Theme.dark
            : _Theme.light;
    return Scaffold(
      appBar: ResponsiveAppBar(
        title: Text(tr(context).settingsTitle),
        actions: const [ConnectionStatusButton()],
      ),
      body: ListView(
        controller: controller,
        padding: context.systemInsets,
        children: <Widget>[
          if (!widget.vm.demoMode) ...[
            const SizedBox(height: 8),
            ListTile(
              title: Text(
                tr(context).settingsProfile,
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
                tr(context).settingsSectionLogin,
                style: Theme.of(context).textTheme.headlineSmall,
              ),
            ),
          ),
          if (!widget.vm.demoMode) const AccountSettingsTile(),
          SwitchListTile.adaptive(
            title: Text(tr(context).settingsStayLoggedIn),
            subtitle: Text(
              '${tr(context).settingsStayLoggedInSubtitle}\n'
              '${tr(context).settingsStayLoggedInBackgroundHint}',
            ),
            onChanged: (bool value) {
              widget.onSetNoPassSaving(!value);
            },
            value: !widget.vm.noPassSaving,
          ),
          SwitchListTile.adaptive(
            title: Text(tr(context).settingsNotificationsEnable),
            subtitle: Text(tr(context).settingsNotificationsEnableSubtitle),
            onChanged: widget.onSetNotificationsEnabled,
            value: widget.vm.notificationsEnabled,
          ),
          ListTile(
            enabled: widget.vm.notificationsEnabled,
            title: Text(tr(context).settingsNotificationsInterval),
            subtitle: Text(tr(context).settingsNotificationsIntervalSubtitle),
            trailing: DropdownButton<int>(
              value: widget.vm.notificationPollMinutes,
              onChanged: !widget.vm.notificationsEnabled
                  ? null
                  : (value) {
                      if (value != null) {
                        widget.onSetNotificationPollMinutes(value);
                      }
                    },
              items: [
                for (final minutes in allowedNotificationPollMinutes)
                  DropdownMenuItem(
                    value: minutes,
                    child: Text(_intervalLabel(context, minutes)),
                  ),
              ],
            ),
          ),
          _subheading(context, tr(context).settingsNotificationsTypes),
          SwitchListTile.adaptive(
            title: Text(tr(context).settingsNotificationsTypeClassbook),
            onChanged:
                widget.vm.notificationsEnabled ? widget.onSetNotifyClassbook : null,
            value: widget.vm.notifyClassbook,
          ),
          SwitchListTile.adaptive(
            title: Text(tr(context).settingsNotificationsTypeMessages),
            onChanged:
                widget.vm.notificationsEnabled ? widget.onSetNotifyMessages : null,
            value: widget.vm.notifyMessages,
          ),
          SwitchListTile.adaptive(
            title: Text(tr(context).settingsNotificationsTypeGrades),
            onChanged:
                widget.vm.notificationsEnabled ? widget.onSetNotifyGrades : null,
            value: widget.vm.notifyGrades,
          ),
          SwitchListTile.adaptive(
            title: Text(tr(context).settingsNotificationsTypeObservations),
            onChanged: widget.vm.notificationsEnabled
                ? widget.onSetNotifyObservations
                : null,
            value: widget.vm.notifyObservations,
          ),
          SwitchListTile.adaptive(
            title: Text(tr(context).settingsNotificationsTypeHomework),
            onChanged:
                widget.vm.notificationsEnabled ? widget.onSetNotifyHomework : null,
            value: widget.vm.notifyHomework,
          ),
          // Next to the account switch it is about; the demo has no second
          // account to switch to.
          if (!widget.vm.demoMode)
            SwitchListTile.adaptive(
              title: Text(tr(context).settingsKeepPageOnAccountSwitch),
              subtitle:
                  Text(tr(context).settingsKeepPageOnAccountSwitchSubtitle),
              onChanged: widget.onSetKeepPageOnAccountSwitch,
              value: widget.vm.keepPageOnAccountSwitch,
            ),
          const Divider(),
          AutoScrollTag(
            controller: controller,
            index: 1,
            key: const ObjectKey(1),
            child: ListTile(
              title: Text(
                tr(context).settingsSectionAppearance,
                style: Theme.of(context).textTheme.headlineSmall,
              ),
            ),
          ),
          ListTile(
            title: Text(tr(context).settingsLanguage),
            trailing: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                // The empty string stands for "follow the device": a
                // DropdownButton cannot tell a null value from no value.
                value: widget.vm.language ?? '',
                onChanged: (value) =>
                    widget.onSetLanguage(value == '' ? null : value),
                items: [
                  DropdownMenuItem(
                    value: '',
                    child: Text(tr(context).settingsLanguageDevice),
                  ),
                  for (final code in supportedLanguages)
                    DropdownMenuItem(
                      value: code,
                      child: Text(languageNames[code]!),
                    ),
                ],
              ),
            ),
          ),
          RadioListTile(
            value: _Theme.followDevice,
            groupValue: currentTheme,
            onChanged: _selectTheme,
            title: Text(tr(context).settingsThemeFollowDevice),
          ),
          RadioListTile(
            value: _Theme.light,
            groupValue: currentTheme,
            onChanged: _selectTheme,
            title: Text(tr(context).settingsThemeLight),
          ),
          RadioListTile(
            value: _Theme.dark,
            groupValue: currentTheme,
            onChanged: _selectTheme,
            title: Text(tr(context).settingsThemeDark),
          ),
          const _SeedColorPicker(),
          SwitchListTile.adaptive(
            title: Text(tr(context).settingsAccentBackground),
            subtitle: Text(tr(context).settingsAccentBackgroundSubtitle),
            value: widget.vm.accentBackground,
            onChanged: widget.onSetAccentBackground,
          ),
          const Divider(
            indent: 15,
            endIndent: 15,
            height: 0,
          ),
          ListTile(
            title: Text(
              tr(context).settingsSectionSubjects,
              style: Theme.of(context).textTheme.headlineSmall,
            ),
          ),
          ListTile(
            title: Text(tr(context).settingsNicksAndColors),
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
            title: Text(
              tr(context).settingsColorHomework,
            ),
            value: widget.vm.dashboardColorBorders,
            onChanged: widget.onSetDashboardColorBorders,
          ),
          SwitchListTile.adaptive(
            title: Text(
              tr(context).settingsColorLessons,
            ),
            value: widget.vm.calendarColorBackground,
            onChanged: widget.onSetCalenderColorBackground,
          ),
          SwitchListTile.adaptive(
            title: Text(
              tr(context).settingsShowTimes,
            ),
            value: widget.vm.calendarShowTimes,
            onChanged: widget.onSetCalendarShowTimes,
          ),
          SwitchListTile.adaptive(
            title: Text(tr(context).settingsShowAllDetails),
            subtitle: Text(tr(context).settingsShowAllDetailsHint),
            value: widget.vm.calendarShowAllDetails,
            onChanged: widget.onSetCalendarShowAllDetails,
          ),
          SwitchListTile.adaptive(
            title: Text(
              tr(context).settingsFrameTestsRed,
            ),
            value: widget.vm.dashboardColorTestsInRed,
            onChanged: widget.onSetDashboardColorTestsInRed,
          ),
          Divider(),
          AutoScrollTag(
            controller: controller,
            index: 2,
            key: ObjectKey(2),
            child: ListTile(
              title: Text(
                tr(context).settingsSectionHomework,
                style: Theme.of(context).textTheme.headlineSmall,
              ),
            ),
          ),
          for (final entry in <DashboardViewMode, String>{
            DashboardViewMode.list: tr(context).settingsViewList,
            DashboardViewMode.month: tr(context).settingsViewMonth,
            DashboardViewMode.week: tr(context).settingsViewWeek,
          }.entries)
            RadioListTile<DashboardViewMode>(
              title: Text(entry.value),
              value: entry.key,
              groupValue: widget.vm.dashboardViewMode,
              onChanged: (mode) {
                if (mode != null) widget.onSetDashboardViewMode(mode);
              },
            ),
          SwitchListTile.adaptive(
            title: Text(tr(context).settingsMarkNewEntries),
            onChanged: (bool value) {
              widget.onSetDashboardMarkNewOrChangedEntries(value);
            },
            value: widget.vm.dashboardMarkNewOrChangedEntries,
          ),
          SwitchListTile.adaptive(
            title: Text(tr(context).settingsIgnoreDuplicates),
            onChanged: (bool value) {
              widget.onSetDashboardDeduplicateEntries(value);
            },
            value: widget.vm.dashboardDeduplicateEntries,
          ),
          const Divider(),
          ListTile(
            title: Text(
              tr(context).settingsClassbook,
              style: Theme.of(context).textTheme.headlineSmall,
            ),
          ),
          ..._arrangementTiles(
            context,
            value: widget.vm.classbookViewMode,
            onChanged: widget.onSetClassbookViewMode,
          ),
          ..._displayModeTiles(
            context,
            value: widget.vm.classbookDisplayMode,
            onChanged: widget.onSetClassbookDisplayMode,
            offerTimeline: true,
            timelineEnabled:
                widget.vm.classbookViewMode == ClassbookViewMode.chronological,
          ),
          const Divider(),
          _heading(context, tr(context).settingsHomeworkOverview),
          ..._arrangementTiles(
            context,
            value: widget.vm.homeworkViewMode,
            onChanged: widget.onSetHomeworkViewMode,
          ),
          ..._displayModeTiles(
            context,
            value: widget.vm.homeworkDisplayMode,
            onChanged: widget.onSetHomeworkDisplayMode,
          ),
          const Divider(),
          _heading(context, tr(context).settingsAbsences),
          ..._displayModeTiles(
            context,
            value: widget.vm.absencesDisplayMode,
            onChanged: widget.onSetAbsencesDisplayMode,
          ),
          const Divider(),
          SwitchListTile.adaptive(
            title: Text(tr(context).settingsAskWhenDeleting),
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
                tr(context).settingsSectionGrades,
                style: Theme.of(context).textTheme.headlineSmall,
              ),
            ),
          ),
          SwitchListTile.adaptive(
            title: Text(tr(context).settingsShowChart),
            onChanged: (bool value) {
              widget.onSetShowGradesDiagram(value);
            },
            value: widget.vm.showGradesDiagram,
          ),
          SwitchListTile.adaptive(
            title: Text(tr(context).settingsShowAllSubjectsAverage),
            onChanged: (bool value) {
              widget.onSetShowAllSubjectsAverage(value);
            },
            value: widget.vm.showAllSubjectsAverage,
          ),
          SwitchListTile.adaptive(
            title: Text(tr(context).settingsShowSubjectAverage),
            onChanged: (bool value) {
              widget.onSetShowSubjectAverage(value);
            },
            value: widget.vm.showSubjectAverage,
          ),
          ..._displayModeTiles(
            context,
            value: widget.vm.gradesDisplayMode,
            onChanged: widget.onSetGradesDisplayMode,
          ),
          ListTile(
            title: Text(tr(context).settingsStarColor),
            subtitle: Text(tr(context).settingsStarColorSubtitle),
            trailing: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: widget.vm.starColor,
                onChanged: (value) {
                  if (value != null) widget.onSetStarColor(value);
                },
                items: [
                  _starColorItem(context, id: accentStarColorId),
                  for (final color in starColors)
                    _starColorItem(context, id: color.id),
                ],
              ),
            ),
          ),
          ListTile(
            title: Text(tr(context).settingsExcludeSubjects),
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
            firstChild: Padding(
              padding: EdgeInsets.only(left: 16),
              child: ListTile(
                title: Text(
                  tr(context).settingsNoSubjectExcluded,
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
                tr(context).settingsSectionAdvanced,
                style: Theme.of(context).textTheme.headlineSmall,
              ),
            ),
          ),
          ListTile(
            title: Text(tr(context).settingsNetworkLog),
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
              title: Text(tr(context).settingsDebugLog),
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
            title: Text(tr(context).settingsSource),
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
      title: Text(tr(context).settingsAddSubject),
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
          child: Text(tr(context).commonCancel),
        ),
        ElevatedButton(
          onPressed: subjectNameController.text != ""
              ? () {
                  Navigator.of(context).pop(subjectNameController.text);
                }
              : null,
          child: Text(tr(context).commonDone),
        ),
      ],
    );
  }
}

class _SeedColorPicker extends StatelessWidget {
  /// The colours to choose from, named in the reader's language.
  static List<({String label, Color color})> _colors(BuildContext context) => [
        (label: tr(context).colorOrange, color: const Color(0xFFFF5722)),
        (label: tr(context).colorRed, color: const Color(0xFFF44336)),
        (label: tr(context).colorPink, color: const Color(0xFFE91E63)),
        (label: tr(context).colorPurple, color: const Color(0xFF9C27B0)),
        (label: tr(context).colorIndigo, color: const Color(0xFF3F51B5)),
        (label: tr(context).colorBlue, color: const Color(0xFF2196F3)),
        (label: tr(context).colorTeal, color: const Color(0xFF009688)),
        (label: tr(context).colorGreen, color: const Color(0xFF4CAF50)),
        (label: tr(context).colorBrown, color: const Color(0xFF795548)),
        (label: tr(context).colorGrey, color: const Color(0xFF607D8B)),
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
          Text(tr(context).settingsAccentColor, style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final entry in _colors(context))
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
                              color: readableOn(entry.color),
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
