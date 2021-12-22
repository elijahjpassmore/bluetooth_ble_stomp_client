library bluetooth_ble_stomp_client;

import 'dart:convert';

import 'package:bluetooth_ble_stomp_client/ble/bluetooth_ble_stomp_client_device_connector.dart';
import 'package:bluetooth_ble_stomp_client/ble/bluetooth_ble_stomp_client_device_finder.dart';
import 'package:bluetooth_ble_stomp_client/ble/bluetooth_ble_stomp_client_device_interactor.dart';
import 'package:bluetooth_ble_stomp_client/bluetooth_ble_stomp_client_frame.dart';
import 'package:bluetooth_ble_stomp_client/bluetooth_ble_stomp_client_frame_command.dart';
import 'package:bluetooth_ble_stomp_client/bluetooth_ble_stomp_client_stomp_status.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_reactive_ble/flutter_reactive_ble.dart';

/// A simple BLE STOMP client.
class BluetoothBleStompClient {
  /// A null response.
  static const List<int> nullResponse = [00];

  /// A warning response.
  static const List<int> warningResponse = [07];

  BluetoothBleStompClient(
      {required this.device,
      required this.serviceUuid,
      required this.readCharacteristicUuid,
      required this.writeCharacteristicUuid,
      this.stateCallback,
      this.logMessage,
      this.actionDelay}) {
    _ble = FlutterReactiveBle();
    _connector = BluetoothBleStompClientDeviceConnector(
        ble: _ble, logMessage: logMessage ?? (message) {});
    _finder = BluetoothBleStompClientDeviceFinder(
        ble: _ble, logMessage: logMessage ?? (message) {}, device: device);

    /// Immediately begin listening for the state of the device connection.
    _listenState();
  }

  late final FlutterReactiveBle _ble;

  final DiscoveredDevice device;
  final Uuid serviceUuid;
  final Uuid readCharacteristicUuid;
  final Uuid writeCharacteristicUuid;
  Function(ConnectionStateUpdate)? stateCallback;
  dynamic Function(String)? logMessage;
  Duration? actionDelay;

  QualifiedCharacteristic? readCharacteristic;
  QualifiedCharacteristic? writeCharacteristic;

  late final BluetoothBleStompClientDeviceConnector _connector;
  late final BluetoothBleStompClientDeviceFinder _finder;
  BluetoothBleStompClientDeviceInteractor? _interactor;

  BluetoothBleStompClientStompStatus status =
      BluetoothBleStompClientStompStatus.disconnected;

  /// Get the current state of the connection.
  Stream<ConnectionStateUpdate> get state => _connector.state;

  /// Check if the device is currently connected.
  DeviceConnectionState? get connectionState =>
      _connector.latestUpdate?.connectionState;

  /// Check if the device is ready to read and write.
  bool get readWriteReady => (readCharacteristic != null &&
      writeCharacteristic != null &&
      _interactor != null &&
      connectionState == DeviceConnectionState.connected);

  /// Convert a String to a bytes.
  static List<int> stringToBytes({required String str}) {
    return utf8.encode(str);
  }

  /// Convert bytes to a String.
  static String bytesToString({required List<int> bytes}) {
    return utf8.decode(bytes);
  }

  /// Compare the read response two another.
  ///
  /// At the moment, this is just a facade for listEquals.
  static bool readResponseEquality(
      {required List<int> one, required List<int> two}) {
    return listEquals(one, two);
  }

  /// Discover all services on a device.
  Future<List<DiscoveredService>> discoverServices() {
    return _finder.discoverServices();
  }

  /// Discover the characteristics associated with a given service UUID on the
  /// device.
  Future<List<DiscoveredCharacteristic>> discoverCharacteristics(Uuid service) {
    return _finder.discoverCharacteristics(serviceToInspect: service);
  }

  /// Listen to the state of the connection.
  void _listenState() async {
    state.listen((event) async {
      if (stateCallback != null) {
        stateCallback!(event);
      }

      /// Evaluate the new connection state.
      ///
      /// Use these cases to perform automatic actions upon changing connection
      /// state.
      ///
      /// When connected, immediately find the characteristics of the service.
      switch (event.connectionState) {
        case DeviceConnectionState.connected:
          _resetData();

          /// Attempt to find the necessary characteristics.
          while (readWriteReady == false) {
            await _findCharacteristics();

            if (readCharacteristic != null && writeCharacteristic != null) {
              _interactor = BluetoothBleStompClientDeviceInteractor(
                  ble: _ble,
                  readCharacteristic: readCharacteristic!,
                  writeCharacteristic: writeCharacteristic!,
                  logMessage: logMessage ?? (message) {});
            } else {
              /// If the characteristics aren't found, wait for a short period
              /// before trying again.
              await Future.delayed(const Duration(milliseconds: 500));
            }
          }
          break;
      }
    });
  }

