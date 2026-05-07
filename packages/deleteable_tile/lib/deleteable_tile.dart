import 'package:flutter/material.dart';

/// A widget that animates when appearing and disappearing.
///
/// A trailing IconButton is placed next to [child], which triggers the
/// deletion.
///
/// See also:
///  * Deleteable, which can be customized to a greater extend.
class DeleteableTile extends StatelessWidget {
  final Widget child;
  final Widget icon;

  /// Called after this widget has disappeared. If [null], the trailing
  /// IconButton will be disabled.
  final VoidCallback? onDeleted;

  /// Describes how to align the child when resizing.
  ///
  /// A value of -1.0 indicates the top.
  /// A value of 1.0 indicates the bottom.
  /// A value of 0.0 (the default) indicates the center.
  final double axisAlignment;

  final bool showEntryAnimation, showExitAnimation;

  final Duration duration;

  const DeleteableTile({
    super.key,
    this.onDeleted,
    this.duration = const Duration(milliseconds: 250),
    required this.child,
    this.axisAlignment = 0,
    this.showEntryAnimation = true,
    this.showExitAnimation = true,
    this.icon = const Icon(Icons.delete),
  });

  @override
  Widget build(BuildContext context) {
    return Deleteable(
      showEntryAnimation: showEntryAnimation,
      showExitAnimation: showExitAnimation,
      axisAlignment: axisAlignment,
      duration: duration,
      builder: (context, onDelete) => Row(
        children: [
          Expanded(child: child),
          IconButton(
            icon: icon,
            onPressed: onDeleted != null
                ? () async {
                    await onDelete();
                    onDeleted!();
                  }
                : null,
          )
        ],
      ),
    );
  }
}

typedef DeleteableBuilder = Widget Function(
  BuildContext context,
  FutureVoidCallback delete,
);

typedef FutureVoidCallback = Future<void> Function();

/// A customizable widget that animates when appearing and disappearing.
class Deleteable extends StatefulWidget {
  /// Builds the child.
  ///
  /// Call [onDelete] to trigger the deletion animation.
  final DeleteableBuilder builder;
  final Duration duration;
  final double axisAlignment;
  final bool showEntryAnimation, showExitAnimation;

  const Deleteable({
    super.key,
    required this.builder,
    this.duration = const Duration(milliseconds: 250),
    this.axisAlignment = 0,
    this.showEntryAnimation = true,
    this.showExitAnimation = true,
  });

  @override
  State<Deleteable> createState() => _DeleteableState();
}

class _DeleteableState extends State<Deleteable>
    with SingleTickerProviderStateMixin, AutomaticKeepAliveClientMixin {
  late AnimationController _controller;
  bool _deleted = false;

  @override
  void initState() {
    _controller = AnimationController(vsync: this, value: 0);
    if (widget.showEntryAnimation) {
      _controller.animateTo(
        1,
        duration: widget.duration,
        curve: Curves.ease,
      );
    } else {
      _controller.value = 1;
    }
    super.initState();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    assert(() {
      if (_deleted) {
        assert(_controller.status == AnimationStatus.completed);
        throw FlutterError(
            'A deleted Deleteable widget is still part of the tree.\n'
            'Make sure to immediately remove the widget from the application\n'
            'once it has been removed.');
      }
      return true;
    }());
    return SizeTransition(
      sizeFactor: _controller,
      axisAlignment: widget.axisAlignment,
      child: widget.builder(
        context,
        () async {
          if (widget.showExitAnimation) {
            await _controller.animateTo(
              0,
              duration: widget.duration,
              curve: Curves.ease,
            );
            _deleted = true;
          }
        },
      ),
    );
  }

  @override
  bool get wantKeepAlive => true;
}
