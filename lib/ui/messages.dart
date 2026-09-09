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

import 'dart:convert';

import 'package:badges/badges.dart' as badge;
import 'package:dr/app_state.dart';
import 'package:dr/ui/account_avatar_button.dart';
import 'package:dr/data.dart';
import 'package:dr/ui/animated_linear_progress_indicator.dart';
import 'package:dr/ui/last_fetched_overlay.dart';
import 'package:dr/ui/no_internet.dart';
import 'package:dr/util.dart';
import 'package:dr/l10n/l10n.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:quill_delta/quill_delta.dart';
import 'package:quill_delta_viewer/quill_delta_viewer.dart';
import 'package:responsive_scaffold/responsive_scaffold.dart';

class MessagesPage extends StatelessWidget {
  final MessagesState? state;
  final bool noInternet;
  final bool hasUnread;
  final void Function(MessageAttachmentFile message) onOpenFile;
  final void Function(Message message) onMarkAsRead;
  final void Function(Message message, {String? response, String? signature})
      onReply;
  final VoidCallback onMarkAllAsRead;
  final Future<void> Function() onRefresh;

  const MessagesPage({
    super.key,
    required this.state,
    required this.noInternet,
    required this.hasUnread,
    required this.onOpenFile,
    required this.onMarkAsRead,
    required this.onReply,
    required this.onMarkAllAsRead,
    required this.onRefresh,
  });
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: ResponsiveAppBar(
        title: Text(tr(context).messagesTitle),
        actions: [
          IconButton(
            icon: const Icon(Icons.done_all),
            tooltip: tr(context).messagesMarkAllRead,
            onPressed: hasUnread ? onMarkAllAsRead : null,
          ),
          const AccountAvatarButton(),
        ],
      ),
      body: state == null
          ? noInternet
              ? RefreshIndicator(
                  onRefresh: onRefresh,
                  child: const SingleChildScrollView(
                    physics: AlwaysScrollableScrollPhysics(),
                    child: SizedBox(
                      height: 400,
                      child: NoInternet(),
                    ),
                  ),
                )
              : const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: onRefresh,
              child: LastFetchedOverlay(
                lastFetched: state!.lastFetched,
                noInternet: noInternet,
                child: Stack(
                  children: <Widget>[
                    AnimatedLinearProgressIndicator(
                      show: state!.showMessage != null &&
                          !state!.messages
                              .any((m) => m.id == state!.showMessage),
                    ),
                    if (state!.messages.isEmpty)
                      Center(
                        child: Text(
                          tr(context).messagesEmpty,
                          style: Theme.of(context).textTheme.headlineMedium,
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ListView.builder(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: EdgeInsets.only(
                          bottom: MediaQuery.of(context).viewPadding.bottom),
                      itemCount: state!.messages.length,
                      itemBuilder: (context, i) {
                        final altColor = Theme.of(context)
                            .colorScheme
                            .surfaceContainerHighest
                            .withOpacity(0.75);
                        return MessageWidget(
                          message: state!.messages[i],
                          onOpenFile: onOpenFile,
                          onMarkAsRead: onMarkAsRead,
                          onReply: onReply,
                          noInternet: noInternet,
                          expand: state!.messages[i].id == state!.showMessage,
                          tileColor: i.isOdd ? altColor : null,
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}

class MessageWidget extends StatefulWidget {
  final Message message;
  final void Function(MessageAttachmentFile message) onOpenFile;
  final void Function(Message message) onMarkAsRead;
  final void Function(Message message, {String? response, String? signature})
      onReply;
  final bool noInternet;
  final bool expand;
  final Color? tileColor;

  const MessageWidget({
    super.key,
    required this.message,
    required this.onOpenFile,
    required this.noInternet,
    required this.onMarkAsRead,
    required this.onReply,
    required this.expand,
    this.tileColor,
  });

  @override
  _MessageWidgetState createState() => _MessageWidgetState();
}

class _MessageWidgetState extends State<MessageWidget> {
  late final bool initiallyExpanded;
  final ExpansibleController _controller = ExpansibleController();

  @override
  void initState() {
    super.initState();
    initiallyExpanded = widget.expand;
    if (initiallyExpanded) {
      WidgetsBinding.instance.addPostFrameCallback(
        (_) { if (mounted) widget.onMarkAsRead(widget.message); },
      );
    }
  }

  @override
  void didUpdateWidget(MessageWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.expand && !oldWidget.expand) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        _controller.expand();
        widget.onMarkAsRead(widget.message);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return ExpansionTile(
      controller: _controller,
      initiallyExpanded: initiallyExpanded,
      backgroundColor: widget.tileColor,
      collapsedBackgroundColor: widget.tileColor,
      onExpansionChanged: (expanded) {
        if (expanded && widget.message.isNew) {
          widget.onMarkAsRead(widget.message);
        }
      },
      title: Row(
        children: <Widget>[
          Expanded(
            child: Text(
              widget.message.subject,
              style: textTheme.titleMedium?.copyWith(
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
          ),
          if (widget.message.isNew)
            badge.Badge(
              badgeStyle: badge.BadgeStyle(
                shape: badge.BadgeShape.square,
                borderRadius: BorderRadius.circular(20),
              ),
              badgeContent: const Text(
                "neu",
                style: TextStyle(color: Colors.white),
              ),
            )
        ],
      ),
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: 16,
          ).copyWith(
            bottom: 8,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text.rich(
                TextSpan(
                  children: [
                    TextSpan(
                      text: tr(context).messagesSent,
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    TextSpan(
                        text: DateFormat("d.M.yy H:mm")
                            .format(widget.message.timeSent))
                  ],
                ),
              ),
              Text.rich(
                TextSpan(
                  children: [
                    TextSpan(
                      text: tr(context).messagesFrom,
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    TextSpan(text: widget.message.fromName)
                  ],
                ),
              ),
              Text.rich(
                TextSpan(
                  children: [
                    TextSpan(
                      text: tr(context).messagesTo,
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    TextSpan(text: widget.message.recipientString)
                  ],
                ),
              ),
              const Divider(),
              renderMessage(widget.message.text, context),
              if (widget.message.attachments.isNotEmpty) ...[
                const Divider(),
                Text(
                  widget.message.attachments.length > 1
                      ? tr(context).messagesAttachments
                      : tr(context).messagesAttachment,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ],
              ...[
                for (final attachment in widget.message.attachments)
                  [
                    Text(
                      attachment.originalName,
                    ),
                    AnimatedLinearProgressIndicator(
                      show: attachment.downloading,
                    ),
                    SizedBox(
                      width: double.infinity,
                      child: TextButton(
                        onPressed:
                            !attachment.fileAvailable && widget.noInternet
                                ? null
                                : () {
                                    widget.onOpenFile(attachment);
                                  },
                        child: const Text("Öffnen"),
                      ),
                    ),
                  ]
              ].intersperse(const Divider()),
              if (widget.message.responseInfo case final info?) ...[
                const Divider(),
                MessageResponseSection(
                  info: info,
                  noInternet: widget.noInternet,
                  onReply: ({String? response, String? signature}) =>
                      widget.onReply(
                    widget.message,
                    response: response,
                    signature: signature,
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

/// Renders the confirmation a message asks for: two buttons, a signature
/// field, or both.
///
/// Mirrors the portal: the buttons hang off the response type, the signature
/// field off [MessageResponseInfo.signatureRequired], and an empty signature
/// blocks sending.
class MessageResponseSection extends StatefulWidget {
  final MessageResponseInfo info;
  final bool noInternet;
  final void Function({String? response, String? signature}) onReply;

  const MessageResponseSection({
    super.key,
    required this.info,
    required this.noInternet,
    required this.onReply,
  });

  @override
  State<MessageResponseSection> createState() => _MessageResponseSectionState();
}

class _MessageResponseSectionState extends State<MessageResponseSection> {
  final TextEditingController _signature = TextEditingController();
  bool _sent = false;

  @override
  void dispose() {
    _signature.dispose();
    super.dispose();
  }

  bool get _canSend {
    if (_sent || widget.noInternet) return false;
    // The portal only checks for a non-empty name, it does not match it
    // against the account.
    return !widget.info.showSignatureField ||
        _signature.text.trim().isNotEmpty;
  }

  void _send(String? response) {
    setState(() => _sent = true);
    widget.onReply(
      response: response,
      signature: widget.info.showSignatureField
          ? _signature.text.trim()
          : null,
    );
  }

  @override
  Widget build(BuildContext context) {
    final info = widget.info;
    final theme = Theme.of(context);

    if (info.answered) {
      return _Hint(info.historyText ?? info.badge ?? tr(context).messageAlreadyConfirmed);
    }
    if (info.parentSignatureRequired) {
      return _Hint(tr(context).messageParentOnly);
    }
    if (info.unsupported) {
      return _Hint(tr(context).messageUnsupported);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (info.badge != null)
          Text(info.badge!, style: theme.textTheme.labelLarge),
        if (info.showSignatureField) ...[
          const SizedBox(height: 8),
          TextField(
            controller: _signature,
            enabled: !_sent,
            textCapitalization: TextCapitalization.words,
            decoration: InputDecoration(
              labelText: tr(context).messageSignaturePrompt,
              border: OutlineInputBorder(),
            ),
            onChanged: (_) => setState(() {}),
          ),
        ],
        const SizedBox(height: 8),
        if (info.showAgreeButtons)
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              OutlinedButton(
                onPressed: _canSend
                    ? () => _send(MessageResponseInfo.answerNotAgree)
                    : null,
                child: Text(tr(context).messageDisagree),
              ),
              const SizedBox(width: 8),
              FilledButton(
                onPressed: _canSend
                    ? () => _send(MessageResponseInfo.answerAgree)
                    : null,
                child: Text(tr(context).messageAgree),
              ),
            ],
          )
        else
          Align(
            alignment: Alignment.centerRight,
            child: FilledButton(
              onPressed: _canSend ? () => _send(null) : null,
              child: Text(tr(context).messageConfirm),
            ),
          ),
      ],
    );
  }
}

class _Hint extends StatelessWidget {
  final String text;
  const _Hint(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            fontStyle: FontStyle.italic,
          ),
    );
  }
}

Widget renderMessage(String msg, BuildContext context) {
  return QuillDeltaViewer(
      delta: Delta.fromJson(jsonDecode(msg)["ops"] as List));
}
