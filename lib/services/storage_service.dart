import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/fridge_item.dart';

class StorageService {
  static const String _keyFridgeItems = 'sik_fridge_items';
  static const String _keyInventoryInitialized = 'sik_inventory_initialized';
  static const String _keyRegion = 'sik_user_region';
  static const String _keyCuisines = 'sik_user_cuisines';
  static const String _keyDietary = 'sik_user_dietary';
  static const String _keyAppliances = 'sik_user_appliances';
  static const String _keyWantList = 'sik_want_list';
  static const String _keyAccentColor = 'sik_accent_color';

  static Future<void> saveFridgeItems(List<FridgeItem> items) async {
    final prefs = await SharedPreferences.getInstance();
    final jsonList = items.map((i) => i.toJson()).toList();
    await prefs.setString(_keyFridgeItems, jsonEncode(jsonList));
    await prefs.setBool(_keyInventoryInitialized, true);
  }

  static Future<List<FridgeItem>?> loadFridgeItems() async {
    final prefs = await SharedPreferences.getInstance();
    if (!prefs.containsKey(_keyFridgeItems)) return null;
    final raw = prefs.getString(_keyFridgeItems);
    if (raw == null) return null;
    try {
      final list = jsonDecode(raw) as List<dynamic>;
      return list.map((e) => FridgeItem.fromJson(e as Map<String, dynamic>)).toList();
    } catch (_) {
      return null;
    }
  }

  static Future<bool> hasSavedFridgeItems() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_keyInventoryInitialized) ?? false;
  }

  static Future<void> saveUserRegion(String region) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyRegion, region);
  }

  static Future<String?> loadUserRegion() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyRegion);
  }

  static Future<void> saveUserCuisines(List<String> cuisines) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_keyCuisines, cuisines);
  }

  static Future<List<String>?> loadUserCuisines() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getStringList(_keyCuisines);
  }

  static Future<void> saveDietaryRestrictions(List<String> dietary) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_keyDietary, dietary);
  }

  static Future<List<String>?> loadDietaryRestrictions() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getStringList(_keyDietary);
  }

  static Future<void> saveAppliances(List<String> appliances) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_keyAppliances, appliances);
  }

  static Future<List<String>?> loadAppliances() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getStringList(_keyAppliances);
  }

  static Future<void> saveWantList(List<String> wantList) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_keyWantList, wantList);
  }

  static Future<List<String>?> loadWantList() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getStringList(_keyWantList);
  }

  static const String _keyRecipeViewMode = 'sik_recipe_view_grid';
  static const String _keyTrackQuantities = 'sik_track_quantities';

  static Future<void> saveTrackQuantities(bool track) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyTrackQuantities, track);
  }

  static Future<bool?> loadTrackQuantities() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_keyTrackQuantities);
  }

  static Future<void> saveRecipeViewMode(bool isGrid) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyRecipeViewMode, isGrid);
  }

  static Future<bool?> loadRecipeViewMode() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_keyRecipeViewMode);
  }

  static Future<void> saveAccentColor(int colorValue) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_keyAccentColor, colorValue);
  }

  static Future<int?> loadAccentColor() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_keyAccentColor);
  }

  static const String _keyApiKey = 'sik_ai_api_key';

  static Future<void> saveApiKey(String apiKey) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyApiKey, apiKey);
  }

  static Future<String?> loadApiKey() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyApiKey);
  }

  static const String _keyCookingRecords = 'sik_cooking_records';
  static const String _keyCookingReminders = 'sik_cooking_reminders';

  static Future<void> saveCookingRecords(String recordsJson) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyCookingRecords, recordsJson);
  }

  static Future<String?> loadCookingRecords() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyCookingRecords);
  }

  static Future<void> saveCookingReminders(String remindersJson) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyCookingReminders, remindersJson);
  }

  static Future<String?> loadCookingReminders() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyCookingReminders);
  }

  static Future<void> clearAll() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
  }
}
