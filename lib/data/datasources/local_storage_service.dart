import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

/// Local storage service using SharedPreferences
class LocalStorageService {
  final SharedPreferences _prefs;

  LocalStorageService(this._prefs);

  /// Save JSON data
  Future<bool> saveJson(String key, Map<String, dynamic> data) async {
    final jsonString = jsonEncode(data);
    return await _prefs.setString(key, jsonString);
  }

  /// Save JSON list
  Future<bool> saveJsonList(String key, List<Map<String, dynamic>> dataList) async {
    final jsonString = jsonEncode(dataList);
    return await _prefs.setString(key, jsonString);
  }

  /// Get JSON data
  Map<String, dynamic>? getJson(String key) {
    final jsonString = _prefs.getString(key);
    if (jsonString == null) return null;
    return jsonDecode(jsonString) as Map<String, dynamic>;
  }

  /// Get JSON list
  List<Map<String, dynamic>>? getJsonList(String key) {
    final jsonString = _prefs.getString(key);
    if (jsonString == null) return null;
    final List<dynamic> decoded = jsonDecode(jsonString);
    return decoded.map((item) => item as Map<String, dynamic>).toList();
  }

  /// Save string
  Future<bool> saveString(String key, String value) async {
    return await _prefs.setString(key, value);
  }

  /// Get string
  String? getString(String key) {
    return _prefs.getString(key);
  }

  /// Save boolean
  Future<bool> saveBool(String key, bool value) async {
    return await _prefs.setBool(key, value);
  }

  /// Get boolean
  bool? getBool(String key) {
    return _prefs.getBool(key);
  }

  /// Save integer
  Future<bool> saveInt(String key, int value) async {
    return await _prefs.setInt(key, value);
  }

  /// Get integer
  int? getInt(String key) {
    return _prefs.getInt(key);
  }

  /// Remove key
  Future<bool> remove(String key) async {
    return await _prefs.remove(key);
  }

  /// Clear all data
  Future<bool> clear() async {
    return await _prefs.clear();
  }

  /// Check if key exists
  bool containsKey(String key) {
    return _prefs.containsKey(key);
  }
}
