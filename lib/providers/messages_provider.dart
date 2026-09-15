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

import 'dart:async';

import 'package:built_collection/built_collection.dart';
import 'package:collection/collection.dart' show IterableExtension;
import 'package:dr/app_state.dart';
import 'package:dr/data.dart';
import 'package:dr/middleware/middleware.dart'
    show canOpenFile, downloadFile, openFile, wrapper;
import 'package:dr/providers/notifications_provider.dart';
import 'package:dr/utc_date_time.dart';
import 'package:dr/util.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class MessagesNotifier extends Notifier<MessagesState> {
  @override
  MessagesState build() => MessagesState();

  void reset() {
    state = MessagesState();
  }

  void restore(MessagesState saved) => state = saved;

  Future<void> load() async {
    if (wrapper.noInternet) return;
    final dynamic response = await wrapper.send("api/message/getMyMessages");
    if (response != null) {
      state = _parseMessages(response as List);
      _revealSelected();
    }
  }

  void select(int messageId) {
    state = state.rebuild((b) => b..showMessage = messageId);
    _revealSelected();
  }

  /// Makes the list show the message about to open: a notification can point
  /// to a sent or archived message, or to one a filter hides. Before the list
  /// has loaded there is nothing to go by; [load] asks again.
  void _revealSelected() {
    final message =
        state.messages.firstWhereOrNull((m) => m.id == state.showMessage);
    if (message == null) return;
    ref.read(messageListProvider.notifier).reveal(message, state.starred);
  }

  void clearSelection() {
    state = state.rebuild((b) => b..showMessage = null);
  }

  /// Marks [messageId] with a star, or takes the star away.
  ///
  /// Kept on this device only: the portal has no such mark.
  void toggleStar(int messageId) {
    state = state.rebuild((b) {
      if (!b.starred.remove(messageId)) b.starred.add(messageId);
    });
  }

  /// Moves the messages in [messageIds] into the archive, or back out with
  /// [archived] false, then loads the list again: the portal answers with
  /// nothing. Messages that do not allow the move are left alone.
  ///
  /// Returns whether every request went through.
  Future<bool> setArchived(
    Iterable<int> messageIds, {
    required bool archived,
  }) async {
    final type =
        archived ? Message.archiveTypeArchive : Message.archiveTypeRestore;
    final ids = messageIds.toSet();
    var allSent = true;
    for (final message in state.messages
        .where((m) => ids.contains(m.id) && m.archiveType == type)) {
      Object? failure;
      await wrapper.send(
        "api/message/archiveMessage",
        args: <String, Object?>{
          "messageId": message.id,
          "archiveType": type,
        },
        onError: (error) => failure = error,
      );
      if (failure != null) allSent = false;
    }
    await load();
    return allSent;
  }

  Future<void> openMessageFile(MessageAttachmentFile file) async {
    if (!file.fileAvailable || !await canOpenFile(file.uniqueName)) {
      _markDownloading(file);
      final success = await downloadFile(
        "${wrapper.baseAddress}api/message/messageSubmissionDownloadEntry",
        file.uniqueName,
        <String, dynamic>{
          "messageId": file.messageId,
          "submissionId": file.id,
        },
      );
      _markFileAvailable(file.rebuild((b) => b..fileAvailable = success));
      if (!success) return;
    }
    await openFile(file.uniqueName);
  }

  Future<void> markAllAsRead() async {
    final unread = state.messages.where((m) => m.isNew).toList();
    if (unread.isEmpty) return;
    ref
        .read(messageListProvider.notifier)
        .keepUnread(unread.map((m) => m.id));
    state = state.rebuild(
      (b) => b.messages.map(
        (m) => m.isNew ? m.rebuild((b) => b..timeRead = now) : m,
      ),
    );
    for (final m in unread) {
      await ref
          .read(notificationsProvider.notifier)
          .markMessageAsRead(m.id);
      unawaited(wrapper.send(
        "api/message/markAsRead",
        args: <String, dynamic>{"messageId": m.id},
      ));
    }
  }

  Future<void> markAsRead(int messageId) async {
    ref.read(messageListProvider.notifier).keepUnread([messageId]);
    state = state.rebuild((b) {
      if (messageId == b.showMessage) {
        b.showMessage = null;
      }
      final index = b.messages.build().indexWhere((m) => m.id == messageId);
      if (index != -1) {
        b.messages[index] =
            b.messages[index].rebuild((b) => b..timeRead = now);
      }
    });
    await ref.read(notificationsProvider.notifier).markMessageAsRead(messageId);
    unawaited(wrapper.send(
      "api/message/markAsRead",
      args: <String, dynamic>{"messageId": messageId},
    ));
  }

  /// Sends a confirmation for [messageId].
  ///
  /// [response] is [MessageResponseInfo.answerAgree] / [answerNotAgree], or
  /// `null` for a plain acknowledgement. [signature] is the typed name, only
  /// for messages that require one.
  ///
  /// Unlike [markAsRead] this is not optimistic: the answer is binding, so the
  /// server state wins. The portal answers with the full, updated message
  /// list.
  ///
  /// Returns whether the message counts as answered afterwards. A request that
  /// fails, or one the server acknowledges with nothing, must not read as
  /// success — the reader would think a binding confirmation had gone out.
  Future<bool> reply(
    int messageId, {
    String? response,
    String? signature,
  }) async {
    Object? failure;
    final dynamic result = await wrapper.send(
      "api/message/reply",
      args: <String, Object?>{
        "messageId": messageId,
        // The web frontend omits these keys rather than sending null; mirror
        // that so the backend sees the exact same request.
        "response": <String, Object?>{
          if (signature != null) "signature": signature,
          if (response != null) "response": response,
        },
      },
      onError: (error) => failure = error,
    );
    if (failure != null) return false;
    if (result is List) {
      state = _parseMessages(result);
    } else {
      // Anything but the list — an empty body included — says nothing about
      // whether the answer was taken. Asking the server beats guessing.
      await load();
    }
    return state.messages
            .firstWhereOrNull((message) => message.id == messageId)
            ?.responseInfo
            ?.answered ??
        false;
  }

  void _markDownloading(MessageAttachmentFile file) {
    final messageIndex =
        state.messages.indexWhere((m) => m.id == file.messageId);
    if (messageIndex == -1) return;
    state = state.rebuild((b) {
      b.messages[messageIndex] = b.messages[messageIndex].rebuild((b) {
        final attachmentIndex =
            b.attachments.build().indexWhere((a) => a.id == file.id);
        if (attachmentIndex != -1) {
          b.attachments[attachmentIndex] =
              b.attachments[attachmentIndex].rebuild(
            (b) => b..downloading = true,
          );
        }
      });
    });
  }

  void _markFileAvailable(MessageAttachmentFile file) {
    final messageIndex =
        state.messages.indexWhere((m) => m.id == file.messageId);
    if (messageIndex == -1) return;
    state = state.rebuild((b) {
      b.messages[messageIndex] = b.messages[messageIndex].rebuild((b) {
        final attachmentIndex =
            b.attachments.build().indexWhere((a) => a.id == file.id);
        if (attachmentIndex != -1) {
          b.attachments[attachmentIndex] =
              b.attachments[attachmentIndex].rebuild(
            (b) => b
              ..fileAvailable = file.fileAvailable
              ..downloading = false,
          );
        }
      });
    });
  }

  MessagesState _parseMessages(List json) {
    final messages = json
        .map((dynamic m) =>
            tryParse(getMap(m), (Map? m) => _parseMessage(m!, state)))
        .whereType<Message>()
        .toList();
    final ids = {for (final m in messages) m.id};
    return MessagesState(
      (b) => b
        ..messages = ListBuilder<Message>(messages)
        ..lastFetched = UtcDateTime.now()
        ..showMessage = state.showMessage
        // Stars exist only on this device, so a reload must not drop them.
        // A message gone from the portal takes its star along.
        ..starred = SetBuilder<int>(state.starred.where(ids.contains)),
    );
  }

  Message _parseMessage(Map json, MessagesState currentState) {
    final id = getInt(json["id"]);
    final oldMessage = currentState.messages.firstWhereOrNull(
      (m) => m.id == id,
    );
    // Preserve optimistic local read: if the server hasn't caught up yet
    // (timeRead still null) but we already marked it locally, keep the
    // local timestamp so the message doesn't flash back to "neu".
    final timeRead = json["timeRead"] != null
        ? UtcDateTime.parse(getString(json["timeRead"])!)
        : oldMessage?.timeRead;
    final message = MessageBuilder()
      ..subject = getString(json["subject"])
      ..text = getString(json["text"])
      ..timeSent = UtcDateTime.parse(getString(json["timeSent"])!)
      ..timeRead = timeRead
      ..recipientString = getString(json["recipientString"])
      ..fromName = getString(json["fromName"])
      // The portal files every message under incoming or outgoing; this is
      // the only field in the list that says which.
      ..outgoing = getBool(json["label_outgoing"]) ?? false
      ..archived = getBool(json["label_archived"]) ?? false
      ..archiveType = getInt(json["archiveMessageEnabled"]) ?? 0
      ..id = id
      ..responseInfo = _parseResponseInfo(json)?.toBuilder();
    final attachments = ListBuilder<MessageAttachmentFile>();
    for (final attachmentJson
        in getList(json["submissions"]) ?? <dynamic>[]) {
      final attachment =
          _parseAttachment(getMap(attachmentJson)!, oldMessage);
      if (attachment != null) {
        attachments.add(attachment);
      }
    }
    message.attachments = attachments;
    return message.build();
  }

  /// Maps the confirmation fields of a message, or `null` when the portal
  /// renders no controls for it.
  ///
  /// The two axes are independent: the buttons hang off `responseType` alone,
  /// the signature field off `signatureRequired` alone. `responseRequired` is
  /// deliberately not used as a gate -- signed messages carry a 0 there.
  MessageResponseInfo? _parseResponseInfo(Map json) {
    final type =
        getString(json["responseType"]) ?? MessageResponseInfo.typeRead;
    // The backend mixes ints and bools across these flags.
    final signatureRequired = getBool(json["signatureRequired"]) ?? false;
    if (type != MessageResponseInfo.typeAgree && !signatureRequired) {
      return null;
    }
    return MessageResponseInfo(
      (b) => b
        ..type = type
        ..responseRequired = getBool(json["responseRequired"]) ?? false
        ..signatureRequired = signatureRequired
        ..parentSignatureRequired =
            getBool(json["needsParentSignature"]) ?? false
        ..givenResponse = getString(json["response"])
        ..givenSignature = getString(json["responseSignature"])
        ..historyText = getString(json["historyString"])
        ..badge = getString(json["badge"]),
    );
  }

  MessageAttachmentFile? _parseAttachment(Map json, Message? oldMessage) {
    if (getString(json["type"]) != "file" ||
        getBool(json["isDownloadable"]) != true) {
      return null;
    }

    final id = getInt(json["id"]);
    final messageId = getInt(json["messageId"]);
    final originalName = getString(json["originalName"]);
    final file = getString(json["file"]);

    if ([id, messageId, originalName, file].contains(null)) {
      return null;
    }

    final oldAttachment = oldMessage?.attachments.firstWhereOrNull(
      (a) => a.id == id,
    );

    final attachment = MessageAttachmentFileBuilder()
      ..id = id
      ..messageId = messageId
      ..originalName = originalName
      ..file = file;
    if (oldAttachment?.file == file) {
      attachment.fileAvailable = oldAttachment!.fileAvailable;
    }
    return attachment.build();
  }
}

