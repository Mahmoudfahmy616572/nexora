import 'dart:io';

import 'package:path_provider/path_provider.dart';

/// Write bytes to a file at [path].
Future<void> writeBytesToFile(String path, List<int> bytes) async {
  final file = File(path);
  await file.writeAsBytes(bytes);
}

/// Get the application documents directory path.
Future<String> getDocumentsPath() async {
  final dir = await getApplicationDocumentsDirectory();
  return dir.path;
}
