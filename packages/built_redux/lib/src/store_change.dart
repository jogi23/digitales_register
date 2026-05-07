import 'dart:async';

import 'package:built_redux/src/action.dart';
import 'package:built_redux/src/store.dart';
import 'package:built_value/built_value.dart';

/// [StoreChange] is the payload for the [Store] subscription.
class StoreChange<State extends Built<State, StateBuilder>,
    StateBuilder extends Builder<State, StateBuilder>, P> {
  final State next;
  final State prev;
  final Action<P> action;

  StoreChange(State n, State p, Action<P> a)
      : next = n,
        prev = p,
        action = a;
}

/// [StoreChangeHandler] handles a change to the store after an action.
typedef StoreChangeHandler<P, State extends Built<State, StateBuilder>,
        StateBuilder extends Builder<State, StateBuilder>>
    = void Function(
  StoreChange<State, StateBuilder, P> storeChange,
);

/// [StoreChangeHandlerBuilder] allows you to listen to the [Store] and
/// perform handlers for a given set of actions with type safety.
class StoreChangeHandlerBuilder<
    State extends Built<State, StateBuilder>,
    StateBuilder extends Builder<State, StateBuilder>,
    Actions extends ReduxActions> {
  final _map = <String, StoreChangeHandler<dynamic, State, StateBuilder>>{};
  late StreamSubscription<StoreChange<State, StateBuilder, dynamic>>
      _subscription;

  /// Registers [handler] function to the given [actionName].
  void add<Payload>(ActionName<Payload> actionName,
      StoreChangeHandler<Payload, State, StateBuilder> handler) {
    _map[actionName.name] = (change) {
      handler(StoreChange<State, StateBuilder, Payload>(
        change.next,
        change.prev,
        change.action as Action<Payload>,
      ));
    };
  }

  /// [build] sets up a subscription to the registered actions.
  void build(Store<State, StateBuilder, Actions> store) {
    _subscription = store.stream
        .listen((StoreChange<State, StateBuilder, dynamic> storeChange) {
      final handler = _map[storeChange.action.name];
      if (handler != null) handler(storeChange);
    });
  }

  /// [dispose] cancels the subscription to the store.
  void dispose() {
    _subscription.cancel();
  }
}