final messagesProvider =
    NotifierProvider<MessagesNotifier, MessagesState>(MessagesNotifier.new);

/// The orders the message list offers.
enum MessageSort { newest, oldest, sender }

/// What the message list shows and in which order — everything about it but
/// the messages themselves.
class MessageListView {
  final MessageCategory category;
  final MessageSort sort;

  /// While "unread only" is on: the messages that were unread when it was
  /// switched on, plus those read since. `null` while it is off.
  ///
  /// Opening a message marks it read. Filtering on [Message.isNew] alone would
  /// make it vanish from the list the moment it opens.
  final BuiltSet<int>? keptUnread;

  final bool starredOnly;

  const MessageListView({
    this.category = MessageCategory.incoming,
    this.sort = MessageSort.newest,
    this.keptUnread,
    this.starredOnly = false,
  });

  bool get unreadOnly => keptUnread != null;

  /// The messages to show, filtered and in order. [starred] holds the ids
  /// the reader marked.
  List<Message> apply(Iterable<Message> messages, BuiltSet<int> starred) {
    final shown = messages
        .where((m) =>
            category.includes(m) &&
            (!unreadOnly || m.isNew || keptUnread!.contains(m.id)) &&
            (!starredOnly || starred.contains(m.id)))
        .toList();
    int newestFirst(Message a, Message b) => b.timeSent.compareTo(a.timeSent);
    shown.sort(switch (sort) {
      MessageSort.newest => newestFirst,
      MessageSort.oldest => (a, b) => newestFirst(b, a),
      // Newest first within one sender.
      MessageSort.sender => (a, b) {
          final bySender =
              a.fromName.toLowerCase().compareTo(b.fromName.toLowerCase());
          return bySender != 0 ? bySender : newestFirst(a, b);
        },
    });
    return shown;
  }

