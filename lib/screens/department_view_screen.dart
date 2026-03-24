import 'package:flutter/material.dart';
import '../theme.dart';
import '../services/database_service.dart';

class DepartmentViewScreen extends StatelessWidget {
  final String departmentName;
  final DatabaseService _databaseService = DatabaseService();

  DepartmentViewScreen({
    super.key,
    this.departmentName = 'Engineering Assets',
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AnweshanTheme.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new,
              color: AnweshanTheme.onSurface),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          departmentName,
          style: Theme.of(context)
              .textTheme
              .headlineMedium
              ?.copyWith(fontSize: 20),
        ),
        centerTitle: true,
      ),
      body: Column(
        children: [
          _buildFilterChips(),
          Expanded(
            child: StreamBuilder<List<DocumentModel>>(
              stream: _databaseService.getDocumentsByCategory(departmentName),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }
                final docs = snapshot.data!;
                if (docs.isEmpty) {
                  return const Center(
                      child: Text('No documents in this department.'));
                }
                return GridView.builder(
                  padding: const EdgeInsets.all(24),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                    childAspectRatio: 0.85,
                  ),
                  itemCount: docs.length,
                  itemBuilder: (context, index) {
                    return _buildDocumentCard(context, docs[index]);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChips() {
    final filters = ['All', 'PDF', 'DOCX', 'PPTX'];
    return SizedBox(
      height: 60,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
        itemCount: filters.length,
        itemBuilder: (context, index) {
          final isSelected = index == 0;
          return Padding(
            padding: const EdgeInsets.only(right: 12),
            child: ChoiceChip(
              label: Text(filters[index]),
              selected: isSelected,
              onSelected: (val) {},
              selectedColor: AnweshanTheme.primaryDeep,
              labelStyle: TextStyle(
                color:
                    isSelected ? Colors.white : AnweshanTheme.onSurfaceVariant,
                fontWeight: FontWeight.w600,
              ),
              shape: StadiumBorder(
                side: BorderSide(
                  color: isSelected
                      ? AnweshanTheme.primaryDeep
                      : AnweshanTheme.outline.withValues(alpha: 0.3),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildDocumentCard(BuildContext context, DocumentModel doc) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AnweshanTheme.primaryDeep.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.insert_drive_file_outlined,
                color: AnweshanTheme.primaryDeep),
          ),
          const Spacer(),
          Text(
            doc.title,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 4),
          Text(
            '${doc.uploadedBy.isNotEmpty ? doc.uploadedBy : 'Admin'} • ${doc.uploadDate.day}/${doc.uploadDate.month}',
            style:
                Theme.of(context).textTheme.labelLarge?.copyWith(fontSize: 10),
          ),
        ],
      ),
    );
  }
}
