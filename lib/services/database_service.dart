import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/foundation.dart';

class DocumentModel {
  final String id;
  final String title;
  final String category;
  final String? categoryId;
  final String uploadedBy;
  final DateTime uploadDate;
  final String fileUrl;

  DocumentModel({
    required this.id,
    required this.title,
    required this.category,
    this.categoryId,
    required this.uploadedBy,
    required this.uploadDate,
    required this.fileUrl,
  });

  factory DocumentModel.fromMap(Map<String, dynamic> data) {
    // Handle joined category data — may come as nested object or flat string
    String categoryName = '';
    if (data['categories'] != null && data['categories'] is Map) {
      categoryName = data['categories']['name'] ?? '';
    } else {
      categoryName = data['category'] ?? '';
    }

    return DocumentModel(
      id: data['id']?.toString() ?? '',
      title: data['title'] ?? '',
      category: categoryName,
      categoryId: data['category_id']?.toString(),
      uploadedBy: data['uploaded_by']?.toString() ?? '',
      uploadDate: data['created_at'] != null
          ? DateTime.parse(data['created_at'])
          : DateTime.now(),
      fileUrl: data['file_url'] ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'category_id': categoryId,
      'uploaded_by': uploadedBy,
      'file_url': fileUrl,
    };
  }
}

class CategoryModel {
  final String id;
  final String name;

  CategoryModel({required this.id, required this.name});

  factory CategoryModel.fromMap(Map<String, dynamic> data) {
    return CategoryModel(
      id: data['id']?.toString() ?? '',
      name: data['name'] ?? '',
    );
  }
}

class DatabaseService {
  final SupabaseClient _supabase = Supabase.instance.client;

  /// Fetch all documents ordered by newest first (returns a Future).
  Future<List<DocumentModel>> getDocuments() async {
    final response = await _supabase
        .from('documents')
        .select('*, categories(name)')
        .order('created_at', ascending: false);

    return (response as List).map((row) => DocumentModel.fromMap(row)).toList();
  }

  /// Stream of latest documents (real-time updates).
  Stream<List<DocumentModel>> getLatestDocuments() {
    return _supabase
        .from('documents')
        .stream(primaryKey: ['id'])
        .order('created_at')
        .map((data) => data.map((map) => DocumentModel.fromMap(map)).toList());
  }

  /// Stream of documents filtered by category name.
  Stream<List<DocumentModel>> getDocumentsByCategory(String category) {
    return _supabase
        .from('documents')
        .stream(primaryKey: ['id'])
        .eq('category', category)
        .order('created_at')
        .map((data) => data.map((map) => DocumentModel.fromMap(map)).toList());
  }

  /// Save a new document record.
  Future<void> saveDocumentMetadata(DocumentModel doc) async {
    final data = doc.toMap();
    data.remove('id'); // Ensure the database auto-generates the UUID
    await _supabase.from('documents').insert(data);
  }

  /// Fetch category objects (id + name) from the categories table.
  Future<List<CategoryModel>> getCategories() async {
    try {
      final response =
          await _supabase.from('categories').select('id, name').order('name');
      return (response as List)
          .map((row) => CategoryModel.fromMap(row))
          .toList();
    } catch (e) {
      debugPrint('Fetch Error: $e');
      return [];
    }
  }

  /// User profile helper.
  Future<void> updateProfile(String userId, String username) async {
    await _supabase.from('users').upsert({
      'id': userId,
      'username': username,
      'updated_at': DateTime.now().toIso8601String(),
    });
  }

  /// Delete a document record.
  Future<void> deleteDocument(String id) async {
    await _supabase.from('documents').delete().eq('id', id);
  }
}
