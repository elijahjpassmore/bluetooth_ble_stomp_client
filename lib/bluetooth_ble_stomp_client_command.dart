library bluetooth_ble_stomp_client;

/// The standard STOMP commands.
enum BluetoothBleStompClientCommand {
  send,
  subscribe,
  unsubscribe,
  begin,
  commit,
  abort,
  ack,
  nack,
  disconnect
}

/// The corresponding command value expected in the frame.
extension BluetoothBleStompClientCommandExtension
on BluetoothBleStompClientCommand {
  String get value {
    switch (this) {
      case BluetoothBleStompClientCommand.send:
        return 'SEND';
      case BluetoothBleStompClientCommand.subscribe:
        return 'SUBSCRIBE';
      case BluetoothBleStompClientCommand.unsubscribe:
        return 'UNSUBSCRIBE';
      case BluetoothBleStompClientCommand.begin:
        return 'BEGIN';
      case BluetoothBleStompClientCommand.commit:
        return 'COMMIT';
      case BluetoothBleStompClientCommand.abort:
        return 'ABORT';
      case BluetoothBleStompClientCommand.ack:
        return 'ACK';
      case BluetoothBleStompClientCommand.nack:
        return 'NACK';
      case BluetoothBleStompClientCommand.disconnect:
        return 'DISCONNECT';
    }
  }
}