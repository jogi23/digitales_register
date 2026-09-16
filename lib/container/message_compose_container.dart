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

import 'package:dr/data.dart';
import 'package:dr/providers/message_compose_provider.dart';
import 'package:dr/providers/no_internet_provider.dart';
import 'package:dr/services/message_export.dart' show plainTextOf;
import 'package:dr/ui/message_compose.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Writes a new message, or an answer to [answerTo].
class MessageComposeContainer extends ConsumerStatefulWidget {
  final Message? answerTo;

  const MessageComposeContainer({super.key, this.answerTo});

  @override
  ConsumerState<MessageComposeContainer> createState() =>
      _MessageComposeContainerState();
}

class _MessageComposeContainerState
    extends ConsumerState<MessageComposeContainer> {
  @override
  void initState() {
    super.initState();
    // After the first build, whose watch keeps the provider alive.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      unawaited(ref
          .read(messageComposeProvider.notifier)
          .start(answerTo: widget.answerTo?.fromUserId));
    });
  }

  /// Asks the system for a file and hands it to the provider.
  ///
  /// Anything goes: the portal takes pictures as readily as PDFs, and what a
  /// school allows is its own business.
  Future<void> _pickAttachment(MessageComposeNotifier notifier) async {
    final picked = await FilePicker.pickFiles();
    final file = picked?.files.firstOrNull;
    final path = file?.path;
    if (file == null || path == null) return;
    await notifier.attach(path: path, name: file.name, size: file.size);
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(messageComposeProvider);
    final notifier = ref.read(messageComposeProvider.notifier);
    final answerTo = widget.answerTo;
    return MessageComposePage(
      state: state,
      noInternet: ref.watch(noInternetProvider),
      isAnswer: answerTo != null,
      initialSubject: answerTo == null ? '' : answerSubject(answerTo.subject),
      onRetry: () => unawaited(notifier.start(answerTo: answerTo?.fromUserId)),
      quotedText: answerTo == null ? null : plainTextOf(answerTo.text),
      onSearch: notifier.search,
      onAdd: (recipient) => unawaited(notifier.add(recipient)),
      onRemove: (recipient) => unawaited(notifier.remove(recipient)),
      onAttach: () => unawaited(_pickAttachment(notifier)),
      onDetach: notifier.detach,
      onToggle: (group, person) =>
          notifier.toggle(group.recipientKey, person.id),
      onTickAll: notifier.tickAll,
      onSend: notifier.send,
    );
  }
}
