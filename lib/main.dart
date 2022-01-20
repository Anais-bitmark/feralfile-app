import 'package:autonomy_flutter/database/app_database.dart';
import 'package:autonomy_flutter/screen/detail/artwork_detail_bloc.dart';
import 'package:autonomy_flutter/screen/detail/artwork_detail_page.dart';
import 'package:autonomy_flutter/screen/detail/preview/artwork_preview_bloc.dart';
import 'package:autonomy_flutter/screen/detail/preview/artwork_preview_page.dart';
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
import 'package:sentry_flutter/sentry_flutter.dart';

import 'common/injector.dart';
import 'common/network_config_injector.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await setup();

  final personaService = injector<PersonaService>();
  if (personaService.getActivePersona() == null) {
    personaService.createPersona("Autonomy");
  }

  await SentryFlutter.init(
    (options) {
      options.dsn =
          'https://3327d497b7324d2e9824c88bec2235e2@o142150.ingest.sentry.io/6088804';
      // Set tracesSampleRate to 1.0 to capture 100% of transactions for performance monitoring.
      // We recommend adjusting this value in production.
      options.tracesSampleRate = 1.0;
    },
    appRunner: () => BlocOverrides.runZoned(
      () => runApp(AutonomyApp()),
      blocObserver: AppBlocObserver(),
    ),
  );
}

class AutonomyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final networkInjector = injector<NetworkConfigInjector>();

    return MaterialApp(
        title: 'Autonomy',
        theme: ThemeData(
          primarySwatch: Colors.grey,
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
                fontSize: 24,
                fontWeight: FontWeight.w700,
                fontFamily: "AtlasGrotesk"),
            headline3: TextStyle(
                color: Colors.black,
                fontSize: 22,
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
        navigatorObservers: [routeObserver],
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
              return MaterialPageRoute(
                  builder: (context) => ScanQRPage(
                        scannerItem: settings.arguments as ScannerItem,
                      ));
            case SettingsPage.tag:
              return MaterialPageRoute(
                builder: (context) => BlocProvider(
                  create: (_) => SettingsBloc(
                      injector(), networkInjector.I(), networkInjector.I()),
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
                            (settings.arguments as SendData).type),
                        child: SendCryptoPage(
                            data: settings.arguments as SendData),
                      ));
            case SendReviewPage.tag:
              return MaterialPageRoute(
                  builder: (context) => SendReviewPage(
                        payload: settings.arguments as SendCryptoPayload,
                      ));
            case ArtworkPreviewPage.tag:
              return MaterialPageRoute(
                  builder: (context) => BlocProvider(
                    create: (_) =>
                        ArtworkPreviewBloc(networkInjector.I<AppDatabase>().assetDao),
                    child: ArtworkPreviewPage(
                      payload: settings.arguments as ArtworkDetailPayload,
                    ),
                  ));
            case SelectNetworkPage.tag:
              return MaterialPageRoute(
                  builder: (context) => BlocProvider(
                        create: (_) => SelectNetworkBloc(injector()),
                        child: SelectNetworkPage(),
                      ));
            case ArtworkDetailPage.tag:
              return MaterialPageRoute(
                  builder: (context) => BlocProvider(
                        create: (_) => ArtworkDetailBloc(networkInjector.I(),
                            networkInjector.I<AppDatabase>().assetDao),
                        child: ArtworkDetailPage(
                            payload:
                                settings.arguments as ArtworkDetailPayload),
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

final RouteObserver<ModalRoute<void>> routeObserver =
    RouteObserver<ModalRoute<void>>();
