import 'dart:async';
import 'dart:convert';

import 'package:autonomy_flutter/common/injector.dart';
import 'package:autonomy_flutter/model/shared_postcard.dart';
import 'package:autonomy_flutter/screen/app_router.dart';
import 'package:autonomy_flutter/screen/detail/artwork_detail_page.dart';
import 'package:autonomy_flutter/screen/interactive_postcard/postcard_detail_page.dart';
import 'package:autonomy_flutter/service/configuration_service.dart';
import 'package:autonomy_flutter/service/navigation_service.dart';
import 'package:autonomy_flutter/util/log.dart';
import 'package:autonomy_flutter/util/rand.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

void onDidReceiveBackgroundNotificationResponse(NotificationResponse details) {
  log.info("[onDidReceiveBackgroundNotificationResponse] $details");
}

enum NotificationType {
  Postcard;

  Map<String, dynamic> toJson() {
    return {
      'name': name,
    };
  }

  static NotificationType fromJson(Map<String, dynamic> map) {
    final value = NotificationType.values
        .firstWhere((element) => element.name == map['name']);
    return value;
  }
}

class Notification {
  int id;
  NotificationType type;
  String tokenId;

  Notification({required this.id, required this.type, required this.tokenId});

  factory Notification.fromJson(Map<String, dynamic> map) {
    return Notification(
      id: map['id'],
      type: NotificationType.fromJson(jsonDecode(map['type'])),
      tokenId: map['tokenId'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': jsonEncode(type.toJson()),
      'tokenId': tokenId,
    };
  }
}

class NotificationPayload {
  int id;
  NotificationType type;
  String metadata;

  NotificationPayload(
      {required this.id, required this.type, required this.metadata});

  factory NotificationPayload.fromJson(Map<String, dynamic> map) {
    return NotificationPayload(
      id: map['id'],
      type: NotificationType.fromJson(jsonDecode(map['type'])),
      metadata: map['metadata'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': jsonEncode(type.toJson()),
      'metadata': metadata,
    };
  }
}

class NotificationService {
  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  List<Notification> notifications = [];
  final groupKey = 'com.android.autonomy.grouped_notification';
  final groupChannelId = 'grouped_channel_id';
  final groupChannelName = 'grouped_channel_name';
  final groupChannelDescription = 'grouped_channel_description';

  final NavigationService _navigationService;
  final ConfigurationService _configurationService;

  NotificationService(this._navigationService, this._configurationService);

  Future<void> initNotification() async {
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('autonomy_icon');

    DarwinInitializationSettings initializationSettingsIOS =
        DarwinInitializationSettings();

    InitializationSettings initializationSettings = InitializationSettings(
        android: initializationSettingsAndroid, iOS: initializationSettingsIOS);
    await flutterLocalNotificationsPlugin.initialize(
      initializationSettings,
      onDidReceiveBackgroundNotificationResponse:
          onDidReceiveBackgroundNotificationResponse,
      onDidReceiveNotificationResponse: onDidReceiveNotificationResponse,
    );
  }

  Future<void> onDidReceiveNotificationResponse(
      NotificationResponse details) async {
    if (details.notificationResponseType !=
        NotificationResponseType.selectedNotification) {
      return;
    }
    try {
      final notificationPayload =
          NotificationPayload.fromJson(jsonDecode(details.payload ?? ""));
      switch (notificationPayload.type) {
        case NotificationType.Postcard:
          final postcardIdentity = PostcardIdentity.fromJson(
              jsonDecode(notificationPayload.metadata));
          _navigationService.popUntilHome();
          _navigationService.navigateTo(AppRouter.claimedPostcardDetailsPage,
              arguments: ArtworkDetailPayload([
                ArtworkIdentity(postcardIdentity.id, postcardIdentity.owner)
              ], 0));
      }
    } catch (e) {
      log.info(
          "[NotificationService] onDidReceiveNotificationResponse error: $e]");
    }
  }

  Future<void> showNotification(
      {int id = 0,
      required String title,
      String? body,
      String? payload}) async {
    AndroidNotificationDetails androidPlatformChannelSpecifics =
        AndroidNotificationDetails(groupChannelId, groupChannelName,
            channelDescription: groupChannelDescription,
            groupKey: groupKey,
            importance: Importance.max,
            priority: Priority.high,
            ticker: 'ticker',
            playSound: false,
            enableVibration: false,
            onlyAlertOnce: true,
            showWhen: false);

    const DarwinNotificationDetails iOSPlatformChannelSpecifics =
        DarwinNotificationDetails(
      presentAlert: false,
      presentBadge: false,
      presentSound: false,
      subtitle: '',
      sound: '',
      badgeNumber: 0,
      threadIdentifier: '',
      attachments: [],
    );

    NotificationDetails platformChannelSpecifics = NotificationDetails(
        android: androidPlatformChannelSpecifics,
        iOS: iOSPlatformChannelSpecifics);
    await flutterLocalNotificationsPlugin
        .show(id, title, body, platformChannelSpecifics, payload: payload);
  }

  Future<void> scheduleShowNotification(
      {int id = 0,
      required String title,
      String? body,
      String? payload}) async {}

  Future<void> cancelNotification(int id) async {
    await flutterLocalNotificationsPlugin.cancel(id);
  }

  Future<void> showPostcardWasnotDeliveredNotification(
      PostcardIdentity postcardIdentity) async {
    final notificationId = random.nextInt(100000);
    final payload = NotificationPayload(
        id: notificationId,
        type: NotificationType.Postcard,
        metadata: jsonEncode(postcardIdentity.toJson()));

    await showNotification(
        title: "moma_postcard".tr(),
        body: "your_postcard_not_delivered".tr(),
        payload: jsonEncode(payload.toJson()),
        id: notificationId);
    notifications.add(Notification(
        id: notificationId,
        type: NotificationType.Postcard,
        tokenId: postcardIdentity.id));
  }

  Future<void> checkNotification() async {
    final expiredPostcardShareLink =
        await _configurationService.getSharedPostcard().expiredPostcards;
    if (_configurationService.isNotificationEnabled() ?? false) {
      Timer.periodic(const Duration(seconds: 1), (timer) async {
        final index = timer.tick;
        if (index >= expiredPostcardShareLink.length) {
          timer.cancel();
        } else {
          final expiredPostcard = expiredPostcardShareLink[index];
          await injector<NotificationService>()
              .showPostcardWasnotDeliveredNotification(PostcardIdentity(
                  id: expiredPostcard.tokenID, owner: expiredPostcard.owner));
        }
      });
      _configurationService.expiredPostcardSharedLinkTip.value = [];
    } else {
      _configurationService.expiredPostcardSharedLinkTip.value =
          expiredPostcardShareLink;
    }
  }
}
