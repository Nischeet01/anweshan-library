import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/foundation.dart';
import 'package:url_launcher/url_launcher.dart';

class StorageService {
  final SupabaseClient _supabase = Supabase.instance.client;

  /// Uploads a file as bytes (web-compatible) and returns the public URL.
  Future<String?> uploadDocument(Uint8List fileBytes, String fileName) async {
    try {
      // Generate a unique path at the root of the bucket
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final String path = '${timestamp}_$fileName';

      await _supabase.storage.from('documents').uploadBinary(
            path,
            fileBytes,
            fileOptions: const FileOptions(
              cacheControl: '3600',
              upsert: false,
              contentType: 'application/octet-stream', // Required for Web
            ),
          );

      // Get public URL
      final String publicUrl =
          _supabase.storage.from('documents').getPublicUrl(path);
      return publicUrl;
    } catch (e) {
      debugPrint('Upload error: $e');
      rethrow;
    }
  }

  /// Trigger a download of the document.
  Future<void> downloadDocument(String url) async {
    try {
      final Uri uri = Uri.parse(url);
      if (await canLaunchUrl(uri)) {
        await launchUrl(
          uri,
          mode: LaunchMode.externalApplication,
        );
      } else {
        throw 'Could not launch $url';
      }
    } catch (e) {
      debugPrint('Download error: $e');
      rethrow;
    }
  }

  Future<void> deleteDocument(String path) async {
    try {
      await _supabase.storage.from('documents').remove([path]);
    } catch (e) {
      debugPrint('Delete error: $e');
      rethrow;
    }
  }
}
