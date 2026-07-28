import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:frosthaven_assistant/services/network/network_info.dart';

void main() {
  test('selects an Ethernet IPv4 address when Wi-Fi is unavailable', () {
    final selected = NetworkInformation.selectLocalIPv4([
      LocalAddressCandidate('Loopback', InternetAddress.loopbackIPv4),
      LocalAddressCandidate('Ethernet', InternetAddress('192.168.20.15')),
    ]);

    expect(selected, '192.168.20.15');
  });

  test('prefers Wi-Fi over Ethernet and ignores virtual adapters', () {
    final selected = NetworkInformation.selectLocalIPv4([
      LocalAddressCandidate(
        'vEthernet (Default Switch)',
        InternetAddress('172.20.0.1'),
      ),
      LocalAddressCandidate('Ethernet', InternetAddress('192.168.20.15')),
      LocalAddressCandidate('Wi-Fi', InternetAddress('192.168.20.22')),
    ]);

    expect(selected, '192.168.20.22');
  });

  test('does not advertise IPv6 or loopback candidates', () {
    final selected = NetworkInformation.selectLocalIPv4([
      LocalAddressCandidate('Wi-Fi', InternetAddress('fe80::1')),
      LocalAddressCandidate('Loopback', InternetAddress.loopbackIPv4),
    ]);

    expect(selected, isNull);
  });
}
