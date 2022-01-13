import 'package:autonomy_flutter/screen/home/home_bloc.dart';
import 'package:autonomy_flutter/screen/home/home_page.dart';
import 'package:autonomy_flutter/screen/scan_qr/scan_qr_page.dart';
import 'package:autonomy_flutter/screen/settings/crypto/receive_page.dart';
import 'package:autonomy_flutter/screen/settings/crypto/send/send_crypto_bloc.dart';
import 'package:autonomy_flutter/screen/settings/crypto/send/send_crypto_page.dart';
import 'package:autonomy_flutter/screen/settings/crypto/send_review_page.dart';
import 'package:autonomy_flutter/screen/settings/crypto/wallet_detail/wallet_detail_bloc.dart';
import 'package:autonomy_flutter/screen/settings/crypto/wallet_detail/wallet_detail_page.dart';
import 'package:autonomy_flutter/screen/settings/networks/select_network_bloc.dart';
import 'package:autonomy_flutter/screen/settings/networks/select_network_page.dart';
import 'package:autonomy_flutter/screen/settings/settings_bloc.dart';
import 'package:autonomy_flutter/screen/settings/settings_page.dart';
import 'package:autonomy_flutter/screen/wallet_connect/send/wc_send_transaction_bloc.dart';
import 'package:autonomy_flutter/screen/wallet_connect/send/wc_send_transaction_page.dart';
import 'package:autonomy_flutter/screen/wallet_connect/wc_connect_page.dart';
import 'package:autonomy_flutter/screen/wallet_connect/wc_sign_message_page.dart';
import 'package:autonomy_flutter/service/navigation_service.dart';
import 'package:autonomy_flutter/service/persona_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'common/injector.dart';
import 'common/network_config_injector.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await setup();

  final personaService = injector<PersonaService>();
  if (personaService.getActivePersona() == null) {
    personaService.createPersona("Autonomy");
  }

  BlocOverrides.runZoned(
    () => runApp(AutonomyApp()),
    blocObserver: AppBlocObserver(),
  );
}

class AutonomyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final networkInjector = injector<NetworkConfigInjector>();

    return MaterialApp(
        title: 'Autonomy',
        theme: ThemeData(
          primarySwatch: Colors.blue,
          // cardColor: Colors.black,
          secondaryHeaderColor: Color(0xFF6D6B6B),
          errorColor: Color(0xFFA1200A),
          textTheme: TextTheme(
            headline1: TextStyle(
                color: Colors.black,
                fontSize: 36,
                fontWeight: FontWeight.w700,
                fontFamily: "AtlasGrotesk"),
            headline2: TextStyle(
                color: Colors.black,
                fontSize: 28,
                fontWeight: FontWeight.w700,
                fontFamily: "AtlasGrotesk"),
            headline5: TextStyle(
                color: Colors.black,
                fontSize: 16,
                fontWeight: FontWeight.w700,
                fontFamily: "AtlasGrotesk"),
            button: TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.w700,
                fontFamily: "IBMPlexMono"),
            caption: TextStyle(
                color: Colors.black,
                fontSize: 14,
                fontWeight: FontWeight.w700,
                fontFamily: "IBMPlexMono"),
            bodyText1: TextStyle(
                color: Colors.black, fontSize: 16, fontFamily: "AtlasGrotesk"),
            bodyText2: TextStyle(
                color: Color(0xFF6D6B6B),
                fontSize: 16,
                fontFamily: "AtlasGrotesk"),
          ),
        ),
        navigatorKey: injector<NavigationService>().navigatorKey,
        onGenerateRoute: (settings) {
          switch (settings.name) {
            case WCConnectPage.tag:
              return MaterialPageRoute(
                builder: (context) => WCConnectPage(
                    args: settings.arguments as WCConnectPageArgs),
              );
            case WCSignMessagePage.tag:
              return MaterialPageRoute(
                builder: (context) => WCSignMessagePage(
                    args: settings.arguments as WCSignMessagePageArgs),
              );
            case WCSendTransactionPage.tag:
              return MaterialPageRoute(
                builder: (context) => BlocProvider(
                  create: (_) => WCSendTransactionBloc(
                      injector(), networkInjector.I(), injector()),
                  child: WCSendTransactionPage(
                      args: settings.arguments as WCSendTransactionPageArgs),
                ),
              );
            case ScanQRPage.tag:
              return MaterialPageRoute(builder: (context) => ScanQRPage());
            case SettingsPage.tag:
              return MaterialPageRoute(
                builder: (context) => BlocProvider(
                  create: (_) =>
                      SettingsBloc(networkInjector.I(), networkInjector.I()),
                  child: SettingsPage(),
                ),
              );
            case WalletDetailPage.tag:
              return MaterialPageRoute(
                  builder: (context) => BlocProvider(
                        create: (_) => WalletDetailBloc(networkInjector.I(),
                            networkInjector.I(), injector()),
                        child: WalletDetailPage(
                            type: settings.arguments as CryptoType),
                      ));
            case ReceivePage.tag:
              return MaterialPageRoute(
                  builder: (context) => ReceivePage(
                      payload: settings.arguments as WalletPayload));
            case SendCryptoPage.tag:
              return MaterialPageRoute(
                  builder: (context) => BlocProvider(
                        create: (_) => SendCryptoBloc(
                            networkInjector.I(),
                            networkInjector.I(),
                            injector(),
                            settings.arguments as CryptoType),
                        child: SendCryptoPage(
                            type: settings.arguments as CryptoType),
                      ));
            case SendReviewPage.tag:
              return MaterialPageRoute(
                  builder: (context) => SendReviewPage(
                        payload: settings.arguments as SendCryptoPayload,
                      ));
            case SelectNetworkPage.tag:
              return MaterialPageRoute(
                  builder: (context) => BlocProvider(
                        create: (_) => SelectNetworkBloc(injector()),
                        child: SelectNetworkPage(),
                      ));
            default:
              return MaterialPageRoute(
                  builder: (context) => BlocProvider(
                        create: (_) =>
                            HomeBloc(networkInjector.I(), injector()),
                        child: HomePage(),
                      ));
          }
        });
  }
}

/// Custom [BlocObserver] that observes all bloc and cubit state changes.
class AppBlocObserver extends BlocObserver {
  @override
  void onChange(BlocBase bloc, Change change) {
    super.onChange(bloc, change);
    if (bloc is Cubit) print(change);
  }

  @override
  void onTransition(Bloc bloc, Transition transition) {
    super.onTransition(bloc, transition);
    print(transition);
  }
}

final RouteObserver<PageRoute> routeObserver = RouteObserver<PageRoute>();
