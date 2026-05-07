import 'dart:async';

import 'package:built_redux/src/action.dart';
import 'package:built_redux/src/store.dart';
import 'package:built_redux/src/typedefs.dart';
import 'package:built_value/built_value.dart';

/// [MiddlewareApi] gives middleware access to the store's state and actions.
class MiddlewareApi<
    State extends Built<State, StateBuilder>,
    StateBuilder extends Builder<State, StateBuilder>,
    Actions extends ReduxActions> {
  final Store<State, StateBuilder, Actions> _store;

  MiddlewareApi(Store<State, StateBuilder, Actions> store) : _store = store;

  State get state => _store.state;
  Actions get actions => _store.actions;
}

/// [MiddlewareHandler] is a typed callback for a specific action in middleware.
typedef MiddlewareHandler<
        State extends Built<State, StateBuilder>,
        StateBuilder extends Builder<State, StateBuilder>,
        Actions extends ReduxActions,
        Payload>
    = FutureOr<void> Function(MiddlewareApi<State, StateBuilder, Actions> api,
        ActionHandler next, Action<Payload> action);

/// [MiddlewareBuilder] allows you to build middleware that handles many
/// different actions with type safety.
class MiddlewareBuilder<
    State extends Built<State, StateBuilder>,
    StateBuilder extends Builder<State, StateBuilder>,
    Actions extends ReduxActions> {
  final _map =
      <String, MiddlewareHandler<State, StateBuilder, Actions, dynamic>>{};

  void add<P>(ActionName<P> actionName,
      MiddlewareHandler<State, StateBuilder, Actions, P> handler) {
    _map[actionName.name] =
        (api, next, action) => handler(api, next, action as Action<P>);
  }

  Middleware<State, StateBuilder, Actions> build() =>
      (MiddlewareApi<State, StateBuilder, Actions> api) =>
          (ActionHandler next) => (Action<dynamic> action) async {
                final handler = _map[action.name];
                if (handler != null) {
                  await handler(api, next, action);
                } else {
                  await next(action);
                }
              };

  void combine(MiddlewareBuilder<State, StateBuilder, Actions> other) {
    _map.addAll(other._map);
  }
}
