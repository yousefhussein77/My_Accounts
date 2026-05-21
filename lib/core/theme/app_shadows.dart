import 'package:flutter/material.dart';

class AppShadows {
  const AppShadows._();

  static const light = [
    BoxShadow(
      color: Color.fromRGBO(0, 0, 0, 0.06),
      blurRadius: 8,
      offset: Offset(0, 2),
    ),
  ];

  static const medium = [
    BoxShadow(
      color: Color.fromRGBO(0, 0, 0, 0.08),
      blurRadius: 20,
      offset: Offset(0, 6),
    ),
  ];

  static const deep = [
    BoxShadow(
      color: Color.fromRGBO(0, 0, 0, 0.10),
      blurRadius: 40,
      offset: Offset(0, 12),
    ),
  ];
}
