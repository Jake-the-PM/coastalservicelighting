import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

/// Network connectivity status
enum NetworkStatus { online, offline, checking }

/// Service to monitor network connectivity and provide retry logic.
class NetworkService extends ChangeNotifier {
  final Connectivity _connectivity = Connectivity();
  StreamSubscription<ConnectivityResult>? _subscription;
  
  NetworkStatus _status = NetworkStatus.checking;
  NetworkStatus get status => _status;
  
  bool get isOnline => _status == NetworkStatus.online;
  bool get isOffline => _status == NetworkStatus.offline;

  NetworkService() {
    _init();
  }

  void _init() async {
    // Initial check
    await _checkConnectivity();
    
    // Listen for changes
    _subscription = _connectivity.onConnectivityChanged.listen((result) {
      _updateStatus(result);
    });
  }

  Future<void> _checkConnectivity() async {
    final result = await _connectivity.checkConnectivity();
    _updateStatus(result);
  }

  void _updateStatus(ConnectivityResult result) {
    final hasConnection = 
      result == ConnectivityResult.wifi || 
      result == ConnectivityResult.mobile || 
      result == ConnectivityResult.ethernet;
    
    final newStatus = hasConnection ? NetworkStatus.online : NetworkStatus.offline;
    
    if (_status != newStatus) {
      _status = newStatus;
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }
}

/// Retry logic for API calls with exponential backoff
class RetryHelper {
  /// Execute a function with automatic retry on failure.
  /// 
  /// [maxRetries] - Maximum number of retry attempts (default: 3)
  /// [baseDelay] - Initial delay before first retry (default: 1 second)
  /// [exponential] - Whether to use exponential backoff (default: true)
  static Future<T> withRetry<T>({
    required Future<T> Function() action,
    int maxRetries = 3,
    Duration baseDelay = const Duration(seconds: 1),
    bool exponential = true,
    void Function(int attempt, Object error)? onRetry,
  }) async {
    int attempt = 0;
    
    while (true) {
      try {
        return await action();
      } catch (e) {
        attempt++;
        
        if (attempt >= maxRetries) {
          rethrow;
        }
        
        onRetry?.call(attempt, e);
        
        // Calculate delay
        final delay = exponential 
            ? baseDelay * (1 << (attempt - 1)) // 1s, 2s, 4s, ...
            : baseDelay;
        
        await Future.delayed(delay);
      }
    }
  }
}

/// Extension to add retry capability to Future
extension RetryExtension<T> on Future<T> {
  /// Retry this future on failure.
  Future<T> withRetry({
    int maxRetries = 3,
    Duration baseDelay = const Duration(seconds: 1),
  }) {
    return RetryHelper.withRetry(
      action: () => this,
      maxRetries: maxRetries,
      baseDelay: baseDelay,
    );
  }
}
