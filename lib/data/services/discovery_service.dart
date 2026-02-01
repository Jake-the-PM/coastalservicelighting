import 'dart:async';
import 'dart:io';
import 'package:multicast_dns/multicast_dns.dart';

/// Discovered WLED device info
class DiscoveredDevice {
  final String name;
  final String ip;
  final int port;

  DiscoveredDevice({
    required this.name,
    required this.ip,
    this.port = 80,
  });

  @override
  String toString() => '$name ($ip)';
}

/// Service to discover WLED controllers on the local network via mDNS.
class DiscoveryService {
  static const String _serviceType = '_wled._tcp';
  
  /// Scans the network for WLED devices.
  /// Returns a list of discovered devices.
  /// [timeout] is how long to scan before returning results.
  Future<List<DiscoveredDevice>> scanForDevices({
    Duration timeout = const Duration(seconds: 5),
  }) async {
    final devices = <DiscoveredDevice>[];
    final seenIps = <String>{}; // Dedupe

    try {
      final MDnsClient client = MDnsClient();
      await client.start();

      // Listen for PTR records (service discovery)
      await for (final PtrResourceRecord ptr in client.lookup<PtrResourceRecord>(
        ResourceRecordQuery.serverPointer(_serviceType),
      ).timeout(timeout, onTimeout: (sink) => sink.close())) {
        
        // For each PTR, look up the SRV record (host/port)
        await for (final SrvResourceRecord srv in client.lookup<SrvResourceRecord>(
          ResourceRecordQuery.service(ptr.domainName),
        ).timeout(const Duration(seconds: 2), onTimeout: (sink) => sink.close())) {
          
          // Resolve the hostname to an IP
          await for (final IPAddressResourceRecord ip in client.lookup<IPAddressResourceRecord>(
            ResourceRecordQuery.addressIPv4(srv.target),
          ).timeout(const Duration(seconds: 2), onTimeout: (sink) => sink.close())) {
            
            final ipString = ip.address.address;
            
            if (!seenIps.contains(ipString)) {
              seenIps.add(ipString);
              devices.add(DiscoveredDevice(
                name: ptr.domainName.split('.').first, // Extract friendly name
                ip: ipString,
                port: srv.port,
              ));
            }
          }
        }
      }

      client.stop();
    } catch (e) {
      print('mDNS Discovery Error: $e');
    }

    return devices;
  }
}
