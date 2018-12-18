import 'dart:io';

import 'package:aufwachen_soundboard/sound.dart';
import 'package:http/http.dart';
import 'package:path_provider/path_provider.dart';

const GITHUB_URL_PREFIX =
    'https://raw.githubusercontent.com/jonasholtkamp/aufwachen-soundboard/master/assets/audio/';

Future<File> getLocalFile(Sound sound) async {
  final dir = await getApplicationDocumentsDirectory();
  return File('${dir.path}/${sound.filename}');
}

downloadFile(Sound sound, Function callback) async {
  final file = await getLocalFile(sound);
  final bytes = await readBytes('$GITHUB_URL_PREFIX${sound.filename}');

  await file.writeAsBytes(bytes);
  if (await file.exists()) {
    callback(sound);
  }
}

delete(Sound sound, Function callback) async {
  final file = await getLocalFile(sound);
  await file.delete();

  if (!await file.exists()) {
    callback(sound);
  }
}
