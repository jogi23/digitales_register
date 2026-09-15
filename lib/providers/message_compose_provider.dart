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

import 'package:dr/middleware/middleware.dart' show wrapper;
import 'package:dr/providers/messages_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// One piece of the portal's `contextstr`: literal text, or a key the portal
/// translates, such as `message.recipients.teacher`.
typedef ContextFragment = ({bool translate, String text});

List<ContextFragment> parseContext(Object? source) => [
      if (source is List)
        for (final fragment in source)
          if (fragment case {'f': final Object? kind, 'key': final String text})
            (translate: kind == 't', text: text),
    ];

/// The subject of an answer to [subject], the way the portal writes it.
String answerSubject(String subject) =>
    subject.toLowerCase().startsWith('re:') ? subject : 'RE: $subject';

/// Names as the portal shows them, without the double spaces some carry.
String _name(Object? source) => switch (source) {
      final String name => name.replaceAll(RegExp(r'\s+'), ' ').trim(),
      _ => '',
    };

int? _id(Object? source) => switch (source) { final int id => id, _ => null };

/// Someone or some group a message can go to, as the recipient search
/// returns it.
///
/// The portal wants these objects back as it sent them — it looks the people
/// behind a group up from them — so the map is kept whole.
class MessageRecipient {
  final Map<String, Object?> json;

  const MessageRecipient(this.json);

  /// `user` for one person; for a group `students`, `parents`, `teachers` or
  /// `class_teachers`.
  String get type => switch (json['type']) {
        final String type => type,
        _ => '',
      };

  int? get id => _id(json['id']);

  String get name => _name(json['name']);

  bool get isGroup => type != 'user';

  /// The groups of one class share the class's id, so the type is part of
  /// the key.
  String get key => '$type:$id';

  List<ContextFragment> get context => parseContext(json['contextstr']);
}

/// A person behind a recipient, with the tick the reader may take away.
class RecipientPerson {
  final Map<String, Object?> json;
  final bool selected;

  const RecipientPerson(this.json, {required this.selected});

  int? get id => _id(json['id']);

  String get name => _name(json['name']);

  bool get disabled => json['disabled'] == true;

  RecipientPerson withSelected({required bool selected}) =>
      RecipientPerson(json, selected: selected);

  Map<String, Object?> toJson() => {...json, 'selected': selected};
}

/// A recipient resolved into the people behind it, from
/// `getRecipientsDetails`.
class RecipientGroup {
  final Map<String, Object?> json;

  /// The [MessageRecipient.key] this group was looked up for: the answer
  /// carries no id of its own.
  final String recipientKey;
  final List<RecipientPerson> people;

  const RecipientGroup(
    this.json, {
    required this.recipientKey,
    required this.people,
  });

  String get name => _name(json['name']);

  RecipientGroup withPeople(List<RecipientPerson> people) =>
      RecipientGroup(json, recipientKey: recipientKey, people: people);

  /// The group as the portal sent it, with the reader's ticks.
  Map<String, Object?> toJson() => {
        ...json,
        'details': [for (final person in people) person.toJson()],
      };
}

/// What is known while a message is being written. Subject and text stay in
/// the page's fields until it is sent.
class MessageComposeState {
  /// Whether `getTypes` has answered.
  final bool ready;

  /// `getTypes` brought nothing usable: a request that went wrong — an
  /// expired session, say — and not a refusal.
  final bool failed;

  /// The kind of message this account sends, from `getTypes`; `null` when it
  /// may send none. Parents are offered exactly one.
  final Map<String, Object?>? type;
  final String? permission;
  final List<MessageRecipient> recipients;
  final List<RecipientGroup> groups;
  final bool loadingDetails;
  final bool sending;

  const MessageComposeState({
    this.ready = false,
    this.failed = false,
    this.type,
    this.permission,
    this.recipients = const [],
    this.groups = const [],
    this.loadingDetails = false,
    this.sending = false,
  });

  bool get allowed => type != null;

  int get peopleCount => groups.fold(0, (n, group) => n + group.people.length);

