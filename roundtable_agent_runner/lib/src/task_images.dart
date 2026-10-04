import 'dart:io';

/// An image attached to a task's prompt, as downloaded by the runner.
typedef TaskImage = ({String fileName, List<int> bytes});

/// Writes [images] into [dir] as `<n>-<fileName>` and returns their paths,
/// in order.
Future<List<String>> writeTaskImages(
  Directory dir,
  List<TaskImage> images,
) async {
  final paths = <String>[];
  for (final (i, image) in images.indexed) {
    final file = File('${dir.path}/${i + 1}-${image.fileName}');
    await file.writeAsBytes(image.bytes);
    paths.add(file.path);
  }
  return paths;
}

/// [prompt] followed by the paths of the task's attached images and an
/// instruction to look at them before starting.
String attachedImagesPrompt(String prompt, List<String> paths) {
  final list = paths.map((p) => '- $p').join('\n');
  return '$prompt\n\n'
      'The developer attached ${paths.length} image(s) to this task '
      '(screenshots or mockups). Open each one with the Read tool before '
      'you start, and use them to understand the request:\n$list';
}
