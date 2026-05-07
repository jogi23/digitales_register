// Minimal Quill Delta implementation for Dart 3.
// Replaces the abandoned quill_delta pub.dev package (last release: Dart 2).
// Only the subset of the API used by this app is implemented.

/// Decoder function to convert raw [data] object into a user-defined type.
typedef DataDecoder = Object Function(Object data);

/// Operation performed on a rich-text document.
class Operation {
  static const String insertKey = 'insert';
  static const String deleteKey = 'delete';
  static const String retainKey = 'retain';
  static const String attributesKey = 'attributes';

  static const List<String> _validKeys = [insertKey, deleteKey, retainKey];

  final String key;
  final int length;
  final Object data;
  final Map<String, dynamic>? _attributes;

  Operation._(
      this.key, this.length, this.data, Map<dynamic, dynamic>? attributes)
      : assert(_validKeys.contains(key), 'Invalid operation key "$key".'),
        _attributes =
            attributes != null ? Map<String, dynamic>.from(attributes) : null;

  /// Creates [Operation] from JSON payload.
  static Operation fromJson(Map<dynamic, dynamic> data,
      {DataDecoder? dataDecoder}) {
    dataDecoder ??= (d) => d;
    final map = Map<String, dynamic>.from(data);
    if (map.containsKey(insertKey)) {
      final insertData = dataDecoder(map[insertKey] as Object);
      final dataLength = insertData is String ? insertData.length : 1;
      return Operation._(
          insertKey, dataLength, insertData, map[attributesKey] as Map?);
    } else if (map.containsKey(deleteKey)) {
      final length = map[deleteKey] as int;
      return Operation._(deleteKey, length, '', null);
    } else if (map.containsKey(retainKey)) {
      final length = map[retainKey] as int;
      return Operation._(retainKey, length, '', map[attributesKey] as Map?);
    }
    throw ArgumentError.value(
        data, 'data', 'Invalid data for Delta operation.');
  }

  /// Creates an insert operation.
  factory Operation.insert(dynamic data, [Map<String, dynamic>? attributes]) =>
      Operation._(insertKey, data is String ? data.length : 1, data as Object,
          attributes);

  /// Creates a delete operation.
  factory Operation.delete(int length) =>
      Operation._(deleteKey, length, '', null);

  /// Creates a retain operation.
  factory Operation.retain(int length, [Map<String, dynamic>? attributes]) =>
      Operation._(retainKey, length, '', attributes);

  /// Returns a copy of attributes, or null if none.
  Map<String, dynamic>? get attributes =>
      _attributes == null ? null : Map<String, dynamic>.from(_attributes!);

  /// Returns JSON-serializable representation of this operation.
  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{key: value};
    if (_attributes != null) json[attributesKey] = attributes;
    return json;
  }

  /// Returns the value of this operation (data for inserts, length otherwise).
  dynamic get value => (key == insertKey) ? data : length;

  bool get isInsert => key == insertKey;
  bool get isDelete => key == deleteKey;
  bool get isRetain => key == retainKey;

  bool get isPlain => _attributes == null || _attributes!.isEmpty;
  bool get isNotPlain => !isPlain;

  bool get isEmpty => length == 0;
  bool get isNotEmpty => length > 0;

  bool hasAttribute(String name) =>
      isNotPlain && _attributes!.containsKey(name);

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! Operation) return false;
    return key == other.key &&
        length == other.length &&
        data == other.data &&
        _attributesEqual(other._attributes);
  }

  bool _attributesEqual(Map<String, dynamic>? other) {
    if (_attributes == other) return true;
    if (_attributes == null || other == null) return false;
    if (_attributes!.length != other.length) return false;
    for (final key in _attributes!.keys) {
      if (_attributes![key] != other[key]) return false;
    }
    return true;
  }

  @override
  int get hashCode => Object.hash(key, value);

  @override
  String toString() {
    final attr = _attributes == null ? '' : ' + $_attributes';
    final text = isInsert
        ? (data is String
            ? (data as String).replaceAll('\n', '⏎')
            : data.toString())
        : '$length';
    return '$key⟨ $text ⟩$attr';
  }
}

/// Delta represents a document or a modification as a sequence of operations.
class Delta {
  final List<Operation> _operations;

  /// Creates an empty [Delta].
  factory Delta() => Delta._();

  Delta._([List<Operation>? operations]) : _operations = operations ?? [];

  /// Creates a [Delta] from another.
  factory Delta.from(Delta other) =>
      Delta._(List<Operation>.from(other._operations));

  /// Creates a [Delta] from a JSON list.
  static Delta fromJson(List<dynamic> data, {DataDecoder? dataDecoder}) {
    return Delta._(data
        .map((op) => Operation.fromJson(op as Map<dynamic, dynamic>,
            dataDecoder: dataDecoder))
        .toList());
  }

  /// Returns JSON-serializable representation.
  List<dynamic> toJson() => _operations.map((op) => op.toJson()).toList();

  /// Returns list of operations.
  List<Operation> toList() => List.from(_operations);

  bool get isEmpty => _operations.isEmpty;
  bool get isNotEmpty => _operations.isNotEmpty;

  /// Returns the number of operations.
  int get length => _operations.length;

  /// Returns operation at [index].
  Operation operator [](int index) => _operations[index];

  /// Returns operation at [index].
  Operation elementAt(int index) => _operations.elementAt(index);

  Operation get first => _operations.first;
  Operation get last => _operations.last;

  /// Appends an insert operation.
  void insert(dynamic data, [Map<String, dynamic>? attributes]) {
    if (data is String && data.isEmpty) return;
    _operations.add(Operation.insert(data, attributes));
  }

  /// Appends a delete operation.
  void delete(int count) {
    if (count == 0) return;
    _operations.add(Operation.delete(count));
  }

  /// Appends a retain operation.
  void retain(int count, [Map<String, dynamic>? attributes]) {
    if (count == 0) return;
    _operations.add(Operation.retain(count, attributes));
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! Delta) return false;
    if (_operations.length != other._operations.length) return false;
    for (var i = 0; i < _operations.length; i++) {
      if (_operations[i] != other._operations[i]) return false;
    }
    return true;
  }

  @override
  int get hashCode => Object.hashAll(_operations);

  @override
  String toString() => _operations.join('\n');
}
