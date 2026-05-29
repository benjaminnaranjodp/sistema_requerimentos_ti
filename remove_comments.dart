import 'dart:io';

void main() {
  final dir = Directory('lib');
  if (!dir.existsSync()) {
    print('lib directory not found');
    return;
  }

  final files = dir.listSync(recursive: true).whereType<File>().where((f) => f.path.endsWith('.dart'));
  
  // RegExp to match strings (group 1) OR comments (no group)
  // Handles:
  // - single quote strings '...'
  // - double quote strings "..."
  // - raw single r'...'
  // - raw double r"..."
  // - triple single '''...'''
  // - triple double """..."""
  // - single line comment // ...
  // - multi line comment /* ... */
  final RegExp regex = RegExp(
    r'("""[\s\S]*?"""|' + "r'''[\\s\\S]*?'''" + r'|r?"[^"\\]*(?:\\.[^"\\]*)*"|r?' + "'[^'\\\\]*(?:\\\\.[^'\\\\]*)*')|//.*?\$|/\\*[\\s\\S]*?\\*/",
    multiLine: true,
  );

  int count = 0;
  for (final file in files) {
    final content = file.readAsStringSync();
    final newContent = content.replaceAllMapped(regex, (Match m) {
      if (m.group(1) != null) {
        return m.group(1)!;
      }
      return '';
    });
    
    if (content != newContent) {
      file.writeAsStringSync(newContent);
      count++;
      print('Removed comments from ${file.path}');
    }
  }
  
  print('Done. Modified $count files.');
}
