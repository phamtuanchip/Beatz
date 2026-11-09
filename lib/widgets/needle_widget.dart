import 'package:flutter/material.dart';

class NeedleWidget extends StatelessWidget {
  final double size;

  const NeedleWidget({super.key, required this.size});

  @override
  Widget build(BuildContext context) {
    return Image(
      image: const AssetImage('assets/needle.png'),
      width: size,
      height: size,
    );
  }
}
