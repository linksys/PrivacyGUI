import 'package:flutter/material.dart';

class BasePageView extends StatelessWidget {
  static const _containerPadding = EdgeInsets.fromLTRB(24, 0, 24, 30);

  final AppBar? appBar;
  final Widget? child;
  final EdgeInsets? padding;
  final bool? scrollable;

  BasePageView.noNavigationBar(
      {Key? key, this.child, this.padding = _containerPadding, this.scrollable = false})
      : appBar = AppBar(
          automaticallyImplyLeading: false,
          backgroundColor: Colors.transparent,
          elevation: 0,
        ), super(key: key);

  BasePageView.withCloseButton(BuildContext context,
      {Key? key, this.child, this.padding = _containerPadding, this.scrollable = false})
      : appBar = AppBar(
          backgroundColor: Colors.transparent,
          iconTheme:
              IconThemeData(color: Theme.of(context).colorScheme.primary),
          elevation: 0,
          automaticallyImplyLeading: false,
          actions: [
            IconButton(
              icon: const Icon(Icons.close),
              onPressed: () => Navigator.pop(context),
            )
          ],
        ),
        super(key: key);

  const BasePageView({
    Key? key,
    this.appBar,
    this.child,
    this.padding = _containerPadding,
    this.scrollable = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: appBar ??
          AppBar(
            backgroundColor: Colors.transparent,
            iconTheme:
                IconThemeData(color: Theme.of(context).colorScheme.primary),
            elevation: 0,
          ),
      body: SafeArea(
        child: scrollable! ? _scrollableView() : _view(),
      ),
    );
  }

  Widget _view() {
    return Container(
      padding: padding,
      child: child,
    );
  }

  Widget _scrollableView() {
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints viewportConstraints) {
        return SingleChildScrollView(
          child: ConstrainedBox(
            constraints: BoxConstraints(
              minHeight: viewportConstraints.maxHeight,
            ),
            child: IntrinsicHeight(
              child: Container(padding: padding, child: child),
            ),
          ),
        );
      },
    );
  }
}
