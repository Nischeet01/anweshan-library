import 'package:flutter/material.dart';
import '../theme.dart';
import '../services/database_service.dart';
import 'department_view_screen.dart';
import 'settings_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  int _selectedIndex = 0;

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _selectedIndex,
        children: [
          const _DashboardContent(),
          DepartmentViewScreen(),
          const _SearchPlaceholder(),
          const SettingsScreen(),
        ],
      ),
      bottomNavigationBar: _buildBottomNav(context),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          await Navigator.pushNamed(context, '/upload');
          // Refresh dashboard when returning from upload
          if (_selectedIndex == 0) setState(() {});
        },
        backgroundColor: AnweshanTheme.primaryDeep,
        shape: const CircleBorder(),
        child: const Icon(Icons.add, color: Colors.white),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
    );
  }

  Widget _buildBottomNav(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(left: 24, right: 24, bottom: 24),
      height: 72,
      decoration: BoxDecoration(
        color: AnweshanTheme.primaryDeep,
        borderRadius: BorderRadius.circular(AnweshanTheme.pillRadius),
        boxShadow: [
          BoxShadow(
            color: AnweshanTheme.primaryDeep.withValues(alpha: 0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _buildNavItem(0, Icons.home_filled, Icons.home_outlined),
          _buildNavItem(1, Icons.folder, Icons.folder_outlined),
          const SizedBox(width: 40), // Space for FAB
          _buildNavItem(2, Icons.search, Icons.search),
          _buildNavItem(3, Icons.settings, Icons.settings_outlined),
        ],
      ),
    );
  }

  Widget _buildNavItem(
      int index, IconData selectedIcon, IconData unselectedIcon) {
    bool isSelected = _selectedIndex == index;
    return GestureDetector(
      onTap: () => _onItemTapped(index),
      child: Icon(
        isSelected ? selectedIcon : unselectedIcon,
        color: isSelected ? AnweshanTheme.secondaryGold : Colors.white70,
        size: 28,
      ),
    );
  }
}

class _DashboardContent extends StatefulWidget {
  const _DashboardContent();

  @override
  State<_DashboardContent> createState() => _DashboardContentState();
}

