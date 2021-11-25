/// An exception raised after bad authentication responses.
class BluetoothBleStompClientResponseException implements Exception {
  BluetoothBleStompClientResponseException({this.message});

  final String? message;
}
