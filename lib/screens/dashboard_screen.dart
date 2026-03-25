import 'package:flutter/material.dart';
import 'dart:async';
import '../theme.dart';
import '../services/database_service.dart';
import '../services/auth_service.dart';
import 'department_view_screen.dart';
import 'settings_screen.dart';
import 'document_detail_screen.dart';
import 'package:provider/provider.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  int _selectedIndex = 0;
  final DatabaseService _databaseService = DatabaseService();
  final GlobalKey<_DashboardContentState> _dashboardKey = GlobalKey();

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  void _showAddOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (BuildContext bc) {
        return SafeArea(
          child: Wrap(
            children: <Widget>[
              ListTile(
                leading: const Icon(Icons.description, color: AnweshanTheme.primaryDeep),
                title: const Text('Upload Document'),
                onTap: () async {
                  Navigator.pop(context); // Close bottom sheet
                  final result = await Navigator.pushNamed(context, '/upload');
                  if (result == true && mounted) {
                    if (_selectedIndex == 0) {
                      _dashboardKey.currentState?._refreshData();
                    }
                  }
                },
              ),
              ListTile(
                leading: const Icon(Icons.create_new_folder, color: AnweshanTheme.primaryDeep),
                title: const Text('Create Folder'),
                onTap: () {
                  Navigator.pop(context);
                  _showCreateRootFolderDialog(context);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  void _showCreateRootFolderDialog(BuildContext context) {
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
                  await _databaseService.createFolder(name, null);
                  if (context.mounted) {
                    Navigator.pop(dialogContext);
                    if (_selectedIndex == 0) {
                      _dashboardKey.currentState?._refreshData();
                    }
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

  @override
  Widget build(BuildContext context) {
    final isAdmin = context.watch<AuthService>().isAdmin;

    return Scaffold(
      body: IndexedStack(
        index: _selectedIndex,
        children: [
          _DashboardContent(key: _dashboardKey),
          DepartmentViewScreen(), 
          const SearchScreen(),
          const SettingsScreen(),
        ],
      ),
      bottomNavigationBar: _buildBottomNav(context),
      floatingActionButton: isAdmin
          ? FloatingActionButton(
              heroTag: 'dashboard_add_fab',
              onPressed: () => _showAddOptions(context),
              backgroundColor: AnweshanTheme.primaryDeep,
              shape: const CircleBorder(),
              child: const Icon(Icons.add, color: Colors.white),
            )
          : null,
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
  const _DashboardContent({super.key});

  @override
  State<_DashboardContent> createState() => _DashboardContentState();
}

class _DashboardContentState extends State<_DashboardContent> {
  final DatabaseService _databaseService = DatabaseService();
  final TextEditingController _searchController = TextEditingController();
  late Stream<List<FolderModel>> _foldersStream;
  late Stream<List<DocumentModel>> _rootDocumentsStream;

  @override
  void initState() {
    super.initState();
    _initStreams();
  }

  void _initStreams() {
    _foldersStream = _databaseService.streamFolders(null);
    _rootDocumentsStream = _databaseService.getDocumentsByFolder(null);
  }

  void _refreshData() {
    if (mounted) {
      setState(() {
        _initStreams();
      });
    }
  }

  String _getGreeting() {
    var hour = DateTime.now().hour;
    if (hour < 12) {
      return 'Good Morning,';
    }
    if (hour < 17) {
      return 'Good Afternoon,';
    }
    return 'Good Evening,';
  }
  List<DocumentModel>? _searchResults;
  bool _isSearching = false;
  Timer? _debounce;

  void _onSearchChanged(String query) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    
    if (query.isEmpty) {
      setState(() {
        _isSearching = false;
        _searchResults = null;
      });
      return;
    }

    setState(() {
      _isSearching = true;
      _searchResults = null; 
    });

    _debounce = Timer(const Duration(milliseconds: 500), () async {
      final results = await _databaseService.searchDocuments(query);
      if (mounted) {
        setState(() {
          _searchResults = results;
        });
      }
    });
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
                  await _databaseService.createFolder(name, null);
                  if (context.mounted) {
                    Navigator.pop(dialogContext);
                    _refreshData();
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

  @override
  Widget build(BuildContext context) {
    final isAdmin = Provider.of<AuthService>(context).isAdmin;

    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _getGreeting(),
                      style: Theme.of(context).textTheme.labelLarge?.copyWith(fontSize: 14),
                    ),
                    Text(
                      'Anweshan Hub',
                      style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                if (isAdmin)
                  IconButton(
                    icon: const Icon(Icons.create_new_folder, color: AnweshanTheme.primaryDeep),
                    onPressed: () => _showCreateFolderDialog(context),
                  )
                else
                  CircleAvatar(
                    backgroundColor: AnweshanTheme.primaryDeep.withValues(alpha: 0.1),
                    child: const Icon(Icons.person_outline,
                        color: AnweshanTheme.primaryDeep),
                  ),
              ],
            ),
            const SizedBox(height: 32),
            _buildSearchBar(context),
            if (_isSearching) ...[
              const SizedBox(height: 40),
              _buildSectionHeader(context, 'Search Results', false),
              const SizedBox(height: 16),
              _buildSearchResultsList(context),
            ] else ...[
              const SizedBox(height: 40),
              _buildSectionHeader(context, 'Root Folders', false),
              const SizedBox(height: 16),
              _buildFoldersGrid(context),
              const SizedBox(height: 40),
              _buildSectionHeader(context, 'Recent Documents', true),
              const SizedBox(height: 16),
              _buildRootDocuments(context),
            ],
            const SizedBox(height: 100), 
          ],
        ),
      ),
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
        onChanged: _onSearchChanged,
        decoration: InputDecoration(
          icon: const Icon(Icons.search, color: AnweshanTheme.onSurfaceVariant),
          hintText: 'Search documents...',
          hintStyle: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: AnweshanTheme.onSurfaceVariant.withValues(alpha: 0.7),
              ),
          border: InputBorder.none,
          filled: false,
          suffixIcon: _isSearching
              ? IconButton(
                  icon: const Icon(Icons.clear, size: 20),
                  onPressed: () {
                    _searchController.clear();
                    _onSearchChanged('');
                  },
                )
              : null,
        ),
      ),
    );
  }

  Widget _buildSearchResultsList(BuildContext context) {
    if (_searchResults == null) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_searchResults!.isEmpty) {
      return _buildEmptyState();
    }

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: _searchResults!.length,
      itemBuilder: (context, index) {
        final doc = _searchResults![index];
        return _buildDocListItem(context, doc);
      },
    );
  }

  Widget _buildDocListItem(BuildContext context, DocumentModel doc) {
    return InkWell(
      onTap: () async {
        final result = await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => DocumentDetailScreen(document: doc),
          ),
        );
        if (result == true && mounted) {
          _refreshData();
        }
      },
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
                      style: const TextStyle(fontWeight: FontWeight.bold)),
                  Text(
                    '${doc.uploadedBy.isNotEmpty ? doc.uploadedBy : 'Admin'} • ${doc.uploadDate.day}/${doc.uploadDate.month}',
                    style: Theme.of(context).textTheme.labelLarge,
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: AnweshanTheme.onSurfaceVariant),
          ],
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

  Widget _buildRootDocuments(BuildContext context) {
    return StreamBuilder<List<DocumentModel>>(
      stream: _rootDocumentsStream,
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
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: docs.length,
          itemBuilder: (context, index) {
            final doc = docs[index];
            return _buildDocListItem(context, doc);
          },
        );
      },
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

  Widget _buildFoldersGrid(BuildContext context) {
    return StreamBuilder<List<FolderModel>>(
      stream: _foldersStream,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return const Text('Could not load folders.',
              style: TextStyle(color: Colors.red));
        }
        final folders = snapshot.data ?? [];
        if (folders.isEmpty) {
          return const Text('No folders available.',
              style: TextStyle(color: AnweshanTheme.onSurfaceVariant));
        }
        return SizedBox(
          height: 110,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: folders.length,
            clipBehavior: Clip.none,
            itemBuilder: (context, index) {
              final folder = folders[index];
              return InkWell(
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => DepartmentViewScreen(
                      folderId: folder.id,
                      folderName: folder.name,
                    ),
                  ),
                ),
                child: Container(
                  width: 140,
                  margin: const EdgeInsets.only(right: 16),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AnweshanTheme.primaryDeep.withValues(alpha: 0.05),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.transparent),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Icon(Icons.folder,
                          color: AnweshanTheme.primaryDeep, size: 36),
                      Text(
                        folder.name,
                        style: const TextStyle(
                            fontWeight: FontWeight.w600, fontSize: 14),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    _debounce?.cancel();
    super.dispose();
  }
}

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final DatabaseService _databaseService = DatabaseService();
  final TextEditingController _searchController = TextEditingController();
  List<DocumentModel>? _searchResults;
  bool _isLoading = false;
  Timer? _debounce;

  void _onSearch(String query) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();

    if (query.isEmpty) {
      setState(() {
        _searchResults = null;
        _isLoading = false;
      });
      return;
    }

    setState(() {
      _isLoading = true;
    });

    _debounce = Timer(const Duration(milliseconds: 500), () async {
      final results = await _databaseService.searchDocuments(query);
      if (mounted) {
        setState(() {
          _searchResults = results;
          _isLoading = false;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Search', style: TextStyle(color: AnweshanTheme.primaryDeep, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(24.0),
            child: Container(
              decoration: BoxDecoration(
                color: const Color(0xFFEDEEEF),
                borderRadius: BorderRadius.circular(AnweshanTheme.pillRadius),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: TextField(
                controller: _searchController,
                onChanged: _onSearch,
                autofocus: true,
                decoration: InputDecoration(
                  icon: const Icon(Icons.search, color: AnweshanTheme.onSurfaceVariant),
                  hintText: 'Search by title...',
                  border: InputBorder.none,
                  suffixIcon: _searchController.text.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear, size: 20),
                          onPressed: () {
                            _searchController.clear();
                            _onSearch('');
                          },
                        )
                      : null,
                ),
              ),
            ),
          ),
          Expanded(
            child: _buildBody(),
          ),
        ],
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_searchResults == null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.search, size: 80, color: AnweshanTheme.primaryDeep.withValues(alpha: 0.1)),
            const SizedBox(height: 16),
            const Text(
              'Enter a title to search',
              style: TextStyle(color: AnweshanTheme.onSurfaceVariant, fontSize: 16),
            ),
          ],
        ),
      );
    }

    if (_searchResults!.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.search_off, size: 80, color: AnweshanTheme.primaryDeep.withValues(alpha: 0.1)),
            const SizedBox(height: 16),
            const Text(
              'No documents matched your search',
              style: TextStyle(color: AnweshanTheme.onSurfaceVariant, fontSize: 16),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      itemCount: _searchResults!.length,
      itemBuilder: (context, index) {
        final doc = _searchResults![index];
        return _buildDocListItem(context, doc);
      },
    );
  }

  Widget _buildDocListItem(BuildContext context, DocumentModel doc) {
    return InkWell(
      onTap: () async {
        final result = await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => DocumentDetailScreen(document: doc),
          ),
        );
        if (result == true && mounted) {
          _onSearch(_searchController.text);
        }
      },
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
              child: const Icon(Icons.description, color: AnweshanTheme.accentGoldDim),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(doc.title, style: const TextStyle(fontWeight: FontWeight.bold)),
                  Text(
                    '${doc.uploadedBy.isNotEmpty ? doc.uploadedBy : 'Admin'} • ${doc.uploadDate.day}/${doc.uploadDate.month}',
                    style: Theme.of(context).textTheme.labelLarge,
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: AnweshanTheme.onSurfaceVariant),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    _debounce?.cancel();
    super.dispose();
  }
}