  int get selectedCount => groups.fold(
        0,
        (n, group) => n + group.people.where((person) => person.selected).length,
      );

  MessageComposeState copyWith({
    List<MessageRecipient>? recipients,
    List<RecipientGroup>? groups,
    bool? loadingDetails,
    bool? sending,
  }) =>
      MessageComposeState(
        ready: ready,
        failed: failed,
        type: type,
        permission: permission,
        recipients: recipients ?? this.recipients,
        groups: groups ?? this.groups,
        loadingDetails: loadingDetails ?? this.loadingDetails,
        sending: sending ?? this.sending,
      );
}

/// Writes one message. Dropped with the page, so every message starts empty.
///
/// The portal asks in steps: what may be sent (`getTypes`), who matches a
/// search (`getRecipients`), who stands behind the chosen recipients
/// (`getRecipientsDetails`), and finally `sendMessage`. Ticking people on and
/// off asks nothing; the ticks go out with the message.
class MessageComposeNotifier extends AutoDisposeNotifier<MessageComposeState> {
  var _disposed = false;

  @override
  MessageComposeState build() {
    ref.onDispose(() => _disposed = true);
    return const MessageComposeState();
  }

  /// Asks what this account may send and, for an answer to [answerTo], puts
  /// that user in as the first recipient.
  Future<void> start({int? answerTo}) async {
    // Back to loading, for a second try after a failed one.
    state = MessageComposeState(
      recipients: state.recipients,
      groups: state.groups,
    );
    Object? failure;
    // No arguments: the portal posts an empty object, as for any call.
    final types = await wrapper.send(
      'api/message/getTypes',
      onError: (error) => failure = error,
    );
    if (_disposed) return;
    final type = switch (types) {
      {'types': [final Map first, ...]} => first.cast<String, Object?>(),
      _ => null,
    };
    final permission = switch (types) {
      {'permissions': [{'id': final String id}, ...]} => id,
      _ => null,
    };
    state = MessageComposeState(
      ready: true,
      // Only an answer listing no kind of message is a refusal.
      failed: failure != null || types is! Map,
      type: type,
      permission: permission,
      recipients: state.recipients,
      groups: state.groups,
    );
    if (answerTo == null || type == null) return;

    final initial = await wrapper.send(
      'api/message/getInitialRecipients',
      args: <String, Object?>{
        'initialRecipientIds': [answerTo],
      },
    );
    if (_disposed || initial is! List) return;
    state = state.copyWith(recipients: [
      for (final recipient in initial)
        if (recipient is Map) MessageRecipient(recipient.cast<String, Object?>()),
    ]);
    await _loadDetails();
  }

  /// People and groups matching [filter]. Like the portal, this searches
  /// from two characters on.
  Future<List<MessageRecipient>> search(String filter) async {
    final trimmed = filter.trim();
    if (trimmed.length < 2) return const [];
    final result = await wrapper.send(
      'api/message/getRecipients',
      args: <String, Object?>{'filter': trimmed},
    );
    return [
      if (result is List)
        for (final recipient in result)
          if (recipient is Map)
            MessageRecipient(recipient.cast<String, Object?>()),
    ];
  }

  Future<void> add(MessageRecipient recipient) async {
    if (state.recipients.any((r) => r.key == recipient.key)) return;
    state = state.copyWith(recipients: [...state.recipients, recipient]);
    await _loadDetails();
  }

  Future<void> remove(MessageRecipient recipient) async {
    state = state.copyWith(recipients: [
      for (final r in state.recipients)
        if (r.key != recipient.key) r,
    ]);
    await _loadDetails();
  }

  /// Ticks or unticks one person of the recipient [recipientKey].
  void toggle(String recipientKey, int? personId) {
    state = state.copyWith(groups: [
      for (final group in state.groups)
        if (group.recipientKey != recipientKey)
          group
        else
          group.withPeople([
            for (final person in group.people)
              if (person.id == personId && !person.disabled)
                person.withSelected(selected: !person.selected)
              else
                person,
          ]),
    ]);
  }

