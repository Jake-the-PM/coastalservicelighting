import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../core/network/network_service.dart';

/// Banner that shows when the app goes offline.
/// Add this at the top of your main Scaffold.
class OfflineBanner extends StatelessWidget {
  const OfflineBanner({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<NetworkService>(
      builder: (context, network, child) {
        return AnimatedSlide(
          offset: network.isOffline ? Offset.zero : const Offset(0, -1),
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOutCubic,
          child: AnimatedOpacity(
            opacity: network.isOffline ? 1.0 : 0.0,
            duration: const Duration(milliseconds: 200),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
              color: Colors.redAccent.shade700,
              child: SafeArea(
                bottom: false,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.wifi_off, size: 16, color: Colors.white),
                    const SizedBox(width: 8),
                    Text(
                      "No Internet Connection",
                      style: GoogleFonts.outfit(
                        color: Colors.white,
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

/// Wrapper widget that adds offline banner to any screen
class NetworkAwareScaffold extends StatelessWidget {
  final PreferredSizeWidget? appBar;
  final Widget body;
  final Widget? floatingActionButton;
  final Widget? bottomNavigationBar;
  final Color? backgroundColor;

  const NetworkAwareScaffold({
    super.key,
    this.appBar,
    required this.body,
    this.floatingActionButton,
    this.bottomNavigationBar,
    this.backgroundColor,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor ?? const Color(0xFF0F172A),
      appBar: appBar,
      floatingActionButton: floatingActionButton,
      bottomNavigationBar: bottomNavigationBar,
      body: Column(
        children: [
          const OfflineBanner(),
          Expanded(child: body),
        ],
      ),
    );
  }
}

/// Shows a snackbar when network status changes
class NetworkStatusListener extends StatefulWidget {
  final Widget child;

  const NetworkStatusListener({super.key, required this.child});

  @override
  State<NetworkStatusListener> createState() => _NetworkStatusListenerState();
}

class _NetworkStatusListenerState extends State<NetworkStatusListener> {
  NetworkStatus? _previousStatus;

  @override
  Widget build(BuildContext context) {
    return Consumer<NetworkService>(
      builder: (context, network, child) {
        // Show snackbar on status change
        if (_previousStatus != null && _previousStatus != network.status) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (network.isOnline && _previousStatus == NetworkStatus.offline) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Row(
                    children: [
                      const Icon(Icons.wifi, color: Colors.white, size: 18),
                      const SizedBox(width: 8),
                      Text("Back online", style: GoogleFonts.outfit(color: Colors.white)),
                    ],
                  ),
                  backgroundColor: Colors.green,
                  duration: const Duration(seconds: 2),
                ),
              );
            }
          });
        }
        _previousStatus = network.status;
        return child!;
      },
      child: widget.child,
    );
  }
}
