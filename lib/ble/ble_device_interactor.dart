import 'dart:async';

import 'package:flutter_reactive_ble/flutter_reactive_ble.dart';

/// Interact with a Bluetooth device.
class BleDeviceInteractor {
  BleDeviceInteractor({
    required this.ble,
    required this.readCharacteristic,
    required this.writeCharacteristic,
    required this.logMessage,
  }) : _logMessage = logMessage;

  final FlutterReactiveBle ble;
  final QualifiedCharacteristic readCharacteristic;
  final QualifiedCharacteristic writeCharacteristic;
  final void Function(String) logMessage;

  final void Function(String message) _logMessage;

  /// Read a characteristic.
  Future<List<int>> read(QualifiedCharacteristic characteristic) async {
    try {
      final response = await ble.readCharacteristic(readCharacteristic);
      _logMessage('Read ${characteristic.characteristicId}: value = $response');
      return response;
    } on Exception catch (e) {
      _logMessage(
        'Error occured when reading ${characteristic.characteristicId} : $e',
      );
      rethrow;
    }
  }

  /// Write a characteristic without expecting a response.
  Future<void> writeWithoutResponse(
      QualifiedCharacteristic characteristic, List<int> value) async {
    try {
      await ble.writeCharacteristicWithoutResponse(characteristic,
          value: value);
      _logMessage(
          'Write without response value: $value to ${characteristic.characteristicId}');
    } on Exception catch (e) {
      _logMessage(
        'Error occured when writing ${characteristic.characteristicId} : $e',
      );
      rethrow;
    }
  }
}
