library bluetooth_ble_stomp_client;

/// The current status of the STOMP client.
enum BluetoothBleStompClientStompStatus {
  disconnected,
  authenticating,
  authenticated,
  connected,
}
