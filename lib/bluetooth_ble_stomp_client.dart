library bluetooth_ble_stomp_client;

import 'dart:convert';

import 'package:bluetooth_ble_stomp_client/bluetooth_ble_stomp_client_frame.dart';
import 'package:flutter_blue/flutter_blue.dart';

/// A simple BLE STOMP client.
class BluetoothBleStompClient {
  /// A null response.
  static List<int> nullResponse = [00];

  BluetoothBleStompClient(
      {required this.writeCharacteristic,
      required this.readCharacteristic,
      this.actionDelay,
      this.consecutiveAttempts});

  final BluetoothCharacteristic writeCharacteristic;
  final BluetoothCharacteristic readCharacteristic;
  Duration? actionDelay;
  int? consecutiveAttempts;

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

    if (attempts != null) {
      for (int i = 0; i <= attempts; i++) {
        try {
          await readCharacteristic.read();
        } catch (e) {
          if (i == attempts) {
            rethrow;
          }
        }
      }
    } else if (consecutiveAttempts != null) {
      for (int i = 0; i <= consecutiveAttempts!; i++) {
        try {
          return await readCharacteristic.read();
        } catch (e) {
          if (i == attempts) {
            rethrow;
          }
        }
      }
    }

    return await readCharacteristic.read();
  }

  /// Check to see if the latest read response is null.
  Future<bool> nullRead({Duration? delay, int? attempts}) async {
    List<int> response = await read(delay: delay, attempts: attempts);
    if (utf8.decode(response) == utf8.decode(nullResponse)) {
      return true;
    }

    return false;
  }

  /// Construct a custom frame and write to the writeCharacteristic.
  Future<void> send(
      {required String command,
      required Map<String, String> headers,
      String? body,
      Duration? delay,
      int? attempts}) async {
    BluetoothBleStompClientFrame newFrame = BluetoothBleStompClientFrame(
        command: command, headers: headers, body: body);
    await _rawSend(str: newFrame.result, delay: delay, attempts: attempts);
  }

  /// Send a frame by writing to the writeCharacteristic.
  Future<void> sendFrame(
      {required dynamic frame, Duration? delay, int? attempts}) async {
    await _rawSend(str: frame.result, delay: delay, attempts: attempts);
  }

  /// Send a String by writing to the writeCharacteristic.
  ///
  /// Note that writeCharacteristic uses CharacteristicWriteType.withoutResponse
  /// because it often causes more trouble than it is worth.
  ///
  /// Therefore, the user should rather rely on explicit responses from the
  /// server for confirmation or acknowledgement.
  Future<void> _rawSend(
      {required String str, Duration? delay, int? attempts}) async {
    if (actionDelay != null) {
      await Future.delayed(actionDelay!);
    } else if (delay != null) {
      await Future.delayed(delay);
    }

    if (attempts != null) {
      for (int i = 0; i <= attempts; i++) {
        try {
          return await writeCharacteristic.write(stringToBytes(str: str),
              withoutResponse: true);
        } catch (e) {
          if (i == attempts) {
            rethrow;
          }
        }
      }
    } else if (consecutiveAttempts != null) {
      for (int i = 0; i <= consecutiveAttempts!; i++) {
        try {
          return await writeCharacteristic.write(stringToBytes(str: str),
              withoutResponse: true);
        } catch (e) {
          if (i == attempts) {
            rethrow;
          }
        }
      }
    }

    return await writeCharacteristic.write(stringToBytes(str: str),
        withoutResponse: true);
  }
}
