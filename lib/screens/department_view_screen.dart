import 'package:flutter/material.dart';
import '../theme.dart';
import '../services/database_service.dart';
import '../services/auth_service.dart';
import 'package:provider/provider.dart';
import 'document_detail_screen.dart';
import 'upload_screen.dart';

class DepartmentViewScreen extends StatefulWidget {
  final String? folderId;
  final String folderName;

  const DepartmentViewScreen({
    super.key,
    this.folderId,
    this.folderName = 'Root',
  });

  @override
  State<DepartmentViewScreen> createState() => DepartmentViewScreenState();
}

class DepartmentViewScreenState extends State<DepartmentViewScreen> {
  final DatabaseService _databaseService = DatabaseService();
  late Stream<List<FolderModel>> _foldersStream;
  late Stream<List<DocumentModel>> _documentsStream;

  @override
  void initState() {
    super.initState();
    _initStreams();
  }

  void _initStreams() {
    _foldersStream = _databaseService.streamFolders(widget.folderId);
    _documentsStream = _databaseService.getDocumentsByFolder(widget.folderId);
  }

  void refreshData() {
    if (mounted) {
      setState(() {
        _initStreams();
      });
    }
  }

  void _showCreateFolderDialog(BuildContext context) {
    final TextEditingController folderNameController = TextEditingController();
    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Create Folder'),
          content: TextField(
            controller: folderNameController,
            decoration: const InputDecoration(hintText: 'Folder Name'),
            autofocus: true,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                final name = folderNameController.text.trim();
                if (name.isNotEmpty) {
                  await _databaseService.createFolder(name, widget.folderId);
                  if (context.mounted) {
                    Navigator.pop(dialogContext);
                    refreshData();
                  }
                }
              },
              child: const Text('Create'),
            ),
          ],
        );
      },
    );
  }

  void _showActionBottomSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 16.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 24),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              ListTile(
                leading: const Icon(Icons.create_new_folder,
                    color: AnweshanTheme.primaryDeep),
                title: const Text('Create Folder'),
                onTap: () {
                  Navigator.pop(context);
                  _showCreateFolderDialog(context);
                },
              ),
              ListTile(
                leading: const Icon(Icons.upload_file,
                    color: AnweshanTheme.primaryDeep),
                title: const Text('Upload Document'),
                onTap: () async {
                  Navigator.pop(context);
                  final result = await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => UploadScreen(
                        initialFolderId: widget.folderId,
                      ),
                    ),
                  );
                  if (result == true && context.mounted) {
                    refreshData();
                  }
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _confirmDeleteFolder(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Confirm Delete'),
        content: const Text(
            'Are you sure you want to delete this folder? All contents may be lost.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      try {
        await _databaseService.deleteFolder(widget.folderId!);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Folder deleted')),
          );
          Navigator.pop(context, true);
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error deleting folder: $e')),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isAdmin = context.watch<AuthService>().isAdmin;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: widget.folderId != null
            ? IconButton(
                icon: Icon(Icons.arrow_back_ios_new,
                    color: Theme.of(context).colorScheme.onSurface),
                onPressed: () => Navigator.pop(context),
              )
            : null,
        title: Text(
          widget.folderName,
          style: Theme.of(context)
              .textTheme
              .headlineMedium
              ?.copyWith(fontSize: 20),
        ),
        centerTitle: true,
        actions: [
          if (isAdmin && widget.folderId != null)
            PopupMenuButton<String>(
              icon: Icon(Icons.more_vert,
                  color: Theme.of(context).colorScheme.onSurface),
              onSelected: (value) {
                if (value == 'delete') {
                  _confirmDeleteFolder(context);
                }
              },
              itemBuilder: (context) => [
                const PopupMenuItem(
                  value: 'delete',
                  child: Row(
                    children: [
                      Icon(Icons.delete_outline, color: Colors.red, size: 20),
                      SizedBox(width: 8),
                      Text('Delete Folder',
                          style: TextStyle(color: Colors.red)),
                    ],
                  ),
                ),
              ],
            ),
        ],
      ),
      floatingActionButton: isAdmin
          ? FloatingActionButton(
              heroTag: 'department_add_fab_${widget.folderId ?? "root"}',
              onPressed: () => _showActionBottomSheet(context),
              backgroundColor: AnweshanTheme.primaryDeep,
              child: const Icon(Icons.add, color: Colors.white),
            )
          : null,
      body: RefreshIndicator(
        onRefresh: () async {
          refreshData();
        },
        color: AnweshanTheme.primaryDeep,
        backgroundColor: Colors.transparent,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Folders',
                  style: Theme.of(context)
                      .textTheme
                      .headlineMedium
                      ?.copyWith(fontSize: 18)),
              const SizedBox(height: 12),
              _buildFoldersGrid(),
              const SizedBox(height: 32),
              Text('Documents',
                  style: Theme.of(context)
                      .textTheme
                      .headlineMedium
                      ?.copyWith(fontSize: 18)),
              const SizedBox(height: 12),
              _buildDocumentsList(isAdmin),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFoldersGrid() {
    return StreamBuilder<List<FolderModel>>(
      stream: _foldersStream,
      builder: (context, snapshot) {
        if (!snapshot.hasData)
          return const Center(child: CircularProgressIndicator());
        final folders = snapshot.data!;
        if (folders.isEmpty) {
          return Center(
            child: Column(
              children: [
                const SizedBox(height: 20),
                Icon(Icons.folder_open,
                    size: 60, color: Colors.grey.withValues(alpha: 0.3)),
                const SizedBox(height: 8),
                const Text('This folder is empty',
                    style: TextStyle(color: Colors.grey)),
              ],
            ),
          );
        }

        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            childAspectRatio: 1.1,
          ),
          itemCount: folders.length,
          itemBuilder: (context, index) {
            final folder = folders[index];
            return Card(
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: BorderSide(
                    color: Theme.of(context)
                        .colorScheme
                        .onSurface
                        .withValues(alpha: 0.1)),
              ),
              color: Theme.of(context).colorScheme.surface,
              child: InkWell(
                borderRadius: BorderRadius.circular(16),
                onTap: () async {
                  final result = await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => DepartmentViewScreen(
                        folderId: folder.id,
                        folderName: folder.name,
                      ),
                    ),
                  );
                  if (result == true && mounted) {
                    refreshData();
                  }
                },
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.folder, color: Colors.blue, size: 48),
                      const SizedBox(height: 12),
                      Text(
                        folder.name,
                        style: const TextStyle(
                            fontWeight: FontWeight.w600, fontSize: 14),
                        textAlign: TextAlign.center,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildDocumentsList(bool isAdmin) {
    return StreamBuilder<List<DocumentModel>>(
      stream: _documentsStream,
      builder: (context, snapshot) {
        if (!snapshot.hasData)
          return const Center(child: CircularProgressIndicator());
        final docs = snapshot.data!;
        if (docs.isEmpty) {
          return Center(
            child: Column(
              children: [
                const SizedBox(height: 20),
                Icon(Icons.description_outlined,
                    size: 60, color: Colors.grey.withValues(alpha: 0.3)),
                const SizedBox(height: 8),
                const Text('No documents yet',
                    style: TextStyle(color: Colors.grey)),
              ],
            ),
          );
        }

        return ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: docs.length,
          itemBuilder: (context, index) {
            final doc = docs[index];
            IconData fileIcon = Icons.insert_drive_file;
            Color iconColor = Colors.grey;

            final ext = doc.title.split('.').last.toLowerCase();
            if (ext == 'pdf') {
              fileIcon = Icons.picture_as_pdf;
              iconColor = Colors.red;
            } else if (['jpg', 'jpeg', 'png'].contains(ext)) {
              fileIcon = Icons.image;
              iconColor = Colors.blue;
            } else if (['doc', 'docx'].contains(ext)) {
              fileIcon = Icons.description;
              iconColor = Colors.blue.shade800;
            }

            return Card(
              elevation: 0,
              margin: const EdgeInsets.only(bottom: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(
                    color: Theme.of(context)
                        .colorScheme
                        .onSurface
                        .withValues(alpha: 0.1)),
              ),
              color: Theme.of(context).colorScheme.surface,
              child: ListTile(
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                leading: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: iconColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(fileIcon, color: iconColor),
                ),
                title: Text(doc.title,
                    style: const TextStyle(fontWeight: FontWeight.w600)),
                subtitle: Text(
                  '${doc.uploadedBy.isNotEmpty ? doc.uploadedBy : 'Admin'} • ${_formatDate(doc.uploadDate)}',
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
                trailing: isAdmin
                    ? Icon(Icons.more_vert, color: Theme.of(context).colorScheme.onSurfaceVariant)
                    : null,
                onTap: () async {
                  final result = await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => DocumentDetailScreen(document: doc),
                    ),
                  );
                  if (result == true && context.mounted) {
                    refreshData();
                  }
                },
              ),
            );
          },
        );
      },
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}
