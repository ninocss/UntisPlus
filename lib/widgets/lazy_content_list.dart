import 'package:flutter/material.dart';

/// Builders are cheap descriptors; heavy cards are created only in the viewport.
class LazyContentList extends StatelessWidget {
  const LazyContentList({
    super.key,
    required this.entries,
    this.padding,
    this.physics,
  });
  final List<WidgetBuilder> entries;
  final EdgeInsetsGeometry? padding;
  final ScrollPhysics? physics;

  @override
  Widget build(BuildContext context) => ListView.builder(
    padding: padding,
    physics: physics,
    itemCount: entries.length,
    itemBuilder: (context, index) => entries[index](context),
  );
}
