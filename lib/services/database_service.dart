import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/foundation.dart';

class DocumentModel {
  final String id;
  final String title;
  final String? folderId;
  final String uploadedBy;
  final DateTime uploadDate;
  final String fileUrl;

  DocumentModel({
    required this.id,
    required this.title,
    this.folderId,
    required this.uploadedBy,
    required this.uploadDate,
    required this.fileUrl,
  });

  factory DocumentModel.fromMap(Map<String, dynamic> data) {
    return DocumentModel(
      id: data['id']?.toString() ?? '',
      title: data['title'] ?? '',
      folderId: data['folder_id']?.toString(),
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
      'folder_id': folderId,
      'uploaded_by': uploadedBy,
      'file_url': fileUrl,
    };
  }
}

class FolderModel {
  final String id;
  final String name;
  final String? parentId;

  FolderModel({required this.id, required this.name, this.parentId});

  factory FolderModel.fromMap(Map<String, dynamic> data) {
    return FolderModel(
      id: data['id']?.toString() ?? '',
      name: data['name'] ?? '',
      parentId: data['parent_id']?.toString(),
    );
  }
}

class DatabaseService {
  final SupabaseClient _supabase = Supabase.instance.client;

  /// Fetch all documents ordered by newest first (returns a Future).
  Future<List<DocumentModel>> getDocuments() async {
    final response = await _supabase
        .from('documents')
        .select('*')
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

  /// Stream of documents filtered by folder.
  Stream<List<DocumentModel>> getDocumentsByFolder(String? folderId) {
    if (folderId == null) {
      return _supabase.from('documents').stream(primaryKey: ['id']).order('created_at')
          .map((data) => data
          .where((map) => map['folder_id'] == null)
          .map((map) => DocumentModel.fromMap(map))
          .toList());
    } else {
      return _supabase.from('documents').stream(primaryKey: ['id']).eq('folder_id', folderId).order('created_at')
          .map((data) => data.map((map) => DocumentModel.fromMap(map)).toList());
    }
  }

  /// Fetch folders based on parentId
  Future<List<FolderModel>> getFolders(String? parentId) async {
    try {
      var query = _supabase.from('folders').select('*');
      if (parentId == null) {
        query = query.isFilter('parent_id', null);
      } else {
        query = query.eq('parent_id', parentId);
      }
      final response = await query.order('name');
      return (response as List).map((row) => FolderModel.fromMap(row)).toList();
    } catch (e) {
      debugPrint('Fetch Error: $e');
      return [];
    }
  }

  /// Fetch all folders for dropdowns
  Future<List<FolderModel>> getAllFolders() async {
    try {
      final response = await _supabase.from('folders').select('*').order('name');
      return (response as List).map((row) => FolderModel.fromMap(row)).toList();
    } catch (e) {
      debugPrint('Fetch Error: $e');
      return [];
    }
  }

  /// Stream of folders filtered by parentId
  Stream<List<FolderModel>> streamFolders(String? parentId) {
    if (parentId == null) {
      return _supabase.from('folders').stream(primaryKey: ['id']).order('name')
          .map((data) => data
          .where((map) => map['parent_id'] == null)
          .map((map) => FolderModel.fromMap(map))
          .toList());
    } else {
      return _supabase.from('folders').stream(primaryKey: ['id']).eq('parent_id', parentId).order('name')
          .map((data) => data.map((map) => FolderModel.fromMap(map)).toList());
    }
  }

  /// Create a new folder
  Future<void> createFolder(String name, String? parentId) async {
    await _supabase.from('folders').insert({
      'name': name,
      'parent_id': parentId,
    });
  }

  /// Save a new document record.
  Future<void> saveDocumentMetadata(DocumentModel doc) async {
    final data = doc.toMap();
    data.remove('id'); // Ensure the database auto-generates the UUID
    await _supabase.from('documents').insert(data);
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

  /// Search documents by title (case-insensitive).
  Future<List<DocumentModel>> searchDocuments(String query) async {
    if (query.isEmpty) return [];
    
    final response = await _supabase
        .from('documents')
        .select('*')
        .ilike('title', '%$query%')
        .order('created_at', ascending: false);

    return (response as List).map((row) => DocumentModel.fromMap(row)).toList();
  }

  /// Delete a folder record.
  Future<void> deleteFolder(String folderId) async {
    await _supabase.from('folders').delete().eq('id', folderId);
  }
}