class _DashboardContentState extends State<_DashboardContent> {
  final DatabaseService _databaseService = DatabaseService();
  final TextEditingController _searchController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 24),
            _buildHeader(context),
            const SizedBox(height: 32),
            _buildSearchBar(context),
            const SizedBox(height: 40),
            _buildSectionHeader(context, 'Latest Documents', true),
            const SizedBox(height: 16),
            _buildLatestDocuments(context),
            const SizedBox(height: 40),
            _buildSectionHeader(context, 'Categories', false),
            const SizedBox(height: 16),
            _buildCategoriesGrid(context),
            const SizedBox(height: 40),
            _buildSectionHeader(context, 'Recent Activity', true),
            const SizedBox(height: 16),
            _buildRecentActivityList(context),
            const SizedBox(height: 100), // Space for bottom nav
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Anweshan Hub',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            Text(
              'Welcome back, Researcher',
              style: Theme.of(context).textTheme.labelLarge,
            ),
          ],
        ),
        CircleAvatar(
          backgroundColor: AnweshanTheme.primaryDeep.withValues(alpha: 0.1),
          child: const Icon(Icons.person_outline,
              color: AnweshanTheme.primaryDeep),
        ),
      ],
    );
  }

  Widget _buildSearchBar(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFEDEEEF),
        borderRadius: BorderRadius.circular(AnweshanTheme.pillRadius),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: TextField(
        controller: _searchController,
        decoration: InputDecoration(
          icon: const Icon(Icons.search, color: AnweshanTheme.onSurfaceVariant),
          hintText: 'Search documents...',
          hintStyle: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: AnweshanTheme.onSurfaceVariant.withValues(alpha: 0.7),
              ),
          border: InputBorder.none,
          filled: false,
        ),
      ),
    );
  }

  Widget _buildSectionHeader(
      BuildContext context, String title, bool showSeeAll) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(title,
            style: Theme.of(context)
                .textTheme
                .headlineMedium
                ?.copyWith(fontSize: 22)),
        if (showSeeAll)
          TextButton(
            onPressed: () {},
            child: const Text('See All',
                style: TextStyle(color: AnweshanTheme.primaryDeep)),
          ),
      ],
    );
  }

  Widget _buildLatestDocuments(BuildContext context) {
    return SizedBox(
      height: 200,
      child: StreamBuilder<List<DocumentModel>>(
        stream: _databaseService.getLatestDocuments(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(
              child: Text('Error loading documents',
                  style: TextStyle(color: Colors.red[400])),
            );
          }
          final docs = snapshot.data ?? [];
          if (docs.isEmpty) {
            return _buildEmptyState();
          }
          return ListView.builder(
            scrollDirection: Axis.horizontal,
            clipBehavior: Clip.none,
            itemCount: docs.length,
            itemBuilder: (context, index) {
              final doc = docs[index];
              return InkWell(
                onTap: () =>
                    Navigator.pushNamed(context, '/detail', arguments: doc),
                child: Container(
                  width: 160,
                  margin: const EdgeInsets.only(right: 16),
                  child: Card(
                    elevation: 4,
                    shadowColor: Colors.black12,
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(Icons.article_outlined,
                              size: 40, color: AnweshanTheme.accentGoldDim),
                          const Spacer(),
                          Text(
                            doc.title,
                            style: const TextStyle(fontWeight: FontWeight.bold),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4),
                          Text(
                              doc.category.isNotEmpty ? doc.category : 'Document',
                              style: Theme.of(context).textTheme.labelLarge),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.description_outlined,
              size: 56, color: AnweshanTheme.primaryDeep.withValues(alpha: 0.3)),
          const SizedBox(height: 12),
          const Text(
            'No documents found.',
            style: TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 16,
              color: AnweshanTheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Upload one using the + button!',
            style: TextStyle(
              fontSize: 13,
              color: AnweshanTheme.onSurfaceVariant.withValues(alpha: 0.7),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoriesGrid(BuildContext context) {
    return FutureBuilder<List<CategoryModel>>(
      future: _databaseService.getCategories(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return const Text('Could not load categories.',
              style: TextStyle(color: Colors.red));
        }
        final categories = snapshot.data ?? [];
        if (categories.isEmpty) {
          return const Text('No categories available.',
              style: TextStyle(color: AnweshanTheme.onSurfaceVariant));
        }
        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            childAspectRatio: 2.5,
          ),
          itemCount: categories.length,
          itemBuilder: (context, index) {
            final category = categories[index];
            return InkWell(
              onTap: () => Navigator.pushNamed(context, '/department',
                  arguments: category.name),
              child: Container(
                decoration: BoxDecoration(
                  color: AnweshanTheme.primaryDeep.withValues(alpha: 0.05),
                  borderRadius:
                      BorderRadius.circular(AnweshanTheme.pillRadius),
                ),
                alignment: Alignment.center,
                child: Text(
                  category.name,
                  style: const TextStyle(
                      fontWeight: FontWeight.w600, fontSize: 13),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildRecentActivityList(BuildContext context) {
    return FutureBuilder<List<DocumentModel>>(
      future: _databaseService.getDocuments(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(24.0),
              child: CircularProgressIndicator(),
            ),
          );
        }
        if (snapshot.hasError) {
          return const Text('Could not load recent activity.',
              style: TextStyle(color: Colors.red));
        }
        final docs = snapshot.data ?? [];
        if (docs.isEmpty) {
          return Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.black.withValues(alpha: 0.05)),
            ),
            child: Center(
              child: Column(
                children: [
                  Icon(Icons.history,
                      size: 40,
                      color: AnweshanTheme.onSurfaceVariant.withValues(alpha: 0.3)),
                  const SizedBox(height: 8),
                  const Text(
                    'No recent activity yet.',
                    style: TextStyle(color: AnweshanTheme.onSurfaceVariant),
                  ),
                ],
              ),
            ),
          );
        }
        // Show at most 5 recent items
        final recentDocs = docs.take(5).toList();
        return ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: recentDocs.length,
          itemBuilder: (context, index) {
            final doc = recentDocs[index];
            return InkWell(
              onTap: () =>
                  Navigator.pushNamed(context, '/detail', arguments: doc),
              child: Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.black.withValues(alpha: 0.05)),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: AnweshanTheme.secondaryGold.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.description,
                          color: AnweshanTheme.accentGoldDim),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(doc.title,
                              style:
                                  const TextStyle(fontWeight: FontWeight.bold)),
                          Text(
                            '${doc.uploadedBy.isNotEmpty ? doc.uploadedBy : 'Admin'} • ${doc.uploadDate.day}/${doc.uploadDate.month}',
                            style: Theme.of(context).textTheme.labelLarge,
                          ),
                        ],
                      ),
                    ),
                    const Icon(Icons.more_vert,
                        color: AnweshanTheme.onSurfaceVariant),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
}

class _SearchPlaceholder extends StatelessWidget {
  const _SearchPlaceholder();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Search')),
      body: const Center(
        child: Text('Global Search functionality coming soon!'),
      ),
    );
  }
}
