import 'package:aufwachen_soundboard/file_handler.dart';
import 'package:aufwachen_soundboard/preferences.dart';
import 'package:aufwachen_soundboard/sound.dart';
import 'package:http/http.dart';
import 'dart:convert' as JSON;

const GITHUB_URL_PREFIX =
    'https://raw.githubusercontent.com/jonasholtkamp/aufwachen-soundboard/master/assets/audio/';

Future initSounds() async {
  Preferences _preferences = Preferences();
  List<Sound> sounds = await retrieveSounds();

  sounds.forEach((sound) async {
    final file = await getLocalFile(sound);
    sound.cached = await file.exists();
    sound.starred = await _preferences.get(sound.filename) == "starred";
  });

  return sounds;
}

Future<List<Sound>> retrieveSounds() async {
  final String songListString = await read('${GITHUB_URL_PREFIX}sounds.json');
  final List<dynamic> json = JSON.jsonDecode(songListString);

  List<Sound> sounds = [];

  json.forEach((item) => sounds.add(Sound(item['title'], item['filename'])));

  return sounds;
}
