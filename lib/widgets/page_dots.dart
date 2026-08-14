import 'package:flutter/material.dart';

class PageDots extends StatefulWidget {
  final PageController controller;
  final int count;

  const PageDots({super.key, required this.controller, required this.count});

  @override
  State<PageDots> createState() => _PageDotsState();
}

class _PageDotsState extends State<PageDots> {
  int _currentPage = 0;

  @override
  void initState() {
    widget.controller.addListener(_onPageChanged);
    super.initState();
  }

  @override
  void didUpdateWidget(PageDots oldWidget) {
    if (widget.controller != oldWidget.controller) {
      oldWidget.controller.removeListener(_onPageChanged);
      widget.controller.addListener(_onPageChanged);
    }
    super.didUpdateWidget(oldWidget);
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onPageChanged);
    super.dispose();
  }

  void _onPageChanged() {
    final page = widget.controller.page;
    if (page != null) {
      setState(() => _currentPage = page.round());
    }
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(widget.count, (index) {
        final isActive = index == _currentPage;
        return GestureDetector(
          onTap: () => widget.controller.animateToPage(index,
              duration: const Duration(milliseconds: 300),
              curve: Curves.ease),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            margin: EdgeInsets.only(right: index < widget.count - 1 ? 10 : 0),
            width: isActive ? 20 : 10,
            height: 10,
            decoration: BoxDecoration(
              color: isActive
                  ? Theme.of(context).colorScheme.primary
                  : Theme.of(context)
                      .colorScheme
                      .onSurface
                      .withValues(alpha: 0.4),
              borderRadius: BorderRadius.circular(5),
            ),
          ),
        );
      }),
    );
  }
}
