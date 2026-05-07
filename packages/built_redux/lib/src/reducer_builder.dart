import 'package:built_collection/built_collection.dart';
import 'package:built_redux/src/action.dart';
import 'package:built_redux/src/typedefs.dart';
import 'package:built_value/built_value.dart';

/// [ReducerBuilder] allows you to build a reducer that handles many different
/// actions with many different payload types, while maintaining type safety.
class ReducerBuilder<State extends Built<State, StateBuilder>,
    StateBuilder extends Builder<State, StateBuilder>> {
  final _map = <String, Reducer<State, StateBuilder, dynamic>>{};

  ReducerBuilder();

  /// Registers [reducer] function to the given [actionName].
  void add<Payload>(ActionName<Payload> actionName,
      Reducer<State, StateBuilder, Payload> reducer) {
    _add(actionName.name, reducer);
  }

  void _add<Payload>(
      String name, Reducer<State, StateBuilder, Payload> reducer) {
    final oldReducer = _map[name];
    _map[name] = (state, action, builder) {
      if (oldReducer != null) oldReducer(state, action, builder);
      reducer(state, action as Action<Payload>, builder);
    };
  }

  void _addAll(Map<String, Reducer<State, StateBuilder, dynamic>> map) {
    for (final entry in map.entries) {
      _add<dynamic>(entry.key, entry.value);
    }
  }

  void combine(ReducerBuilder<State, StateBuilder> other) {
    _addAll(other._map);
  }

  @pragma('dart2js:noInline')
  void combineNested<N extends Built<N, NB>, NB extends Builder<N, NB>>(
      NestedReducerBuilder<State, StateBuilder, N, NB> nested) {
    _addAll(nested._map);
  }

  void combineAbstract(
      Map<String, Reducer<State, StateBuilder, dynamic>> other) {
    _addAll(other);
  }

  void combineList<T>(ListReducerBuilder<State, StateBuilder, T> other) {
    _addAll(other._map);
  }

  void combineListMultimap<K, V>(
      ListMultimapReducerBuilder<State, StateBuilder, K, V> other) {
    _addAll(other._map);
  }

  void combineMap<K, V>(MapReducerBuilder<State, StateBuilder, K, V> other) {
    _addAll(other._map);
  }

  void combineSet<T>(SetReducerBuilder<State, StateBuilder, T> other) {
    _addAll(other._map);
  }

  void combineSetMultimap<K, V>(
      SetMultimapReducerBuilder<State, StateBuilder, K, V> other) {
    _addAll(other._map);
  }

  Reducer<State, StateBuilder, dynamic> build() =>
      (State state, Action<dynamic> action, StateBuilder builder) {
        final reducer = _map[action.name];
        if (reducer != null) reducer(state, action, builder);
      };
}

typedef Mapper<State, NestedState> = NestedState Function(State state);

/// [NestedReducerBuilder] allows you to build a reducer that rebuilds built
/// values nested within your main app state model.
class NestedReducerBuilder<
    State extends Built<State, StateBuilder>,
    StateBuilder extends Builder<State, StateBuilder>,
    NestedState extends Built<NestedState, NestedStateBuilder>,
    NestedStateBuilder extends Builder<NestedState, NestedStateBuilder>> {
  final _map = <String, Reducer<State, StateBuilder, dynamic>>{};
  final Mapper<State, NestedState> _stateMapper;
  final Mapper<StateBuilder, NestedStateBuilder> _builderMapper;

  NestedReducerBuilder(this._stateMapper, this._builderMapper);

  void add<Payload>(ActionName<Payload> actionName,
      Reducer<NestedState, NestedStateBuilder, Payload> reducer) {
    _add(actionName.name, reducer);
  }

  void _add<Payload>(
      String name, Reducer<NestedState, NestedStateBuilder, Payload> reducer) {
    final oldReducer = _map[name];
    _map[name] = (state, action, builder) {
      if (oldReducer != null) oldReducer(state, action, builder);
      reducer(
        _stateMapper(state),
        action as Action<Payload>,
        _builderMapper(builder),
      );
    };
  }

  void combineReducerBuilder(
      ReducerBuilder<NestedState, NestedStateBuilder> other) {
    for (final entry in other._map.entries) {
      _add<dynamic>(entry.key, entry.value);
    }
  }
}

/// [AbstractReducerBuilder] returns a reducer builder that rebuilds an
/// abstract, or mixed in, piece of state.
class AbstractReducerBuilder<AState, AStateBuilder> {
  final _map = <String, CReducer<AState, AStateBuilder, dynamic>>{};

  void add<Payload>(ActionName<Payload> actionName,
      CReducer<AState, AStateBuilder, Payload> reducer) {
    final oldReducer = _map[actionName.name];
    _map[actionName.name] = (state, action, builder) {
      if (oldReducer != null) oldReducer(state, action, builder);
      reducer(state, action as Action<Payload>, builder);
    };
  }

