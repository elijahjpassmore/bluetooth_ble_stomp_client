library bluetooth_ble_stomp_client;

import 'dart:convert';

import 'package:bluetooth_ble_stomp_client/ble/ble_device_interactor.dart';
import 'package:bluetooth_ble_stomp_client/bluetooth_ble_stomp_client_frame.dart';
import 'package:flutter/material.dart';
import 'package:flutter_reactive_ble/flutter_reactive_ble.dart';

/// A simple BLE STOMP client.
class BluetoothBleStompClient {
  /// A null response.
  static List<int> nullResponse = [00];
  static List<int> warningResponse = [07];

  BluetoothBleStompClient({
    required this.readCharacteristic,
    required this.writeCharacteristic,
    this.logMessage,
    this.actionDelay}) {
    _interactor = BleDeviceInteractor(ble: FlutterReactiveBle(),
        readCharacteristic: readCharacteristic,
        writeCharacteristic: writeCharacteristic,
        logMessage: (message) => debugPrint(message));
  }

  final QualifiedCharacteristic readCharacteristic;
  final QualifiedCharacteristic writeCharacteristic;
  void Function(String)? logMessage;
  Duration? actionDelay;
  late final BleDeviceInteractor _interactor;

  /// Convert a String to a bytes.
  static List<int> stringToBytes({required String str}) {
    return utf8.encode(str);
  }

  /// Convert bytes to a String.
  static String bytesToString({required List<int> bytes}) {
    return utf8.decode(bytes);
  }

  /// Read from the readCharacteristic.
  Future<List<int>> read({Duration? delay, int? attempts}) async {
    if (actionDelay != null) {
      await Future.delayed(actionDelay!);
    } else if (delay != null) {
      await Future.delayed(delay);
    }

    return await _interactor.read(readCharacteristic);
  }

  /// Check to see if the latest read response is null.
  Future<bool> nullRead({Duration? delay, int? attempts}) async {
    List<int> response = await read(delay: delay, attempts: attempts);
    if (bytesToString(bytes: response) == bytesToString(bytes: nullResponse)) {
      return true;
    }

    return false;
  }

  /// Check to see if the latest read response is a warning.
  Future<bool> warningRead({Duration? delay, int? attempts}) async {
    List<int> response = await read(delay: delay, attempts: attempts);
    if (bytesToString(bytes: response) ==
        bytesToString(bytes: warningResponse)) {
      return true;
    }

    return false;
  }

  /// Construct a custom frame and write to the writeCharacteristic.
  Future<void> send({required String command,
    required Map<String, String> headers,
    String? body,
    Duration? delay}) async {
    BluetoothBleStompClientFrame newFrame = BluetoothBleStompClientFrame(
        command: command, headers: headers, body: body);
    await _rawSend(str: newFrame.result, delay: delay);
  }

  /// Send a frame by writing to the writeCharacteristic.
  Future<void> sendFrame({required dynamic frame, Duration? delay}) async {
    await _rawSend(str: frame.result, delay: delay);
  }

  /// Send a String by writing to the writeCharacteristic.
  Future<void> _rawSend({required String str, Duration? delay}) async {
    if (actionDelay != null) {
      await Future.delayed(actionDelay!);
    } else if (delay != null) {
      await Future.delayed(delay);
    }

    return await _interactor.writeWithoutResponse(
        writeCharacteristic, stringToBytes(str: str));
  }
}
