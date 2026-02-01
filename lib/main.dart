import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'core/theme/app_theme.dart';
import 'core/constants/app_specs.dart';
import 'core/config/supabase_config.dart';
import 'data/repositories/lighting_repository.dart';
import 'data/services/auth_service.dart';
import 'data/services/automation_service.dart';
import 'data/services/installation_service.dart';
import 'data/services/cloud_installation_service.dart';
import 'data/services/bridge_relay_service.dart';
import 'data/services/schedule_service.dart';
import 'data/services/device_discovery_service.dart';
import 'core/background/background_scheduler.dart';
import 'core/network/network_service.dart';
import 'data/wled/wled_client.dart';
import 'presentation/auth/auth_gate.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  // INSTANT LAUNCH: No async delays here.
  runApp(const BootstrapApp());
}

/// The "Loader" App that runs immediately.
/// It creates a lightweight MaterialApp to show the Splash immediately
/// while initializing the heavy backend in the background.
class BootstrapApp extends StatefulWidget {
  const BootstrapApp({super.key});

  @override
  State<BootstrapApp> createState() => _BootstrapAppState();
}

class _BootstrapAppState extends State<BootstrapApp> {
  // Using a Future to track initialization so it only happens once
  late final Future<void> _initFuture;

  @override
  void initState() {
    super.initState();
    _initFuture = _initializeSystem();
  }

  Future<void> _initializeSystem() async {
    // 1. Initialize Supabase
    await Supabase.initialize(
      url: SupabaseConfig.url,
      anonKey: SupabaseConfig.anonKey,
    );

    // Initialize Background Workmanager (Headless)
    await BackgroundScheduler.init();
    // 2. (Optional) Initialize SharedPreferences here if essential for Theme
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: _initFuture,
      builder: (context, snapshot) {
        // If error, show retry UI
        if (snapshot.hasError) {
          return MaterialApp(
            debugShowCheckedModeBanner: false,
            home: Scaffold(
              backgroundColor: const Color(0xFF050E1C), // Navy
              body: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.signal_wifi_off, color: Colors.white, size: 48),
                    const SizedBox(height: 16),
                    Text(
                      "CONNECTION ERROR", 
                      style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)
                    ),
                    const SizedBox(height: 8),
                    Text(
                      "${snapshot.error}",
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.white70)
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton(
                      onPressed: () {
                         setState(() {
                           _initFuture = _initializeSystem();
                         });
                      },
                      child: const Text("RETRY"),
                    )
                  ],
                ),
              ),
            ),
          );
        }

        // If done, mount the REAL app (Providers & Logic)
        if (snapshot.connectionState == ConnectionState.done) {
          return const CoastalAppRoot();
        }

        // Otherwise, show the visual Splash (Lightweight)
        return MaterialApp(
          debugShowCheckedModeBanner: false,
          home: Scaffold(
            backgroundColor: const Color(0xFF050E1C),
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Image.asset('assets/images/logo.png', width: 120),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

/// The Real Shell (Renamed from CoastalApp)
/// Only mounted when dependencies are ready.
class CoastalAppRoot extends StatelessWidget {
  const CoastalAppRoot({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        // Authentication (must be first - other services may depend on it)
        ChangeNotifierProvider(create: (_) => AuthService()),
        
        // Auto-Discovery Service (Needed for Self-Healing)
        ChangeNotifierProvider(create: (_) => DeviceDiscoveryService()),

        // Local device management
        ChangeNotifierProxyProvider<DeviceDiscoveryService, LightingRepository>(
          create: (_) => LightingRepository(WledClient()),
          update: (_, discovery, repo) => repo!..setDiscoveryService(discovery),
        ),
        
        // Automation depends on LightingRepository
        ProxyProvider<LightingRepository, AutomationService>(
          update: (_, repo, __) => AutomationService(repo),
        ),
        
        // Phase 2: Device Registry (Fleet Management)
        ChangeNotifierProvider(create: (_) => InstallationService()),
        
        // Cloud Sync
        ChangeNotifierProvider(create: (_) => CloudInstallationService()),
        
        // Remote Access (Bridge Mode)
        ChangeNotifierProvider(create: (_) => BridgeRelayService()),
        
        // Network Connectivity
        ChangeNotifierProvider(create: (_) => NetworkService()),
        
        // Scheduling (Sunrise/Sunset Automation)
        ChangeNotifierProxyProvider<LightingRepository, ScheduleService>(
          create: (context) => ScheduleService(context.read<LightingRepository>()),
          update: (_, repo, service) => service!,
        ),
        
      ],
      child: MaterialApp(
        title: AppSpecs.appName,
        debugShowCheckedModeBanner: false,
        theme: AppTheme.darkTheme,
        home: const AuthGate(),
        scrollBehavior: const MaterialScrollBehavior().copyWith(
          dragDevices: {
            PointerDeviceKind.mouse,
            PointerDeviceKind.touch,
            PointerDeviceKind.stylus,
            PointerDeviceKind.trackpad,
            PointerDeviceKind.unknown,
          },
        ),
      ),
    );
  }
}