  @override
  bool operator ==(Object other) =>
      other is MessageListView &&
      other.category == category &&
      other.sort == sort &&
      other.keptUnread == keptUnread &&
      other.starredOnly == starredOnly;

  @override
  int get hashCode => Object.hash(category, sort, keptUnread, starredOnly);
}

/// Folder, order and filters of the message list. Not saved: the app starts
/// on the received messages, newest first, unfiltered.
class MessageListNotifier extends Notifier<MessageListView> {
  @override
  MessageListView build() => const MessageListView();

  void showCategory(MessageCategory category) => state = MessageListView(
        category: category,
        sort: state.sort,
        keptUnread: state.keptUnread,
        starredOnly: state.starredOnly,
      );

  void sortBy(MessageSort sort) => state = MessageListView(
        category: state.category,
        sort: sort,
        keptUnread: state.keptUnread,
        starredOnly: state.starredOnly,
      );

  void showUnreadOnly(bool on) => state = MessageListView(
        category: state.category,
        sort: state.sort,
        keptUnread: on ? BuiltSet<int>() : null,
        starredOnly: state.starredOnly,
      );

  void showStarredOnly(bool on) => state = MessageListView(
        category: state.category,
        sort: state.sort,
        keptUnread: state.keptUnread,
        starredOnly: on,
      );

  /// Keeps [messageIds] under "unread only" once they are read. Called just
  /// before they are marked read; does nothing while the filter is off.
  void keepUnread(Iterable<int> messageIds) {
    final kept = state.keptUnread;
    if (kept == null) return;
    state = MessageListView(
      category: state.category,
      sort: state.sort,
      keptUnread: kept.rebuild((b) => b.addAll(messageIds)),
      starredOnly: state.starredOnly,
    );
  }

  /// Makes sure [message] is in the list: switches to its folder and drops
  /// the filters, if they hide it.
  void reveal(Message message, BuiltSet<int> starred) {
    if (state.apply([message], starred).isNotEmpty) return;
    state = MessageListView(
      category: state.category.includes(message)
          ? state.category
          : MessageCategory.of(message),
      sort: state.sort,
    );
  }
}

final messageListProvider =
    NotifierProvider<MessageListNotifier, MessageListView>(
        MessageListNotifier.new);
