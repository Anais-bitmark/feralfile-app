import 'dart:convert';

import 'package:autonomy_flutter/common/app_config.dart';
import 'package:autonomy_flutter/common/injector.dart';
import 'package:autonomy_flutter/model/tezos_connection.dart';
import 'package:autonomy_flutter/screen/app_router.dart';
import 'package:autonomy_flutter/service/configuration_service.dart';
import 'package:autonomy_flutter/service/tezos_beacon_service.dart';
import 'package:autonomy_flutter/util/custom_exception.dart';
import 'package:autonomy_flutter/util/error_handler.dart';
import 'package:autonomy_flutter/util/log.dart';
import 'package:autonomy_flutter/util/style.dart';
import 'package:autonomy_flutter/util/ui_helper.dart';
import 'package:autonomy_flutter/view/au_filled_button.dart';
import 'package:autonomy_flutter/view/back_appbar.dart';
import 'package:flutter/material.dart';
import 'package:share/share.dart';
import 'package:uuid/uuid.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

class LinkTezosTemplePage extends StatefulWidget {
  const LinkTezosTemplePage({Key? key}) : super(key: key);

  @override
  State<LinkTezosTemplePage> createState() => _LinkTezosTemplePageState();
}

class _LinkTezosTemplePageState extends State<LinkTezosTemplePage> {
  WebSocketChannel? _websocketChannel;
  Peer? _peer;

