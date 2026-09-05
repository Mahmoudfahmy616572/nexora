/// Write bytes to a file at [path] on web (not supported).
Future<void> writeBytesToFile(String path, List<int> bytes) async {
  throw UnsupportedError(
    'File system write is not available on web. '
    'Use browser download instead.',
  );
}

/// Get the application documents directory path on web (not supported).
Future<String> getDocumentsPath() async {
  throw UnsupportedError(
    'File system access is not available on web.',
  );
}
