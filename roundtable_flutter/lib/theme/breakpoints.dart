import 'package:flutter/widgets.dart';

/// The panel's layout classes (`docs/UI-DESIGN.md` §4). Decided from a
/// width: the window's for the app shell, the space a screen actually gets
/// (`LayoutBuilder`) for the layout inside it.
enum LayoutSize {
  /// Phones: one column, bottom navigation.
  compact,

  /// Tablets and narrow windows: icon-only navigation, stacked panels.
  medium,

  /// Laptops and up: the full layout.
  expanded;

  static const compactMax = 600.0;
  static const mediumMax = 1024.0;

  static LayoutSize forWidth(double width) => width < compactMax
      ? compact
      : width < mediumMax
      ? medium
      : expanded;

  /// The class of the window [context] is in.
  static LayoutSize of(BuildContext context) =>
      forWidth(MediaQuery.sizeOf(context).width);

  bool get isCompact => this == compact;
  bool get isExpanded => this == expanded;
}
