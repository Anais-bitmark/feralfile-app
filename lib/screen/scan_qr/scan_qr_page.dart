import 'dart:developer';
import 'dart:io';

import 'package:autonomy_flutter/common/injector.dart';
import 'package:autonomy_flutter/screen/app_router.dart';
import 'package:autonomy_flutter/screen/bloc/feralfile/feralfile_bloc.dart';
import 'package:autonomy_flutter/service/tezos_beacon_service.dart';
import 'package:autonomy_flutter/service/wallet_connect_service.dart';
import 'package:autonomy_flutter/util/style.dart';
import 'package:autonomy_flutter/view/back_appbar.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/src/provider.dart';
import 'package:qr_code_scanner/qr_code_scanner.dart';

class ScanQRPage extends StatefulWidget {
  static const String tag = AppRouter.scanQRPage;

  final ScannerItem scannerItem;

  const ScanQRPage({Key? key, this.scannerItem = ScannerItem.GLOBAL})
      : super(key: key);

  @override
  _ScanQRPageState createState() => _ScanQRPageState();
}

class _ScanQRPageState extends State<ScanQRPage> {
  final GlobalKey qrKey = GlobalKey(debugLabel: 'QR');
  late QRViewController controller;
  var isScanDataError = false;

  // In order to get hot reload to work we need to pause the camera if the platform
  // is android, or resume the camera if the platform is iOS.
  @override
  void reassemble() {
    super.reassemble();
    if (Platform.isAndroid) {
      controller.pauseCamera();
    } else if (Platform.isIOS) {
      controller.resumeCamera();
    }
  }

  @override
  void initState() {
    super.initState();

    checkPermission();
  }

  Future checkPermission() async {
    await Permission.camera.request();
    final status = await Permission.camera.status;

    if (status.isPermanentlyDenied) {
      openAppSettings();
    }
  }

  @override
  Widget build(BuildContext context) {
    final qrSize = MediaQuery.of(context).size.width - 90;
    return Scaffold(
      body: Stack(
        children: <Widget>[
          Container(
            child: QRView(
              key: qrKey,
              overlay: QrScannerOverlayShape(
                borderColor: isScanDataError ? Colors.red : Colors.black,
                cutOutSize: qrSize,
                borderRadius: 20,
                borderWidth: 8,
                borderLength: qrSize / 2,
              ),
              onQRViewCreated: _onQRViewCreated,
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(15, 55, 15, 0),
            child: GestureDetector(
              behavior: HitTestBehavior.translucent,
              onTap: () => Navigator.of(context).pop(),
              child: Row(
                children: [
                  Icon(CupertinoIcons.back, color: Colors.white),
                  Text(
                    "BACK",
                    style: appTextTheme.caption?.copyWith(color: Colors.white),
                  ),
                ],
              ),
            ),
          ),
          Padding(
            padding: EdgeInsets.fromLTRB(0, qrSize + 40, 0, 0),
            child: Center(
              child: Text(
                "SCAN QR CODE",
                style: appTextTheme.button?.copyWith(color: Colors.white),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _onQRViewCreated(QRViewController controller) {
    this.controller = controller;
    controller.scannedDataStream.listen((scanData) async {
      if (scanData.code == null) return;

      final code = scanData.code!;

      switch (widget.scannerItem) {
        case ScannerItem.WALLET_CONNECT:
          if (code.startsWith("wc:") == true) {
            _handleWalletConnect(code);
          } else {
            setState(() {
              isScanDataError = true;
            });
          }
          break;

        case ScannerItem.BEACON_CONNECT:
          if (code.startsWith("tezos://") == true) {
            _handleBeaconConnect(code);
          } else {
            setState(() {
              isScanDataError = true;
            });
          }
          break;

        case ScannerItem.FERALFILE_TOKEN:
          if (code.startsWith("feralfile-api:") == true) {
            controller.dispose();
            Navigator.pop(context, code);
          } else {
            setState(() {
              isScanDataError = true;
            });
          }
          break;

        case ScannerItem.ETH_ADDRESS:
        case ScannerItem.XTZ_ADDRESS:
          controller.dispose();
          Navigator.pop(context, code);
          break;
        case ScannerItem.GLOBAL:
          if (code.startsWith("wc:") == true) {
            _handleWalletConnect(code);
          } else if (code.startsWith("tezos:") == true) {
            _handleBeaconConnect(code);
          } else if (code.startsWith("feralfile-api:") == true) {
            _handleFeralFileToken(code);
            /* TODO: Remove or support for multiple wallets
          } else if (code.startsWith("tz1")) {
            Navigator.of(context).popAndPushNamed(SendCryptoPage.tag,
                arguments: SendData(CryptoType.XTZ, code));
          } else {
            try {
              final _ = EthereumAddress.fromHex(code);
              Navigator.of(context).popAndPushNamed(SendCryptoPage.tag,
                  arguments: SendData(CryptoType.ETH, code));
            } catch (err) {
              log(err.toString());
            }
            */
          } else {
            setState(() {
              isScanDataError = true;
            });
          }
          break;
      }
    });
  }

  void _handleWalletConnect(String code) {
    controller.dispose();
    injector<WalletConnectService>().connect(code);
    Navigator.of(context).pop();
  }

  void _handleBeaconConnect(String code) {
    controller.dispose();
    injector<TezosBeaconService>().addPeer(code);
    Navigator.of(context).pop();
  }

  void _handleFeralFileToken(String code) {
    controller.dispose();
    context.read<FeralfileBloc>().add(LinkFFAccountInfoEvent(code));
    Navigator.of(context).pop();
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }
}

enum ScannerItem {
  WALLET_CONNECT,
  BEACON_CONNECT,
  ETH_ADDRESS,
  XTZ_ADDRESS,
  FERALFILE_TOKEN,
  GLOBAL
}

extension ScannerItemValue on ScannerItem {
  String pureValue(String string) {
    switch (this) {
      case ScannerItem.FERALFILE_TOKEN:
        return string.replaceFirst("feralfile-api:", "");
      default:
        return string;
    }
  }
}
