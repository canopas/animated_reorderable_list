import 'package:flutter/cupertino.dart';

extension StringExtension on String {
  String capitalize() {
    return "${this[0].toUpperCase()}${substring(1)}";
  }
}

extension BuildContextExtensions on BuildContext {

  EdgeInsets get mediaQueryPadding => MediaQuery.paddingOf(this);
}