  /// Reset the previously found data in case of a change.
  void _resetData() {
    readCharacteristic = null;
    writeCharacteristic = null;
    _interactor = null;
  }

  /// Find the expected read and write characteristics.
  ///
  /// The write characteristic found does not distinguish between a
  /// characteristic expecting a response and one which does not.
  Future<void> _findCharacteristics() async {
    if (connectionState != DeviceConnectionState.connected) {
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
      {prescanDuration = const Duration(seconds: 5),
      timeoutDuration = const Duration(seconds: 5),
      scanOffset = const Duration(milliseconds: 250)}) async {
    if (connectionState == DeviceConnectionState.connected) {
      if (logMessage != null) {
        logMessage!("Device ${device.id} already connected");
      }
    }

    await _connector.connect(
        deviceId: device.id,
        service: serviceUuid,
        timeout: timeoutDuration,
        prescan: prescanDuration);

    /// Wait for the scan to stop.
    ///
    /// If the device starts the connection process, immediately stop the
    /// future.
    await Future.doWhile(() async {
      if (connectionState == DeviceConnectionState.connecting) {
        return false;
      } else {
        /// Don't flood with too many checks at once.
        await Future.delayed(const Duration(milliseconds: 100));
        return true;
      }
    }).timeout(prescanDuration, onTimeout: () {});

    await Future.delayed(scanOffset);

    /// Keep the asynchronous method busy while the connection stream does not
    /// indicate that the device has been connected.
    await Future.doWhile(() async {
      if (connectionState == DeviceConnectionState.connected) {
        return false;
      } else if (connectionState == DeviceConnectionState.disconnected) {
        return false;
      } else {
        /// Don't flood with too many checks at once.
        await Future.delayed(const Duration(milliseconds: 100));
        return true;
      }

      /// If the connection takes too long, time it out.
    }).timeout(timeoutDuration, onTimeout: () async {
      if (connectionState != DeviceConnectionState.disconnected ||
          connectionState != DeviceConnectionState.disconnecting) {
        if (logMessage != null) {
          logMessage!('Device ${device.id} connection timed out');
        }
        await _connector.disconnect(deviceId: device.id);
      }
    });

    if (connectionState == DeviceConnectionState.connected) {
      return true;
    }

    return false;
  }

  /// Disconnect from the device.
  Future<void> disconnectDevice() async {
    await _connector.disconnect(deviceId: device.id);
  }

  /// Read from the read characteristic.
  Future<List<int>> read({Duration? delay}) async {
    if (readWriteReady == false) {
      if (logMessage != null) {
        logMessage!(
            "Cannot read characteristic ${readCharacteristicUuid.toString()}: read characteristic not found");
      }

      return [];
    }
    if (actionDelay != null) {
      await Future.delayed(actionDelay!);
    } else if (delay != null) {
      await Future.delayed(delay);
    }

    return await _interactor!.read(readCharacteristic!);
  }

  /// Check to see if the latest read response is null.
  Future<bool> nullRead({Duration? delay}) async {
    List<int> response = await read(delay: delay);
    if (bytesToString(bytes: response) == bytesToString(bytes: nullResponse)) {
      return true;
    }

    return false;
  }

  /// Check to see if the latest read response is a warning.
  Future<bool> warningRead({Duration? delay}) async {
    List<int> response = await read(delay: delay);
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
  Future<void> _rawSend(
      {required String str, Duration? delay, bool withResponse = true}) async {
    if (readWriteReady == false) {
      if (logMessage != null) {
        logMessage!(
            "Cannot write characteristic ${readCharacteristicUuid.toString()}: write characteristic not found");
      }

      return;
    }
    if (actionDelay != null) {
      await Future.delayed(actionDelay!);
    } else if (delay != null) {
      await Future.delayed(delay);
    }

    if (withResponse == true) {
      return await _interactor!.writeCharacteristicWithResponse(
          writeCharacteristic!, stringToBytes(str: str));
    } else {
      return await _interactor!.writeCharacteristicWithoutResponse(
          writeCharacteristic!, stringToBytes(str: str));
    }
  }
}
