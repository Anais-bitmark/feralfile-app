import 'package:autonomy_theme/autonomy_theme.dart';
import 'package:flutter/material.dart';

class PostcardButton extends StatelessWidget {
  final Function()? onTap;
  final Color? color;
  final String? text;
  final double? width;
  final bool isProcessing;
  final bool enabled;
  final Color? textColor;

  const PostcardButton({
    Key? key,
    this.onTap,
    this.color,
    this.text,
    this.width,
    this.enabled = true,
    this.isProcessing = false,
    this.textColor,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    const defaultActiveColor = Colors.amber;
    return SizedBox(
      width: width,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor:
              enabled ? color ?? defaultActiveColor : theme.auLightGrey,
          shadowColor: Colors.transparent,
          disabledForegroundColor: theme.auLightGrey,
          disabledBackgroundColor: theme.auLightGrey,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(0),
          ),
        ),
        onPressed: enabled ? onTap : null,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 14),
          child: Center(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                isProcessing
                    ? Container(
                        height: 14.0,
                        width: 14.0,
                        margin: const EdgeInsets.only(right: 8.0),
                        child: CircularProgressIndicator(
                          color: theme.colorScheme.primary,
                          backgroundColor: theme.colorScheme.surface,
                          strokeWidth: 2.0,
                        ),
                      )
                    : const SizedBox(),
                Text(
                  text ?? '',
                  style: theme.textTheme.ppMori400Black14.copyWith(color: textColor),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class PostcardOutlineButton extends StatelessWidget {
  final Function()? onTap;
  final Color? color;
  final String? text;
  final double? width;
  final bool isProcessing;
  final bool enabled;
  final Color? textColor;
  final Color? borderColor;

  const PostcardOutlineButton({
    Key? key,
    this.onTap,
    this.color,
    this.text,
    this.width,
    this.enabled = true,
    this.isProcessing = false,
    this.textColor,
    this.borderColor,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SizedBox(
      width: width,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: color ?? theme.auGreyBackground,
          shadowColor: Colors.transparent,
          elevation: 0,
          shape: RoundedRectangleBorder(
            side: BorderSide(color: borderColor ?? Colors.white),
            borderRadius: BorderRadius.circular(0),
          ),
        ),
        onPressed: enabled ? onTap : null,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 13),
          child: Center(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                isProcessing
                    ? Container(
                        height: 14.0,
                        width: 14.0,
                        margin: const EdgeInsets.only(right: 8.0),
                        child: CircularProgressIndicator(
                          color: theme.colorScheme.primary,
                          backgroundColor: theme.colorScheme.surface,
                          strokeWidth: 2.0,
                        ),
                      )
                    : const SizedBox(),
                Text(
                  text ?? '',
                  style: theme.textTheme.ppMori400White14.copyWith(
                      color: textColor ??
                          (!enabled ? AppColor.disabledColor : null)),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class PostcardCustomOutlineButton extends StatelessWidget {
  final Function()? onTap;
  final Color? color;
  final Widget child;
  final double? width;
  final bool isProcessing;
  final bool enabled;
  final Color? textColor;
  final Color? borderColor;

  const PostcardCustomOutlineButton({
    Key? key,
    this.onTap,
    this.color,
    required this.child,
    this.width,
    this.enabled = true,
    this.isProcessing = false,
    this.textColor,
    this.borderColor,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SizedBox(
      width: width,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: color ?? theme.auGreyBackground,
          shadowColor: Colors.transparent,
          elevation: 0,
          shape: RoundedRectangleBorder(
            side: BorderSide(color: borderColor ?? Colors.white),
            borderRadius: BorderRadius.circular(0),
          ),
        ),
        onPressed: enabled ? onTap : null,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 13),
          child: Center(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                isProcessing
                    ? Container(
                        height: 14.0,
                        width: 14.0,
                        margin: const EdgeInsets.only(right: 8.0),
                        child: CircularProgressIndicator(
                          color: theme.colorScheme.primary,
                          backgroundColor: theme.colorScheme.surface,
                          strokeWidth: 2.0,
                        ),
                      )
                    : const SizedBox(),
                child,
              ],
            ),
          ),
        ),
      ),
    );
  }
}
