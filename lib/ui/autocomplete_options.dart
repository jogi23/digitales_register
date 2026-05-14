// Copyright (C) 2026 Johannes Feichter
// Copied from the flutter framework

// The default Material-style Autocomplete options.
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

class AutocompleteOptions<T extends Object> extends StatelessWidget {
  const AutocompleteOptions({
    super.key,
    required this.displayStringForOption,
    required this.onSelected,
    required this.options,
    required this.maxOptionsHeight,
    required this.width,
  });

  final AutocompleteOptionToString<T> displayStringForOption;

  final AutocompleteOnSelected<T> onSelected;

  final Iterable<T> options;
  final double maxOptionsHeight;
  final double width;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.topLeft,
      child: Material(
        elevation: 4.0,
        child: ConstrainedBox(
          constraints:
              BoxConstraints(maxHeight: maxOptionsHeight, maxWidth: width),
          child: Scrollbar(
            child: ListView.builder(
              padding: EdgeInsets.zero,
              shrinkWrap: true,
              itemCount: options.length,
              itemBuilder: (BuildContext context, int index) {
                final T option = options.elementAt(index);
                return InkWell(
                  onTap: () {
                    onSelected(option);
                  },
                  child: _AutocompleteOptionItem(
                    index: index,
                    child: Text(displayStringForOption(option)),
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}

/// A stateful list item that only schedules [Scrollable.ensureVisible] when
/// the highlighted state transitions from false → true. This prevents the
/// [addPostFrameCallback] from being re-registered every frame during a scroll
/// animation, which would cause [pumpAndSettle] to never settle.
class _AutocompleteOptionItem extends StatefulWidget {
  const _AutocompleteOptionItem({
    required this.index,
    required this.child,
  });

  final int index;
  final Widget child;

  @override
  State<_AutocompleteOptionItem> createState() =>
      _AutocompleteOptionItemState();
}

class _AutocompleteOptionItemState extends State<_AutocompleteOptionItem> {
  bool _wasHighlighted = false;

  @override
  Widget build(BuildContext context) {
    final bool highlight =
        AutocompleteHighlightedOption.of(context) == widget.index;

    if (highlight && !_wasHighlighted) {
      _wasHighlighted = true;
      SchedulerBinding.instance.addPostFrameCallback((_) {
        if (mounted) Scrollable.ensureVisible(context, alignment: 0.5);
      });
    } else if (!highlight) {
      _wasHighlighted = false;
    }

    return Container(
      color: highlight ? Theme.of(context).focusColor : null,
      padding: const EdgeInsets.all(16.0),
      child: widget.child,
    );
  }
}
