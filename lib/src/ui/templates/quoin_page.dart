import 'package:flutter/material.dart';

import 'package:quoin/src/core/theme/quoin_icons.dart';
import 'package:quoin/src/core/theme/quoin_tokens.dart';
import 'package:quoin/src/core/theme/quoin_type.dart';
import 'package:quoin/src/ui/atoms/quoin_icon.dart';

class QuoinPage extends StatelessWidget {
  const QuoinPage({
    super.key,
    required this.title,
    required Widget this.body,
    this.trailing,
  }) : children = null,
       itemCount = 0,
       itemBuilder = null;

  const QuoinPage.list({
    super.key,
    required this.title,
    required List<Widget> this.children,
    this.trailing,
  }) : body = null,
       itemCount = 0,
       itemBuilder = null;

  const QuoinPage.lazy({
    super.key,
    required this.title,
    required List<Widget> header,
    required this.itemCount,
    required IndexedWidgetBuilder this.itemBuilder,
    this.trailing,
  }) : body = null,
       children = header;

  final String title;
  final Widget? body;
  final List<Widget>? children;
  final int itemCount;
  final IndexedWidgetBuilder? itemBuilder;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.paddingOf(context).bottom;
    final children = this.children;
    final padding = EdgeInsets.fromLTRB(
      QuoinSpace.gutter,
      0,
      QuoinSpace.gutter,
      QuoinSpace.gutter + bottom,
    );
    final canPop = ModalRoute.of(context)?.impliesAppBarDismissal ?? false;
    return SafeArea(
      bottom: false,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: EdgeInsetsDirectional.fromSTEB(
              canPop ? 4 : QuoinSpace.gutter,
              12,
              trailing == null ? QuoinSpace.gutter : 8,
              QuoinSpace.gutter,
            ),
            child: Row(
              children: [
                if (canPop)
                  IconButton(
                    icon: const QuoinIcon(QuoinIcons.back),
                    tooltip: MaterialLocalizations.of(context)
                        .backButtonTooltip,
                    onPressed: () => Navigator.of(context).maybePop(),
                  ),
                Expanded(
                  child: Semantics(
                    header: true,
                    child: Text(title, style: QuoinType.of(context).title),
                  ),
                ),
                ?trailing,
              ],
            ),
          ),
          Expanded(
            child: switch ((children, itemBuilder)) {
              (null, _) => Padding(
                padding: EdgeInsets.only(bottom: bottom),
                child: body,
              ),
              (final children?, null) => ListView(
                padding: padding,
                children: children,
              ),
              (final children?, final build?) => ListView.builder(
                padding: padding,
                itemCount: children.length + itemCount,
                itemBuilder: (context, i) => i < children.length
                    ? children[i]
                    : build(context, i - children.length),
              ),
            },
          ),
        ],
      ),
    );
  }
}
