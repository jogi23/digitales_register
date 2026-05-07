import 'dart:async';

import 'package:built_redux/built_redux.dart';
import 'package:flutter/widgets.dart' hide Builder;

/// [Connect] maps state from the store to the local state that a given
/// component cares about.
typedef Connect<StoreState, LocalState> = LocalState Function(StoreState state);

/// [StoreConnectionBuilder] returns a widget given context, local state,
/// and actions.
typedef StoreConnectionBuilder<LocalState, Actions extends ReduxActions>
    = Widget Function(BuildContext context, LocalState state, Actions actions);

/// [StoreConnection] is a widget that rebuilds when the redux store has
/// triggered and the connect function yields a new result.
class StoreConnection<StoreState, Actions extends ReduxActions, LocalState>
    extends StoreConnector<StoreState, Actions, LocalState> {
  final Connect<StoreState, LocalState> _connect;
  final StoreConnectionBuilder<LocalState, Actions> _builder;

  const StoreConnection({
    required LocalState Function(StoreState state) connect,
    required Widget Function(
            BuildContext context, LocalState state, Actions actions)
        builder,
    super.key,
  })  : _connect = connect,
        _builder = builder;

  @protected
  @override
  LocalState connect(StoreState state) => _connect(state);

  @protected
  @override
  Widget build(BuildContext context, LocalState state, Actions actions) =>
      _builder(context, state, actions);
}

/// [StoreConnector] is a widget that rebuilds when the redux store has
/// triggered and the connect function yields a new result.
abstract class StoreConnector<StoreState, Actions extends ReduxActions,
    LocalState> extends StatefulWidget {
  const StoreConnector({super.key});

  @protected
  LocalState connect(StoreState state);

  @override
  State<StoreConnector<StoreState, Actions, LocalState>> createState() =>
      _StoreConnectorState<StoreState, Actions, LocalState>();

  @protected
  Widget build(BuildContext context, LocalState state, Actions actions);
}

class _StoreConnectorState<StoreState, Actions extends ReduxActions, LocalState>
    extends State<StoreConnector<StoreState, Actions, LocalState>> {
  StreamSubscription<SubstateChange<LocalState>>? _storeSub;
  LocalState? _state;

  Store get _store {
    final ReduxProvider? reduxProvider =
        context.dependOnInheritedWidgetOfExactType<ReduxProvider>();

    assert(reduxProvider != null,
        'Store was not found, make sure ReduxProvider is an ancestor of this component.');
    assert(reduxProvider!.store.state is StoreState,
        'Store found was not the correct type, make sure StoreConnector\'s generic for StoreState matches the state type of your built_redux store.');
    assert(reduxProvider!.store.actions is Actions,
        'Store found was not the correct type, make sure StoreConnector\'s generic for Actions matches the actions type of your built_redux store.');

    return reduxProvider!.store;
  }

  @override
  @mustCallSuper
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_storeSub != null) return;

    _state = widget.connect(_store.state as StoreState);

    _storeSub = _store
        .substateStream((state) => widget.connect(state as StoreState))
        .listen((change) {
      setState(() {
        _state = change.next;
      });
    });
  }

  @override
  @mustCallSuper
  void dispose() {
    _storeSub!.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) =>
      widget.build(context, _state as LocalState, _store.actions as Actions);
}

/// [ReduxProvider] provides access to the redux store to descendant widgets.
class ReduxProvider extends InheritedWidget {
  const ReduxProvider({super.key, required this.store, required super.child});

  final Store store;

  @override
  bool updateShouldNotify(ReduxProvider old) => store != old.store;
}
