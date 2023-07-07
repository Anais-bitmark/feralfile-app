//
//  SPDX-License-Identifier: BSD-2-Clause-Patent
//  Copyright © 2022 Bitmark. All rights reserved.
//  Use of this source code is governed by the BSD-2-Clause Plus Patent License
//  that can be found in the LICENSE file.
//

import 'dart:convert';
import 'dart:io';

import 'package:autonomy_flutter/common/injector.dart';
import 'package:autonomy_flutter/database/cloud_database.dart';
import 'package:autonomy_flutter/main.dart';
import 'package:autonomy_flutter/screen/app_router.dart';
import 'package:autonomy_flutter/screen/bloc/accounts/accounts_bloc.dart'
    as accounts;
import 'package:autonomy_flutter/screen/bloc/ethereum/ethereum_bloc.dart';
import 'package:autonomy_flutter/screen/bloc/feralfile/feralfile_bloc.dart';
import 'package:autonomy_flutter/screen/bloc/persona/persona_bloc.dart';
import 'package:autonomy_flutter/screen/bloc/tezos/tezos_bloc.dart';
import 'package:autonomy_flutter/screen/global_receive/receive_page.dart';
import 'package:autonomy_flutter/service/audit_service.dart';
import 'package:autonomy_flutter/service/canvas_client_service.dart';
import 'package:autonomy_flutter/service/deeplink_service.dart';
import 'package:autonomy_flutter/service/feralfile_service.dart';
import 'package:autonomy_flutter/service/metric_client_service.dart';
import 'package:autonomy_flutter/service/navigation_service.dart';
import 'package:autonomy_flutter/service/tezos_beacon_service.dart';
import 'package:autonomy_flutter/service/wallet_connect_service.dart';
import 'package:autonomy_flutter/service/wc2_service.dart';
import 'package:autonomy_flutter/util/constants.dart';
import 'package:autonomy_flutter/util/error_handler.dart';
import 'package:autonomy_flutter/util/log.dart';
import 'package:autonomy_flutter/util/string_ext.dart';
import 'package:autonomy_flutter/util/style.dart';
import 'package:autonomy_flutter/util/ui_helper.dart';
import 'package:autonomy_flutter/util/wallet_connect_ext.dart';
import 'package:autonomy_flutter/view/back_appbar.dart';
import 'package:autonomy_flutter/view/primary_button.dart';
import 'package:autonomy_theme/autonomy_theme.dart';
import 'package:autonomy_tv_proto/models/canvas_device.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:qr_code_scanner/qr_code_scanner.dart';
import 'package:synchronized/synchronized.dart';

class ScanQRPage extends StatefulWidget {
  static const String tag = AppRouter.scanQRPage;

  final ScannerItem scannerItem;

  const ScanQRPage({Key? key, this.scannerItem = ScannerItem.GLOBAL})
      : super(key: key);

  @override
  State<ScanQRPage> createState() => _ScanQRPageState();
}

