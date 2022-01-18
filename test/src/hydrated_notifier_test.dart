import 'dart:async';
import 'dart:io';

import 'package:hydrated_notifier/hydrated_notifier.dart';
import 'package:mocktail/mocktail.dart';
import 'package:path/path.dart' as path;
import 'package:test/test.dart';

import '../helpers/helpers.dart';

class MockStorage extends Mock implements Storage {}

Future<void> sleep() => Future<void>.delayed(const Duration(milliseconds: 100));

void main() {
  group('HydratedLogic', () {
    group('read', () {
      late Storage storage;
      setUp(() => storage = setUpStorage());

      test('reads from storage once upon initialization', () {
        MyCallbackHydratedLogic();
        verify<dynamic>(() => storage.read('MyCallbackHydratedLogic'))
            .called(1);
      });

      test(
          'does not read from storage on subsequent state changes '
          'when cache value exists', () {
        when<dynamic>(() => storage.read(any())).thenReturn({'value': 42});
        final logic = MyCallbackHydratedLogic();
        expect(logic.state, 42);
        logic.increment();
        expect(logic.state, 43);
        verify<dynamic>(() => storage.read('MyCallbackHydratedLogic'))
            .called(1);
      });

      test(
          'does not deserialize state on subsequent state changes '
          'when cache value exists', () {
        final fromJsonCalls = <dynamic>[];
        when<dynamic>(() => storage.read(any())).thenReturn({'value': 42});
        final logic = MyCallbackHydratedLogic(
          onFromJsonCalled: fromJsonCalls.add,
        );
        expect(logic.state, 42);
        logic.increment();
        expect(logic.state, 43);
        expect(fromJsonCalls, [
          {'value': 42}
        ]);
      });

      test(
          'does not read from storage on subsequent state changes '
          'when cache is empty', () {
        when<dynamic>(() => storage.read(any())).thenReturn(null);
        final logic = MyCallbackHydratedLogic();
        expect(logic.state, 0);
        logic.increment();
        expect(logic.state, 1);
        verify<dynamic>(() => storage.read('MyCallbackHydratedLogic'))
            .called(1);
      });

      test('does not deserialize state when cache is empty', () {
        final fromJsonCalls = <dynamic>[];
        when<dynamic>(() => storage.read(any())).thenReturn(null);
        final logic = MyCallbackHydratedLogic(
          onFromJsonCalled: fromJsonCalls.add,
        );
        expect(logic.state, 0);
        logic.increment();
        expect(logic.state, 1);
        expect(fromJsonCalls, isEmpty);
      });

      test(
          'does not read from storage on subsequent state changes '
          'when cache is malformed', () {
        when<dynamic>(() => storage.read(any())).thenReturn('{');
        final logic = MyCallbackHydratedLogic();
        expect(logic.state, 0);
        logic.increment();
        expect(logic.state, 1);
        verify<dynamic>(() => storage.read('MyCallbackHydratedLogic'))
            .called(1);
      });

      test('does not deserialize state when cache is malformed', () {
        final fromJsonCalls = <dynamic>[];
        runZonedGuarded(
          () {
            when<dynamic>(() => storage.read(any())).thenReturn('{');
            MyCallbackHydratedLogic(onFromJsonCalled: fromJsonCalls.add);
          },
          (_, __) {
            expect(fromJsonCalls, isEmpty);
          },
        );
      });
    });

    group('SingleHydratedLogic', () {
      late Storage storage;
      setUp(() => storage = setUpStorage());

      test('should throw StorageNotFound when storage is null', () {
        HydratedStateNotifier.storage = null;
        expect(() => MyHydratedLogic(), throwsA(isA<StorageNotFound>()));
      });

      test('StorageNotFound overrides toString', () {
        expect(
          // ignore: prefer_const_constructors
          StorageNotFound().toString(),
          'Storage was accessed before it was initialized.\n'
          'Please ensure that storage has been initialized.\n\n'
          'For example:\n\n'
          // ignore: lines_longer_than_80_chars
          'HydratedStateNotifier.storage = await HydratedStateNotifier.build();',
        );
      });

      test('storage getter returns correct storage instance', () {
        final storage = MockStorage();
        HydratedStateNotifier.storage = storage;
        expect(HydratedStateNotifier.storage, storage);
      });

      test('stores initial state when instantiated', () {
        MyHydratedLogic();
        verify(() => storage.write('MyHydratedLogic', {'value': 0})).called(1);
      });

      test('initial state should return 0 when fromJson returns null', () {
        when<dynamic>(() => storage.read(any())).thenReturn(null);
        expect(MyHydratedLogic().state, 0);
        verify<dynamic>(() => storage.read('MyHydratedLogic')).called(1);
      });

      test('initial state should return 0 when deserialization fails', () {
        when<dynamic>(() => storage.read(any())).thenThrow(Exception('oops'));
        expect(MyHydratedLogic('').state, 0);
      });

      test('initial state should return 101 when fromJson returns 101', () {
        when<dynamic>(() => storage.read(any())).thenReturn({'value': 101});
        expect(MyHydratedLogic().state, 101);
        verify<dynamic>(() => storage.read('MyHydratedLogic')).called(1);
      });

      group('clear', () {
        test('calls delete on storage', () async {
          await MyHydratedLogic().clear();
          verify(() => storage.delete('MyHydratedLogic')).called(1);
        });
      });
    });

    group('MultiHydratedStateNotifier', () {
      late Storage storage;
      setUp(() => storage = setUpStorage());

      test('initial state should return 0 when fromJson returns null', () {
        when<dynamic>(() => storage.read(any())).thenReturn(null);
        expect(MyMultiHydratedStateNotifier('A').state, 0);
        verify<dynamic>(
          () => storage.read('MyMultiHydratedStateNotifierA'),
        ).called(1);

        expect(MyMultiHydratedStateNotifier('B').state, 0);
        verify<dynamic>(
          () => storage.read('MyMultiHydratedStateNotifierB'),
        ).called(1);
      });

      test('initial state should return 101/102 when fromJson returns 101/102',
          () {
        when<dynamic>(
          () => storage.read('MyMultiHydratedStateNotifierA'),
        ).thenReturn({'value': 101});

        expect(MyMultiHydratedStateNotifier('A').state, 101);
        verify<dynamic>(
          () => storage.read('MyMultiHydratedStateNotifierA'),
        ).called(1);

        when<dynamic>(
          () => storage.read('MyMultiHydratedStateNotifierB'),
        ).thenReturn({'value': 102});

        expect(MyMultiHydratedStateNotifier('B').state, 102);

        verify<dynamic>(
          () => storage.read('MyMultiHydratedStateNotifierB'),
        ).called(1);
      });

      group('clear', () {
        test('calls delete on storage', () async {
          await MyMultiHydratedStateNotifier('A').clear();
          verify(
            () => storage.delete('MyMultiHydratedStateNotifierA'),
          ).called(1);

          verifyNever(
            () => storage.delete('MyMultiHydratedStateNotifierB'),
          );

          await MyMultiHydratedStateNotifier('B').clear();

          verify(
            () => storage.delete('MyMultiHydratedStateNotifierB'),
          ).called(1);
        });
      });
    });

    group('MyUuidHydratedLogic', () {
      late Storage storage;
      setUp(() => storage = setUpStorage());

      test('stores initial state when instantiated', () {
        MyUuidHydratedLogic();
        verify(
          () => storage.write('MyUuidHydratedLogic', any<dynamic>()),
        ).called(1);
      });

      test('correctly caches computed initial state', () async {
        dynamic cachedState;
        when<dynamic>(() => storage.read(any())).thenReturn(cachedState);
        when(
          () => storage.write(any(), any<dynamic>()),
        ).thenAnswer((_) => Future<void>.value());

        MyUuidHydratedLogic();
        final captured = verify(
          () => storage.write('MyUuidHydratedLogic', captureAny<dynamic>()),
        ).captured;
        cachedState = captured.first;

        when<dynamic>(() => storage.read(any())).thenReturn(cachedState);
        MyUuidHydratedLogic();
        final secondCaptured = verify(
          () => storage.write('MyUuidHydratedLogic', captureAny<dynamic>()),
        ).captured;
        final dynamic initialStateB = secondCaptured.first;

        expect(initialStateB, cachedState);
      });
    });

    group('List', () {
      late Storage storage;

      setUp(() async {
        storage = await HydratedStorage.build(
          storageDirectory: Directory(
            path.join(Directory.current.path, '.cache'),
          ),
        );
        HydratedStateNotifier.storage = storage;
      });

      tearDown(() async {
        await storage.clear();
        try {
          Directory(
            path.join(Directory.current.path, '.cache'),
          ).deleteSync(recursive: true);
          await HydratedStorage.hive.deleteFromDisk();
        } catch (_) {}
      });

      test('persists and restores string list correctly', () async {
        const item = 'foo';
        final logic = ListNotifier();
        expect(logic.state, isEmpty);
        logic.addItem(item);
        await sleep();
        expect(ListNotifier().state, const <String>[item]);
      });

      test('persists and restores object->map list correctly', () async {
        const item = MapObject(1);
        const fromJson = MapObject.fromJson;
        final logic = ListNotifierMap<MapObject, int>(fromJson);
        expect(logic.state, isEmpty);
        logic.addItem(item);
        await sleep();
        expect(
          ListNotifierMap<MapObject, int>(fromJson).state,
          const <MapObject>[item],
        );
      });

      test('persists and restores object-*>map list correctly', () async {
        const item = MapObject(1);
        const fromJson = MapObject.fromJson;
        final logic = ListNotifierMap<MapObject, int>(fromJson, true);
        expect(logic.state, isEmpty);
        logic.addItem(item);
        await sleep();
        expect(
          ListNotifierMap<MapObject, int>(fromJson).state,
          const <MapObject>[item],
        );
      });

      test('persists and restores obj->map<custom> list correctly', () async {
        final item = MapCustomObject(1);
        const fromJson = MapCustomObject.fromJson;
        final logic = ListNotifierMap<MapCustomObject, CustomObject>(fromJson);
        expect(logic.state, isEmpty);
        logic.addItem(item);
        await sleep();
        expect(
          ListNotifierMap<MapCustomObject, CustomObject>(fromJson).state,
          <MapCustomObject>[item],
        );
      });

      test('persists and restores obj-*>map<custom> list correctly', () async {
        final item = MapCustomObject(1);
        const fromJson = MapCustomObject.fromJson;
        final logic =
            ListNotifierMap<MapCustomObject, CustomObject>(fromJson, true);
        expect(logic.state, isEmpty);
        logic.addItem(item);
        await sleep();
        expect(
          ListNotifierMap<MapCustomObject, CustomObject>(fromJson).state,
          <MapCustomObject>[item],
        );
      });

      test('persists and restores object->list list correctly', () async {
        const item = ListObject(1);
        const fromJson = ListObject.fromJson;
        final logic = ListNotifierList<ListObject, int>(fromJson);
        expect(logic.state, isEmpty);
        logic.addItem(item);
        await sleep();
        expect(
          ListNotifierList<ListObject, int>(fromJson).state,
          const <ListObject>[item],
        );
      });

      test('persists and restores object-*>list list correctly', () async {
        const item = ListObject(1);
        const fromJson = ListObject.fromJson;
        final logic = ListNotifierList<ListObject, int>(fromJson, true);
        expect(logic.state, isEmpty);
        logic.addItem(item);
        await sleep();
        expect(
          ListNotifierList<ListObject, int>(fromJson).state,
          const <ListObject>[item],
        );
      });

      test('persists and restores object->list<map> list correctly', () async {
        final item = ListMapObject(1);
        const fromJson = ListMapObject.fromJson;
        final logic = ListNotifierList<ListMapObject, MapObject>(fromJson);
        expect(logic.state, isEmpty);
        logic.addItem(item);
        await sleep();
        expect(
          ListNotifierList<ListMapObject, MapObject>(fromJson).state,
          <ListMapObject>[item],
        );
      });

      test('persists and restores obj-*>list<map> list correctly', () async {
        final item = ListMapObject(1);
        const fromJson = ListMapObject.fromJson;
        final logic =
            ListNotifierList<ListMapObject, MapObject>(fromJson, true);
        expect(logic.state, isEmpty);
        logic.addItem(item);
        await sleep();
        expect(
          ListNotifierList<ListMapObject, MapObject>(fromJson).state,
          <ListMapObject>[item],
        );
      });

      test('persists and restores obj->list<list> list correctly', () async {
        final item = ListListObject(1);
        const fromJson = ListListObject.fromJson;
        final logic = ListNotifierList<ListListObject, ListObject>(fromJson);
        expect(logic.state, isEmpty);
        logic.addItem(item);
        await sleep();
        expect(
          ListNotifierList<ListListObject, ListObject>(fromJson).state,
          <ListListObject>[item],
        );
      });

      test('persists and restores obj-*>list<list> list correctly', () async {
        final item = ListListObject(1);
        const fromJson = ListListObject.fromJson;
        final logic =
            ListNotifierList<ListListObject, ListObject>(fromJson, true);
        expect(logic.state, isEmpty);
        logic.addItem(item);
        await sleep();
        expect(
          ListNotifierList<ListListObject, ListObject>(fromJson).state,
          <ListListObject>[item],
        );
      });

      test('persists and restores obj->list<custom> list correctly', () async {
        final item = ListCustomObject(1);
        const fromJson = ListCustomObject.fromJson;
        final logic =
            ListNotifierList<ListCustomObject, CustomObject>(fromJson);
        expect(logic.state, isEmpty);
        logic.addItem(item);
        await sleep();
        expect(
          ListNotifierList<ListCustomObject, CustomObject>(fromJson).state,
          <ListCustomObject>[item],
        );
      });

      test('persists and restores obj-*>list<custom> list correctly', () async {
        final item = ListCustomObject(1);
        const fromJson = ListCustomObject.fromJson;
        final logic =
            ListNotifierList<ListCustomObject, CustomObject>(fromJson, true);
        expect(logic.state, isEmpty);
        logic.addItem(item);
        await sleep();
        expect(
          ListNotifierList<ListCustomObject, CustomObject>(fromJson).state,
          <ListCustomObject>[item],
        );
      });

      test('persists and restores obj->list<custom> empty list correctly',
          () async {
        const fromJson = ListCustomObject.fromJson;
        final logic =
            ListNotifierList<ListCustomObject, CustomObject>(fromJson);
        expect(logic.state, isEmpty);
        logic.reset();
        expect(
          ListNotifierList<ListCustomObject, CustomObject>(fromJson).state,
          isEmpty,
        );
      });

      test('persists and restores obj-*>list<custom> empty list correctly',
          () async {
        const fromJson = ListCustomObject.fromJson;
        final logic =
            ListNotifierList<ListCustomObject, CustomObject>(fromJson, true);
        expect(logic.state, isEmpty);
        logic.reset();
        expect(
          ListNotifierList<ListCustomObject, CustomObject>(fromJson).state,
          isEmpty,
        );
      });
    });

    group('Error', () {
      setUp(setUpStorage);

      test('call onError', () {
        final listener = ErrorListener();
        (MyErrorLogic()..onError = listener).increment();
        verify(() => listener.call(any(), any())).called(1);
      });

      test('HydratedCyclicError override toString()', () {
        expect(
          HydratedCyclicError(1).toString(),
          'Cyclic error while state traversing',
        );
      });

      test('HydratedUnsupportedError override toString()', () {
        expect(
          HydratedUnsupportedError(1).toString(),
          'Converting object did not return an encodable object: 1',
        );
      });

      test('throws unsupported error', () {
        Object? error;
        (BadNotifier()..onError = (e, _) => error = e).setBad(VeryBadObject());
        expect(error, isA<HydratedUnsupportedError>());
      });

      test('throws cyclic error', () async {
        Object? error;
        final cycle2 = Cycle2();
        final cycle1 = Cycle1(cycle2);
        cycle2.cycle1 = cycle1;
        final logic = CyclicNotifier()..onError = (e, _) => error = e;
        expect(logic.state, isNull);
        logic.setCyclic(cycle1);
        expect(
          error,
          isA<HydratedUnsupportedError>().having(
            (e) => e.cause,
            'cycle2 -> cycle1 -> cycle2 ->',
            isA<HydratedCyclicError>(),
          ),
        );
      });
    });
  });
}
