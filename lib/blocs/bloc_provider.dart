import 'package:flutter/material.dart';

abstract class BlocBase {
  void dispose();
}

/// Owns a bloc for the lifetime of its subtree and disposes it afterwards.
class BlocProvider<T extends BlocBase> extends StatefulWidget {
  const BlocProvider({super.key, required this.child, required this.bloc});

  final T bloc;
  final Widget child;

  @override
  State<BlocProvider<T>> createState() => _BlocProviderState<T>();

  static T of<T extends BlocBase>(BuildContext context) {
    final provider = context.findAncestorWidgetOfExactType<BlocProvider<T>>();
    assert(provider != null, 'No BlocProvider<$T> found in context');
    return provider!.bloc;
  }
}

class _BlocProviderState<T extends BlocBase> extends State<BlocProvider<T>> {
  @override
  void dispose() {
    widget.bloc.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
