//
//  SPDX-License-Identifier: BSD-2-Clause-Patent
//  Copyright © 2022 Bitmark. All rights reserved.
//  Use of this source code is governed by the BSD-2-Clause Plus Patent License
//  that can be found in the LICENSE file.
//

import 'package:after_layout/after_layout.dart';
import 'package:autonomy_flutter/common/environment.dart';
import 'package:autonomy_flutter/common/injector.dart';
import 'package:autonomy_flutter/database/cloud_database.dart';
import 'package:autonomy_flutter/main.dart';
import 'package:autonomy_flutter/model/connection_request_args.dart';
import 'package:autonomy_flutter/screen/app_router.dart';
import 'package:autonomy_flutter/screen/bloc/accounts/accounts_bloc.dart';
import 'package:autonomy_flutter/screen/connection/persona_connections_page.dart';
import 'package:autonomy_flutter/service/configuration_service.dart';
import 'package:autonomy_flutter/service/ethereum_service.dart';
import 'package:autonomy_flutter/service/metric_client_service.dart';
import 'package:autonomy_flutter/service/navigation_service.dart';
import 'package:autonomy_flutter/service/tezos_beacon_service.dart';
import 'package:autonomy_flutter/service/wallet_connect_service.dart';
import 'package:autonomy_flutter/service/wc2_service.dart';
import 'package:autonomy_flutter/util/constants.dart';
import 'package:autonomy_flutter/util/debouce_util.dart';
import 'package:autonomy_flutter/util/inapp_notifications.dart';
import 'package:autonomy_flutter/util/log.dart';
import 'package:autonomy_flutter/util/style.dart';
import 'package:autonomy_flutter/util/ui_helper.dart';
import 'package:autonomy_flutter/util/wallet_storage_ext.dart';
import 'package:autonomy_flutter/util/wallet_utils.dart';
import 'package:autonomy_flutter/view/back_appbar.dart';
import 'package:autonomy_flutter/view/list_address_account.dart';
import 'package:autonomy_flutter/view/primary_button.dart';
import 'package:autonomy_flutter/view/responsive.dart';
import 'package:autonomy_theme/autonomy_theme.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:wallet_connect/models/wc_peer_meta.dart';

import '../../service/account_service.dart';

/*
 Because WalletConnect & TezosBeacon are using same logic:
 - select persona 
 - suggest to generate persona
 => use this page for both WalletConnect & TezosBeacon connect
*/
class WCConnectPage extends StatefulWidget {
  static const String tag = AppRouter.wcConnectPage;

  final ConnectionRequest connectionRequest;

  const WCConnectPage({
    Key? key,
    required this.connectionRequest,
  }) : super(key: key);

  @override
  State<WCConnectPage> createState() => _WCConnectPageState();
}

