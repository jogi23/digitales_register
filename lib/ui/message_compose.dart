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

import 'package:dr/l10n/l10n.dart';
import 'package:dr/providers/message_compose_provider.dart';
import 'package:dr/ui/snack_bar.dart';
import 'package:flutter/material.dart';

/// The role of a recipient, from the translatable part of its `contextstr`.
///
/// The literal parts only repeat the name. Keys the app does not know are
/// left out rather than shown raw.
String recipientRole(L l, List<ContextFragment> context) => [
      for (final fragment in context)
        if (fragment.translate)
          switch (fragment.text) {
            'message.recipients.teacher' => l.messageRecipientTeacher,
            'message.recipients.secretary' => l.messageRecipientSecretary,
            _ => '',
          },
    ].where((role) => role.isNotEmpty).join(', ');

/// Writes a message: recipients, the people behind them, subject and text.
class MessageComposePage extends StatefulWidget {
  final MessageComposeState state;
  final bool noInternet;

  /// The subject to start with, for an answer.
  final String initialSubject;

  final Future<List<MessageRecipient>> Function(String filter) onSearch;
  final ValueChanged<MessageRecipient> onAdd;
  final ValueChanged<MessageRecipient> onRemove;
  final void Function(RecipientGroup group, RecipientPerson person) onToggle;
  final ValueChanged<bool> onTickAll;

  /// Sends; `null` when the portal took the message, otherwise its error key,
  /// empty without one.
  final Future<String?> Function({
    required String subject,
    required String text,
  }) onSend;

  const MessageComposePage({
    super.key,
    required this.state,
    required this.noInternet,
    required this.initialSubject,
    required this.onSearch,
    required this.onAdd,
    required this.onRemove,
    required this.onToggle,
    required this.onTickAll,
    required this.onSend,
  });

  @override
  State<MessageComposePage> createState() => _MessageComposePageState();
}

class _MessageComposePageState extends State<MessageComposePage> {
  late final _subject = TextEditingController(text: widget.initialSubject);
  final _text = TextEditingController();
  final _search = TextEditingController();
  Timer? _debounce;
  var _hits = const <MessageRecipient>[];
  var _searchedFor = '';
  String? _error;

  /// Set once the page is on its way out, so the draft guard lets it go.
  var _leaving = false;

  @override
  void dispose() {
    _debounce?.cancel();
    _subject.dispose();
    _text.dispose();
    _search.dispose();
    super.dispose();
  }

  bool get _hasDraft =>
      _text.text.trim().isNotEmpty ||
      (_subject.text.trim().isNotEmpty &&
          _subject.text != widget.initialSubject);

  bool get _canSend {
    final state = widget.state;
    return state.allowed &&
        !state.sending &&
        !state.loadingDetails &&
        !widget.noInternet &&
        state.selectedCount > 0 &&
        _subject.text.trim().isNotEmpty &&
        _text.text.trim().isNotEmpty;
  }

  void _onSearchChanged(String value) {
    _debounce?.cancel();
    // Typing on asks once, after a pause.
    _debounce = Timer(const Duration(milliseconds: 300), () async {
      final filter = value.trim();
      final hits = filter.length < 2
          ? const <MessageRecipient>[]
          : await widget.onSearch(filter);
      if (!mounted || _search.text.trim() != filter) return;
      setState(() {
        _hits = hits;
        _searchedFor = filter.length < 2 ? '' : filter;
      });
    });
  }

  void _add(MessageRecipient recipient) {
    widget.onAdd(recipient);
    _search.clear();
    setState(() {
      _hits = const [];
      _searchedFor = '';
    });
  }

