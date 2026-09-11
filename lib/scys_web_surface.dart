import 'package:flutter/widgets.dart';

Widget buildScysWebSurface({required Widget child, required bool edgeToEdge}) =>
    SafeArea(top: true, bottom: !edgeToEdge, child: child);
