import 'package:autonomy_flutter/screen/settings/preferences/preferences_bloc.dart';
import 'package:autonomy_flutter/screen/settings/preferences/preferences_state.dart';
import 'package:autonomy_flutter/util/style.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class PreferenceView extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    context.read<PreferencesBloc>().add(PreferenceInfoEvent());

    return BlocBuilder<PreferencesBloc, PreferenceState>(
        builder: (context, state) {
      return Container(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Preferences",
              style: appTextTheme.headline1,
            ),
            SizedBox(height: 24),
            _preferenceItem(
              context,
              'Immediate playback',
              "Enable playback when tapping on a thumbnail.",
              state.isImmediatePlaybackEnabled,
              (value) {
                final newState = PreferenceState(
                    value,
                    state.isDevicePasscodeEnabled,
                    state.isNotificationEnabled,
                    state.isAnalyticEnabled,
                    state.authMethodName);
                context
                    .read<PreferencesBloc>()
                    .add(PreferenceUpdateEvent(newState));
              },
            ),
            Divider(),
            _preferenceItem(
              context,
              state.authMethodName,
              "Use ${state.authMethodName != 'Device Passcode' ? state.authMethodName : 'device passcode'} to unlock the app, transact, and authenticate.",
              state.isDevicePasscodeEnabled,
              (value) {
                final newState = PreferenceState(
                    state.isImmediatePlaybackEnabled,
                    value,
                    state.isNotificationEnabled,
                    state.isAnalyticEnabled,
                    state.authMethodName);
                context
                    .read<PreferencesBloc>()
                    .add(PreferenceUpdateEvent(newState));
              },
            ),
            Divider(),
            _preferenceItem(
              context,
              "Notifications",
              "Receive alerts about your transactions and other activities in your wallet.",
              state.isNotificationEnabled,
              (value) {
                final newState = PreferenceState(
                    state.isImmediatePlaybackEnabled,
                    state.isDevicePasscodeEnabled,
                    value,
                    state.isAnalyticEnabled,
                    state.authMethodName);
                context
                    .read<PreferencesBloc>()
                    .add(PreferenceUpdateEvent(newState));
              },
            ),
            Divider(),
            _preferenceItem(
              context,
              "Analytics",
              "Contribute anonymized, aggregate usage data to help improve Autonomy.",
              state.isAnalyticEnabled,
              (value) {
                final newState = PreferenceState(
                    state.isImmediatePlaybackEnabled,
                    state.isDevicePasscodeEnabled,
                    state.isNotificationEnabled,
                    value,
                    state.authMethodName);
                context
                    .read<PreferencesBloc>()
                    .add(PreferenceUpdateEvent(newState));
              },
            ),
          ],
        ),
      );
    });
  }

  Widget _preferenceItem(BuildContext context, String title, String description,
      bool isEnabled, ValueChanged<bool> onChanged) {
    return Container(
      padding: EdgeInsets.only(bottom: 16.0),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(title, style: appTextTheme.headline4),
              CupertinoSwitch(
                value: isEnabled,
                onChanged: onChanged,
                activeColor: Colors.black,
              )
            ],
          ),
          Text(
            description,
            style: appTextTheme.bodyText1,
          ),
        ],
      ),
    );
  }
}
