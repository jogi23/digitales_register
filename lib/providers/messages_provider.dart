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
    }
  }

  void select(int messageId) {
    state = state.rebuild((b) => b..showMessage = messageId);
  }

  void clearSelection() {
    state = state.rebuild((b) => b..showMessage = null);
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
    final unread = state.messages.where((m) => m.timeRead == null).toList();
    if (unread.isEmpty) return;
    state = state.rebuild(
      (b) => b.messages.map(
        (m) => m.timeRead == null ? m.rebuild((b) => b..timeRead = now) : m,
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
    return MessagesState(
      (b) => b
        ..messages = ListBuilder<Message>(messages)
        ..lastFetched = UtcDateTime.now(),
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
      ..id = id;
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