  void _leave() {
    setState(() => _leaving = true);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) Navigator.of(context).pop();
    });
  }

  Future<void> _send() async {
    final l = tr(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l.messageSendConfirmTitle),
        content: Text(l.messageSendConfirm(widget.state.selectedCount)),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(l.commonCancel),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(l.messageSend),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    setState(() => _error = null);
    final error = await widget.onSend(
      subject: _subject.text.trim(),
      text: _text.text.trim(),
    );
    if (!mounted) return;
    if (error == null) {
      showSnackBar(l.messageSent);
      _leave();
    } else {
      setState(() => _error =
          error.isEmpty ? l.messageSendFailed : l.messageSendRejected(error));
    }
  }

  Future<void> _confirmDiscard() async {
    final l = tr(context);
    final discard = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l.messageComposeDiscardTitle),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(l.commonCancel),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(l.messageComposeDiscard),
          ),
        ],
      ),
    );
    if (discard == true && mounted) _leave();
  }

  @override
  Widget build(BuildContext context) {
    final l = tr(context);
    final state = widget.state;
    return PopScope(
      // A stray back gesture does not throw typed text away.
      canPop: _leaving || !_hasDraft,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _confirmDiscard();
      },
      child: Scaffold(
        appBar: AppBar(title: Text(l.messageComposeTitle)),
        body: !state.ready
            ? const Center(child: CircularProgressIndicator())
            : !state.allowed
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Text(
                        l.messageComposeNotAllowed,
                        textAlign: TextAlign.center,
                      ),
                    ),
                  )
                : _form(context, l, state),
      ),
    );
  }

  Widget _form(BuildContext context, L l, MessageComposeState state) {
    final theme = Theme.of(context);
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text(l.messageComposeRecipients, style: theme.textTheme.titleSmall),
        const SizedBox(height: 8),
        if (state.recipients.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Wrap(
              spacing: 8,
              runSpacing: 4,
              children: [
                for (final recipient in state.recipients)
                  InputChip(
                    avatar: Icon(
                      recipient.isGroup
                          ? Icons.groups_outlined
                          : Icons.person_outline,
                      size: 18,
                    ),
                    label: Text(recipient.name),
                    onDeleted:
                        state.sending ? null : () => widget.onRemove(recipient),
                  ),
              ],
            ),
          ),
        TextField(
          controller: _search,
          enabled: !state.sending,
          decoration: InputDecoration(
            labelText: l.messageComposeSearch,
            helperText: l.messageComposeSearchHelper,
            prefixIcon: const Icon(Icons.search),
            border: const OutlineInputBorder(),
          ),
          onChanged: _onSearchChanged,
        ),
        if (_searchedFor.isNotEmpty && _hits.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Text(l.messageComposeNoHits),
          ),
        for (final hit in _hits)
          ListTile(
            leading: Icon(
              hit.isGroup ? Icons.groups_outlined : Icons.person_outline,
            ),
            title: Text(hit.name),
            subtitle: switch (recipientRole(l, hit.context)) {
              '' => null,
              final role => Text(role),
            },
            trailing: const Icon(Icons.add),
            enabled: !state.recipients.any((r) => r.key == hit.key),
            onTap: () => _add(hit),
          ),
        if (state.loadingDetails)
          const Padding(
            padding: EdgeInsets.only(top: 8),
            child: LinearProgressIndicator(),
          ),
        if (state.groups.isNotEmpty) ...[
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: Text(
                  l.messageComposeSelected(
                    state.selectedCount,
                    state.peopleCount,
                  ),
                  style: theme.textTheme.titleSmall,
                ),
              ),
              TextButton(
                onPressed: state.sending ? null : () => widget.onTickAll(true),
                child: Text(l.messageComposeTickAll),
              ),
              TextButton(
                onPressed: state.sending ? null : () => widget.onTickAll(false),
                child: Text(l.messageComposeTickNone),
              ),
            ],
          ),
          for (final group in state.groups) ...[
            // A single person needs no heading of their own.
            if (group.people.length > 1)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(group.name, style: theme.textTheme.labelLarge),
              ),
            for (final person in group.people)
              CheckboxListTile(
                dense: true,
                contentPadding: EdgeInsets.zero,
                controlAffinity: ListTileControlAffinity.leading,
                value: person.selected,
                title: Text(person.name),
                onChanged: person.disabled || state.sending
                    ? null
                    : (_) => widget.onToggle(group, person),
              ),
          ],
        ],
        const SizedBox(height: 16),
        TextField(
          controller: _subject,
          enabled: !state.sending,
          textCapitalization: TextCapitalization.sentences,
          decoration: InputDecoration(
            labelText: l.messageComposeSubject,
            border: const OutlineInputBorder(),
          ),
          onChanged: (_) => setState(() {}),
        ),
        const SizedBox(height: 16),
        TextField(
          controller: _text,
          enabled: !state.sending,
          minLines: 6,
          maxLines: null,
          keyboardType: TextInputType.multiline,
          textCapitalization: TextCapitalization.sentences,
          decoration: InputDecoration(
            labelText: l.messageComposeText,
            alignLabelWithHint: true,
            border: const OutlineInputBorder(),
          ),
          onChanged: (_) => setState(() {}),
        ),
        if (_error case final error?)
          Padding(
            padding: const EdgeInsets.only(top: 12),
            child: Text(
              error,
              style: theme.textTheme.bodyMedium
                  ?.copyWith(color: theme.colorScheme.error),
            ),
          ),
        const SizedBox(height: 16),
        if (state.sending)
          const Padding(
            padding: EdgeInsets.only(bottom: 8),
            child: LinearProgressIndicator(),
          ),
        FilledButton.icon(
          onPressed: _canSend ? _send : null,
          icon: const Icon(Icons.send),
          label: Text(l.messageSend),
        ),
      ],
    );
  }
}
