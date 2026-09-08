import 'dart:async';

import 'package:flutter/material.dart';

import '../../../Resource/app_constants.dart';
import '../../persistence_action.dart';
import '../../view_models/main_menu_view_model.dart';
import '../../../Resource/settings.dart';
import '../../../Resource/state/game_state.dart';
import '../../../l10n/app_localizations.dart';
import '../../../services/network/client.dart';
import '../../../services/network/network.dart';

class SettingsNetworkSection extends StatefulWidget {
  static const double _kInputWidth = 200.0;
  static const double _kInputHeight = 40.0;
  static const double _kDropdownHeight = 20.0;
  static const int _kPortMaxLength = 6;

  const SettingsNetworkSection({
    super.key,
    required this.settings,
    required this.network,
    required this.client,
    required this.gameState,
  });

  final Settings settings;
  final Network network;
  final Client client;
  final GameState gameState;

  @override
  SettingsNetworkSectionState createState() => SettingsNetworkSectionState();
}

class SettingsNetworkSectionState extends State<SettingsNetworkSection> {
  final TextEditingController _serverTextController = TextEditingController();
  final TextEditingController _portTextController = TextEditingController();

  @override
  void initState() {
    super.initState();
    widget.network.networkInfo.initNetworkInfo();
    _serverTextController.text = widget.settings.lastKnownConnection;
    _portTextController.text = widget.settings.lastKnownPort;
  }

  @override
  void dispose() {
    _serverTextController.dispose();
    _portTextController.dispose();
    super.dispose();
  }

  List<DropdownMenuItem<String>> _getIPList() {
    return widget.network.networkInfo.wifiIPv6List
        .map((item) => DropdownMenuItem<String>(value: item, child: Text(item)))
        .toList();
  }

  MainMenuViewModel get _roles => MainMenuViewModel(
    gameState: widget.gameState,
    settings: widget.settings,
    client: widget.client,
    network: widget.network,
  );

  Future<void> _toggleClientConnection() => runPersistenceAction(
    context,
    () => _roles.toggleClientConnection(
      address: _serverTextController.text,
      port: _portTextController.text,
    ),
  );

  Future<void> _toggleServer() => runPersistenceAction(
    context,
    () => _roles.toggleServer(port: _portTextController.text),
  );
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(AppLocalizations.of(context)!.networkConnectLocal),
        ValueListenableBuilder<bool>(
          valueListenable: widget.network.roleChangePending,
          builder: (context, roleChangePending, _) =>
              ValueListenableBuilder<ClientState>(
                valueListenable: widget.settings.client,
                builder: (context, value, child) {
                  final l10n = AppLocalizations.of(context)!;
                  bool connected = false;
                  final clientState = widget.settings.client.value;
                  String connectionText = l10n.connectAsClientLabel;
                  if (clientState == ClientState.connected) {
                    connected = true;
                    connectionText = l10n.connectedAsClient;
                  }
                  if (clientState == ClientState.connecting) {
                    connectionText = l10n.connecting;
                  }
                  return CheckboxListTile(
                    enabled:
                        !roleChangePending &&
                        !widget.settings.server.value &&
                        widget.settings.client.value != ClientState.connecting,
                    secondary: clientState == ClientState.connecting
                        ? IconButton(
                            icon: const Icon(Icons.close),
                            tooltip: l10n.cancelConnect,
                            onPressed: () => widget.client.cancelConnect(),
                          )
                        : null,
                    title: Text(connectionText),
                    value: connected,
                    onChanged: (bool? value) =>
                        unawaited(_toggleClientConnection()),
                  );
                },
              ),
        ),
        Container(
          margin: const EdgeInsets.only(
            top: SettingsNetworkSection._kInputHeight,
          ),
          width: SettingsNetworkSection._kInputWidth,
          child: TextField(
            controller: _serverTextController,
            decoration: InputDecoration(
              counterText: "",
              helperText: AppLocalizations.of(context)!.networkServerIpHint,
            ),
          ),
        ),
        Container(
          margin: const EdgeInsets.only(top: kMenuTopPadding),
          width: SettingsNetworkSection._kInputWidth,
          height: SettingsNetworkSection._kInputHeight,
          child: TextField(
            keyboardType: TextInputType.number,
            controller: _portTextController,
            decoration: InputDecoration(
              counterText: "",
              helperText: AppLocalizations.of(context)!.networkPortHint,
            ),
            maxLength: SettingsNetworkSection._kPortMaxLength,
          ),
        ),
        ValueListenableBuilder<bool>(
          valueListenable: widget.network.roleChangePending,
          builder: (context, roleChangePending, _) =>
              ValueListenableBuilder<bool>(
                valueListenable: widget.settings.server,
                builder: (context, value, child) {
                  final l10n = AppLocalizations.of(context)!;
                  return CheckboxListTile(
                    enabled:
                        !roleChangePending &&
                        widget.settings.client.value != ClientState.connecting,
                    title: Text(
                      widget.settings.server.value
                          ? l10n.stopServerButton
                          : l10n.startHostServerButton,
                    ),
                    value: widget.settings.server.value,
                    onChanged: (bool? value) => unawaited(_toggleServer()),
                  );
                },
              ),
        ),
        ValueListenableBuilder<String>(
          valueListenable: widget.network.networkInfo.wifiIPv6,
          builder: (context, value, child) {
            return SizedBox(
              width: SettingsNetworkSection._kInputWidth,
              height: SettingsNetworkSection._kDropdownHeight,
              child: DropdownButtonHideUnderline(
                child: DropdownButton(
                  value: widget.network.networkInfo.wifiIPv6.value,
                  items: _getIPList(),
                  onChanged: (value) =>
                      widget.network.networkInfo.wifiIPv6.value = value ?? "",
                ),
              ),
            );
          },
        ),
        ValueListenableBuilder<String>(
          valueListenable: widget.network.networkInfo.outgoingIPv6,
          builder: (context, value, child) {
            return SizedBox(
              width: SettingsNetworkSection._kInputWidth,
              height: SettingsNetworkSection._kDropdownHeight,
              child: Text(widget.network.networkInfo.outgoingIPv6.value),
            );
          },
        ),
      ],
    );
  }
}
