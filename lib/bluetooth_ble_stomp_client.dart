library bluetooth_ble_stomp_client;

import 'dart:convert';

import 'package:bluetooth_ble_stomp_client/bluetooth_ble_stomp_client_frame.dart';
import 'package:flutter_blue/flutter_blue.dart';

class BluetoothBleStompClient {
  BluetoothBleStompClient(
      {required this.writeCharacteristic, required this.readCharacteristic}) {
    readCharacteristic.setNotifyValue(true);
  }

  final BluetoothCharacteristic writeCharacteristic;
  final BluetoothCharacteristic readCharacteristic;

  static List<int> stringToBytes({required String str}) {
    return utf8.encode(str);
  }

  Future<List<int>> read() async {
    return await readCharacteristic.read();
  }

  Future<void> send(
      {required String command,
      required Map<String, String> headers,
      String? body,
      Function? callback}) async {
    BluetoothBleStompClientFrame newFrame = BluetoothBleStompClientFrame(
        command: command, headers: headers, body: body);
    await _rawSend(str: newFrame.result, callback: callback);
  }

  Future<void> sendFrame(dynamic frame) async {
    await _rawSend(str: frame.result);
  }

  Future<void> _rawSend({required String str, Function? callback}) async {
    await writeCharacteristic.write(stringToBytes(str: str));
    if (callback != null) {
      callback();
    }
  }
}
