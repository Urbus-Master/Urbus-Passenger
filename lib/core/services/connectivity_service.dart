import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

enum ConnectivityStatus { online, offline }

ConnectivityStatus _fromResults(List<ConnectivityResult> results) {
  final isOffline =
      results.isEmpty || results.every((r) => r == ConnectivityResult.none);
  return isOffline ? ConnectivityStatus.offline : ConnectivityStatus.online;
}

class ConnectivityNotifier extends Notifier<ConnectivityStatus> {
  StreamSubscription<List<ConnectivityResult>>? _subscription;

  @override
  ConnectivityStatus build() {
    final connectivity = Connectivity();

    _subscription = connectivity.onConnectivityChanged.listen((results) {
      state = _fromResults(results);
    });
    ref.onDispose(() => _subscription?.cancel());

    // Kick off an initial real check — starts as online until it resolves,
    // matching the previous default and avoiding a false "offline" flash.
    connectivity.checkConnectivity().then((results) {
      state = _fromResults(results);
    });

    return ConnectivityStatus.online;
  }
}

final connectivityProvider = NotifierProvider<ConnectivityNotifier, ConnectivityStatus>(
  ConnectivityNotifier.new,
);
