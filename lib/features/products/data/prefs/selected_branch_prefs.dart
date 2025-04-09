import 'package:shared_preferences/shared_preferences.dart';

class SelectedBranchPrefs {
  static const _key = 'selected_branch_id';

  static Future<String?> load() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_key);
  }

  static Future<void> save(String branchId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, branchId);
  }

  static Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_key);
  }
}