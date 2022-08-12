//
//  SPDX-License-Identifier: BSD-2-Clause-Patent
//  Copyright © 2022 Bitmark. All rights reserved.
//  Use of this source code is governed by the BSD-2-Clause Plus Patent License
//  that can be found in the LICENSE file.
//

import 'package:autonomy_flutter/util/log.dart';
import 'package:autonomy_flutter/view/au_button_clipper.dart';
import 'package:flutter/material.dart';
import 'package:flutter_vibrate/flutter_vibrate.dart';
import 'package:onesignal_flutter/onesignal_flutter.dart';
import 'package:overlay_support/overlay_support.dart';
// ignore: implementation_imports
import 'package:overlay_support/src/overlay_state_finder.dart';

Widget _notificationToast(BuildContext context, OSNotification notification,
    {Function(OSNotification notification)? notificationOpenedHandler}) {
  return _simpleNotificationToast(
      context, notification.body ?? "", Key(notification.notificationId),
      notificationOpenedHandler: () {
    if (notificationOpenedHandler != null) {
      notificationOpenedHandler(notification);
    }
  });
}

Widget _simpleNotificationToast(
    BuildContext context, String notification, Key key,
    {Function()? notificationOpenedHandler}) {
  final theme = Theme.of(context);
  return ClipPath(
      clipper: AutonomyButtonClipper(),
      child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 68),
          child: GestureDetector(
              onTap: () {
                hideOverlay(key);
                if (notificationOpenedHandler != null) {
                  notificationOpenedHandler();
                }
              },
              child: Container(
                color: theme.colorScheme.primary.withOpacity(0.8),
                padding:
                    const EdgeInsets.symmetric(vertical: 10, horizontal: 15),
                child: Center(
                    child: Text(
                  notification,
                  textAlign: TextAlign.center,
                  style: theme.primaryTextTheme.button,
                )),
              ))));
}

void showNotifications(BuildContext context, OSNotification notification,
    {Function(OSNotification notification)? notificationOpenedHandler}) {
  showSimpleNotification(
      _notificationToast(context, notification,
          notificationOpenedHandler: notificationOpenedHandler),
      background: Colors.transparent,
      duration: const Duration(seconds: 3),
      elevation: 0,
      key: Key(notification.notificationId),
      slideDismissDirection: DismissDirection.up);
  Vibrate.feedback(FeedbackType.warning);
}

void showCustomNotifications(BuildContext context, String notification, Key key,
    {Function()? notificationOpenedHandler}) {
  showSimpleNotification(
      _simpleNotificationToast(context, notification, key,
          notificationOpenedHandler: notificationOpenedHandler),
      background: Colors.transparent,
      elevation: 0,
      autoDismiss: false,
      key: key,
      slideDismissDirection: DismissDirection.up);
  Vibrate.feedback(FeedbackType.warning);
}

void hideOverlay(Key key) {
  final OverlaySupportState? overlaySupport = findOverlayState();
  if (overlaySupport == null) {
    log.warning("Cannot find overlay key: $key");
    return;
  }

  final overlayEntry = overlaySupport.getEntry(key: key);

  overlayEntry?.dismiss();
}
