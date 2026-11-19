import 'package:flutter/material.dart';

import 'package:quoin/src/core/theme/quoin_colors.dart';
import 'package:quoin/src/core/theme/quoin_icons.dart';
import 'package:quoin/src/core/theme/quoin_tokens.dart';
import 'package:quoin/src/core/theme/quoin_type.dart';
import 'package:quoin/src/ui/atoms/quoin_icon.dart';

class QuoinPage extends StatelessWidget {
  const QuoinPage({
    super.key,
    required this.title,
    required Widget this.body,
    this.leading,
    this.trailing,
    this.subheader,
    this.actions = const [],
    this.onRefresh,
  }) : children = null,
       itemCount = 0,
       itemBuilder = null,
       card = false;

  const QuoinPage.list({
    super.key,
    required this.title,
    required List<Widget> this.children,
    this.leading,
    this.trailing,
    this.subheader,
    this.actions = const [],
    this.onRefresh,
  }) : body = null,
       itemCount = 0,
       itemBuilder = null,
       card = false;

  const QuoinPage.lazy({
    super.key,
    required this.title,
    required List<Widget> header,
    required this.itemCount,
    required IndexedWidgetBuilder this.itemBuilder,
    this.leading,
    this.trailing,
    this.subheader,
    this.actions = const [],
    this.onRefresh,
    this.card = true,
  }) : body = null,
       children = header;

  final String title;
  final Widget? body;
  final List<Widget>? children;
  final int itemCount;
  final IndexedWidgetBuilder? itemBuilder;
  final Widget? leading;
  final Widget? trailing;
  final Widget? subheader;
  final List<Widget> actions;
  final bool card;
  final Future<void> Function()? onRefresh;

  @override
  Widget build(BuildContext context) {
    final canPop = ModalRoute.of(context)?.impliesAppBarDismissal ?? false;
    final leading =
        this.leading ??
        (canPop
            ? IconButton(
                icon: const QuoinIcon(QuoinIcons.back),
                tooltip: MaterialLocalizations.of(context).backButtonTooltip,
                onPressed: () => Navigator.of(context).maybePop(),
              )
            : null);
    final bottom = actions.isEmpty ? MediaQuery.paddingOf(context).bottom : 0.0;
    return SafeArea(
      bottom: false,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: EdgeInsetsDirectional.fromSTEB(
              leading == null ? QuoinSpace.gutter : QuoinSpace.xs,
              QuoinSpace.m,
              trailing == null ? QuoinSpace.gutter : QuoinSpace.s,
              subheader == null ? QuoinSpace.gutter : QuoinSpace.s,
            ),
            child: ConstrainedBox(
              constraints: const BoxConstraints(
                minHeight: kMinInteractiveDimension,
              ),
              child: Row(
                children: [
                  ?leading,
                  Expanded(
                    child: title.isEmpty
                        ? const SizedBox.shrink()
                        : Semantics(
                            header: true,
                            child: Text(
                              title,
                              style: QuoinType.of(context).title,
                            ),
                          ),
                  ),
                  ?trailing,
                ],
              ),
            ),
          ),
          if (subheader case final subheader?)
            Padding(
              padding: const EdgeInsets.fromLTRB(
                QuoinSpace.gutter,
                0,
                QuoinSpace.gutter,
                QuoinSpace.m,
              ),
              child: subheader,
            ),
          Expanded(child: _refreshable(_content(context, bottom))),
          if (actions.isNotEmpty) _Actions(actions: actions),
        ],
      ),
    );
  }

  Widget _content(BuildContext context, double bottom) {
    final children = this.children;
    final physics = onRefresh == null
        ? null
        : const AlwaysScrollableScrollPhysics();
    final padding = EdgeInsets.fromLTRB(
      QuoinSpace.gutter,
      0,
      QuoinSpace.gutter,
      QuoinSpace.gutter + bottom,
    );
    return switch ((children, itemBuilder)) {
      (null, _) when onRefresh != null => LayoutBuilder(
        builder: (context, box) => SingleChildScrollView(
          physics: physics,
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: box.maxHeight),
            child: Padding(
              padding: EdgeInsets.only(bottom: bottom),
              child: body,
            ),
          ),
        ),
      ),
      (null, _) => Padding(
        padding: EdgeInsets.only(bottom: bottom),
        child: body,
      ),
      (final children?, null) => ListView(
        physics: physics,
        padding: padding,
        children: children,
      ),
      (final children?, final build?) => CustomScrollView(
        physics: physics,
        slivers: [
          SliverPadding(
            padding: padding.copyWith(bottom: 0),
            sliver: SliverList.list(children: children),
          ),
          SliverPadding(
            padding: padding,
            sliver: itemCount == 0
                ? null
                : !card
                ? SliverList.builder(itemCount: itemCount, itemBuilder: build)
                : DecoratedSliver(
                    decoration: _cardDecoration(context),
                    sliver: SliverList.builder(
                      itemCount: itemCount,
                      itemBuilder: (context, i) =>
                          _cardRow(i, build(context, i)),
                    ),
                  ),
          ),
        ],
      ),
    };
  }

  ShapeDecoration _cardDecoration(BuildContext context) {
    final c = QuoinColors.of(context);
    return ShapeDecoration(
      color: c.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(QuoinRadius.card),
        side: BorderSide(color: c.borderSubtle),
      ),
    );
  }

  Widget _cardRow(int i, Widget row) {
    const corner = Radius.circular(QuoinRadius.card);
    return ClipRRect(
      borderRadius: BorderRadius.vertical(
        top: i == 0 ? corner : Radius.zero,
        bottom: i == itemCount - 1 ? corner : Radius.zero,
      ),
      child: Material(type: MaterialType.transparency, child: row),
    );
  }

  Widget _refreshable(Widget content) => switch (onRefresh) {
    final refresh? => RefreshIndicator(onRefresh: refresh, child: content),
    null => content,
  };
}

class _Actions extends StatelessWidget {
  const _Actions({required this.actions});

  final List<Widget> actions;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(color: QuoinColors.of(context).borderSubtle),
        ),
      ),
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          QuoinSpace.gutter,
          QuoinSpace.m,
          QuoinSpace.gutter,
          QuoinSpace.gutter,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          spacing: QuoinSpace.s,
          children: actions,
        ),
      ),
    );
  }
}
