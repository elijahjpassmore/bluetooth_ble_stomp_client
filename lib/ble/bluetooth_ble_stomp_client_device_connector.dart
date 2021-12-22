import 'dart:async';

import 'package:bluetooth_ble_stomp_client/ble/reactive_state.dart';
import 'package:flutter_reactive_ble/flutter_reactive_ble.dart';

/// BLE device connector.
class BluetoothBleStompClientDeviceConnector
    extends ReactiveState<ConnectionStateUpdate> {
  BluetoothBleStompClientDeviceConnector({
    required FlutterReactiveBle ble,
    required Function(String message) logMessage,
  })  : _ble = ble,
        _logMessage = logMessage;

  final FlutterReactiveBle _ble;
  final void Function(String message) _logMessage;
  ConnectionStateUpdate? latestUpdate;

  @override
  Stream<ConnectionStateUpdate> get state => _deviceConnectionController.stream;

  final _deviceConnectionController = StreamController<ConnectionStateUpdate>();

  // ignore: cancel_subscriptions
  late StreamSubscription<ConnectionStateUpdate> _connection;

  /// Connect to a device by first scanning.
  ///
  /// Does not use autoConnect.
  Future<void> connect(
      {required String deviceId,
      required Uuid service,
      Duration timeout = const Duration(seconds: 5)}) async {
    _logMessage('Start connecting to $deviceId');
    _connection =
        _ble.connectToDevice(id: deviceId, connectionTimeout: timeout).listen(
      (update) {
        latestUpdate = update;
        _deviceConnectionController.add(update);
        _logMessage(
            'ConnectionState for device $deviceId : ${update.connectionState}');
      },
      onError: (Object e) =>
          _logMessage('Connecting to device $deviceId resulted in error $e'),
    );
  }

  /// Connect to a device by first scanning.
  ///
  /// Does not use autoConnect.
  Future<void> connectToAdvertising(
      {required String deviceId,
      required Uuid service,
      Duration timeout = const Duration(seconds: 5),
      Duration prescan = const Duration(seconds: 5)}) async {
    _logMessage('Start connecting to $deviceId');
    _connection = _ble
        .connectToAdvertisingDevice(
            id: deviceId,
            withServices: [service],
            prescanDuration: prescan,
            connectionTimeout: timeout)
        .listen(
      (update) {
        latestUpdate = update;
        _deviceConnectionController.add(update);
        _logMessage(
            'ConnectionState for device $deviceId : ${update.connectionState}');
      },
      onError: (Object e) =>
          _logMessage('Connecting to device $deviceId resulted in error $e'),
    );
  }

  /// Disconnect from a device.
  Future<void> disconnect({required String deviceId}) async {
    try {
      _logMessage('Disconnecting to device: $deviceId');
      await _connection.cancel();
    } on Exception catch (e, _) {
      _logMessage("Error disconnecting from a device: $e");
    } finally {
      // Since [_connection] subscription is terminated, the "disconnected" state cannot be received and propagated
      ConnectionStateUpdate disconnectedUpdate = ConnectionStateUpdate(
          deviceId: deviceId,
          connectionState: DeviceConnectionState.disconnected,
          failure: null);

      latestUpdate = disconnectedUpdate;
      _deviceConnectionController.add(disconnectedUpdate);

      _logMessage(
          'ConnectionState for device $deviceId : ${disconnectedUpdate.connectionState}');
    }
  }

  Future<void> dispose() async {
    await _deviceConnectionController.close();
  }
}
