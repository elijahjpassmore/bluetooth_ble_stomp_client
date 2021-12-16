library bluetooth_ble_stomp_client;

import 'dart:convert';

import 'package:bluetooth_ble_stomp_client/ble/bluetooth_ble_stomp_client_device_connector.dart';
import 'package:bluetooth_ble_stomp_client/ble/bluetooth_ble_stomp_client_device_finder.dart';
import 'package:bluetooth_ble_stomp_client/ble/bluetooth_ble_stomp_client_device_interactor.dart';
import 'package:bluetooth_ble_stomp_client/bluetooth_ble_stomp_client_frame.dart';
import 'package:flutter_reactive_ble/flutter_reactive_ble.dart';

/// A simple BLE STOMP client.
class BluetoothBleStompClient {
  /// A null response.
  static List<int> nullResponse = [00];

  /// A warning response.
  static List<int> warningResponse = [07];

  BluetoothBleStompClient(
      {required this.device,
      required this.serviceUuid,
      required this.readCharacteristicUuid,
      required this.writeCharacteristicUuid,
      this.logMessage,
      this.actionDelay}) {
    _ble = FlutterReactiveBle();
    _connector = BluetoothBleStompClientDeviceConnector(
        ble: _ble, logMessage: logMessage ?? (message) {});
    _finder = BluetoothBleStompClientDeviceFinder(
        ble: _ble, logMessage: logMessage ?? (message) {}, device: device);
  }

  late final FlutterReactiveBle _ble;

  final DiscoveredDevice device;
  final Uuid serviceUuid;
  final Uuid readCharacteristicUuid;
  final Uuid writeCharacteristicUuid;

  QualifiedCharacteristic? readCharacteristic;
  QualifiedCharacteristic? writeCharacteristic;
  dynamic Function(String)? logMessage;
  Duration? actionDelay;

  late final BluetoothBleStompClientDeviceConnector _connector;
  late final BluetoothBleStompClientDeviceFinder _finder;
  late final BluetoothBleStompClientDeviceInteractor _interactor;

  bool get connected =>
      _connector.latestUpdate?.connectionState ==
      DeviceConnectionState.connected;

  bool get characteristicsFound =>
      (readCharacteristic != null && writeCharacteristic != null);

  /// Convert a String to a bytes.
  static List<int> stringToBytes({required String str}) {
    return utf8.encode(str);
  }

  /// Convert bytes to a String.
  static String bytesToString({required List<int> bytes}) {
    return utf8.decode(bytes);
  }

  /// Initialize the client.
  Future<void> init({quickConnect = false}) async {
    if (quickConnect == true) {
      await connectDevice();
    }

    if (connected == false) {
      if (logMessage != null) {
        logMessage!(
            'Device ${device.id} must be connected before initialization');
      }

      return;
    }

    while (characteristicsFound == false) {
      await _findCharacteristics();
    }

    /// When the characteristics have been found, the interactor can then be
    /// created.
    _interactor = BluetoothBleStompClientDeviceInteractor(
        ble: _ble,
        readCharacteristic: readCharacteristic!,
        writeCharacteristic: writeCharacteristic!,
        logMessage: logMessage ?? (message) {});
  }

  /// Find the expected read and write characteristics.
  Future<void> _findCharacteristics() async {
    if (connected == false) {
      if (logMessage != null) {
        logMessage!(
            'Device ${device.id} must be connected before finding characteristics');
      }

      return;
    }
    List<DiscoveredCharacteristic> characteristics =
        await _finder.discoverCharacteristics(serviceToInspect: serviceUuid);

    for (DiscoveredCharacteristic characteristic in characteristics) {
      /// If it's the expected read characteristic, mark it as discovered.
      if (characteristic.isReadable &&
          characteristic.characteristicId == readCharacteristicUuid) {
        readCharacteristic = QualifiedCharacteristic(
            characteristicId: characteristic.characteristicId,
            serviceId: serviceUuid,
            deviceId: device.id);

        /// If it's the expected write characteristic, mark it as discovered.
      } else if ((characteristic.isWritableWithResponse ||
              characteristic.isWritableWithoutResponse) &&
          characteristic.characteristicId == writeCharacteristicUuid) {
        writeCharacteristic = QualifiedCharacteristic(
            characteristicId: characteristic.characteristicId,
            serviceId: serviceUuid,
            deviceId: device.id);
      }
    }
  }

  /// Connect to the device.
  Future<bool> connectDevice(
      {connectTimeout = const Duration(seconds: 10)}) async {
    if (connected == true) {
      if (logMessage != null) {
        logMessage!("Device ${device.id} already connected");
      }
    }
    await _connector.connect(deviceId: device.id);

    /// Keep the asynchronous method busy while the connection stream does not
    /// indicate that the device has been connected.
    await Future.doWhile(() async {
      if (connected == true) {
        return false;
      } else {
        /// Don't flood with too many checks at once.
        await Future.delayed(const Duration(milliseconds: 100));
        return true;
      }

      /// If the connection takes too long, time it out.
    }).timeout(connectTimeout, onTimeout: () async {
      if (logMessage != null) {
        logMessage!('Device ${device.id} connection timed out');
      }
      await _connector.disconnect(deviceId: device.id);
    });

    return connected;
  }

  /// Disconnect from the device.
  Future<void> disconnectDevice() async {
    await _connector.disconnect(deviceId: device.id);
  }

  /// Read from the read characteristic.
  Future<List<int>> read({Duration? delay, int? attempts}) async {
    if (connected == false) {
      if (logMessage != null) {
        logMessage!(
            "Cannot read characteristic ${readCharacteristicUuid.toString()}: not connected");
      }

      return [];
    }
    if (characteristicsFound == false) {
      if (logMessage != null) {
        logMessage!(
            "Cannot read characteristic ${readCharacteristicUuid.toString()}: characteristics not found");
      }

      return [];
    }
    if (actionDelay != null) {
      await Future.delayed(actionDelay!);
    } else if (delay != null) {
      await Future.delayed(delay);
    }

    return await _interactor.read(readCharacteristic!);
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

  /// Construct a custom frame and write to the write characteristic.
  Future<void> send(
      {required String command,
      required Map<String, String> headers,
      String? body,
      Duration? delay}) async {
    BluetoothBleStompClientFrame newFrame = BluetoothBleStompClientFrame(
        command: command, headers: headers, body: body);
    await _rawSend(str: newFrame.result, delay: delay);
  }

  /// Send a frame by writing to the write characteristic.
  Future<void> sendFrame({required dynamic frame, Duration? delay}) async {
    await _rawSend(str: frame.result, delay: delay);
  }

  /// Send a String by writing to the write characteristic.
  Future<void> _rawSend({required String str, Duration? delay}) async {
    if (connected == false) {
      if (logMessage != null) {
        logMessage!(
            "Cannot write characteristic ${readCharacteristicUuid.toString()}: not connected");
      }

      return;
    }
    if (characteristicsFound == false) {
      if (logMessage != null) {
        logMessage!(
            "Cannot write characteristic ${readCharacteristicUuid.toString()}: characteristics not found");
      }

      return;
    }
    if (actionDelay != null) {
      await Future.delayed(actionDelay!);
    } else if (delay != null) {
      await Future.delayed(delay);
    }

    return await _interactor.writeCharacteristicWithResponse(
        writeCharacteristic!, stringToBytes(str: str));
  }
}
