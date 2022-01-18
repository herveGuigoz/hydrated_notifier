import 'package:hydrated_notifier/hydrated_notifier.dart';
import 'package:meta/meta.dart';
import 'package:mocktail/mocktail.dart';
import 'package:uuid/uuid.dart';

class MyUuidHydratedLogic extends HydratedStateNotifier<String> {
  MyUuidHydratedLogic() : super(const Uuid().v4());

  @override
  Map<String, String> toJson(String state) => {'value': state};

  @override
  String? fromJson(Map<String, dynamic> json) => json['value'] as String?;
}

class MyCallbackHydratedLogic extends HydratedStateNotifier<int> {
  MyCallbackHydratedLogic({this.onFromJsonCalled}) : super(0);

  final void Function(dynamic)? onFromJsonCalled;

  void increment() => state = state + 1;

  @override
  Map<String, int> toJson(int state) => {'value': state};

  @override
  int? fromJson(Map<String, dynamic> json) {
    onFromJsonCalled?.call(json);
    return json['value'] as int?;
  }
}

class MyHydratedLogic extends HydratedStateNotifier<int> {
  MyHydratedLogic([
    this._id,
  ]) : super(0);

  final String? _id;

  @override
  String get id => _id ?? '';

  @override
  Map<String, int> toJson(int state) => {'value': state};

  @override
  int? fromJson(Map<String, dynamic> json) => json['value'] as int?;
}

class MyMultiHydratedStateNotifier extends HydratedStateNotifier<int> {
  MyMultiHydratedStateNotifier(String id)
      : _id = id,
        super(0);

  final String _id;

  @override
  String get id => _id;

  @override
  Map<String, int> toJson(int state) => {'value': state};

  @override
  int? fromJson(Map<String, dynamic> json) => json['value'] as int?;
}

class ErrorListener extends Mock {
  void call(Object? error, StackTrace? stackTrace);
}

class MyErrorLogic extends HydratedStateNotifier<int> {
  MyErrorLogic() : super(0);

  void increment() => state = state + 1;

  @override
  Map<String, String> toJson(int state) {
    throw Exception('_toJson_');
  }

  @override
  int? fromJson(Map<String, dynamic> json) {
    throw Exception('_fromJson_');
  }
}

class BadNotifier extends HydratedStateNotifier<BadState?> {
  BadNotifier() : super(null);

  void setBad([dynamic badObject = Object]) => state = BadState(badObject);

  @override
  Map<String, dynamic>? toJson(BadState? state) => state?.toJson();

  @override
  BadState? fromJson(Map<String, dynamic> json) => null;
}

class BadState {
  BadState(this.badObject);

  final dynamic badObject;

  Map<String, dynamic> toJson() {
    return <String, dynamic>{'bad_obj': badObject};
  }
}

class VeryBadObject {
  dynamic toJson() => Object;
}

class CyclicNotifier extends HydratedStateNotifier<Cycle1?> {
  CyclicNotifier() : super(null);

  // ignore: use_setters_to_change_properties
  void setCyclic(Cycle1 cycle1) => state = cycle1;

  @override
  Map<String, dynamic>? toJson(Cycle1? state) => state?.toJson();

  @override
  Cycle1 fromJson(Map<String, dynamic> json) => Cycle1.fromJson(json);
}

@immutable
class Cycle1 {
  const Cycle1([this.cycle2]);

  factory Cycle1.fromJson(Map<String, dynamic> json) {
    return Cycle1(json['cycle2'] as Cycle2);
  }

  final Cycle2? cycle2;

  Map<String, dynamic> toJson() => <String, dynamic>{'cycle2': cycle2};

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Cycle1 && other.cycle2 == cycle2;
  }

  @override
  int get hashCode => cycle2.hashCode;
}

class Cycle2 {
  Cycle2([this.cycle1]);

  factory Cycle2.fromJson(Map<String, dynamic> json) {
    return Cycle2(json['cycle1'] as Cycle1);
  }

  Cycle1? cycle1;

  Map<String, dynamic> toJson() => <String, dynamic>{'cycle1': cycle1};

  @override
  // ignore: avoid_equals_and_hash_code_on_mutable_classes
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Cycle2 && other.cycle1 == cycle1;
  }

  @override
  // ignore: avoid_equals_and_hash_code_on_mutable_classes
  int get hashCode => cycle1.hashCode;
}

class ListNotifier extends HydratedStateNotifier<List<String>> {
  ListNotifier() : super(const <String>[]);

  void addItem(String item) => state = [...state, item];

  @override
  Map<String, dynamic> toJson(List<String> state) {
    return <String, dynamic>{'state': state};
  }

  @override
  List<String> fromJson(Map<String, dynamic> json) {
    return json['state'] as List<String>;
  }
}

class ListNotifierMap<T extends ToJsonMap<E>, E>
    extends HydratedStateNotifier<List<T>> {
  // ignore: avoid_positional_boolean_parameters
  ListNotifierMap(this._fromJson, [this.explicit = false]) : super(<T>[]);
  final T Function(Map<String, dynamic> json) _fromJson;
  final bool explicit;

  void addItem(T item) => state = [...state, item];

  @override
  Map<String, dynamic> toJson(List<T> state) {
    final map = <String, dynamic>{
      'state': explicit
          ? List<Map<String, E>>.from(state.map<dynamic>((x) => x.toJson()))
          : state
    };
    return map;
  }

  @override
  List<T> fromJson(Map<String, dynamic> json) {
    final list = (json['state'] as List)
        .map((dynamic x) => x as Map<String, dynamic>)
        .map(_fromJson)
        .toList();
    return list;
  }
}