class _ScanQRPageState extends State<ScanQRPage>
    with RouteAware, TickerProviderStateMixin {
  final GlobalKey qrKey = GlobalKey(debugLabel: 'QR');
  late QRViewController controller;
  var isScanDataError = false;
  var _isLoading = false;
  bool cameraPermission = false;
  String? currentCode;
  late TabController _tabController;
  final metricClient = injector<MetricClientService>();
  final _navigationService = injector<NavigationService>();
  late Lock _lock;

  @override
  void initState() {
    super.initState();
    //There is a conflict with lib qr_code_scanner on Android.
    if (Platform.isIOS) {
      SystemChrome.setEnabledSystemUIMode(SystemUiMode.leanBack);
    }
    _tabController = TabController(length: 2, vsync: this);
    checkPermission();
    _lock = Lock();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    routeObserver.subscribe(this, ModalRoute.of(context)!);
  }

  Future checkPermission() async {
    await Permission.camera.request();
    final status = await Permission.camera.status;

    if (status.isPermanentlyDenied || status.isDenied) {
      if (cameraPermission) {
        setState(() {
          cameraPermission = false;
        });
      }
    } else {
      if (!cameraPermission) {
        setState(() {
          cameraPermission = true;
        });
      }
      if (Platform.isAndroid) {
        Future.delayed(const Duration(seconds: 1), () {
          controller.resumeCamera();
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final size1 = MediaQuery.of(context).size.height / 2;
    final qrSize = size1 < 240.0 ? size1 : 240.0;

    var cutPaddingTop = qrSize + 500 - MediaQuery.of(context).size.height;
    if (cutPaddingTop < 0) cutPaddingTop = 0;
    final theme = Theme.of(context);
    return BlocListener<FeralfileBloc, FeralFileState>(
      listener: (context, state) {
        final event = state.event;
        if (event == null) return;

        if (event is LinkAccountSuccess) {
          Navigator.of(context).pop();
        } else if (event is AlreadyLinkedError) {
          showErrorDiablog(
              context,
              ErrorEvent(
                  null,
                  "already_linked".tr(),
                  "al_you’ve_already".tr(),
                  //"You’ve already linked this account to Autonomy.",
                  ErrorItemState.seeAccount), defaultAction: () {
            Navigator.of(context).pushReplacementNamed(
                AppRouter.linkedAccountDetailsPage,
                arguments: event.connection);
          }, cancelAction: () {
            controller.resumeCamera();
          });
        } else if (event is NotFFLoggedIn) {
          _handleError("feralfile-api:qrcode-with-feralfile-format");
          controller.resumeCamera();
        }
      },
      child: Scaffold(
        body: Stack(
          children: <Widget>[
            if (!cameraPermission)
              _noPermissionView()
            else
              Stack(
                children: [
                  Column(
                    children: [
                      Expanded(
                        child: TabBarView(
                          controller: _tabController,
                          children: [
                            Stack(
                              children: [
                                _qrView(),
                                Scaffold(
                                  backgroundColor: Colors.transparent,
                                  appBar: getCloseAppBar(
                                    context,
                                    onClose: () => Navigator.of(context).pop(),
                                    withBottomDivider: false,
                                    icon: closeIcon(color: AppColor.white),
                                  ),
                                ),
                                Padding(
                                  padding: EdgeInsets.fromLTRB(
                                    0,
                                    MediaQuery.of(context).size.height / 2 +
                                        qrSize / 2 -
                                        cutPaddingTop,
                                    0,
                                    30,
                                  ),
                                  child: Center(
                                    child: Column(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        _instructionView(),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            MultiBlocProvider(providers: [
                              BlocProvider(
                                  create: (_) => accounts.AccountsBloc(
                                      injector(),
                                      injector<CloudDatabase>(),
                                      injector(),
                                      injector<AuditService>(),
                                      injector())),
                              BlocProvider(
                                create: (_) => PersonaBloc(
                                  injector<CloudDatabase>(),
                                  injector(),
                                  injector(),
                                  injector<AuditService>(),
                                ),
                              ),
                              BlocProvider(
                                  create: (_) =>
                                      EthereumBloc(injector(), injector())),
                              BlocProvider(
                                create: (_) =>
                                    TezosBloc(injector(), injector()),
                              ),
                            ], child: const GlobalReceivePage()),
                          ],
                        ),
                      ),
                    ],
                  ),
                  Align(
                    alignment: Alignment.bottomCenter,
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16.0, 10, 16.0, 40),
                      child: Container(
                        height: 55,
                        padding: const EdgeInsets.all(5),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(50),
                          color: theme.auLightGrey,
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: OutlineButton(
                                onTap: () {
                                  _tabController.animateTo(0,
                                      duration:
                                          const Duration(milliseconds: 300));
                                  setState(() {});
                                },
                                text: 'scan_code'.tr(),
                                color: _tabController.index == 0
                                    ? theme.colorScheme.primary
                                    : theme.auLightGrey,
                                borderColor: Colors.transparent,
                                textColor: _tabController.index == 1
                                    ? AppColor.disabledColor
                                    : AppColor.white,
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: OutlineButton(
                                onTap: () {
                                  _tabController.animateTo(1,
                                      duration:
                                          const Duration(milliseconds: 300));
                                  setState(() {});
                                },
                                text: 'show_my_code'.tr(),
                                color: _tabController.index == 1
                                    ? theme.colorScheme.primary
                                    : theme.auLightGrey,
                                borderColor: Colors.transparent,
                                textColor: _tabController.index == 0
                                    ? AppColor.disabledColor
                                    : AppColor.white,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            if (_isLoading) ...[
              Center(
                child: CupertinoActivityIndicator(
                  color: theme.colorScheme.primary,
                  radius: 16,
                ),
              ),
            ]
          ],
        ),
      ),
    );
  }

  Widget _qrView() {
    final theme = Theme.of(context);
    final size1 = MediaQuery.of(context).size.height / 2;
    final qrSize = size1 < 240.0 ? size1 : 240.0;

    var cutPaddingTop = qrSize + 500 - MediaQuery.of(context).size.height;
    if (cutPaddingTop < 0) cutPaddingTop = 0;
    return QRView(
      key: qrKey,
      overlay: QrScannerOverlayShape(
        borderColor:
            isScanDataError ? AppColor.red : theme.colorScheme.secondary,
        overlayColor: (cameraPermission || Platform.isIOS)
            ? const Color.fromRGBO(0, 0, 0, 80)
            : const Color.fromRGBO(255, 255, 255, 60),
        cutOutSize: qrSize,
        borderWidth: 8,
        borderRadius: 40,
        // borderLength: qrSize / 2,
        cutOutBottomOffset: 32 + cutPaddingTop,
      ),
      onQRViewCreated: _onQRViewCreated,
      onPermissionSet: (ctrl, p) {
        setState(() {
          cameraPermission = ctrl.hasPermissions;
        });
      },
    );
  }

  Widget _noPermissionView() {
    final size1 = MediaQuery.of(context).size.height / 2;
    final qrSize = size1 < 240.0 ? size1 : 240.0;

    var cutPaddingTop = qrSize + 500 - MediaQuery.of(context).size.height;
    if (cutPaddingTop < 0) cutPaddingTop = 0;
    return Stack(
      children: [
        _qrView(),
        Padding(
          padding: EdgeInsets.fromLTRB(
            0,
            MediaQuery.of(context).size.height / 2 + qrSize / 2 - cutPaddingTop,
            0,
            30,
          ),
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _instructionViewNoPermission(),
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: PrimaryButton(
                    text: "open_setting".tr(
                      namedArgs: {
                        "device": Platform.isAndroid ? "Device" : "iOS",
                      },
                    ),
                    onTap: () {
                      openAppSettings();
                    },
                  ),
                )
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _instructionViewNoPermission() {
    final theme = Theme.of(context);
    final size1 = MediaQuery.of(context).size.height / 2;
    final qrSize = size1 < 240.0 ? size1 : 240.0;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      width: qrSize,
      child: Text(
        'please_ensure'.tr(),
        style: theme.textTheme.ppMori400White14,
        textAlign: TextAlign.center,
      ),
    );
  }

  Widget _instructionView() {
    final theme = Theme.of(context);

    switch (widget.scannerItem) {
      case ScannerItem.WALLET_CONNECT:
      case ScannerItem.BEACON_CONNECT:
      case ScannerItem.FERALFILE_TOKEN:
      case ScannerItem.GLOBAL:
        return Padding(
          padding: const EdgeInsets.all(15),
          child: Container(
            width: MediaQuery.of(context).size.width,
            decoration: BoxDecoration(
              color: theme.colorScheme.primary,
              borderRadius: BorderRadius.circular(5),
            ),
            padding: const EdgeInsets.all(15),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "scan_qr_to".tr(),
                  style: theme.textTheme.ppMori700White14,
                ),
                Divider(
                  color: theme.colorScheme.secondary,
                  height: 30,
                ),
                RichText(
                  text: TextSpan(
                    text: "apps".tr(),
                    children: [
                      TextSpan(
                        text: ' ',
                        style: theme.textTheme.ppMori400Grey14,
                      ),
                      TextSpan(
                        text: "such_as_openSea".tr(),
                        style: theme.textTheme.ppMori400Grey14,
                      ),
                    ],
                    style: theme.textTheme.ppMori400White14,
                  ),
                ),
                const SizedBox(height: 15),
                RichText(
                  text: TextSpan(
                    text: "wallets".tr(),
                    children: [
                      TextSpan(
                        text: ' ',
                        style: theme.textTheme.ppMori400Grey14,
                      ),
                      TextSpan(
                        text: 'such_as_metamask'.tr(),
                        style: theme.textTheme.ppMori400Grey14,
                      ),
                    ],
                    style: theme.textTheme.ppMori400White14,
                  ),
                ),
                const SizedBox(height: 15),
                RichText(
                  text: TextSpan(
                    text: "h_autonomy".tr(),
                    children: [
                      TextSpan(
                        text: ' ',
                        style: theme.textTheme.ppMori400Grey14,
                      ),
                      TextSpan(
                        text: 'on_tv_or_desktop'.tr(),
                        style: theme.textTheme.ppMori400Grey14,
                      ),
                    ],
                    style: theme.textTheme.ppMori400White14,
                  ),
                ),
              ],
            ),
          ),
        );

      case ScannerItem.ETH_ADDRESS:
      case ScannerItem.XTZ_ADDRESS:
        return Column(
          children: [
            Text("scan_qr".tr(), style: theme.primaryTextTheme.labelLarge),
          ],
        );
      case ScannerItem.CANVAS_DEVICE:
        return const SizedBox();
    }
  }

  void _onQRViewCreated(QRViewController controller) {
    this.controller = controller;
    controller.scannedDataStream.listen((scanData) async {
      if (scanData.code == null) return;
      if (scanData.code == currentCode && isScanDataError) return;
      currentCode = scanData.code;
      String code = scanData.code!;

      if (DEEP_LINKS.any((prefix) => code.startsWith(prefix))) {
        controller.dispose();
        Navigator.pop(context);
        injector<DeeplinkService>().handleDeeplink(
          code,
          delay: const Duration(milliseconds: 100),
        );
        return;
      }

      switch (widget.scannerItem) {
        case ScannerItem.WALLET_CONNECT:
          if (code.startsWith("wc:") == true) {
            if (code.isAutonomyConnectUri) {
              _handleAutonomyConnect(code);
            } else {
              _handleWalletConnect(code);
            }
          } else {
            _handleError(code);
          }
          break;

        case ScannerItem.BEACON_CONNECT:
          if (code.startsWith("tezos://") == true) {
            _handleBeaconConnect(code);
          } else {
            _handleError(code);
          }
          break;

        case ScannerItem.FERALFILE_TOKEN:
          if (code.startsWith(FF_TOKEN_DEEPLINK_PREFIX)) {
            controller.dispose();
            Navigator.pop(context, code);
          } else {
            _handleError(code);
          }
          break;

        case ScannerItem.ETH_ADDRESS:
        case ScannerItem.XTZ_ADDRESS:
          controller.dispose();
          Navigator.pop(context, code);
          break;
        case ScannerItem.GLOBAL:
          if (code.startsWith("wc:") == true) {
            if (code.isAutonomyConnectUri) {
              _handleAutonomyConnect(code);
            } else {
              _handleWalletConnect(code);
            }
          } else if (code.startsWith("tezos:") == true) {
            _handleBeaconConnect(code);
          } else if (code.startsWith(FF_TOKEN_DEEPLINK_PREFIX) == true) {
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
          } else if (_isCanvasQrCode(code)) {
            _lock.synchronized(() async {
              final result = await _handleCanvasQrCode(code);
              if (result) {
                if (!mounted) return;
                await UIHelper.showInfoDialog(
                  context,
                  "connected".tr(),
                  "canvas_connected".tr(),
                  closeButton: "close".tr(),
                  onClose: () => UIHelper.hideInfoDialog(
                      injector<NavigationService>()
                          .navigatorKey
                          .currentContext!),
                  autoDismissAfter: 3,
                  isDismissible: true,
                );
              }
            });
          } else {
            _handleError(code);
          }
          break;
        case ScannerItem.CANVAS_DEVICE:
          if (_isCanvasQrCode(code)) {
            _lock.synchronized(() => _handleCanvasQrCode(code));
          } else {
            _handleError(code);
          }
          break;
      }
    });
  }

  bool _isCanvasQrCode(String code) {
    try {
      CanvasDevice.fromJson(jsonDecode(code));
      return true;
    } catch (err) {
      return false;
    }
  }

  Future<bool> _handleCanvasQrCode(String code) async {
    log.info("Canvas device scanned: $code");
    setState(() {
      _isLoading = true;
    });
    controller.pauseCamera();
    try {
      final premium = await isPremium();
      if (!premium) {
        if (mounted) {
          Navigator.pop(context);
        }
        return false;
      }
      final device = CanvasDevice.fromJson(jsonDecode(code));
      final canvasClient = injector<CanvasClientService>();
      final result = await canvasClient.connectToDevice(device);
      if (result) {
        device.isConnecting = true;
      }
      if (!mounted) return false;
      Navigator.pop(context, device);
      return result;
    } catch (e) {
      Navigator.pop(context);
      if (e.toString().contains("DEADLINE_EXCEEDED") || true) {
        UIHelper.showInfoDialog(_navigationService.navigatorKey.currentContext!,
            "failed_to_connect".tr(), "canvas_ip_fail".tr(),
            closeButton: "close".tr());
      }
    }
    return false;
  }

  Future _addScanQREvent(
      {required String link,
      required String linkType,
      required String prefix,
      Map<dynamic, dynamic> addData = const {}}) async {
    final uri = Uri.parse(link);
    final uriData = uri.queryParameters;
    final data = {
      "link": link,
      'linkType': linkType,
      "prefix": prefix,
    };
    data.addAll(uriData);
    data.addAll(addData.map((key, value) => MapEntry(key, value.toString())));

    metricClient.addEvent(MixpanelEvent.scanQR, data: data);
  }

  void _handleError(String data) {
    setState(() {
      isScanDataError = true;
    });
    Future.delayed(const Duration(seconds: 4), () {
      if (mounted) {
        setState(() {
          isScanDataError = false;
        });
      }
    });

    log.info("[Scanner][start] scan ${widget.scannerItem}");
    log.info(
        "[Scanner][incorrectScanItem] item: ${data.substring(0, data.length ~/ 2)}");
  }

  void _handleAutonomyConnect(String code) {
    controller.dispose();
    _addScanQREvent(
        link: code, linkType: LinkType.autonomyConnect, prefix: "wc:");
    injector<Wc2Service>().connect(code);
    Navigator.of(context).pop();
  }

  void _handleWalletConnect(String code) {
    controller.dispose();
    injector<WalletConnectService>().connect(code);
    _addScanQREvent(
        link: code, linkType: LinkType.walletConnect, prefix: "wc:");
    Navigator.of(context).pop();
  }

  void _handleBeaconConnect(String code) {
    controller.dispose();
    _addScanQREvent(
        link: code, linkType: LinkType.beaconConnect, prefix: "tezos://");
    injector<TezosBeaconService>().addPeer(code);
    Navigator.of(context).pop();
    injector<NavigationService>().showContactingDialog();
  }

  void _handleFeralFileToken(String code) async {
    setState(() {
      _isLoading = true;
    });
    controller.pauseCamera();
    try {
      _addScanQREvent(
          link: code,
          linkType: LinkType.feralFileToken,
          prefix: FF_TOKEN_DEEPLINK_PREFIX);
      final connection = await injector<FeralFileService>().linkFF(
          code.replacePrefix(FF_TOKEN_DEEPLINK_PREFIX, ""),
          delayLink: false);
      injector<NavigationService>().popUntilHomeOrSettings();
      if (!mounted) return;
      UIHelper.showFFAccountLinked(context, connection.name);
    } catch (_) {
      Navigator.of(context).pop();
      rethrow;
    }
  }

  @override
  void didPopNext() {
    if (Platform.isIOS) {
      SystemChrome.setEnabledSystemUIMode(SystemUiMode.leanBack);
    }
  }

  @override
  void didPushNext() {
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.manual,
        overlays: SystemUiOverlay.values);
  }

  @override
  void dispose() {
    controller.dispose();
    routeObserver.unsubscribe(this);
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.manual,
        overlays: SystemUiOverlay.values);
    super.dispose();
  }
}

enum ScannerItem {
  WALLET_CONNECT,
  BEACON_CONNECT,
  ETH_ADDRESS,
  XTZ_ADDRESS,
  FERALFILE_TOKEN,
  CANVAS_DEVICE,
  GLOBAL
}
