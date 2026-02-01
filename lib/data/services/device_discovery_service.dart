import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:multicast_dns/multicast_dns.dart';

class DiscoveredDevice {
  final String name;
  final String ip;
  final int port;

  DiscoveredDevice({required this.name, required this.ip, this.port = 80});

  @override
  String toString() => '$name ($ip:$port)';
}

class DeviceDiscoveryService extends ChangeNotifier {
  static const String _serviceType = '_wled._tcp';
  
  List<DiscoveredDevice> _devices = [];
  bool _isScanning = false;
  String? _error;

  List<DiscoveredDevice> get devices => _devices;
  bool get isScanning => _isScanning;
  String? get error => _error;

  /// Start scanning for WLED devices on the local network
  Future<void> startDiscovery() async {
    if (_isScanning) return;
    
    _isScanning = true;
    _devices = [];
    _error = null;
    notifyListeners();

    // Web platform doesn't support mDNS directly
    if (kIsWeb) {
      _error = 'Auto-discovery requires the mobile app. Please enter IP manually.';
      _isScanning = false;
      notifyListeners();
      return;
    }

    try {
      final MDnsClient client = MDnsClient();
      await client.start();

      // Listen for PTR records (service discovery)
      await for (final PtrResourceRecord ptr in client.lookup<PtrResourceRecord>(
        ResourceRecordQuery.serverPointer(_serviceType),
      )) {
        // For each PTR, look up the SRV record to get host/port
        await for (final SrvResourceRecord srv in client.lookup<SrvResourceRecord>(
          ResourceRecordQuery.service(ptr.domainName),
        )) {
          // Resolve the hostname to an IP
          await for (final IPAddressResourceRecord ip in client.lookup<IPAddressResourceRecord>(
            ResourceRecordQuery.addressIPv4(srv.target),
          )) {
            final device = DiscoveredDevice(
              name: ptr.domainName.replaceAll('.$_serviceType.local', ''),
              ip: ip.address.address,
              port: srv.port,
            );
            
            // Avoid duplicates
            if (!_devices.any((d) => d.ip == device.ip)) {
              _devices.add(device);
              notifyListeners();
            }
          }
        }
      }

      client.stop();
    } catch (e) {
      _error = 'Discovery error: $e';
    }

    _isScanning = false;
    notifyListeners();
  }

  /// Stop any ongoing discovery
  void stopDiscovery() {
    _isScanning = false;
    notifyListeners();
  }

  /// Clear discovered devices
  void clearDevices() {
    _devices = [];
    notifyListeners();
  }
}