class ListNotifierList<T extends ToJsonList<E>, E>
    extends HydratedStateNotifier<List<T>> {
  // ignore: avoid_positional_boolean_parameters
  ListNotifierList(this._fromJson, [this.explicit = false]) : super(<T>[]);
  final T Function(List<dynamic> json) _fromJson;
  final bool explicit;

  void addItem(T item) => state = [...state, item];
  void reset() => state = <T>[];

  @override
  Map<String, dynamic> toJson(List<T> state) {
    final map = <String, dynamic>{
      'state': explicit
          ? List<List<E>>.from(state.map<dynamic>((x) => x.toJson()))
          : state
    };
    return map;
  }

  @override
  List<T> fromJson(Map<String, dynamic> json) {
    final list = (json['state'] as List)
        .map((dynamic x) => x as List<dynamic>)
        .map(_fromJson)
        .toList();
    return list;
  }
}

mixin ToJsonMap<T> {
  Map<String, T> toJson();
}

@immutable
class MapObject with ToJsonMap<int> {
  const MapObject(this.value);
  final int value;

  @override
  Map<String, int> toJson() {
    return <String, int>{'value': value};
  }

  // ignore: prefer_constructors_over_static_methods
  static MapObject fromJson(Map<String, dynamic> map) {
    return MapObject(map['value'] as int);
  }

  @override
  bool operator ==(Object o) {
    if (identical(this, o)) return true;

    return o is MapObject && o.value == value;
  }

  @override
  int get hashCode => value.hashCode;
}

@immutable
class MapCustomObject with ToJsonMap<CustomObject> {
  MapCustomObject(int value) : value = CustomObject(value);
  final CustomObject value;

  @override
  Map<String, CustomObject> toJson() {
    return <String, CustomObject>{'value': value};
  }

  // ignore: prefer_constructors_over_static_methods
  static MapCustomObject fromJson(Map<String, dynamic> map) {
    return MapCustomObject(
      CustomObject.fromJson(
        map['value'] as Map<String, dynamic>,
      ).value,
    );
  }

  @override
  bool operator ==(Object o) {
    if (identical(this, o)) return true;

    return o is MapCustomObject && o.value == value;
  }

  @override
  int get hashCode => value.hashCode;
}

mixin ToJsonList<T> {
  List<T> toJson();
}

@immutable
class ListObject with ToJsonList<int> {
  const ListObject(this.value);
  final int value;

  @override
  List<int> toJson() {
    return <int>[value];
  }

  // ignore: prefer_constructors_over_static_methods
  static ListObject fromJson(List<dynamic> list) {
    return ListObject(list[0] as int);
  }

  @override
  bool operator ==(Object o) {
    if (identical(this, o)) return true;

    return o is ListObject && o.value == value;
  }

  @override
  int get hashCode => value.hashCode;
}

@immutable
class ListMapObject with ToJsonList<MapObject> {
  ListMapObject(int value) : value = MapObject(value);
  final MapObject value;

  @override
  List<MapObject> toJson() {
    return <MapObject>[value];
  }

  // ignore: prefer_constructors_over_static_methods
  static ListMapObject fromJson(List<dynamic> list) {
    return ListMapObject(
      MapObject.fromJson(list[0] as Map<String, dynamic>).value,
    );
  }

  @override
  bool operator ==(Object o) {
    if (identical(this, o)) return true;

    return o is ListMapObject && o.value == value;
  }

  @override
  int get hashCode => value.hashCode;
}

@immutable
class ListListObject with ToJsonList<ListObject> {
  ListListObject(int value) : value = ListObject(value);
  final ListObject value;

  @override
  List<ListObject> toJson() {
    return <ListObject>[value];
  }

  // ignore: prefer_constructors_over_static_methods
  static ListListObject fromJson(List<dynamic> list) {
    return ListListObject(
      ListObject.fromJson(list[0] as List<dynamic>).value,
    );
  }

  @override
  bool operator ==(Object o) {
    if (identical(this, o)) return true;

    return o is ListListObject && o.value == value;
  }

  @override
  int get hashCode => value.hashCode;
}

@immutable
class ListCustomObject with ToJsonList<CustomObject> {
  ListCustomObject(int value) : value = CustomObject(value);
  final CustomObject value;

  @override
  List<CustomObject> toJson() {
    return <CustomObject>[value];
  }

  // ignore: prefer_constructors_over_static_methods
  static ListCustomObject fromJson(List<dynamic> list) {
    return ListCustomObject(
      CustomObject.fromJson(
        list[0] as Map<String, dynamic>,
      ).value,
    );
  }

  @override
  bool operator ==(Object o) {
    if (identical(this, o)) return true;

    return o is ListCustomObject && o.value == value;
  }

  @override
  int get hashCode => value.hashCode;
}

@immutable
class CustomObject {
  const CustomObject(this.value);
  final int value;

  Map<String, dynamic> toJson() {
    return <String, int>{'value': value};
  }

  // ignore: prefer_constructors_over_static_methods
  static CustomObject fromJson(Map<String, dynamic> json) {
    return CustomObject(json['value'] as int);
  }

  @override
  bool operator ==(Object o) {
    if (identical(this, o)) return true;

    return o is CustomObject && o.value == value;
  }

  @override
  int get hashCode => value.hashCode;
}
