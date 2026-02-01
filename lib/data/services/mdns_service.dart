import 'package:multicast_dns/multicast_dns.dart';
import '../../core/constants/app_specs.dart';

class MDnsDiscoveryService {
  /// Scans for WLED devices for a set duration.
  /// Returns a Stream of discovered IP addresses.
  Stream<String> scanForWledDevices({Duration timeout = AppSpecs.lanDiscoveryTimeout}) async* {
    final MDnsClient client = MDnsClient();
    
    try {
      await client.start();
      
      // Look for WLED specific service
      await for (final PtrResourceRecord ptr in client.lookup<PtrResourceRecord>(
        ResourceRecordQuery.serverPointer('_wled._tcp.local'),
      ).timeout(timeout, onTimeout: (sink) => sink.close())) {
        
        await for (final SrvResourceRecord srv in client.lookup<SrvResourceRecord>(
          ResourceRecordQuery.service(ptr.domainName),
        )) {
           await for (final IPAddressResourceRecord ip in client.lookup<IPAddressResourceRecord>(
             ResourceRecordQuery.addressIPv4(srv.target),
           )) {
             yield ip.address.address;
           }
        }
      }
    } catch (e) {
      print("mDNS Scan Error: $e");
    } finally {
      client.stop();
    }
  }

  /// Quick One-Shot: Returns first WLED found or null
  Future<String?> findFirstWled() async {
    try {
      final stream = scanForWledDevices(timeout: const Duration(seconds: 3));
      return await stream.first;
    } catch (e) {
      return null;
    }
  }
}
