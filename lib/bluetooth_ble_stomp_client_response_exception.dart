library bluetooth_ble_stomp_client;

/// An exception raised after bad authentication responses.
class BluetoothBleStompClientResponseException implements Exception {
  BluetoothBleStompClientResponseException({this.message});

  final String? message;
}
