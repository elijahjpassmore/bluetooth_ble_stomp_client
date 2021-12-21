library bluetooth_ble_stomp_client;

/// An exception raised after bad frame creation or response.
class BluetoothBleStompClientResponseException implements Exception {
  BluetoothBleStompClientResponseException({this.message});

  final String? message;
}
