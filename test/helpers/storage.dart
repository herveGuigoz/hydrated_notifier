import 'package:hydrated_notifier/hydrated_notifier.dart';
import 'package:mocktail/mocktail.dart';

class MockStorage extends Mock implements Storage {}

Storage setUpStorage({
  Future<void> Function(Invocation invocation)? onWrite,
  Map<String, dynamic>? onRead,
  Future<void> Function(Invocation invocation)? onDelete,
  Future<void> Function(Invocation invocation)? onClear,
}) {
  final storage = MockStorage();

  when(() => storage.write(any(), any<dynamic>())).thenAnswer(
    (_) async => onWrite?.call(_),
  );

  when<dynamic>(() => storage.read(any())).thenReturn(onRead);

  when(() => storage.delete(any())).thenAnswer(
    (_) async => onDelete?.call(_),
  );

  when(storage.clear).thenAnswer(
    (_) async => onClear?.call(_),
  );

  HydratedStateNotifier.storage = storage;

  return storage;
}
