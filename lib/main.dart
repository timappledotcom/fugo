import 'dart:convert';
import 'dart:io';

import 'package:file_selector/file_selector.dart';
import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:path/path.dart' as p;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:yaru/yaru.dart';

import 'utils/hugo_utils.dart';
import 'widgets/new_post_dialog.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return YaruTheme(
      builder: (context, yaru, child) {
        return MaterialApp(
          title: 'Fugo',
          theme: yaru.theme?.copyWith(
            appBarTheme: yaru.theme?.appBarTheme.copyWith(
              backgroundColor: yaru.theme?.colorScheme.surface,
              foregroundColor: yaru.theme?.colorScheme.onSurface,
              elevation: 1,
            ),
            cardTheme: CardThemeData(
              elevation: 1,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
          ),
          darkTheme: yaru.darkTheme?.copyWith(
            appBarTheme: yaru.darkTheme?.appBarTheme.copyWith(
              backgroundColor: yaru.darkTheme?.colorScheme.surface,
              foregroundColor: yaru.darkTheme?.colorScheme.onSurface,
              elevation: 1,
            ),
            cardTheme: CardThemeData(
              elevation: 1,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
          ),
          home: const FugoHome(),
          debugShowCheckedModeBanner: false,
        );
      },
    );
  }
}

class FugoHome extends StatefulWidget {
  const FugoHome({super.key});

  @override
  State<FugoHome> createState() => _FugoHomeState();
}

class _FugoHomeState extends State<FugoHome> {
  String? selectedSitePath;
  List<Map<String, dynamic>> sitePosts = [];
  List<Map<String, dynamic>> sitePages = [];
  List<Map<String, dynamic>> siteDrafts = [];
  int selectedIndex = 0;
  String? selectedFilePath;
  String? selectedFileContent;
  bool showPreview = false;

  @override
  void initState() {
    super.initState();
    _loadSiteSelection();
  }

  Future<void> _loadSiteSelection() async {
    final prefs = await SharedPreferences.getInstance();
    final savedPath = prefs.getString('selected_site_path');
    if (savedPath != null && Directory(savedPath).existsSync()) {
      setState(() {
        selectedSitePath = savedPath;
      });
      await _refreshContent();
    }
  }

