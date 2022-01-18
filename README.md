# Hydrated Notifier

## Features

An extension to the [state_notifier](https://pub.dev/packages/state_notifier) library which automatically persists and restores states built on top of [hive](https://pub.dev/packages/hive).

## Usage

### Setup `HydratedStorage`

```dart
void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  /// Initialize storage
  HydratedStateNotifier.storage = await HydratedStorage.build(
    storageDirectory: kIsWeb
        ? HydratedStorage.webStorageDirectory
        : await getTemporaryDirectory(),
  );

  runApp(App())
}
```

### Create a HydratedStateNotifier

```dart
class CounterNotifier extends HydratedStateNotifier<int> {
  CounterNotifier() : super(0);

  void increment() => state = state + 1;

  @override
  int fromJson(Map<String, dynamic> json) => json['value'] as int;

  @override
  Map<String, int> toJson(int state) => { 'value': state };
}
```

Now the `CounterNotifier` will automatically persist/restore their state. 
We can increment the counter value, hot restart, kill the app, etc... and the previous state will be retained.

## Additional information

This is a fork of [hydrated_bloc](https://pub.dev/packages/hydrated_bloc).
