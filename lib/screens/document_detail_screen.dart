import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:provider/provider.dart';
import '../theme.dart';
import '../services/database_service.dart';
import '../services/storage_service.dart';
import '../services/auth_service.dart';
import 'full_screen_image_viewer.dart';

class DocumentDetailScreen extends StatelessWidget {
  final DocumentModel document;
  const DocumentDetailScreen({super.key, required this.document});

  /// Returns a file-type category for icon/color selection.
  static const _imageExtensions = {'jpg', 'jpeg', 'png', 'gif', 'webp', 'bmp'};
  static const _pdfExtensions = {'pdf'};
  static const _docExtensions = {'doc', 'docx', 'odt', 'rtf', 'txt'};
  static const _slideExtensions = {'ppt', 'pptx', 'odp'};
  static const _sheetExtensions = {'xls', 'xlsx', 'csv', 'ods'};

  String _getExtension(String url) {
    return url.split('?').first.split('.').last.toLowerCase();
  }

  bool _isImage(String ext) => _imageExtensions.contains(ext);

  _FileTypeInfo _getFileTypeInfo(String ext) {
    if (_pdfExtensions.contains(ext)) {
      return _FileTypeInfo(Icons.picture_as_pdf_rounded, const Color(0xFFE53935), 'PDF Document');
    } else if (_docExtensions.contains(ext)) {
      return _FileTypeInfo(Icons.article_rounded, const Color(0xFF1E88E5), 'Word Document');
    } else if (_slideExtensions.contains(ext)) {
      return _FileTypeInfo(Icons.slideshow_rounded, const Color(0xFFF4511E), 'Presentation');
    } else if (_sheetExtensions.contains(ext)) {
      return _FileTypeInfo(Icons.table_chart_rounded, const Color(0xFF43A047), 'Spreadsheet');
    }
    return _FileTypeInfo(Icons.insert_drive_file_rounded, AnweshanTheme.outline, 'File');
  }

