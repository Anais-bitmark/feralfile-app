//
//  SPDX-License-Identifier: BSD-2-Clause-Patent
//  Copyright © 2022 Bitmark. All rights reserved.
//  Use of this source code is governed by the BSD-2-Clause Plus Patent License
//  that can be found in the LICENSE file.
//

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:autonomy_flutter/common/injector.dart';
import 'package:autonomy_flutter/database/cloud_database.dart';
import 'package:autonomy_flutter/main.dart';
import 'package:autonomy_flutter/screen/app_router.dart';
import 'package:autonomy_flutter/screen/bloc/accounts/accounts_bloc.dart'
    as accounts;
import 'package:autonomy_flutter/screen/bloc/ethereum/ethereum_bloc.dart';
import 'package:autonomy_flutter/screen/bloc/persona/persona_bloc.dart';
import 'package:autonomy_flutter/screen/bloc/tezos/tezos_bloc.dart';
import 'package:autonomy_flutter/screen/global_receive/receive_page.dart';
import 'package:autonomy_flutter/service/audit_service.dart';
import 'package:autonomy_flutter/service/canvas_client_service.dart';
import 'package:autonomy_flutter/service/deeplink_service.dart';
import 'package:autonomy_flutter/service/metric_client_service.dart';
import 'package:autonomy_flutter/service/navigation_service.dart';
import 'package:autonomy_flutter/service/tezos_beacon_service.dart';
import 'package:autonomy_flutter/service/wc2_service.dart';
import 'package:autonomy_flutter/util/constants.dart';
import 'package:autonomy_flutter/util/log.dart';
import 'package:autonomy_flutter/util/style.dart';
import 'package:autonomy_flutter/util/ui_helper.dart';
import 'package:autonomy_flutter/view/back_appbar.dart';
import 'package:autonomy_flutter/view/header.dart';
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

// ignore_for_file: constant_identifier_names

class ScanQRPage extends StatefulWidget {
  static const String tag = AppRouter.scanQRPage;

  final ScannerItem scannerItem;

  const ScanQRPage({super.key, this.scannerItem = ScannerItem.GLOBAL});

  @override
  State<ScanQRPage> createState() => _ScanQRPageState();
}

