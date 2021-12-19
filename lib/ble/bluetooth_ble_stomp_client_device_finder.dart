import 'package:flutter_reactive_ble/flutter_reactive_ble.dart';

/// BLE device services and characteristics finder.
class BluetoothBleStompClientDeviceFinder {
  BluetoothBleStompClientDeviceFinder(
      {required this.ble, required this.logMessage, required this.device});

  final FlutterReactiveBle ble;
  final Function(String) logMessage;
  final DiscoveredDevice device;

  /// Discover the services associated with a device.
  Future<List<DiscoveredService>> discoverServices() async {
    try {
      logMessage('Start discovering services for: ${device.id}');
      final result = await ble.discoverServices(device.id);
      logMessage('Discovering services finished');
      return result;
    } on Exception catch (e) {
      logMessage('Error occurred when discovering services: $e');
      rethrow;
    }
  }

  /// Discover the characteristics associated with a device.
  Future<List<DiscoveredCharacteristic>> discoverCharacteristics(
      {Uuid? serviceToInspect}) async {
    try {
      logMessage('Start discovering services for: ${device.id}');
      final result = await ble.discoverServices(device.id);
      logMessage('Discovering services finished');

      /// Find characteristics of a specified service.
      if (serviceToInspect != null) {
        for (DiscoveredService service in result) {
          if (service.serviceId == serviceToInspect) {
            return service.characteristics;
          }
        }
        return [];
      } else {
        /// Else, return all characteristics of all services.
        List<DiscoveredCharacteristic> characteristics = [];
        for (DiscoveredService service in result) {
          characteristics.addAll(service.characteristics);
        }
        return characteristics;
      }
    } on Exception catch (e) {
      logMessage('Error occurred when discovering services: $e');
      rethrow;
    }
  }
}