  @override
  Widget build(BuildContext context) {
    final doc = document;
    final StorageService storageService = StorageService();
    final DatabaseService databaseService = DatabaseService();
    final String formattedDate =
        DateFormat('MMM dd, yyyy').format(doc.uploadDate);
    final String ext = _getExtension(doc.fileUrl);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Document Details'),
        actions: [
          IconButton(icon: const Icon(Icons.share_outlined), onPressed: () {}),
          IconButton(icon: const Icon(Icons.more_vert), onPressed: () {}),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildFilePreview(context, doc, ext),
            const SizedBox(height: 32),
            Text(
              doc.title,
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(height: 16),
            _buildMetadataTable(context, doc, formattedDate),
            const SizedBox(height: 32),
            // "Open File" button for non-image types
            if (!_isImage(ext)) ...[
              _buildOpenFileButton(context, doc),
              const SizedBox(height: 16),
            ],
            _buildActionButtons(context, doc, storageService, databaseService),
          ],
        ),
      ),
    );
  }

  // ─── FILE PREVIEW ──────────────────────────────────────────────

  Widget _buildFilePreview(BuildContext context, DocumentModel doc, String ext) {
    if (_isImage(ext)) {
      return _buildImagePreview(context, doc);
    }
    return _buildDocumentFallback(context, doc, ext);
  }

  /// Image preview with tap-to-fullscreen.
  Widget _buildImagePreview(BuildContext context, DocumentModel doc) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => FullScreenImageViewer(
              imageUrl: doc.fileUrl,
              title: doc.title,
            ),
          ),
        );
      },
      child: Container(
        width: double.infinity,
        height: 300,
        decoration: BoxDecoration(
          color: const Color(0xFFEDEEEF),
          borderRadius: BorderRadius.circular(24),
        ),
        clipBehavior: Clip.antiAlias,
        child: Stack(
          fit: StackFit.expand,
          children: [
            Image.network(
              doc.fileUrl,
              fit: BoxFit.contain,
              errorBuilder: (context, error, stackTrace) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.broken_image, size: 64, color: Colors.grey),
                      const SizedBox(height: 8),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Text(
                          'Image could not be loaded.',
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ),
                    ],
                  ),
                );
              },
              loadingBuilder: (context, child, loadingProgress) {
                if (loadingProgress == null) return child;
                return Center(
                  child: CircularProgressIndicator(
                    value: loadingProgress.expectedTotalBytes != null
                        ? loadingProgress.cumulativeBytesLoaded /
                            loadingProgress.expectedTotalBytes!
                        : null,
                  ),
                );
              },
            ),
            // "Tap to expand" hint overlay
            Positioned(
              bottom: 12,
              right: 12,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.6),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.zoom_in, color: Colors.white, size: 16),
                    SizedBox(width: 4),
                    Text(
                      'Tap to expand',
                      style: TextStyle(color: Colors.white, fontSize: 12),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Visually pleasing fallback for non-image files.
  Widget _buildDocumentFallback(BuildContext context, DocumentModel doc, String ext) {
    final info = _getFileTypeInfo(ext);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 48, horizontal: 24),
      decoration: BoxDecoration(
        color: info.color.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: info.color.withValues(alpha: 0.15),
          width: 1.5,
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Large icon in a circle
          Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              color: info.color.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(info.icon, size: 52, color: info.color),
          ),
          const SizedBox(height: 20),
          // Extension badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            decoration: BoxDecoration(
              color: info.color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              ext.toUpperCase(),
              style: TextStyle(
                color: info.color,
                fontWeight: FontWeight.w800,
                fontSize: 14,
                letterSpacing: 1.2,
              ),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            info.label,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: AnweshanTheme.onSurfaceVariant,
                  fontWeight: FontWeight.w500,
                ),
          ),
          const SizedBox(height: 4),
          Text(
            doc.title,
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  color: AnweshanTheme.outline,
                ),
          ),
        ],
      ),
    );
  }

  // ─── "OPEN FILE" BUTTON ────────────────────────────────────────

  Widget _buildOpenFileButton(BuildContext context, DocumentModel doc) {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        onPressed: () async {
          final uri = Uri.parse(doc.fileUrl);
          try {
            await launchUrl(uri, mode: LaunchMode.externalApplication);
          } catch (e) {
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Could not open file: $e')),
              );
            }
          }
        },
        icon: const Icon(Icons.open_in_new_rounded),
        label: const Text('Open File'),
        style: OutlinedButton.styleFrom(
          foregroundColor: AnweshanTheme.primaryDeep,
          side: const BorderSide(color: AnweshanTheme.primaryDeep, width: 1.5),
          shape: const StadiumBorder(),
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
          textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }

  // ─── METADATA ──────────────────────────────────────────────────

  Widget _buildMetadataTable(
      BuildContext context, DocumentModel doc, String date) {
    return Column(
      children: [
        _buildMetadataRow(
            'Uploaded By', doc.uploadedBy.isEmpty ? 'Admin' : doc.uploadedBy),
        const Divider(),
        _buildMetadataRow('Date', date),
        const Divider(),
        _buildMetadataRow(
            'Folder', doc.folderId == null ? 'Root' : doc.folderId!),
      ],
    );
  }

  Widget _buildMetadataRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style: const TextStyle(color: AnweshanTheme.onSurfaceVariant)),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.end,
              style: const TextStyle(fontWeight: FontWeight.w600),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  // ─── ACTION BUTTONS ────────────────────────────────────────────

  Widget _buildActionButtons(BuildContext context, DocumentModel doc,
      StorageService storageService, DatabaseService databaseService) {
    return Row(
      children: [
        Expanded(
          child: ElevatedButton.icon(
            onPressed: () async {
              try {
                await storageService.downloadDocument(doc.fileUrl);
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Opening download link...')),
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Download failed: $e')),
                  );
                }
              }
            },
            icon: const Icon(Icons.download),
            label: const Text('Download'),
          ),
        ),
        if (context.watch<AuthService>().isAdmin) ...[
          const SizedBox(width: 16),
          Container(
            height: 56,
            width: 56,
            decoration: BoxDecoration(
              color: Colors.red.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(16),
            ),
            child: IconButton(
              icon: const Icon(Icons.delete_outline, color: Colors.red),
              onPressed: () {
                _showDeleteConfirmation(
                    context, doc, storageService, databaseService);
              },
            ),
          ),
        ],
      ],
    );
  }

  // ─── DELETE DIALOG ─────────────────────────────────────────────

  void _showDeleteConfirmation(BuildContext context, DocumentModel doc,
      StorageService storageService, DatabaseService databaseService) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete Document'),
        content: Text(
            'Are you sure you want to delete "${doc.title}"? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              try {
                Navigator.pop(dialogContext);

                final uri = Uri.parse(doc.fileUrl);
                final path = uri.pathSegments.last;
                await storageService.deleteDocument(path);
                await databaseService.deleteDocument(doc.id);

                if (context.mounted) {
                  Navigator.pop(context, true);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                        content: Text('Document deleted successfully')),
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Delete failed: $e')),
                  );
                }
              }
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}

/// Helper class holding icon, color, and label for a file type.
class _FileTypeInfo {
  final IconData icon;
  final Color color;
  final String label;
  const _FileTypeInfo(this.icon, this.color, this.label);
}
