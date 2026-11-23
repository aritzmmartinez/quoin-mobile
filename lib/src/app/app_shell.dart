import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:quoin/src/app/router.dart';
import 'package:quoin/src/core/l10n/gen/app_localizations.dart';
import 'package:quoin/src/core/theme/quoin_icons.dart';
import 'package:quoin/src/features/sync/presentation/widgets/sync_actions.dart';
import 'package:quoin/src/ui/organisms/quoin_bar_fade.dart';
import 'package:quoin/src/ui/organisms/quoin_bottom_bar.dart';

const _tabRoots = {
  Routes.home,
  Routes.portfolio,
  Routes.analysis,
  Routes.settings,
};

class AppShell extends ConsumerStatefulWidget {
  const AppShell({super.key, required this.shell, required this.branches});

  final StatefulNavigationShell shell;
  final List<Widget> branches;

  @override
  ConsumerState<AppShell> createState() => _AppShellState();
}

class _AppShellState extends ConsumerState<AppShell> {
  late final _pages = PageController(initialPage: widget.shell.currentIndex);
  late final _position = ValueNotifier(widget.shell.currentIndex.toDouble());
  var _dragging = false;
  var _swipe = 0.0;

  @override
  void initState() {
    super.initState();
    Future.microtask(() => syncOnOpen(ref));
  }

  @override
  void didUpdateWidget(AppShell old) {
    super.didUpdateWidget(old);
    final index = widget.shell.currentIndex;
    if (!_dragging && _pages.hasClients && _pages.page?.round() != index) {
      _pages.jumpToPage(index);
    }
  }

  @override
  void dispose() {
    _pages.dispose();
    _position.dispose();
    super.dispose();
  }

  void _settle(int page) {
    if (page == widget.shell.currentIndex) return;
    HapticFeedback.selectionClick();
    widget.shell.goBranch(page);
  }

  bool _onScroll(ScrollNotification n) {
    if (n.depth != 0) return false;
    switch (n) {
      case ScrollStartNotification(dragDetails: _?):
        setState(() => _dragging = true);
      case ScrollUpdateNotification() when _dragging:
        _position.value = _pages.page!;
      case ScrollEndNotification():
        if (_dragging) setState(() => _dragging = false);
        _settle(_pages.page!.round());
    }
    return false;
  }

  void _onSwipeEnd(DragEndDetails details) {
    final velocity = details.primaryVelocity ?? 0;
    final fling = velocity.abs() > kMinFlingVelocity;
    if (!fling && _swipe.abs() < context.size!.width / 3) return;
    var step = -(fling ? velocity : _swipe).sign.toInt();
    if (Directionality.of(context) == TextDirection.rtl) step = -step;
    _settle((widget.shell.currentIndex + step).clamp(0, 3));
  }

  @override
  Widget build(BuildContext context) {
    final shell = widget.shell;
    final l10n = AppLocalizations.of(context);
    final reduceMotion = MediaQuery.disableAnimationsOf(context);
    final swipes = _tabRoots.contains(
      shell.shellRouteContext.routerState.uri.path,
    );

    final jumps = swipes && reduceMotion;
    final edges = swipes
        ? MediaQuery.systemGestureInsetsOf(context)
        : EdgeInsets.zero;
    Widget edge() => GestureDetector(
      behavior: HitTestBehavior.translucent,
      onHorizontalDragStart: (_) {},
    );
    final pages = NotificationListener<ScrollNotification>(
      onNotification: _onScroll,
      child: PageView(
        controller: _pages,
        physics: swipes && !reduceMotion
            ? null
            : const NeverScrollableScrollPhysics(),
        children: [
          for (final (i, branch) in widget.branches.indexed)
            TickerMode(
              enabled: i == shell.currentIndex || _dragging,
              child: branch,
            ),
        ],
      ),
    );
    return Scaffold(
      extendBody: true,
      body: Builder(
        builder: (context) => _faded(
          context,
          Stack(
            children: [
              GestureDetector(
                onHorizontalDragStart: jumps ? (_) => _swipe = 0 : null,
                onHorizontalDragUpdate: jumps
                    ? (d) => _swipe += d.primaryDelta ?? 0
                    : null,
                onHorizontalDragEnd: jumps ? _onSwipeEnd : null,
                child: pages,
              ),
              PositionedDirectional(
                start: 0,
                top: 0,
                bottom: 0,
                width: edges.left,
                child: edge(),
              ),
              PositionedDirectional(
                end: 0,
                top: 0,
                bottom: 0,
                width: edges.right,
                child: edge(),
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: QuoinBottomBar(
        items: [
          QuoinBarItem(icon: QuoinIcons.home, label: l10n.tabHome),
          QuoinBarItem(icon: QuoinIcons.portfolio, label: l10n.tabPortfolio),
          QuoinBarItem(icon: QuoinIcons.analysis, label: l10n.tabAnalysis),
          QuoinBarItem(icon: QuoinIcons.settings, label: l10n.tabSettings),
        ],
        currentIndex: shell.currentIndex,
        position: reduceMotion ? null : _position,
        onSelected: (i) =>
            shell.goBranch(i, initialLocation: i == shell.currentIndex),
        addIcon: QuoinIcons.add,
        addLabel: l10n.importCsv,
        onAdd: () => context.push(Routes.import),
      ),
    );
  }

  Widget _faded(BuildContext context, Widget tab) {
    final media = MediaQuery.of(context);
    final under = media.padding.bottom + QuoinBarFade.reach;
    return Stack(
      children: [
        MediaQuery(
          data: media.copyWith(padding: media.padding.copyWith(bottom: under)),
          child: tab,
        ),
        PositionedDirectional(
          start: 0,
          end: 0,
          bottom: 0,
          child: QuoinBarFade(height: under),
        ),
      ],
    );
  }
}
