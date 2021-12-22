import 'dart:convert';

import 'package:autonomy_flutter/common/injector.dart';
import 'package:autonomy_flutter/service/ethereum_service.dart';
import 'package:autonomy_flutter/service/wallet_connect_service.dart';
import 'package:autonomy_flutter/view/back_appbar.dart';
import 'package:autonomy_flutter/view/filled_button.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:wallet_connect/models/wc_peer_meta.dart';
import 'package:web3dart/crypto.dart';

class WCSignMessagePage extends StatelessWidget {
  static const String tag = 'wc_sign_message';

  final WCSignMessagePageArgs args;

  const WCSignMessagePage({Key? key, required this.args}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final message = hexToBytes(args.message);
    final messageInUtf8 = utf8.decode(message);

    return Scaffold(
      appBar: getBackAppBar(
        context,
        onBack: () {
          injector<WalletConnectService>().rejectRequest(args.peerMeta, args.id);
          Navigator.of(context).pop();
        },
      ),
      body: Container(
        margin: EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(height: 8.0),
                    Text(
                      "Confirm",
                      style: Theme.of(context).textTheme.headline1,
                    ),
                    SizedBox(height: 40.0),
                    Text(
                      "Connection",
                      style: Theme.of(context).textTheme.headline5,
                    ),
                    SizedBox(height: 16.0),
                    Text(
                      args.peerMeta.name,
                      style: Theme.of(context).textTheme.bodyText2,
                    ),
                    Divider(height: 32),
                    Text(
                      "Message",
                      style: Theme.of(context).textTheme.headline5,
                    ),
                    SizedBox(height: 16.0),
                    Text(
                      messageInUtf8,
                      style: Theme.of(context).textTheme.bodyText2,
                    ),
                  ],
                ),
              ),
            ),
            FilledButton(
              text: "Sign".toUpperCase(),
              onPress: () async {
                final signature = await injector<EthereumService>().signPersonalMessage(message);
                injector<WalletConnectService>().approveRequest(args.peerMeta, args.id, signature);
                Navigator.of(context).pop();
              },
            ),
          ],
        ),
      ),
    );
  }
}

class WCSignMessagePageArgs {
  final int id;
  final WCPeerMeta peerMeta;
  final String message;

  WCSignMessagePageArgs(this.id, this.peerMeta, this.message);
}
