import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../theme.dart';
import '../services/database_service.dart';
import '../services/storage_service.dart';
import '../services/auth_service.dart';
import 'package:provider/provider.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';

class DocumentDetailScreen extends StatelessWidget {
  final DocumentModel document;
  const DocumentDetailScreen({super.key, required this.document});

  @override
  Widget build(BuildContext context) {
    final doc = document;

    final StorageService storageService = StorageService();
    final DatabaseService databaseService = DatabaseService();
    final String formattedDate =
        DateFormat('MMM dd, yyyy').format(doc.uploadDate);

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
            _buildFilePreview(context, doc),
            const SizedBox(height: 32),
            Text(
              doc.title,
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(height: 16),
            _buildMetadataTable(context, doc, formattedDate),
            const SizedBox(height: 48),
            _buildActionButtons(context, doc, storageService, databaseService),
          ],
        ),
      ),
    );
  }

  Widget _buildFilePreview(BuildContext context, DocumentModel doc) {
    final String fileUrl = doc.fileUrl;
    final String ext = fileUrl.split('?').first.split('.').last.toLowerCase();

    if (['jpg', 'jpeg', 'png'].contains(ext)) {
      return Container(
        width: double.infinity,
        height: 300,
        decoration: BoxDecoration(
          color: const Color(0xFFEDEEEF),
          borderRadius: BorderRadius.circular(24),
        ),
        clipBehavior: Clip.antiAlias,
        child: Image.network(
          fileUrl,
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
                       'Image loading failed. This might be a CORS issue on Flutter Web.',
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
      );
    } else if (ext == 'pdf') {
      return Container(
        width: double.infinity,
        height: 400,
        decoration: BoxDecoration(
          color: const Color(0xFFEDEEEF),
          borderRadius: BorderRadius.circular(24),
          border:
              Border.all(color: AnweshanTheme.outline.withValues(alpha: 0.2)),
        ),
        clipBehavior: Clip.antiAlias,
        child: SfPdfViewer.network(fileUrl),
      );
    }

    return Container(
      width: double.infinity,
      height: 300,
      decoration: BoxDecoration(
        color: const Color(0xFFEDEEEF),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.description, size: 80, color: AnweshanTheme.outline),
          const SizedBox(height: 16),
          Text(
            ext.toUpperCase(),
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  color: AnweshanTheme.onSurfaceVariant.withValues(alpha: 0.5),
                ),
          ),
          const SizedBox(height: 8),
          Text('Preview Unavailable',
              style: Theme.of(context).textTheme.labelLarge),
        ],
      ),
    );
  }

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
                // Close dialog first
                Navigator.pop(dialogContext);

                // 1. Delete from Storage
                final uri = Uri.parse(doc.fileUrl);
                final path = uri.pathSegments.last;
                await storageService.deleteDocument(path);

                // 2. Delete from Database
                await databaseService.deleteDocument(doc.id);

                if (context.mounted) {
                  Navigator.pop(context, true); // Go back from detail screen with success flag
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
