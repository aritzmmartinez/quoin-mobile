import 'package:flutter/material.dart';

import 'package:quoin/src/core/theme/quoin_tokens.dart';
import 'package:quoin/src/core/theme/quoin_type.dart';

class QuoinPage extends StatelessWidget {
  const QuoinPage({super.key, required this.title, required Widget this.body})
    : children = null;

  const QuoinPage.list({
    super.key,
    required this.title,
    required List<Widget> this.children,
  }) : body = null;

  final String title;
  final Widget? body;
  final List<Widget>? children;

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.paddingOf(context).bottom;
    return SafeArea(
      bottom: false,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(
              QuoinSpace.gutter,
              12,
              QuoinSpace.gutter,
              QuoinSpace.gutter,
            ),
            child: Semantics(
              header: true,
              child: Text(title, style: QuoinType.of(context).title),
            ),
          ),
          Expanded(
            child: children == null
                ? Padding(
                    padding: EdgeInsets.only(bottom: bottom),
                    child: body,
                  )
                : ListView(
                    padding: EdgeInsets.fromLTRB(
                      QuoinSpace.gutter,
                      0,
                      QuoinSpace.gutter,
                      QuoinSpace.gutter + bottom,
                    ),
                    children: children!,
                  ),
          ),
        ],
      ),
    );
  }
}
