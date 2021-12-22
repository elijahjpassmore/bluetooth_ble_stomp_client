/// The BLE state.
abstract class ReactiveState<T> {
  Stream<T> get state;
}
