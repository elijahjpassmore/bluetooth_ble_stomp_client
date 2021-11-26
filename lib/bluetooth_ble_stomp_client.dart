library bluetooth_ble_stomp_client;

import 'dart:convert';

import 'package:bluetooth_ble_stomp_client/bluetooth_ble_stomp_client_frame.dart';
import 'package:flutter_blue/flutter_blue.dart';

class BluetoothBleStompClient {
  BluetoothBleStompClient(
      {required this.writeCharacteristic,
      required this.readCharacteristic,
      this.actionDelay}) {
    readCharacteristic.setNotifyValue(true);
  }

  final BluetoothCharacteristic writeCharacteristic;
  final BluetoothCharacteristic readCharacteristic;
  Duration? actionDelay;

  static List<int> stringToBytes({required String str}) {
    return utf8.encode(str);
  }

  Future<List<int>> read(Duration? delay) async {
    if (actionDelay != null) {
      Future.delayed(actionDelay!);
    } else if (delay != null) {
      Future.delayed(delay);
    }
    return await readCharacteristic.read();
  }

  Future<void> send(
      {required String command,
      required Map<String, String> headers,
      String? body,
      Function? callback,
      Duration? delay}) async {
    BluetoothBleStompClientFrame newFrame = BluetoothBleStompClientFrame(
        command: command, headers: headers, body: body);
    await _rawSend(str: newFrame.result, callback: callback, delay: delay);
  }

  Future<void> sendFrame(
      {required dynamic frame, Function? callback, Duration? delay}) async {
    await _rawSend(str: frame.result, callback: callback, delay: delay);
  }

  Future<void> _rawSend(
      {required String str, Function? callback, Duration? delay}) async {
    if (actionDelay != null) {
      Future.delayed(actionDelay!);
    } else if (delay != null) {
      Future.delayed(delay);
    }
    await writeCharacteristic.write(
        stringToBytes(
          str: str,
        ),
        withoutResponse: false);
    if (callback != null) {
      callback();
    }
  }
}
