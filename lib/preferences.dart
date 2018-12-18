import 'package:shared_preferences/shared_preferences.dart';

class Preferences {
  Future<String> get(String key) async => (await SharedPreferences.getInstance()).getString(key);

  void save(String key, String value) async =>
      (await SharedPreferences.getInstance()).setString(key, value);

  void remove(String key) async => (await SharedPreferences.getInstance()).remove(key);
}