  void tickAll(bool ticked) {
    state = state.copyWith(groups: [
      for (final group in state.groups)
        group.withPeople([
          for (final person in group.people)
            if (person.disabled)
              person
            else
              person.withSelected(selected: ticked),
        ]),
    ]);
  }

  /// Sends the message to everyone ticked.
  ///
  /// Returns `null` once the portal took it, otherwise the portal's error
  /// key — empty when there is none, as for a request that never arrived.
  Future<String?> send({required String subject, required String text}) async {
    final type = state.type;
    if (type == null) return '';
    state = state.copyWith(sending: true);
    Object? failure;
    final result = await wrapper.send(
      'api/message/sendMessage',
      args: <String, Object?>{
        'recipientsDetails': [for (final group in state.groups) group.toJson()],
        'message': <String, Object?>{
          'subject': subject,
          // The portal keeps message texts as Quill deltas, and its editor
          // ends every text with a line break.
          'text': jsonEncode({
            'ops': [
              {'insert': '$text\n'},
            ],
          }),
          'signatureRequired': type['signatureRequired'] == true,
          'responseRequired': type['responseRequired'] == true,
          'responseType': type['typeId'] ?? 'read',
          'permission': state.permission ?? 'me',
          'submissions': const <Object?>[],
        },
      },
      onError: (error) => failure = error,
    );
    final error = failure != null
        ? ''
        : switch (result) {
            {'success': true} => null,
            {'error': final String key} => key,
            _ => '',
          };
    if (_disposed) return error;
    state = state.copyWith(sending: false);
    // Unlike a confirmation, the portal answers without the new list.
    if (error == null) await ref.read(messagesProvider.notifier).load();
    return error;
  }

  Future<void> _loadDetails() async {
    final requested = state.recipients;
    if (requested.isEmpty) {
      state = state.copyWith(groups: const [], loadingDetails: false);
      return;
    }
    state = state.copyWith(loadingDetails: true);
    final result = await wrapper.send(
      'api/message/getRecipientsDetails',
      args: <String, Object?>{
        'recipientGroups': [for (final recipient in requested) recipient.json],
      },
    );
    // The recipients changed meanwhile; that change asks on its own.
    if (_disposed || !identical(requested, state.recipients)) return;
    final details = switch (result) {
      {'recipientsDetails': final List details} => details,
      _ => const <Object?>[],
    };
    // Ticks taken away stay away when another recipient joins; the portal
    // answers with everyone ticked again.
    final before = {
      for (final group in state.groups)
        group.recipientKey: {
          for (final person in group.people) person.id: person.selected,
        },
    };
    final unmatched = [...requested];
    final groups = <RecipientGroup>[];
    for (final group in details) {
      if (group is! Map) continue;
      final json = group.cast<String, Object?>();
      // The answer names no id and may leave recipients out — the account
      // itself, for one — so a group is matched by type and name, each
      // recipient once, rather than by its position.
      final index = unmatched.indexWhere(
        (r) => r.type == json['type'] && r.name == _name(json['name']),
      );
      final key = index == -1
          ? '${json['type']}:${_name(json['name'])}'
          : unmatched.removeAt(index).key;
      groups.add(_group(json, key, before));
    }
    state = state.copyWith(loadingDetails: false, groups: groups);
  }

  static RecipientGroup _group(
    Map<String, Object?> json,
    String recipientKey,
    Map<String, Map<int?, bool>> before,
  ) =>
      RecipientGroup(
        json,
        recipientKey: recipientKey,
        people: [
          if (json['details'] case final List details)
            for (final person in details)
              if (person is Map)
                _person(person.cast<String, Object?>(), before[recipientKey]),
        ],
      );

  static RecipientPerson _person(
    Map<String, Object?> json,
    Map<int?, bool>? before,
  ) =>
      RecipientPerson(
        json,
        selected: before?[_id(json['id'])] ?? json['selected'] == true,
      );
}

final messageComposeProvider =
    NotifierProvider.autoDispose<MessageComposeNotifier, MessageComposeState>(
        MessageComposeNotifier.new);
