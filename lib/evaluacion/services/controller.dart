import 'package:flutter/widgets.dart';

class TableScrollControllers {
  final ScrollController verticalController;
  final ScrollController horizontalController;

  TableScrollControllers()
      : verticalController = ScrollController(),
        horizontalController = ScrollController();

  void dispose() {
    verticalController.dispose();
    horizontalController.dispose();
  }
}