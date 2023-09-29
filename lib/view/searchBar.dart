import 'package:autonomy_flutter/util/au_icons.dart';
import 'package:autonomy_theme/autonomy_theme.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';

class AuSearchBar extends StatefulWidget {
  final Function(String)? onChanged;

  const AuSearchBar({super.key, this.onChanged});

  @override
  State<AuSearchBar> createState() => _SearchBarState();
}

class _SearchBarState extends State<AuSearchBar> {
  final _controller = TextEditingController();
  final _focusNode = FocusNode();
  bool _isSearching = false;

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      height: 37,
      decoration: BoxDecoration(
        color: AppColor.auLightGrey,
        borderRadius: BorderRadius.circular(5),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 10),
      child: Row(
        children: [
          SvgPicture.asset(
            "assets/images/search.svg",
            width: 20,
            height: 20,
            colorFilter: const ColorFilter.mode(
                AppColor.secondarySpanishGrey, BlendMode.srcIn),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Center(
              child: TextField(
                controller: _controller,
                focusNode: _focusNode,
                style: theme.textTheme.ppMori400Black14,
                decoration: InputDecoration(
                  contentPadding: const EdgeInsets.only(bottom: 10),
                  hintText: "search".tr(),
                  hintStyle: theme.textTheme.ppMori400Grey14
                      .copyWith(color: AppColor.secondarySpanishGrey),
                  border: InputBorder.none,
                ),
                onChanged: (value) {
                  widget.onChanged?.call(value);
                  if (value.isNotEmpty) {
                    setState(() {
                      _isSearching = true;
                    });
                  } else {
                    setState(() {
                      _isSearching = false;
                    });
                  }
                },
              ),
            ),
          ),
          const SizedBox(width: 10),
          if (_isSearching)
            GestureDetector(
              onTap: () {
                _controller.clear();
                widget.onChanged?.call("");
              },
              child: const Icon(
                AuIcon.close,
                size: 20,
                color: AppColor.primaryBlack,
              ),
            ),
        ],
      ),
    );
  }
}

class ActionBar extends StatefulWidget {
  final AuSearchBar searchBar;
  final Function()? onSearch;
  final Function()? onCancel;

  const ActionBar(
      {super.key, required this.searchBar, this.onSearch, this.onCancel});

  @override
  State<ActionBar> createState() => _ActionBarState();
}

class _ActionBarState extends State<ActionBar> {
  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Expanded(
          child: widget.searchBar,
        ),
        const SizedBox(width: 14),
        GestureDetector(
          onTap: () {
            widget.onCancel?.call();
          },
          child: Text(
            "Cancel",
            style: theme.textTheme.ppMori400Grey14,
          ),
        )
      ],
    );
  }
}
