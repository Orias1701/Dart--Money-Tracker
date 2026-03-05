import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/services/supabase_service.dart';
import '../domain/category.dart';

class CategoryRepository {
  CategoryRepository() : _client = SupabaseService.client;

  final SupabaseClient _client;

  String? get _userId => _client.auth.currentUser?.id;

  /// Lấy danh mục: hệ thống (user_id null) + của user.
  Future<List<Category>> getCategories({String? type}) async {
    final uid = _userId;
    try {
      var query = _client.from('categories').select().eq('is_active', true);
      if (type != null) query = query.eq('type', type);
      final res = uid == null
          ? await query.isFilter('user_id', null).order('order_index')
          : await query.or('user_id.is.null,user_id.eq.$uid').order('order_index');
      return (res as List).map((e) => Category.fromMap(e as Map<String, dynamic>)).toList();
    } catch (_) {
      return [];
    }
  }

  /// Thêm danh mục của user (user_id = current user).
  Future<Category?> addCategory({
    required String name,
    required String type,
    String iconName = 'category',
    String colorHex = '#6B7280',
    int orderIndex = 0,
  }) async {
    final uid = _userId;
    if (uid == null) return null;
    try {
      final res = await _client.from('categories').insert({
        'user_id': uid,
        'name': name,
        'type': type,
        'icon_name': iconName,
        'color_hex': colorHex,
        'order_index': orderIndex,
        'is_active': true,
      }).select().single();
      return Category.fromMap(res);
    } catch (_) {
      return null;
    }
  }
}