class _ScanQRPageState extends State<ScanQRPage>
    with RouteAware, TickerProviderStateMixin {
  final GlobalKey qrKey = GlobalKey(debugLabel: 'QR');
  late QRViewController controller;
  bool isScanDataError = false;
  bool _isLoading = false;
  bool cameraPermission = false;
  String? currentCode;
  late TabController _tabController;
  final metricClient = injector<MetricClientService>();
  final _navigationService = injector<NavigationService>();
  late Lock _lock;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    //There is a conflict with lib qr_code_scanner on Android.
    if (Platform.isIOS) {
      unawaited(SystemChrome.setEnabledSystemUIMode(SystemUiMode.leanBack));
    }
    _tabController = TabController(length: 2, vsync: this);
    unawaited(checkPermission());
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
        if (Platform.isAndroid) {
          _timer?.cancel();
          _timer = Timer(const Duration(seconds: 1), () {
            controller.resumeCamera();
          });
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final size1 = MediaQuery.of(context).size.height / 2;
    final qrSize = size1 < 240.0 ? size1 : 240.0;

    var cutPaddingTop = qrSize + 500 - MediaQuery.of(context).size.height;
    if (cutPaddingTop < 0) {
      cutPaddingTop = 0;
    }
    final theme = Theme.of(context);
    return Scaffold(
      extendBodyBehindAppBar: true,
      backgroundColor: cameraPermission ? null : theme.colorScheme.primary,
      appBar: _tabController.index == 0
          ? getDarkEmptyAppBar()
          : getLightEmptyAppBar(),
      body: Stack(
        children: <Widget>[
          _content(context),
          if (_isLoading) ...[
            Center(
              child: CupertinoActivityIndicator(
                color: theme.colorScheme.primary,
                radius: 16,
              ),
            ),
          ],
          _header(context),
        ],
      ),
    );
  }

  Widget _content(BuildContext context) {
    final size1 = MediaQuery.of(context).size.height / 2;
    final qrSize = size1 < 240.0 ? size1 : 240.0;

    double cutPaddingTop = qrSize + 500 - MediaQuery.of(context).size.height;
    if (cutPaddingTop < 0) {
      cutPaddingTop = 0;
    }
    return Column(
      children: [
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: [
              Stack(
                children: [
                  if (!cameraPermission)
                    _noPermissionView(context)
                  else ...[
                    _qrView(context),
                    Padding(
                      padding: EdgeInsets.fromLTRB(
                        0,
                        MediaQuery.of(context).size.height / 2 +
                            qrSize / 2 -
                            cutPaddingTop,
                        0,
                        15,
                      ),
                      child: Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            _instructionView(context),
                          ],
                        ),
                      ),
                    )
                  ],
                ],
              ),
              MultiBlocProvider(
                  providers: [
                    BlocProvider(
                        create: (_) =>
                            accounts.AccountsBloc(injector(), injector())),
                    BlocProvider(
                      create: (_) => PersonaBloc(
                        injector<CloudDatabase>(),
                        injector(),
                        injector<AuditService>(),
                      ),
                    ),
                    BlocProvider(
                        create: (_) => EthereumBloc(injector(), injector())),
                    BlocProvider(
                      create: (_) => TezosBloc(injector(), injector()),
                    ),
                  ],
                  child: GlobalReceivePage(
                    onClose: () {
                      setState(() {
                        _tabController.animateTo(0,
                            duration: const Duration(milliseconds: 300));
                      });
                    },
                  )),
            ],
          ),
        ),
      ],
    );
  }

  Widget _header(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Padding(
          padding: EdgeInsets.only(top: MediaQuery.of(context).viewPadding.top),
          child: HeaderView(
              title: 'scan'.tr(),
              action: widget.scannerItem == ScannerItem.GLOBAL
                  ? GestureDetector(
                      onTap: () {
                        setState(() {
                          _tabController.animateTo(1,
                              duration: const Duration(milliseconds: 300));
                        });
                      },
                      child: Text(
                        'show_my_code'.tr(),
                        style: theme.textTheme.ppMori400White14.copyWith(
                          decoration: TextDecoration.underline,
                        ),
                      ),
                    )
                  : GestureDetector(
                      onTap: () {
                        Navigator.pop(context);
                      },
                      child: closeIcon(color: AppColor.white),
                    )),
        ),
      ],
    );
  }

  Widget _qrView(BuildContext context) {
    final theme = Theme.of(context);
    final size1 = MediaQuery.of(context).size.height / 2;
    final qrSize = size1 < 240.0 ? size1 : 240.0;

    var cutPaddingTop = qrSize + 500 - MediaQuery.of(context).size.height;
    if (cutPaddingTop < 0) {
      cutPaddingTop = 0;
    }
    final cutOutBottomOffset = 80 + cutPaddingTop;
    return Stack(
      children: [
        QRView(
          key: qrKey,
          overlay: QrScannerOverlayShape(
            borderColor:
                isScanDataError ? AppColor.red : theme.colorScheme.secondary,
            overlayColor: cameraPermission
                ? const Color.fromRGBO(0, 0, 0, 0.6)
                : const Color.fromRGBO(0, 0, 0, 1),
            cutOutSize: qrSize,
            borderWidth: 8,
            borderRadius: 40,
            cutOutBottomOffset: cutOutBottomOffset,
          ),
          onQRViewCreated: _onQRViewCreated,
          onPermissionSet: (ctrl, p) {
            setState(() {
              cameraPermission = ctrl.hasPermissions;
            });
          },
        ),
        if (isScanDataError)
          Positioned(
            left: (MediaQuery.of(context).size.width - qrSize) / 2,
            top: (MediaQuery.of(context).size.height - qrSize) / 2 -
                cutOutBottomOffset,
            child: SizedBox(
              height: qrSize,
              width: qrSize,
              child: Center(
                child: Text(
                  'invalid_qr_code'.tr(),
                  style: theme.textTheme.ppMori700Black14
                      .copyWith(color: AppColor.red),
                ),
              ),
            ),
          )
      ],
    );
  }

  Widget _noPermissionView(BuildContext context) {
    final size1 = MediaQuery.of(context).size.height / 2;
    final qrSize = size1 < 240.0 ? size1 : 240.0;

    var cutPaddingTop = qrSize + 500 - MediaQuery.of(context).size.height;
    if (cutPaddingTop < 0) {
      cutPaddingTop = 0;
    }
    final cutOutBottomOffset = 80 + cutPaddingTop;
    return Stack(
      children: [
        _qrView(context),
        Padding(
          padding: EdgeInsets.fromLTRB(
            0,
            MediaQuery.of(context).size.height / 2 +
                qrSize / 2 -
                cutOutBottomOffset +
                32,
            0,
            120,
          ),
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _instructionViewNoPermission(context),
                Padding(
                  padding: const EdgeInsets.all(8),
                  child: PrimaryButton(
                    text: 'open_setting'.tr(
                      namedArgs: {
                        'device': Platform.isAndroid ? 'Device' : 'iOS',
                      },
                    ),
                    onTap: () async {
                      await openAppSettings();
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

  Widget _instructionViewNoPermission(BuildContext context) {
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

  Widget _instructionView(BuildContext context) {
    final theme = Theme.of(context);

    switch (widget.scannerItem) {
      case ScannerItem.WALLET_CONNECT:
      case ScannerItem.BEACON_CONNECT:
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
                  'scan_qr_to'.tr(),
                  style: theme.textTheme.ppMori700White14,
                ),
                Divider(
                  color: theme.colorScheme.secondary,
                  height: 30,
                ),
                RichText(
                  text: TextSpan(
                    text: 'apps'.tr(),
                    children: [
                      TextSpan(
                        text: ' ',
                        style: theme.textTheme.ppMori400Grey14,
                      ),
                      TextSpan(
                        text: 'such_as_openSea'.tr(),
                        style: theme.textTheme.ppMori400Grey14,
                      ),
                    ],
                    style: theme.textTheme.ppMori400White14,
                  ),
                ),
                const SizedBox(height: 15),
                RichText(
                  text: TextSpan(
                    text: 'autonomy_canvas'.tr(),
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
            Text('scan_qr'.tr(), style: theme.primaryTextTheme.labelLarge),
          ],
        );
      case ScannerItem.CANVAS_DEVICE:
        return const SizedBox();
    }
  }

  void _onQRViewCreated(QRViewController controller) {
    this.controller = controller;
    controller.scannedDataStream.listen((scanData) async {
      if (_isLoading) {
        return;
      }
      if (scanData.code == null) {
        return;
      }
      if (scanData.code == currentCode && isScanDataError) {
        return;
      }
      currentCode = scanData.code;
      String code = scanData.code!;

      if (DEEP_LINKS.any((prefix) => code.startsWith(prefix))) {
        setState(() {
          _isLoading = true;
        });
        unawaited(controller.pauseCamera());
        if (!mounted) {
          return;
        }
        Navigator.pop(context);

        injector<DeeplinkService>().handleDeeplink(
          code,
          delay: const Duration(seconds: 1),
        );
        return;
      }

      switch (widget.scannerItem) {
        case ScannerItem.WALLET_CONNECT:
          if (code.startsWith('wc:')) {
            await _handleAutonomyConnect(code);
          } else {
            _handleError(code);
          }
          break;

        case ScannerItem.BEACON_CONNECT:
          if (code.startsWith('tezos://')) {
            await _handleBeaconConnect(code);
          } else {
            _handleError(code);
          }
          break;

        case ScannerItem.ETH_ADDRESS:
        case ScannerItem.XTZ_ADDRESS:
          setState(() {
            _isLoading = true;
          });
          await controller.pauseCamera();
          if (!mounted) {
            return;
          }
          Navigator.pop(context, code);
          break;
        case ScannerItem.GLOBAL:
          if (code.startsWith('wc:')) {
            setState(() {
              _isLoading = true;
            });
            await _handleAutonomyConnect(code);
          } else if (code.startsWith('tezos:')) {
            await _handleBeaconConnect(code);
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
            unawaited(_lock.synchronized(() async {
              await _handleCanvasQrCode(code);
            }));
          } else {
            _handleError(code);
          }
          break;
        case ScannerItem.CANVAS_DEVICE:
          if (_isCanvasQrCode(code)) {
            unawaited(_lock.synchronized(() => _handleCanvasQrCode(code)));
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
    log.info('Canvas device scanned: $code');
    setState(() {
      _isLoading = true;
    });
    await controller.pauseCamera();
    try {
      final device = CanvasDevice.fromJson(jsonDecode(code));
      final canvasClient = injector<CanvasClientService>();
      final result = await canvasClient.connectToDevice(device);
      if (result) {
        device.isConnecting = true;
      }
      if (!mounted) {
        return false;
      }
      Navigator.pop(context, device);
      return result;
    } catch (e) {
      if (mounted) {
        Navigator.pop(context);
        if (e.toString().contains('DEADLINE_EXCEEDED') || true) {
          await UIHelper.showInfoDialog(
              _navigationService.navigatorKey.currentContext!,
              'failed_to_connect'.tr(),
              'canvas_ip_fail'.tr(),
              closeButton: 'close'.tr());
        }
      }
    }
    return false;
  }

  void _addScanQREvent(
      {required String link,
      required String linkType,
      required String prefix,
      Map<dynamic, dynamic> addData = const {}}) {
    final uri = Uri.parse(link);
    final uriData = uri.queryParameters;
    final data = {
      'link': link,
      'linkType': linkType,
      'prefix': prefix,
    }
      ..addAll(uriData)
      ..addAll(addData.map((key, value) => MapEntry(key, value.toString())));

    unawaited(metricClient.addEvent(MixpanelEvent.scanQR, data: data));
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

    log
      ..info('[Scanner][start] scan ${widget.scannerItem}')
      ..info('[Scanner][incorrectScanItem] item: '
          '${data.substring(0, data.length ~/ 2)}');
  }

  Future<void> _handleAutonomyConnect(String code) async {
    setState(() {
      _isLoading = true;
    });
    await controller.pauseCamera();
    if (!mounted) {
      return;
    }
    Navigator.pop(context);
    await Future.delayed(const Duration(seconds: 1));

    _addScanQREvent(
        link: code, linkType: LinkType.autonomyConnect, prefix: 'wc:');
    await injector<Wc2Service>().connect(code);
  }

  Future<void> _handleBeaconConnect(String code) async {
    setState(() {
      _isLoading = true;
    });
    await controller.pauseCamera();
    if (!mounted) {
      return;
    }
    Navigator.pop(context);
    await Future.delayed(const Duration(seconds: 1));

    _addScanQREvent(
        link: code, linkType: LinkType.beaconConnect, prefix: 'tezos://');
    await Future.wait([
      injector<TezosBeaconService>().addPeer(code),
      injector<NavigationService>().showContactingDialog()
    ]);
  }

  @override
  void didPopNext() {
    super.didPopNext();
    if (Platform.isIOS) {
      unawaited(SystemChrome.setEnabledSystemUIMode(SystemUiMode.leanBack));
    }
    unawaited(controller.resumeCamera());
  }

  @override
  void didPushNext() {
    super.didPushNext();
    unawaited(SystemChrome.setEnabledSystemUIMode(SystemUiMode.manual,
        overlays: SystemUiOverlay.values));
    unawaited(Future.delayed(const Duration(milliseconds: 300)).then((_) {
      controller.pauseCamera();
    }));
  }

  @override
  void dispose() {
    controller.dispose();
    _timer?.cancel();
    routeObserver.unsubscribe(this);
    unawaited(SystemChrome.setEnabledSystemUIMode(SystemUiMode.manual,
        overlays: SystemUiOverlay.values));
    super.dispose();
  }
}

enum ScannerItem {
  WALLET_CONNECT,
  BEACON_CONNECT,
  ETH_ADDRESS,
  XTZ_ADDRESS,
  CANVAS_DEVICE,
  GLOBAL
}
