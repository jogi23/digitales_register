import 'dart:async';

/// [Action] is the object passed to your reducer to signify the state change
/// that needs to take place. Action [name]s should always be unique.
class Action<Payload> {
  /// A unique action name.
  final String name;

  /// The actions payload.
  final Payload payload;

  Action(this.name, this.payload);

  @override
  String toString() => 'Action {\n  name: $name,\n  payload: $payload,\n}';
}

// Dispatches an action to the store
typedef Dispatcher<P> = FutureOr<void> Function(Action<P> action);

/// [ActionDispatcher] dispatches an action with the name provided to the
/// constructor and the payload supplied when called.
class ActionDispatcher<P> {
  late Dispatcher _dispatcher;
  final String _name;

  String get name => _name;

  Future<void> call(P payload) async =>
      await _dispatcher(Action<P>(_name, payload));

  ActionDispatcher(this._name);

  void setDispatcher(Dispatcher dispatcher) {
    _dispatcher = dispatcher;
  }
}

/// [VoidActionDispatcher] dispatches an action with no payload.
class VoidActionDispatcher {
  late Dispatcher _dispatcher;
  final String _name;

  String get name => _name;

  Future<void> call() async => await _dispatcher(Action<void>(_name, null));

  VoidActionDispatcher(this._name);

  void setDispatcher(Dispatcher dispatcher) {
    _dispatcher = dispatcher;
  }
}

/// [ReduxActions] is a container for all of your applications actions.
abstract class ReduxActions {
  void setDispatcher(Dispatcher dispatcher);
}

/// [ActionName] is an object that simply contains the action name but is typed
/// with a generic that is the same as the relative [ActionDispatcher]s payload
/// generic.
class ActionName<T> {
  String name;
  ActionName(this.name);
}
