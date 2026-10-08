import 'package:flutter_test/flutter_test.dart';
import 'package:roundtable_flutter/theme/breakpoints.dart';

void main() {
  test('widths map to phone, tablet and desktop layouts', () {
    expect(LayoutSize.forWidth(390), LayoutSize.compact);
    expect(LayoutSize.forWidth(599), LayoutSize.compact);
    expect(LayoutSize.forWidth(600), LayoutSize.medium);
    expect(LayoutSize.forWidth(768), LayoutSize.medium);
    expect(LayoutSize.forWidth(1024), LayoutSize.expanded);
    expect(LayoutSize.forWidth(1600), LayoutSize.expanded);
  });
}
