import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:roundtable_flutter/widgets/diff_view.dart';

void main() {
  group('mergeFullFileDiff', () {
    test('reconciles a changed line into context before and after it', () {
      const patch = '''
@@ -1,4 +1,4 @@
 line1
-line2
+line2 changed
 line3
 line4''';
      const fileContent = 'line1\nline2 changed\nline3\nline4';

      final merged = mergeFullFileDiff(patch: patch, fileContent: fileContent);

      expect(merged, [
        const MergedDiffLine(DiffLineKind.context, 'line1'),
        const MergedDiffLine(DiffLineKind.removed, 'line2'),
        const MergedDiffLine(DiffLineKind.added, 'line2 changed'),
        const MergedDiffLine(DiffLineKind.context, 'line3'),
        const MergedDiffLine(DiffLineKind.context, 'line4'),
      ]);
    });

    test('throws when the fetched file content no longer matches the patch', () {
      const patch = '''
@@ -1,2 +1,2 @@
 line1
-line2
+line2 changed''';
      // Context line "line1" doesn't match what the patch expects.
      const staleFileContent = 'line1 edited\nline2 changed';

      expect(
        () => mergeFullFileDiff(patch: patch, fileContent: staleFileContent),
        throwsA(isA<DiffReconciliationException>()),
      );
    });

    test('throws when the fetched file content has fewer lines than expected', () {
      const patch = '''
@@ -4,1 +4,1 @@
-d
+d2''';
      const shortFileContent = 'a\nb';

      expect(
        () => mergeFullFileDiff(patch: patch, fileContent: shortFileContent),
        throwsA(isA<DiffReconciliationException>()),
      );
    });

    test('keeps lines before and after the hunk as unmodified context', () {
      const patch = '''
@@ -4,1 +4,1 @@
-d
+d2''';
      const fileContent = 'a\nb\nc\nd2\ne\nf';

      final merged = mergeFullFileDiff(patch: patch, fileContent: fileContent);

      expect(merged, [
        const MergedDiffLine(DiffLineKind.context, 'a'),
        const MergedDiffLine(DiffLineKind.context, 'b'),
        const MergedDiffLine(DiffLineKind.context, 'c'),
        const MergedDiffLine(DiffLineKind.removed, 'd'),
        const MergedDiffLine(DiffLineKind.added, 'd2'),
        const MergedDiffLine(DiffLineKind.context, 'e'),
        const MergedDiffLine(DiffLineKind.context, 'f'),
      ]);
    });

    test('reconciles multiple hunks in one file', () {
      const patch = '''
@@ -1,2 +1,2 @@
-first
+first changed
 second
@@ -5,2 +5,2 @@
 fifth
-sixth
+sixth changed''';
      const fileContent =
          'first changed\nsecond\nthird\nfourth\nfifth\nsixth changed';

      final merged = mergeFullFileDiff(patch: patch, fileContent: fileContent);

      expect(merged, [
        const MergedDiffLine(DiffLineKind.removed, 'first'),
        const MergedDiffLine(DiffLineKind.added, 'first changed'),
        const MergedDiffLine(DiffLineKind.context, 'second'),
        const MergedDiffLine(DiffLineKind.context, 'third'),
        const MergedDiffLine(DiffLineKind.context, 'fourth'),
        const MergedDiffLine(DiffLineKind.context, 'fifth'),
        const MergedDiffLine(DiffLineKind.removed, 'sixth'),
        const MergedDiffLine(DiffLineKind.added, 'sixth changed'),
      ]);
    });
  });

  group('FullFileDiffView', () {
    testWidgets('renders removed and added lines from the reconciled diff', (
      tester,
    ) async {
      const patch = '''
@@ -4,1 +4,1 @@
-d
+d2''';
      const fileContent = 'a\nb\nc\nd2\ne\nf';

      await tester.pumpWidget(
        const MaterialApp(
          home: FullFileDiffView(patch: patch, fileContent: fileContent),
        ),
      );

      expect(find.text('a'), findsOneWidget);
      expect(find.text('d'), findsOneWidget);
      expect(find.text('d2'), findsOneWidget);
      expect(find.text('f'), findsOneWidget);
    });

    testWidgets(
      'falls back to the plain file content when the patch no longer matches',
      (tester) async {
        const patch = '''
@@ -1,1 +1,1 @@
-d
+d2''';
        // Doesn't start with "d" like the patch expects.
        const staleFileContent = 'not d2 at all';

        await tester.pumpWidget(
          const MaterialApp(
            home: FullFileDiffView(
              patch: patch,
              fileContent: staleFileContent,
            ),
          ),
        );

        expect(find.textContaining('without highlighting'), findsOneWidget);
        expect(find.text(staleFileContent), findsOneWidget);
      },
    );
  });
}
