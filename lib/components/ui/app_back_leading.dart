import 'package:flutter/material.dart';
import 'package:vector_academy/utils/navigation_utils.dart';

class AppBackLeading extends StatelessWidget {
  final Color? color;

  const AppBackLeading({super.key, this.color});

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: Icon(Icons.arrow_back, color: color),
      onPressed: () => safePop(context: context),
    );
  }
}
