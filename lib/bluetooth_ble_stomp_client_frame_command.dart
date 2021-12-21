library bluetooth_ble_stomp_client;

/// The standard STOMP commands.
enum BluetoothBleStompClientFrameCommand {
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
extension BluetoothBleStompClientFrameCommandExtension
    on BluetoothBleStompClientFrameCommand {
  String get value {
    switch (this) {
      case BluetoothBleStompClientFrameCommand.send:
        return 'SEND';
      case BluetoothBleStompClientFrameCommand.subscribe:
        return 'SUBSCRIBE';
      case BluetoothBleStompClientFrameCommand.unsubscribe:
        return 'UNSUBSCRIBE';
      case BluetoothBleStompClientFrameCommand.begin:
        return 'BEGIN';
      case BluetoothBleStompClientFrameCommand.commit:
        return 'COMMIT';
      case BluetoothBleStompClientFrameCommand.abort:
        return 'ABORT';
      case BluetoothBleStompClientFrameCommand.ack:
        return 'ACK';
      case BluetoothBleStompClientFrameCommand.nack:
        return 'NACK';
      case BluetoothBleStompClientFrameCommand.disconnect:
        return 'DISCONNECT';
    }
  }
}

Set<String> validBluetoothBleStompClientFrameCommandValues = {
  'SEND',
  'SUBSCRIBE',
  'UNSUBSCRIBE',
  'BEGIN',
  'COMMIT',
  'ABORT',
  'ACK',
  'NACK',
  'DISCONNECT'
};
