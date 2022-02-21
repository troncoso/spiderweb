import 'package:flutter/material.dart';

const DEFAULT_MARGIN_SIZE = 16;

class Margin extends StatelessWidget {
  const Margin({Key? key, this.horizontalSize = DEFAULT_MARGIN_SIZE, this.verticalSize = DEFAULT_MARGIN_SIZE}) : super(key: key);

  final int horizontalSize;
  final int verticalSize;

  @override
  Widget build(BuildContext context) =>
      Container(margin: EdgeInsets.symmetric(horizontal: horizontalSize / 2, vertical: verticalSize / 2));
}

class HorizontalMargin extends Margin {
  const HorizontalMargin({Key? key, size = DEFAULT_MARGIN_SIZE}) : super(key: key, horizontalSize: size, verticalSize: 0);
}

class VerticalMargin extends Margin {
  const VerticalMargin({Key? key, int size = DEFAULT_MARGIN_SIZE}) : super(key: key, horizontalSize: 0, verticalSize: size);
}