import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../theme.dart';
import '../services/database_service.dart';
import '../services/storage_service.dart';

class DocumentDetailScreen extends StatelessWidget {
  const DocumentDetailScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final DocumentModel? doc = ModalRoute.of(context)?.settings.arguments as DocumentModel?;

    if (doc == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Error')),
        body: const Center(child: Text('No document data found.')),
      );
    }

    final StorageService storageService = StorageService();
    final DatabaseService databaseService = DatabaseService();
    final String formattedDate = DateFormat('MMM dd, yyyy').format(doc.uploadDate);

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
            doc.title.split('.').last.toUpperCase(),
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              color: AnweshanTheme.onSurfaceVariant.withValues(alpha: 0.5),
            ),
          ),
          const SizedBox(height: 8),
          Text('Preview Unavailable', style: Theme.of(context).textTheme.labelLarge),
        ],
      ),
    );
  }

  Widget _buildMetadataTable(BuildContext context, DocumentModel doc, String date) {
    return Column(
      children: [
        _buildMetadataRow('Uploaded By', doc.uploadedBy.isEmpty ? 'Admin' : doc.uploadedBy),
        const Divider(),
        _buildMetadataRow('Date', date),
        const Divider(),
        _buildMetadataRow('Category', doc.category.isEmpty ? 'Uncategorized' : doc.category),
      ],
    );
  }

  Widget _buildMetadataRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: AnweshanTheme.onSurfaceVariant)),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w600)),
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
              _showDeleteConfirmation(context, doc, storageService, databaseService);
            },
          ),
        ),
      ],
    );
  }

  void _showDeleteConfirmation(BuildContext context, DocumentModel doc, 
      StorageService storageService, DatabaseService databaseService) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete Document'),
        content: Text('Are you sure you want to delete "${doc.title}"? This action cannot be undone.'),
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
                  Navigator.pop(context); // Go back from detail screen
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Document deleted successfully')),
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
