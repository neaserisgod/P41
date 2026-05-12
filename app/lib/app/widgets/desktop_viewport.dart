import 'package:flutter/widgets.dart';

class DesktopViewport {
  const DesktopViewport({
    required this.width,
    required this.height,
  });

  final double width;
  final double height;

  bool get compactWidth => width < 1280;
  bool get tightWidth => width < 1180;
  bool get narrowWidth => width < 1040;
  bool get compactHeight => height < 820;
  bool get tightHeight => height < 760;
  bool get shortHeight => height < 700;
  bool get stackedPanels => tightWidth || tightHeight;
  bool get ultraCompact => narrowWidth || shortHeight;

  double get pagePadding {
    if (ultraCompact) {
      return 14;
    }
    if (stackedPanels) {
      return 16;
    }
    if (compactWidth || compactHeight) {
      return 18;
    }
    return 22;
  }

  double get sectionGap => ultraCompact ? 10 : 14;
}

extension DesktopViewportX on BoxConstraints {
  DesktopViewport get viewport => DesktopViewport(
    width: maxWidth,
    height: maxHeight,
  );
}
