import 'dart:async';

import 'package:built_redux/src/action.dart';
import 'package:built_redux/src/middleware.dart';
import 'package:built_redux/src/store_change.dart';
import 'package:built_redux/src/typedefs.dart';
import 'package:built_value/built_value.dart';

/// [Store] is the container of your state. It listens for actions, invokes
/// reducers, and publishes changes to the state.
class Store<
    State extends Built<State, StateBuilder>,
    StateBuilder extends Builder<State, StateBuilder>,
    Actions extends ReduxActions> {
  final StreamController<StoreChange<State, StateBuilder, dynamic>>
      _stateController = StreamController.broadcast();

  State _state;
  final Actions _actions;

  Store(
    Reducer<State, StateBuilder, dynamic> reducer,
    State defaultState,
    Actions actions, {
    Iterable<Middleware<State, StateBuilder, Actions>> middleware = const [],
  })  : _state = defaultState,
        _actions = actions {
    final api = MiddlewareApi<State, StateBuilder, Actions>(this);

    ActionHandler handler = (action) async {
      final state = _state.rebuild((b) => reducer(_state, action, b));
      if (_state == state) return;
      if (!_stateController.isClosed) {
        _stateController.add(
            StoreChange<State, StateBuilder, dynamic>(state, _state, action));
      }
      _state = state;
    };

    if (middleware.isNotEmpty) {
      final Iterable<NextActionHandler> chain = middleware.map((m) => m(api));
      final NextActionHandler combinedMiddleware = chain.reduce(
        (composed, middleware) => (handler) => composed(middleware(handler)),
      );
      handler = combinedMiddleware(handler);
    }

    actions.setDispatcher(handler);
  }

  /// [dispose] closes the state stream.
  Future<void> dispose() async {
    await _stateController.close();
  }

  /// [replaceState] replaces the state of your store.
  void replaceState(State state) {
    if (_state != state) {
      _stateController.add(StoreChange<State, StateBuilder, dynamic>(
          state, _state, Action<void>('replaceState', null)));
      _state = state;
    }
  }

  /// [state] returns the current state.
  State get state => _state;

  /// [stream] returns a stream that fires whenever the state changes.
  Stream<StoreChange<State, StateBuilder, dynamic>> get stream =>
      _stateController.stream;

  /// [actions] returns the synced actions.
  Actions get actions => _actions;

  /// [nextState] is a stream which has a payload of the next state value.
  Stream<State> get nextState => stream
      .map((StoreChange<State, StateBuilder, dynamic> change) => change.next);

  /// [substateStream] returns a stream to the state returned by the mapper.
  Stream<SubstateChange<Substate>> substateStream<Substate>(
    StateMapper<State, StateBuilder, Substate> mapper,
  ) =>
      stream
          .map((c) => SubstateChange<Substate>(
                mapper(c.prev),
                mapper(c.next),
              ))
          .where((c) => c.prev != c.next);

  /// [nextSubstate] is a stream with a payload of the next subState value.
  Stream<Substate> nextSubstate<Substate>(
    StateMapper<State, StateBuilder, Substate> mapper,
  ) =>
      substateStream(mapper)
          .map((SubstateChange<Substate> change) => change.next);

  /// [actionStream] returns a stream that fires when a state change is caused
  /// by the action with the name provided.
  Stream<StoreChange<State, StateBuilder, Payload>> actionStream<Payload>(
          ActionName<Payload> actionName) =>
      stream
          .where((c) => c.action.name == actionName.name)
          .map((c) => StoreChange<State, StateBuilder, Payload>(
                c.next,
                c.prev,
                c.action as Action<Payload>,
              ));
}
