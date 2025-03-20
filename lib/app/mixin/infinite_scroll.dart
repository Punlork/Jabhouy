import 'package:flutter/material.dart';

mixin InfiniteScrollMixin<T extends StatefulWidget> on State<T> {
  ScrollController? _scrollController;

  void setupScrollListener(BuildContext context) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _scrollController = getScrollController(context);
        _scrollController?.addListener(_onScroll);
        setState(() {});
      }
    });
  }

  ScrollController? getScrollController(BuildContext context);

  void onScrollToBottom();

  bool isScrollAtBottom() {
    if (_scrollController == null || !_scrollController!.hasClients) return false;
    final maxScroll = _scrollController!.position.maxScrollExtent;
    final currentScroll = _scrollController!.offset;
    return currentScroll >= (maxScroll * 0.9); // Trigger at 90%
  }

  void _onScroll() {
    if (!mounted || !isScrollAtBottom()) return;
    onScrollToBottom();
  }

  void disposeScrollListener() => _scrollController?.removeListener(_onScroll);

  ScrollController? get controller => _scrollController;
}