  Future<void> _saveSiteSelection(String path) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('selected_site_path', path);
  }

  Future<void> _selectSite() async {
    final directoryPath = await getDirectoryPath();
    if (directoryPath != null) {
      if (HugoUtils.isHugoSite(directoryPath)) {
        setState(() {
          selectedSitePath = directoryPath;
        });
        await _saveSiteSelection(directoryPath);
        await _refreshContent();
      } else {
        if (mounted) {
          _showErrorDialog('Selected directory does not appear to be a Hugo site.\nLooking for config.toml, config.yaml, or hugo.toml');
        }
      }
    }
  }

  Future<void> _refreshContent() async {
    if (selectedSitePath == null) return;

    final contentDir = Directory(p.join(selectedSitePath!, 'content'));
    if (!contentDir.existsSync()) return;

    sitePosts.clear();
    sitePages.clear();
    siteDrafts.clear();

    await _scanDirectory(contentDir);
    setState(() {});
  }

  Future<void> _scanDirectory(Directory dir) async {
    await for (final entity in dir.list(recursive: true)) {
      if (entity is File && 
          (entity.path.endsWith('.md') || entity.path.endsWith('.markdown'))) {
        
        final content = await entity.readAsString();
        final frontMatter = HugoUtils.extractFrontMatter(content);
        final relativePath = p.relative(entity.path, from: selectedSitePath!);
        
        final fileInfo = {
          'path': entity.path,
          'relativePath': relativePath,
          'title': frontMatter['title'] ?? p.basenameWithoutExtension(entity.path),
          'date': frontMatter['date'] ?? '',
          'draft': frontMatter['draft'] == true || frontMatter['draft'] == 'true',
          'lastModified': entity.lastModifiedSync(),
        };

        if (fileInfo['draft'] == true) {
          siteDrafts.add(fileInfo);
        } else if (relativePath.startsWith('content${Platform.pathSeparator}posts${Platform.pathSeparator}') ||
                   relativePath.contains('${Platform.pathSeparator}posts${Platform.pathSeparator}')) {
          sitePosts.add(fileInfo);
        } else {
          sitePages.add(fileInfo);
        }
      }
    }

    // Sort by date (newest first)
    sitePosts.sort((a, b) => b['lastModified'].compareTo(a['lastModified']));
    sitePages.sort((a, b) => (a['title'] as String).compareTo(b['title'] as String));
    siteDrafts.sort((a, b) => b['lastModified'].compareTo(a['lastModified']));
  }



  Future<void> _openFile(String filePath) async {
    try {
      final content = await File(filePath).readAsString();
      setState(() {
        selectedFilePath = filePath;
        selectedFileContent = content;
      });
    } catch (e) {
      _showErrorDialog('Error opening file: $e');
    }
  }

  Future<void> _saveFile() async {
    if (selectedFilePath != null && selectedFileContent != null) {
      try {
        await File(selectedFilePath!).writeAsString(selectedFileContent!);
        _showSuccessDialog('File saved successfully');
        await _refreshContent();
      } catch (e) {
        _showErrorDialog('Error saving file: $e');
      }
    }
  }

  Future<void> _createNewPost() async {
    final result = await showDialog<Map<String, String>>(
      context: context,
      builder: (context) => const NewPostDialog(),
    );

    if (result != null && selectedSitePath != null) {
      final postsDir = Directory(p.join(selectedSitePath!, 'content', 'posts'));
      if (!postsDir.existsSync()) {
        await postsDir.create(recursive: true);
      }

      final fileName = '${result['filename']}.md';
      final filePath = p.join(postsDir.path, fileName);
      
      final content = HugoUtils.createPostTemplate(
        title: result['title']!,
        isDraft: result['draft'] == 'true',
      );

      await File(filePath).writeAsString(content);
      await _refreshContent();
      await _openFile(filePath);
    }
  }

  Future<void> _publishSite() async {
    if (selectedSitePath == null) return;

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Publish Site'),
        content: const Text('This will run "hugo" to build your site. Continue?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Publish'),
          ),
        ],
      ),
    );

    if (result == true) {
      try {
        final process = await Process.start(
          'hugo',
          [],
          workingDirectory: selectedSitePath,
        );

        final output = await process.stdout.transform(utf8.decoder).join();
        final error = await process.stderr.transform(utf8.decoder).join();
        final exitCode = await process.exitCode;

        if (exitCode == 0) {
          _showSuccessDialog('Site published successfully!\n\n$output');
        } else {
          _showErrorDialog('Publishing failed:\n\n$error');
        }
      } catch (e) {
        _showErrorDialog('Error running Hugo: $e\n\nMake sure Hugo is installed and in your PATH.');
      }
    }
  }

  Future<void> _openSiteInBrowser() async {
    final url = Uri.parse('http://localhost:1313');
    if (await canLaunchUrl(url)) {
      await launchUrl(url);
    } else {
      _showErrorDialog('Could not open browser. Make sure Hugo server is running.');
    }
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Error'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _showSuccessDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Success'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Icon(Icons.code, color: theme.colorScheme.primary),
            const SizedBox(width: 8),
            const Text('Fugo'),
          ],
        ),
        actions: [
          if (selectedSitePath != null) ...[
            IconButton(
              icon: const Icon(Icons.refresh),
              tooltip: 'Refresh Content',
              onPressed: _refreshContent,
            ),
            IconButton(
              icon: const Icon(Icons.add),
              tooltip: 'New Post',
              onPressed: _createNewPost,
            ),
            IconButton(
              icon: const Icon(Icons.web),
              tooltip: 'Open in Browser',
              onPressed: _openSiteInBrowser,
            ),
            IconButton(
              icon: const Icon(Icons.publish),
              tooltip: 'Publish Site',
              onPressed: _publishSite,
            ),
          ],
          const SizedBox(width: 8),
        ],
        elevation: 1,
      ),
      body: selectedSitePath == null ? _buildWelcomeScreen() : _buildMainInterface(),
    );
  }

  Widget _buildWelcomeScreen() {
    final theme = Theme.of(context);
    
    return Center(
      child: Card(
        margin: const EdgeInsets.all(32),
        child: Padding(
          padding: const EdgeInsets.all(48),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.folder_open,
                size: 64,
                color: theme.colorScheme.primary,
              ),
              const SizedBox(height: 24),
              Text(
                'Welcome to Fugo',
                style: theme.textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'A Hugo site management tool for Ubuntu',
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 32),
              FilledButton.icon(
                onPressed: _selectSite,
                icon: const Icon(Icons.folder_open),
                label: const Text('Select Hugo Site'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMainInterface() {
    return Row(
      children: [
        _buildSidebar(),
        const VerticalDivider(width: 1),
        Expanded(child: _buildContentArea()),
      ],
    );
  }

  Widget _buildSidebar() {
    final theme = Theme.of(context);
    
    return SizedBox(
      width: 280,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Site: ${p.basename(selectedSitePath!)}',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  selectedSitePath!,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: NavigationRail(
              extended: true,
              minExtendedWidth: 280,
              destinations: const [
                NavigationRailDestination(
                  icon: Icon(Icons.article),
                  label: Text('Posts'),
                ),
                NavigationRailDestination(
                  icon: Icon(Icons.description),
                  label: Text('Pages'),
                ),
                NavigationRailDestination(
                  icon: Icon(Icons.drafts),
                  label: Text('Drafts'),
                ),
              ],
              selectedIndex: selectedIndex,
              onDestinationSelected: (index) {
                setState(() {
                  selectedIndex = index;
                  selectedFilePath = null;
                  selectedFileContent = null;
                });
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContentArea() {
    if (selectedFilePath != null && selectedFileContent != null) {
      return _buildEditor();
    }
    
    return _buildFileList();
  }

  Widget _buildFileList() {
    final theme = Theme.of(context);
    List<Map<String, dynamic>> currentList;
    String title;
    IconData icon;

    switch (selectedIndex) {
      case 0:
        currentList = sitePosts;
        title = 'Posts';
        icon = Icons.article;
        break;
      case 1:
        currentList = sitePages;
        title = 'Pages';
        icon = Icons.description;
        break;
      case 2:
        currentList = siteDrafts;
        title = 'Drafts';
        icon = Icons.drafts;
        break;
      default:
        currentList = [];
        title = '';
        icon = Icons.article;
    }

    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Icon(icon, color: theme.colorScheme.primary),
              const SizedBox(width: 8),
              Text(
                title,
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              Text(
                '${currentList.length} ${currentList.length == 1 ? 'item' : 'items'}',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
        const Divider(height: 1),
        Expanded(
          child: currentList.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        icon,
                        size: 48,
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'No $title yet',
                        style: theme.textTheme.titleMedium?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        selectedIndex == 0 ? 'Create your first post to get started' : 
                        selectedIndex == 1 ? 'Add some pages to your site' :
                        'Drafts will appear here',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  itemCount: currentList.length,
                  itemBuilder: (context, index) {
                    final item = currentList[index];
                    return Card(
                      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                      child: ListTile(
                        leading: Icon(
                          selectedIndex == 0 ? Icons.article :
                          selectedIndex == 1 ? Icons.description : Icons.drafts,
                          color: theme.colorScheme.primary,
                        ),
                        title: Text(item['title']),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(item['relativePath']),
                            if (item['date'].isNotEmpty)
                              Text(
                                'Date: ${item['date']}',
                                style: theme.textTheme.bodySmall,
                              ),
                          ],
                        ),
                        trailing: item['draft'] == true
                            ? Chip(
                                label: const Text('Draft'),
                                backgroundColor: theme.colorScheme.errorContainer,
                                labelStyle: TextStyle(
                                  color: theme.colorScheme.onErrorContainer,
                                ),
                              )
                            : null,
                        onTap: () => _openFile(item['path']),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildEditor() {
    final theme = Theme.of(context);
    
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Icon(Icons.edit, color: theme.colorScheme.primary),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  p.basename(selectedFilePath!),
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              SegmentedButton<bool>(
                segments: const [
                  ButtonSegment(
                    value: false,
                    label: Text('Edit'),
                    icon: Icon(Icons.edit),
                  ),
                  ButtonSegment(
                    value: true,
                    label: Text('Preview'),
                    icon: Icon(Icons.preview),
                  ),
                ],
                selected: {showPreview},
                onSelectionChanged: (Set<bool> selection) {
                  setState(() {
                    showPreview = selection.first;
                  });
                },
              ),
              const SizedBox(width: 8),
              FilledButton.icon(
                onPressed: _saveFile,
                icon: const Icon(Icons.save),
                label: const Text('Save'),
              ),
              const SizedBox(width: 8),
              IconButton(
                icon: const Icon(Icons.close),
                tooltip: 'Close File',
                onPressed: () {
                  setState(() {
                    selectedFilePath = null;
                    selectedFileContent = null;
                    showPreview = false;
                  });
                },
              ),
            ],
          ),
        ),
        const Divider(height: 1),
        Expanded(
          child: showPreview ? _buildPreview() : _buildTextEditor(),
        ),
      ],
    );
  }

  Widget _buildTextEditor() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: TextField(
        controller: TextEditingController(text: selectedFileContent),
        maxLines: null,
        expands: true,
        style: const TextStyle(fontFamily: 'monospace'),
        decoration: const InputDecoration(
          border: InputBorder.none,
          hintText: 'Start writing...',
        ),
        onChanged: (value) {
          selectedFileContent = value;
        },
      ),
    );
  }

  Widget _buildPreview() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Markdown(
        data: HugoUtils.removeYamlFrontMatter(selectedFileContent ?? ''),
        selectable: true,
      ),
    );
  }


}
