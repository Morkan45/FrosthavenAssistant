import 'dart:async';
import 'dart:developer' as developer;
import 'dart:io';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:dart_ipify/dart_ipify.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:network_info_plus/network_info_plus.dart';

import '../service_locator.dart';
import 'network.dart';

class LocalAddressCandidate {
  final String interfaceName;
  final InternetAddress address;

  const LocalAddressCandidate(this.interfaceName, this.address);
}

class NetworkInformation {
  // ignore: prefer-match-file-name, file name uses short form of NetworkInformation
  NetworkInformation({
    Connectivity? connectivity,
    NetworkInfo? networkInfo,
    Future<List<NetworkInterface>> Function()? interfaces,
    Future<String> Function()? publicIp,
  }) : _connectivity = connectivity ?? Connectivity(),
       networkInfo = networkInfo ?? NetworkInfo(),
       _interfaces = interfaces ?? NetworkInterface.list,
       _publicIp = publicIp ?? Ipify.ipv64 {
    _connectivitySubscription = _connectivity.onConnectivityChanged.listen((
      result,
    ) {
      if (result.isNotEmpty && _connectionStatus != result.first) {
        if (_connectionStatus != null && getIt.isRegistered<Network>()) {
          var connection = result.first.name;
          if (result.contains(ConnectivityResult.wifi)) {
            connection = ConnectivityResult.wifi.name;
          }
          getIt<Network>().networkMessage.value =
              'Network connection: $connection';
        }
        _connectionStatus = result.first;
      }
      initNetworkInfo();
    });
  }

  final NetworkInfo networkInfo;
  final Connectivity _connectivity;
  final Future<List<NetworkInterface>> Function() _interfaces;
  final Future<String> Function() _publicIp;
  ConnectivityResult? _connectionStatus;
  StreamSubscription<List<ConnectivityResult>>? _connectivitySubscription;
  Future<void>? _refresh;
  bool _disposed = false;

  final Set<String> wifiIPv6List = {};
  final wifiIPv6 = ValueNotifier<String>('');
  final outgoingIPv6 = ValueNotifier<String>('');

  static String? selectLocalIPv4(Iterable<LocalAddressCandidate> candidates) {
    final usable = usableLocalIPv4(candidates).toList();

    int priority(LocalAddressCandidate candidate) {
      final name = candidate.interfaceName.toLowerCase();
      if (name.contains('wi-fi') ||
          name.contains('wifi') ||
          name.contains('wlan')) {
        return 0;
      }
      if (name.contains('ethernet') || name.startsWith('eth')) {
        return 1;
      }
      return 2;
    }

    usable.sort((a, b) => priority(a).compareTo(priority(b)));
    return usable.isEmpty ? null : usable.first.address.address;
  }

  static Iterable<LocalAddressCandidate> usableLocalIPv4(
    Iterable<LocalAddressCandidate> candidates,
  ) {
    return candidates.where((candidate) {
      final address = candidate.address;
      final name = candidate.interfaceName.toLowerCase();
      return address.type == InternetAddressType.IPv4 &&
          !address.isLoopback &&
          !address.isLinkLocal &&
          !address.isMulticast &&
          !name.contains('virtual') &&
          !name.contains('veth') &&
          !name.contains('docker') &&
          !name.contains('switch');
    });
  }

  Future<void> initNonWifiIPs() async {
    final candidates = <LocalAddressCandidate>[];
    for (final interface in await _interfaces()) {
      for (final address in interface.addresses) {
        candidates.add(LocalAddressCandidate(interface.name, address));
      }
    }
    final address = selectLocalIPv4(candidates);
    if (address != null) {
      wifiIPv6List.add(address);
      if (wifiIPv6.value.isEmpty) wifiIPv6.value = address;
    }
  }

  Future<void> initNetworkInfo() async {
    return _refresh ??= _refreshNetworkInfo().whenComplete(
      () => _refresh = null,
    );
  }

  Future<void> _refreshNetworkInfo() async {
    final localAddresses = <String>{};
    String? wifiAddress;

    try {
      final wifiAddress = await networkInfo.getWifiIP();
      if (wifiAddress != null &&
          InternetAddress.tryParse(wifiAddress)?.type ==
              InternetAddressType.IPv4) {
        localAddresses.add(wifiAddress);
      }
    } on PlatformException catch (error) {
      developer.log('Failed to get Wi-Fi IP', error: error);
    }
    final candidates = <LocalAddressCandidate>[];
    for (final interface in await _interfaces()) {
      for (final address in interface.addresses) {
        candidates.add(LocalAddressCandidate(interface.name, address));
      }
    }
    localAddresses.addAll(
      usableLocalIPv4(candidates).map((item) => item.address.address),
    );
    if (_disposed) return;
    wifiIPv6List
      ..clear()
      ..addAll(localAddresses);
    wifiIPv6.value = wifiAddress ?? selectLocalIPv4(candidates) ?? '';

    try {
      final publicAddress = await _publicIp().timeout(
        const Duration(seconds: 3),
      );
      if (!_disposed) outgoingIPv6.value = publicAddress;
    } catch (_) {
      if (!_disposed) outgoingIPv6.value = '';
    }

    developer.log(
      'Local IPv4: ${wifiIPv6.value}\n'
      'Outgoing IP: ${outgoingIPv6.value}\n',
    );
  }

  Future<void> dispose() async {
    _disposed = true;
    await _connectivitySubscription?.cancel();
    wifiIPv6.dispose();
    outgoingIPv6.dispose();
  }
}
