import 'dart:io';

class SessionFileStorage {
  File? _file;

  File _getFile() {
    if (_file case final file?) return file;
    final directory = Directory.systemTemp.createTempSync('caren_sessions_');
    return _file = File('${directory.path}/measurement_sessions.json');
  }

  Future<String?> read() async {
    final file = _getFile();
    return await file.exists() ? await file.readAsString() : null;
  }

  Future<void> write(String content) async {
    await _getFile().writeAsString(content, flush: true);
  }
}