  @override
  void dispose() {
    super.dispose();

    _websocketChannel?.sink.close();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: getBackAppBar(
          context,
          onBack: () => Navigator.of(context).pop(),
        ),
        body: Container(
          margin: pageEdgeInsetsWithSubmitButton,
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Linking to Temple",
                      style: appTextTheme.headline1,
                    ),
                    addTitleSpace(),
                    Text(
                      "Since Temple only exists as a browser extension, you will need to follow these additional steps to link it to Autonomy: ",
                      style: appTextTheme.bodyText1,
                    ),
                    SizedBox(height: 20),
                    _stepWidget('1',
                        'Generate a link request and send it to the web browser where you are currently signed in to Temple.'),
                    SizedBox(height: 10),
                    _stepWidget('2',
                        'When prompted by Temple, approve Autonomy’s permissions requests. '),
                    SizedBox(height: 40),
                    Row(
                        mainAxisAlignment: MainAxisAlignment.start,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [Expanded(child: _wantMoreSecurityWidget())]),
                  ],
                ),
              ),
            ),
            Row(
              children: [
                Expanded(
                  child: AuFilledButton(
                    text: "GENERATE LINK".toUpperCase(),
                    onPress: () => _generateLinkAndListen(),
                  ),
                ),
              ],
            ),
          ]),
        ));
  }

  Widget _stepWidget(String stepNumber, String stepGuide) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.start,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.only(top: 2),
          child: Text(
            stepNumber,
            style: appTextTheme.caption,
          ),
        ),
        SizedBox(
          width: 10,
        ),
        Expanded(
          child: Text(stepGuide, style: appTextTheme.bodyText1),
        )
      ],
    );
  }

  Widget _wantMoreSecurityWidget() {
    return Container(
      padding: EdgeInsets.all(10),
      color: AppColorTheme.secondaryDimGreyBackground,
      child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Want more security and portability?',
                style: appTextTheme.caption
                    ?.copyWith(color: AppColorTheme.secondaryDimGrey)),
            SizedBox(height: 5),
            Text(
                'You can get all the Tezos functionality of Temple in a mobile app by importing your account to Autonomy.',
                style: bodySmall),
            SizedBox(height: 10),
            Text('Learn more about Autonomy security ...', style: linkStyle),
          ]),
    );
  }

  // MARK: - Handlers
  Future _generateLinkAndListen() async {
    log.info('[LinkTemple][start] _generateLinkAndListen');

    if (_websocketChannel != null) {
      log.info('[LinkTemple][start] close existing channel');
      _websocketChannel!.sink.close();
      _peer = null;
    }

    final tezosBeaconService = injector<TezosBeaconService>();

    final payload = await tezosBeaconService.getPostMessageConnectiopnURI();
    final sessionID = Uuid().v4();
    final link = AppConfig.testNetworkConfig.extensionSupportUrl +
        "?session_id=$sessionID&data=$payload";

    _websocketChannel = WebSocketChannel.connect(
      Uri.parse(AppConfig.testNetworkConfig.websocketUrl +
          '/init?session_id=$sessionID'),
    );

    if (_websocketChannel == null) return;

    log.info('[LinkTemple] connect WebSocketChannel and listen');
    _websocketChannel!.stream.listen((event) {
      log.info("[LinkTemple] _websocketChannel: has event $event");
      Map<String, dynamic> message = json.decode(event);

      final payload = message['payload'];

      if (_peer == null) {
        _handlePostMessageOpenChannel(payload);
      } else {
        _handleMessageResponse(_peer!.publicKey, payload);
      }
    });

    Share.share(link);
  }

  Future _handlePostMessageOpenChannel(String payload) async {
    log.info('[LinkTemple][start] _handlePostMessageOpenChannel');
    final result = await injector<TezosBeaconService>()
        .handlePostMessageOpenChannel(payload);

    final peer = result[0];
    final permissionRequestMessage = result[1];

    if (peer is Peer && permissionRequestMessage is String) {
      _peer = peer;
      final wcEvent = {
        'type': 'encrypted_message',
        'payload': permissionRequestMessage
      };
      _websocketChannel?.sink.add(json.encode(wcEvent));

      log.info('[LinkTemple][done] _handlePostMessageOpenChannel');
      UIHelper.showInfoDialog(context, "Link requested",
          "Autonomy has sent a request to ${peer.name} to link to your account. Please open the wallet and authorize the request.");
    }
  }

  Future _handleMessageResponse(String peerPublicKey, String payload) async {
    log.info('[LinkTemple][start] _handleMessageResponse');
    try {
      final result = await injector<TezosBeaconService>()
          .handlePostMessageMessage(peerPublicKey, payload);

      final tzAddress = result[0];
      final response = result[1];

      UIHelper.hideInfoDialog(context);

      if (_peer != null &&
          tzAddress is String &&
          response is PermissionResponse) {
        final linkedAccount = await injector<TezosBeaconService>()
            .onPostMessageLinked(tzAddress, _peer!, response);
        _websocketChannel?.sink.add(json.encode({
          'type': 'success',
        }));

        log.info('[LinkTemple][Done] _handleMessageResponse');
        UIHelper.showInfoDialog(context, "Account linked",
            "Autonomy has received autorization to link to your NFTs in ${_peer!.name}.");

        Future.delayed(SHOW_DIALOG_DURATION, () {
          UIHelper.hideInfoDialog(context);

          if (injector<ConfigurationService>().isDoneOnboarding()) {
            Navigator.of(context).pushNamed(AppRouter.nameLinkedAccountPage,
                arguments: linkedAccount);
          } else {
            Navigator.of(context).pushNamedAndRemoveUntil(
                AppRouter.nameLinkedAccountPage, (route) => false,
                arguments: linkedAccount);
          }
        });
      } else {
        throw SystemException(
            '[LinkTemple][error] _handleMessageResponse: unexpect param $_peer; $tzAddress; $response');
      }
    } on AbortedException catch (exception) {
      UIHelper.hideInfoDialog(context);
      _websocketChannel?.sink.add(json.encode({
        'type': 'aborted',
      }));
      rethrow;
    } on AlreadyLinkedException catch (exception) {
      UIHelper.hideInfoDialog(context);
      showErrorDiablog(
          context,
          ErrorEvent(
              null,
              "Already linked",
              "You’ve already linked this account to Autonomy.",
              ErrorItemState.seeAccount), defaultAction: () {
        Navigator.of(context).pushNamed(AppRouter.linkedAccountDetailsPage,
            arguments: exception.connection);
      });
    } catch (_) {
      UIHelper.hideInfoDialog(context);
      rethrow;
    }
  }
}