class _WCConnectPageState extends State<WCConnectPage>
    with RouteAware, WidgetsBindingObserver, AfterLayoutMixin<WCConnectPage> {
  WalletIndex? selectedPersona;
  List<Account>? categorizedAccounts;
  bool createPersona = false;
  final metricClient = injector.get<MetricClientService>();
  bool isAccountSelected = false;
  final padding = ResponsiveLayout.pageEdgeInsets.copyWith(top: 0, bottom: 0);
  late ConnectionRequest connectionRequest;
  String? ethSelectedAddress;
  String? tezSelectedAddress;

  bool get _confirmEnable =>
      (categorizedAccounts != null &&
          categorizedAccounts!.isNotEmpty &&
          selectedPersona != null) ||
      widget.connectionRequest.isAutonomyConnect;

  @override
  void initState() {
    super.initState();
    connectionRequest = widget.connectionRequest;
    callAccountBloc();
    injector<NavigationService>().setIsWCConnectInShow(true);
    memoryValues.deepLink.value = null;
  }

  @override
  void afterFirstLayout(BuildContext context) {
    metricClient.timerEvent(MixpanelEvent.backConnectMarket);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    routeObserver.subscribe(this, ModalRoute.of(context)!);
  }

  @override
  void didPopNext() {
    super.didPopNext();
    callAccountBloc();
  }

  void callAccountBloc() {
    context.read<AccountsBloc>().add(GetCategorizedAccountsEvent(
        includeLinkedAccount: false,
        getTezos: widget.connectionRequest.isBeaconConnect ||
            widget.connectionRequest.isAutonomyConnect,
        getEth: !widget.connectionRequest.isBeaconConnect));
  }

  @override
  void dispose() {
    super.dispose();
    routeObserver.unsubscribe(this);
    injector<NavigationService>().setIsWCConnectInShow(false);
    Future.delayed(const Duration(seconds: 2), () {
      injector<TezosBeaconService>().handleNextRequest(isRemoved: true);
    });
  }

  Future<void> _reject() async {
    // final wc2Proposal = widget.wc2Proposal;
    // final wcConnectArgs = widget.wcConnectArgs;
    // final beaconRequest = widget.beaconRequest;

    if (connectionRequest.isAutonomyConnect) {
      try {
        await injector<Wc2Service>().rejectSession(
          connectionRequest.id,
          reason: "User reject",
        );
      } catch (e) {
        log.info("[WCConnectPage] Reject AutonomyConnect Proposal $e");
      }
      return;
    }

    if (connectionRequest.isWalletConnect2) {
      try {
        await injector<Wc2Service>().rejectSession(
          connectionRequest.id,
          reason: "User reject",
        );
      } catch (e) {
        log.info("[WCConnectPage] Reject WalletConnect2 Proposal $e");
      }
      return;
    }

    if (connectionRequest.isWalletConnect) {
      injector<WalletConnectService>()
          .rejectSession((connectionRequest as WCConnectPageArgs).peerMeta);
      return;
    }

    if (connectionRequest.isBeaconConnect) {
      injector<TezosBeaconService>()
          .permissionResponse(null, null, connectionRequest.id, null, null);
    }
  }

  Future _approve({bool onBoarding = false}) async {
    if (selectedPersona == null && !connectionRequest.isAutonomyConnect) return;

    UIHelper.showLoadingScreen(context, text: 'connecting_wallet'.tr());
    late String payloadAddress;
    late CryptoType payloadType;
    switch (connectionRequest.runtimeType) {
      case Wc2Proposal:
        if (connectionRequest.isAutonomyConnect) {
          final account = await injector<AccountService>().getDefaultAccount();
          final accountDid = await account.getAccountDID();
          final walletAddresses = await injector<CloudDatabase>()
              .addressDao
              .findByWalletID(account.uuid);
          final accountNumber =
              walletAddresses.map((e) => e.address).join("||");
          await injector<Wc2Service>().approveSession(
            connectionRequest as Wc2Proposal,
            account: accountDid.substring("did:key:".length),
            connectionKey: account.uuid,
            accountNumber: accountNumber,
            isAuConnect: true,
          );
          payloadType = CryptoType.ETH;
          payloadAddress =
              await account.getETHEip55Address(index: selectedPersona!.index);
          metricClient.addEvent(
            MixpanelEvent.connectExternal,
            data: {
              "method": "autonomy_connect",
              "name": connectionRequest.name,
              "url": connectionRequest.url,
            },
          );
        } else {
          final address = await injector<EthereumService>()
              .getETHAddress(selectedPersona!.wallet, selectedPersona!.index);
          await injector<Wc2Service>().approveSession(
            connectionRequest as Wc2Proposal,
            account: address,
            connectionKey: address,
            accountNumber: address,
          );
          payloadType = CryptoType.ETH;
          payloadAddress = address;
        }

        break;
      case WCConnectPageArgs:
        final address = await injector<EthereumService>()
            .getETHAddress(selectedPersona!.wallet, selectedPersona!.index);

        final chainId = Environment.web3ChainId;

        final approvedAddresses = [address];
        log.info(
            "[WCConnectPage] approve WCConnect with addresses $approvedAddresses");
        await injector<WalletConnectService>().approveSession(
          selectedPersona!.wallet.uuid,
          selectedPersona!.index,
          (connectionRequest as WCConnectPageArgs).peerMeta,
          approvedAddresses,
          chainId,
        );

        payloadAddress = address;
        payloadType = CryptoType.ETH;

        if (connectionRequest.name == AUTONOMY_TV_PEER_NAME) {
          metricClient.addEvent(MixpanelEvent.connectAutonomyDisplay);
          injector<ConfigurationService>().setAlreadyShowTvAppTip(true);
          injector<ConfigurationService>().showTvAppTip.value = false;
        } else {
          metricClient.addEvent(
            MixpanelEvent.connectExternal,
            data: {
              "method": "wallet_connect",
              "name": connectionRequest.name,
              "url": connectionRequest.url,
            },
          );
        }
        break;
      case BeaconRequest:
        final wallet = selectedPersona!.wallet;
        final index = selectedPersona!.index;
        final publicKey = await wallet.getTezosPublicKey(index: index);
        final address = wallet.getTezosAddressFromPubKey(publicKey);
        await injector<TezosBeaconService>().permissionResponse(
          wallet.uuid,
          index,
          (connectionRequest as BeaconRequest).id,
          publicKey,
          address,
        );
        payloadAddress = address;
        payloadType = CryptoType.XTZ;
        metricClient.addEvent(
          MixpanelEvent.connectExternal,
          data: {
            "method": "tezos_beacon",
            "name": (connectionRequest as BeaconRequest).appName ?? "unknown",
            "url":
                (connectionRequest as BeaconRequest).sourceAddress ?? "unknown",
          },
        );
        break;
      default:
    }

    if (!mounted) return;
    UIHelper.hideInfoDialog(context);

    if (memoryValues.scopedPersona != null) {
      Navigator.of(context).pop();
      return;
    }

    final payload = PersonaConnectionsPayload(
      personaUUID: selectedPersona!.wallet.uuid,
      index: selectedPersona!.index,
      address: payloadAddress,
      type: payloadType,
      isBackHome: onBoarding,
    );

    Navigator.of(context).pushReplacementNamed(
      AppRouter.personaConnectionsPage,
      arguments: payload,
    );
  }

  Future<void> _approveThenNotify({bool onBoarding = false}) async {
    await _approve(onBoarding: onBoarding);

    metricClient.addEvent(MixpanelEvent.connectMarketSuccess);
    if (!mounted) return;
    showInfoNotification(
      const Key("connected"),
      "connected_to".tr(),
      frontWidget: SvgPicture.asset(
        "assets/images/checkbox_icon.svg",
        width: 24,
      ),
      addOnTextSpan: [
        TextSpan(
          text: connectionRequest.name,
          style: Theme.of(context).textTheme.ppMori400Green14,
        )
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final padding = ResponsiveLayout.pageEdgeInsets.copyWith(top: 0, bottom: 0);
    return WillPopScope(
      onWillPop: () async {
        metricClient.addEvent(MixpanelEvent.backConnectMarket);
        _reject();
        return true;
      },
      child: Scaffold(
        appBar: getBackAppBar(
          context,
          title: 'connect'.tr(),
          onBack: () async {
            metricClient.addEvent(MixpanelEvent.backConnectMarket);
            await _reject();
            if (!mounted) return;
            Navigator.pop(context);
          },
        ),
        body: Container(
          margin: ResponsiveLayout.pageEdgeInsetsWithSubmitButton
              .copyWith(left: 0, right: 0),
          child: Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      addTitleSpace(),
                      Padding(
                        padding: padding,
                        child: _appInfo(),
                      ),
                      const SizedBox(height: 32),
                      addDivider(height: 52),
                      Padding(
                        padding: padding,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "you_have_permission".tr(),
                              style: theme.textTheme.ppMori400Black16,
                            ),
                            const SizedBox(
                              height: 12,
                            ),
                            Container(
                                width: double.infinity,
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: AppColor.auGrey,
                                  borderRadius: BorderRadius.circular(5),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    ...grantPermissions.map(
                                      (permission) => Row(
                                        children: [
                                          const SizedBox(
                                            width: 6,
                                          ),
                                          Text("•",
                                              style: theme
                                                  .textTheme.ppMori400Black14),
                                          const SizedBox(
                                            width: 6,
                                          ),
                                          Text(permission,
                                              style: theme
                                                  .textTheme.ppMori400Black14),
                                        ],
                                      ),
                                    ),
                                  ],
                                )),
                          ],
                        ),
                      ),
                      const SizedBox(height: 40),
                      BlocConsumer<AccountsBloc, AccountsState>(
                          listener: (context, state) async {
                        var stateCategorizedAccounts = state.accounts;

                        if (connectionRequest.isAutonomyConnect) {
                          final persona = await injector<AccountService>()
                              .getOrCreateDefaultPersona();
                          selectedPersona = WalletIndex(persona.wallet(), 0);
                        }
                        if (stateCategorizedAccounts == null ||
                            stateCategorizedAccounts.isEmpty) {
                          setState(() {
                            createPersona = true;
                          });
                          return;
                        }
                        categorizedAccounts = stateCategorizedAccounts;
                        await _autoSelectDefault(categorizedAccounts);
                        setState(() {});
                      }, builder: (context, state) {
                        return _selectAccount();
                      }),
                    ],
                  ),
                ),
              ),
              _connect(context)
            ],
          ),
        ),
      ),
    );
  }

  Future _autoSelectDefault(List<Account>? categorizedAccounts) async {
    if (categorizedAccounts == null) return;
    if (categorizedAccounts.length != 1) return;
    final persona = categorizedAccounts.first.persona;
    if (persona == null) return;

    final ethAccounts = categorizedAccounts.where((element) => element.isEth);
    final xtzAccounts = categorizedAccounts.where((element) => element.isTez);

    if (ethAccounts.length == 1) {
      ethSelectedAddress = ethAccounts.first.accountNumber;
      selectedPersona = WalletIndex(persona.wallet(),
          (await persona.getEthWalletAddresses()).first.index);
    }

    if (xtzAccounts.length == 1) {
      tezSelectedAddress = xtzAccounts.first.accountNumber;
      selectedPersona = WalletIndex(persona.wallet(),
          (await persona.getTezWalletAddresses()).first.index);
    }
  }

  Widget _appInfo() {
    if (connectionRequest.isAutonomyConnect ||
        connectionRequest.isWalletConnect2) {
      final wc2Proposer = (connectionRequest as Wc2Proposal).proposer;
      final peer = WCPeerMeta(
        name: wc2Proposer.name,
        url: wc2Proposer.url,
        description: wc2Proposer.description,
        icons: wc2Proposer.icons,
      );
      return _wcAppInfo(peer);
    }
    if (connectionRequest.isWalletConnect) {
      return _wcAppInfo((connectionRequest as WCConnectPageArgs).peerMeta);
    }

    if (connectionRequest.isBeaconConnect) {
      return _tbAppInfo(connectionRequest as BeaconRequest);
    }

    return const SizedBox();
  }

  Widget _selectAccount() {
    final stateCategorizedAccounts = categorizedAccounts;
    if (stateCategorizedAccounts == null) return const SizedBox();

    if (stateCategorizedAccounts.isEmpty) {
      return const SizedBox(); // Expanded(child: _createAccountAndConnect());
    }
    if (connectionRequest.isAutonomyConnect) {
      return const SizedBox();
    }
    return _selectPersonaWidget(stateCategorizedAccounts);
  }

  Widget _connect(BuildContext context) {
    if (connectionRequest.isAutonomyConnect) {
      return Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          Row(
            children: [
              Expanded(
                child: Padding(
                  padding: padding,
                  child: PrimaryButton(
                    enabled: _confirmEnable,
                    text: "h_confirm".tr(),
                    onTap: () => withDebounce(() => _approveThenNotify()),
                  ),
                ),
              )
            ],
          )
        ],
      );
    } else if (createPersona == true) {
      return _createAccountAndConnect(context);
    } else {
      return Row(
        children: [
          Expanded(
            child: Padding(
              padding: padding,
              child: PrimaryButton(
                enabled: _confirmEnable,
                text: "h_confirm".tr(),
                onTap: selectedPersona != null
                    ? () {
                        metricClient.addEvent(MixpanelEvent.connectMarket);
                        withDebounce(() => _approveThenNotify());
                      }
                    : null,
              ),
            ),
          )
        ],
      );
    }
  }

  Widget _wcAppInfo(WCPeerMeta peerMeta) {
    final theme = Theme.of(context);

    return Row(
      children: [
        if (peerMeta.icons.isNotEmpty) ...[
          CachedNetworkImage(
            imageUrl: peerMeta.icons.first,
            width: 64.0,
            height: 64.0,
            errorWidget: (context, url, error) => SizedBox(
                width: 64,
                height: 64,
                child:
                    Image.asset("assets/images/walletconnect-alternative.png")),
          ),
        ] else ...[
          SizedBox(
              width: 64,
              height: 64,
              child:
                  Image.asset("assets/images/walletconnect-alternative.png")),
        ],
        const SizedBox(width: 16.0),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(peerMeta.name, style: theme.textTheme.ppMori700Black24),
            ],
          ),
        )
      ],
    );
  }

  Widget _tbAppInfo(BeaconRequest request) {
    final theme = Theme.of(context);

    return Row(
      children: [
        request.icon != null
            ? CachedNetworkImage(
                imageUrl: request.icon!,
                width: 64.0,
                height: 64.0,
                errorWidget: (context, url, error) => SvgPicture.asset(
                  "assets/images/tezos_social_icon.svg",
                  width: 64.0,
                  height: 64.0,
                ),
              )
            : SvgPicture.asset(
                "assets/images/tezos_social_icon.svg",
                width: 64.0,
                height: 64.0,
              ),
        const SizedBox(width: 24.0),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(request.appName ?? "",
                  style: theme.textTheme.ppMori700Black24),
            ],
          ),
        )
      ],
    );
  }

  Widget _selectPersonaWidget(List<Account> accounts) {
    final theme = Theme.of(context);
    String select = "";
    if (widget.connectionRequest.isBeaconConnect) {
      select = "select_tezos".tr(args: ["1"]);
    } else if (widget.connectionRequest.isWalletConnect ||
        widget.connectionRequest.isWalletConnect2) {
      select = "select_ethereum".tr(args: ["1"]);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: padding,
          child: Text(
            select,
            style: theme.textTheme.ppMori400Black16,
          ),
        ),
        const SizedBox(height: 16.0),
        ListAccountConnect(
          accounts: accounts,
          onSelectEth: (value) {
            int index = value.walletAddress?.index ?? 0;
            setState(() {
              ethSelectedAddress = value.accountNumber;
              selectedPersona = WalletIndex(value.persona!.wallet(), index);
            });
          },
          onSelectTez: (value) {
            int index = value.walletAddress?.index ?? 0;
            setState(() {
              tezSelectedAddress = value.accountNumber;
              selectedPersona = WalletIndex(value.persona!.wallet(), index);
            });
          },
          isAutoSelect: accounts.length == 1,
        ),
      ],
    );
  }

  Widget _createAccountAndConnect(BuildContext context) {
    return Padding(
      padding: ResponsiveLayout.pageHorizontalEdgeInsets,
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: PrimaryButton(
                  text: "h_confirm".tr(),
                  onTap: () {
                    metricClient.addEvent(MixpanelEvent.connectMarket);
                    withDebounce(() => _createAccount(context));
                  },
                ),
              )
            ],
          ),
        ],
      ),
    );
  }

  Future _createAccount(BuildContext context) async {
    UIHelper.showLoadingScreen(context, text: "connecting".tr());
    final persona =
        await injector<AccountService>().getOrCreateDefaultPersona();
    await persona.insertAddress(connectionRequest.isBeaconConnect
        ? WalletType.Tezos
        : WalletType.Ethereum);
    injector<ConfigurationService>().setDoneOnboarding(true);
    injector<MetricClientService>().mixPanelClient.initIfDefaultAccount();
    setState(() {
      selectedPersona = WalletIndex(persona.wallet(), 0);
    });
    _approveThenNotify(onBoarding: true);
  }
}
