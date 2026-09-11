import 'dart:async';

import 'package:flutter/material.dart';
import 'package:frosthaven_assistant/Resource/settings.dart';
import 'package:frosthaven_assistant/services/network/client.dart';

import '../../Resource/ui_utils.dart';
import '../service_locator.dart';
import 'network.dart';

class NetworkUI extends StatefulWidget {
  const NetworkUI({super.key, this.network, this.settings, this.client});

  // injected for testing
  final Network? network;
  final Settings? settings;
  final Client? client;

  @override
  State<NetworkUI> createState() => _NetworkUIState();
}

class _NetworkUIState extends State<NetworkUI> {
  Timer? _messageTimer;

  Network get _network => widget.network ?? getIt<Network>();
  Settings get _settings => widget.settings ?? getIt<Settings>();
  Client get _client => widget.client ?? getIt<Client>();

  @override
  void dispose() {
    _messageTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    //dummy ui to get context to make toasts.
    return ValueListenableBuilder<String>(
      valueListenable: _network.networkMessage,
      builder: (context, value, child) {
        _messageTimer?.cancel();
        final message = value;
        final isError = _network.networkMessageIsError.value;
        if (message.isNotEmpty) {
          _messageTimer = Timer(const Duration(milliseconds: 200), () {
            if (!mounted || _network.networkMessage.value != message) return;
            if (message != "") {
              if (isError) {
                showErrorToastStickyWithRetry(context, message, () {
                  if (_settings.client.value != ClientState.connected &&
                      _settings.lastKnownConnection != "") {
                    _settings.client.value = ClientState.connecting;
                    unawaited(_client.connect(_settings.lastKnownConnection));
                    _settings.saveToDisk();
                  }
                });
              } else {
                if (context.mounted) {
                  showToast(context, message);
                }
              }
              _network.networkMessageIsError.value = false;
              _network.networkMessage.value = "";
            }
          });
        }

        return const SizedBox(
          //todo: remove hack?
          width: 0.00001,
          height: 0.00001,
        );
      },
    );
  }
}
