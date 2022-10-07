import 'package:autonomy_flutter/model/ff_account.dart';
import 'package:easy_localization/easy_localization.dart';

extension FeralfileErrorExt on FeralfileError {
  String get dialogTitle {
    switch (code) {
      case 5006:
        return "Too soon";
      case 5011:
        return "expired2".tr();
      case 5013:
        return "Out of token";
      case 5014:
        return "already_accepted".tr();
      default:
        return "error".tr();
    }
  }

  String get dialogMessage {
    switch (code) {
      case 5006:
        return "The show has not started. Please scan the QR code at the start time of airdrop.";
      case 5011:
        return "qr_expired_message".tr();
      case 5013:
        return "Sorry, the tokens have been delivered to all fastest users.";
      case 5014:
        return "claimed_error_message".tr();
      default:
        return message;
    }
  }
}
