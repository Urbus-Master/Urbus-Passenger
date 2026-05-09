import 'package:flutter_riverpod/flutter_riverpod.dart';

enum ConnectivityStatus { online, offline }

class ConnectivityNotifier extends Notifier<ConnectivityStatus> {
  @override
  ConnectivityStatus build() => ConnectivityStatus.online;

  void toggle() => state = state == ConnectivityStatus.online 
      ? ConnectivityStatus.offline 
      : ConnectivityStatus.online;
}

final connectivityProvider = NotifierProvider<ConnectivityNotifier, ConnectivityStatus>(
  ConnectivityNotifier.new,
);