  Map<String, CReducer<AState, AStateBuilder, dynamic>> build() => _map;
}

/// This is the Reducer typedef without the Built/Builder constraints.
typedef CReducer<AState, AStateBuilder, P> = void Function(
    AState state, Action<P> action, AStateBuilder builder);

class ListReducerBuilder<State extends Built<State, StateBuilder>,
    StateBuilder extends Builder<State, StateBuilder>, T> {
  final _map = <String, Reducer<State, StateBuilder, dynamic>>{};
  final Mapper<State, BuiltList<T>> _stateMapper;
  final Mapper<StateBuilder, ListBuilder<T>> _builderMapper;

  ListReducerBuilder(this._stateMapper, this._builderMapper);

  void add<Payload>(ActionName<Payload> actionName,
      CReducer<BuiltList<T>, ListBuilder<T>, Payload> reducer) {
    final oldReducer = _map[actionName.name];
    _map[actionName.name] = (state, action, builder) {
      if (oldReducer != null) oldReducer(state, action, builder);
      reducer(_stateMapper(state), action as Action<Payload>,
          _builderMapper(builder));
    };
  }
}

class ListMultimapReducerBuilder<State extends Built<State, StateBuilder>,
    StateBuilder extends Builder<State, StateBuilder>, K, V> {
  final _map = <String, Reducer<State, StateBuilder, dynamic>>{};
  final Mapper<State, BuiltListMultimap<K, V>> _stateMapper;
  final Mapper<StateBuilder, ListMultimapBuilder<K, V>> _builderMapper;

  ListMultimapReducerBuilder(this._stateMapper, this._builderMapper);

  void add<Payload>(
      ActionName<Payload> actionName,
      CReducer<BuiltListMultimap<K, V>, ListMultimapBuilder<K, V>, Payload>
          reducer) {
    final oldReducer = _map[actionName.name];
    _map[actionName.name] = (state, action, builder) {
      if (oldReducer != null) oldReducer(state, action, builder);
      reducer(_stateMapper(state), action as Action<Payload>,
          _builderMapper(builder));
    };
  }
}

class MapReducerBuilder<State extends Built<State, StateBuilder>,
    StateBuilder extends Builder<State, StateBuilder>, K, V> {
  final _map = <String, Reducer<State, StateBuilder, dynamic>>{};
  final Mapper<State, BuiltMap<K, V>> _stateMapper;
  final Mapper<StateBuilder, MapBuilder<K, V>> _builderMapper;

  MapReducerBuilder(this._stateMapper, this._builderMapper);

  void add<Payload>(ActionName<Payload> actionName,
      CReducer<BuiltMap<K, V>, MapBuilder<K, V>, Payload> reducer) {
    final oldReducer = _map[actionName.name];
    _map[actionName.name] = (state, action, builder) {
      if (oldReducer != null) oldReducer(state, action, builder);
      reducer(_stateMapper(state), action as Action<Payload>,
          _builderMapper(builder));
    };
  }
}

class SetReducerBuilder<State extends Built<State, StateBuilder>,
    StateBuilder extends Builder<State, StateBuilder>, T> {
  final _map = <String, Reducer<State, StateBuilder, dynamic>>{};
  final Mapper<State, BuiltSet<T>> _stateMapper;
  final Mapper<StateBuilder, SetBuilder<T>> _builderMapper;

  SetReducerBuilder(this._stateMapper, this._builderMapper);

  void add<Payload>(ActionName<Payload> actionName,
      CReducer<BuiltSet<T>, SetBuilder<T>, Payload> reducer) {
    final oldReducer = _map[actionName.name];
    _map[actionName.name] = (state, action, builder) {
      if (oldReducer != null) oldReducer(state, action, builder);
      reducer(_stateMapper(state), action as Action<Payload>,
          _builderMapper(builder));
    };
  }
}

class SetMultimapReducerBuilder<State extends Built<State, StateBuilder>,
    StateBuilder extends Builder<State, StateBuilder>, K, V> {
  final _map = <String, Reducer<State, StateBuilder, dynamic>>{};
  final Mapper<State, BuiltSetMultimap<K, V>> _stateMapper;
  final Mapper<StateBuilder, SetMultimapBuilder<K, V>> _builderMapper;

  SetMultimapReducerBuilder(this._stateMapper, this._builderMapper);

  void add<Payload>(
      ActionName<Payload> actionName,
      CReducer<BuiltSetMultimap<K, V>, SetMultimapBuilder<K, V>, Payload>
          reducer) {
    final oldReducer = _map[actionName.name];
    _map[actionName.name] = (state, action, builder) {
      if (oldReducer != null) oldReducer(state, action, builder);
      reducer(_stateMapper(state), action as Action<Payload>,
          _builderMapper(builder));
    };
  }
}
