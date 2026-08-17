import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../main.dart';
import '../../presentation/screens/thoughts_screen.dart';

final bucketListProvider = StateNotifierProvider<BucketListNotifier, List<BucketItem>>((ref) {
  final prefs = ref.watch(sharedPreferencesProvider);
  return BucketListNotifier(prefs);
});

class BucketListNotifier extends StateNotifier<List<BucketItem>> {
  final SharedPreferences _prefs;
  static const _key = 'bucket_list_data';

  BucketListNotifier(this._prefs) : super([]) {
    _load();
  }

  void _load() {
    final data = _prefs.getString(_key);
    if (data != null) {
      final List<dynamic> decoded = jsonDecode(data);
      state = decoded.map((item) => BucketItem(
        id: item['id'],
        title: item['title'],
        isCompleted: item['isCompleted'] ?? false,
      )).toList();
    }
  }

  void _save(List<BucketItem> items) {
    state = items;
    final encoded = jsonEncode(items.map((i) => {
      'id': i.id,
      'title': i.title,
      'isCompleted': i.isCompleted,
    }).toList());
    _prefs.setString(_key, encoded);
  }

  void addItem(String title) {
    final newItem = BucketItem(id: DateTime.now().toString(), title: title);
    _save([...state, newItem]);
  }

  void toggleItem(String id) {
    final items = state.map((item) {
      if (item.id == id) {
        return BucketItem(id: item.id, title: item.title, isCompleted: !item.isCompleted);
      }
      return item;
    }).toList();
    _save(items);
  }
}
