import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import 'logger_service.dart';

/// A service for managing local storage using SharedPreferences
class StorageService {
  /// SharedPreferences instance
  late final SharedPreferences _prefs;
  
  /// Initialize the storage service
  Future<void> initialize() async {
    try {
      _prefs = await SharedPreferences.getInstance();
      logger.i('StorageService initialized');
    } catch (e) {
      logger.e('Error initializing StorageService', e);
      rethrow;
    }
  }
  
  /// Save a string value
  Future<bool> setString(String key, String value) async {
    try {
      final result = await _prefs.setString(key, value);
      logger.d('Stored string value for key: $key');
      return result;
    } catch (e) {
      logger.e('Error storing string value for key: $key', e);
      return false;
    }
  }
  
  /// Get a string value
  String? getString(String key) {
    try {
      return _prefs.getString(key);
    } catch (e) {
      logger.e('Error getting string value for key: $key', e);
      return null;
    }
  }
  
  /// Save a boolean value
  Future<bool> setBool(String key, bool value) async {
    try {
      final result = await _prefs.setBool(key, value);
      logger.d('Stored bool value for key: $key');
      return result;
    } catch (e) {
      logger.e('Error storing bool value for key: $key', e);
      return false;
    }
  }
  
  /// Get a boolean value
  bool? getBool(String key) {
    try {
      return _prefs.getBool(key);
    } catch (e) {
      logger.e('Error getting bool value for key: $key', e);
      return null;
    }
  }
  
  /// Save an integer value
  Future<bool> setInt(String key, int value) async {
    try {
      final result = await _prefs.setInt(key, value);
      logger.d('Stored int value for key: $key');
      return result;
    } catch (e) {
      logger.e('Error storing int value for key: $key', e);
      return false;
    }
  }
  
  /// Get an integer value
  int? getInt(String key) {
    try {
      return _prefs.getInt(key);
    } catch (e) {
      logger.e('Error getting int value for key: $key', e);
      return null;
    }
  }
  
  /// Save a double value
  Future<bool> setDouble(String key, double value) async {
    try {
      final result = await _prefs.setDouble(key, value);
      logger.d('Stored double value for key: $key');
      return result;
    } catch (e) {
      logger.e('Error storing double value for key: $key', e);
      return false;
    }
  }
  
  /// Get a double value
  double? getDouble(String key) {
    try {
      return _prefs.getDouble(key);
    } catch (e) {
      logger.e('Error getting double value for key: $key', e);
      return null;
    }
  }
  
  /// Save a list of strings
  Future<bool> setStringList(String key, List<String> value) async {
    try {
      final result = await _prefs.setStringList(key, value);
      logger.d('Stored string list for key: $key');
      return result;
    } catch (e) {
      logger.e('Error storing string list for key: $key', e);
      return false;
    }
  }
  
  /// Get a list of strings
  List<String>? getStringList(String key) {
    try {
      return _prefs.getStringList(key);
    } catch (e) {
      logger.e('Error getting string list for key: $key', e);
      return null;
    }
  }
  
  /// Save an object value (encoded as JSON)
  Future<bool> setObject(String key, dynamic value) async {
    try {
      final jsonString = json.encode(value);
      final result = await _prefs.setString(key, jsonString);
      logger.d('Stored object for key: $key');
      return result;
    } catch (e) {
      logger.e('Error storing object for key: $key', e);
      return false;
    }
  }
  
  /// Get an object value (decoded from JSON)
  dynamic getObject(String key) {
    try {
      final jsonString = _prefs.getString(key);
      if (jsonString == null) return null;
      return json.decode(jsonString);
    } catch (e) {
      logger.e('Error getting object for key: $key', e);
      return null;
    }
  }
  
  /// Check if a key exists
  bool containsKey(String key) {
    return _prefs.containsKey(key);
  }
  
  /// Remove a value
  Future<bool> remove(String key) async {
    try {
      final result = await _prefs.remove(key);
      logger.d('Removed value for key: $key');
      return result;
    } catch (e) {
      logger.e('Error removing value for key: $key', e);
      return false;
    }
  }
  
  /// Clear all values
  Future<bool> clear() async {
    try {
      final result = await _prefs.clear();
      logger.i('Cleared all stored values');
      return result;
    } catch (e) {
      logger.e('Error clearing stored values', e);
      return false;
    }
  }
}