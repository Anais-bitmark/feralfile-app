//
//  SPDX-License-Identifier: BSD-2-Clause-Patent
//  Copyright © 2022 Bitmark. All rights reserved.
//  Use of this source code is governed by the BSD-2-Clause Plus Patent License
//  that can be found in the LICENSE file.
//

import 'dart:convert';

import 'package:autonomy_flutter/common/injector.dart';
import 'package:autonomy_flutter/service/settings_data_service.dart';
import 'package:autonomy_flutter/service/social_recovery/shard_deck.dart';
import 'package:autonomy_flutter/service/social_recovery/social_recovery_service.dart';
import 'package:autonomy_flutter/util/custom_exception.dart';
import 'package:autonomy_flutter/util/style.dart';
import 'package:autonomy_flutter/util/ui_helper.dart';
import 'package:autonomy_flutter/view/au_filled_button.dart';
import 'package:autonomy_flutter/view/au_text_field.dart';
import 'package:autonomy_flutter/view/back_appbar.dart';
import 'package:flutter/material.dart';

class RestoreWithEmergencyContactPage extends StatefulWidget {
  const RestoreWithEmergencyContactPage({Key? key}) : super(key: key);

  @override
  State<RestoreWithEmergencyContactPage> createState() =>
      _RestoreWithEmergencyContactPageState();
}

class _RestoreWithEmergencyContactPageState
    extends State<RestoreWithEmergencyContactPage> {
  TextEditingController _deckTextController = TextEditingController();
  bool _isError = false;
  bool _isSubmissionEnabled = false;
  bool _isProcessing = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: getCloseAppBar(
        context,
        onBack: () async {
          await injector<SocialRecoveryService>().clearRestoreProcess();
          Navigator.of(context).pop();
        },
      ),
      body: Container(
        margin: pageEdgeInsetsWithSubmitButton,
        child: Column(children: [
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Get ShardDeck from Emergency Contact",
                      style: appTextTheme.headline1,
                    ),
                    addTitleSpace(),
                    Text(
                      "some description about Emergency Contact",
                      style: appTextTheme.bodyText1,
                    ),
                    SizedBox(height: 40),
                    Container(
                      height: 120,
                      child: AuTextField(
                          title: "",
                          placeholder: "Enter contact deck",
                          keyboardType: TextInputType.multiline,
                          expanded: true,
                          maxLines: null,
                          hintMaxLines: 2,
                          controller: _deckTextController,
                          isError: _isError,
                          onChanged: (value) async {
                            setState(() {
                              _isSubmissionEnabled = value.isNotEmpty;
                            });
                          }),
                    ),
                  ]),
            ),
          ),
          Row(
            children: [
              Expanded(
                child: AuFilledButton(
                  enabled: _isSubmissionEnabled,
                  text: _isProcessing ? "RESTORING..." : "RESTORE",
                  isProcessing: _isProcessing,
                  onPress: () {
                    if (_isSubmissionEnabled) _submitRestore();
                  },
                ),
              ),
            ],
          ),
        ]),
      ),
    );
  }

  Future _submitRestore() async {
    FocusScope.of(context).unfocus();
    setState(() {
      _isProcessing = true;
    });

    // Check valid ShardDeck input
    late ShardDeck shardDeck;
    try {
      shardDeck = ShardDeck.fromJson(jsonDecode(_deckTextController.text));
    } catch (_) {
      setState(() {
        _isProcessing = false;
        _isError = true;
      });
      return;
    }

    // Restore
    // Done Onboarding if success
    try {
      await injector<SocialRecoveryService>().restoreAccount(shardDeck);
      doneOnboarding(context);
      try {
        injector<SettingsDataService>().restoreSettingsData();
      } catch (_) {
        // just ignore this so that user can go through onboarding
      }
      await askForNotification();
    } catch (exception) {
      setState(() {
        _isProcessing = false;
        _isError = true;
      });

      UIHelper.showInfoDialog(
        context,
        "Error",
        "ShardDecks don't match. Please check again",
        closeButton: "CLOSE",
        isDismissible: true,
      );
    }
  }
}
