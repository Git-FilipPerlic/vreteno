import 'package:flutter/material.dart';

import 'core/theme/app_theme.dart';
import 'data/repositories/article_repository.dart';
import 'features/blindspots/ui/blind_spots_screen.dart';
import 'features/feed/ui/feed_screen.dart';
import 'features/sources/ui/sources_screen.dart';

void main() => runApp(VretenoApp(repo: ArticleRepository()));

class VretenoApp extends StatelessWidget {
  const VretenoApp({super.key, required this.repo});

  final ArticleRepository repo;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Vreteno',
      debugShowCheckedModeBanner: false,
      theme: buildLightTheme(),
      themeMode: ThemeMode.light,
      home: _Home(repo: repo),
    );
  }
}

class _Home extends StatefulWidget {
  const _Home({required this.repo});

  final ArticleRepository repo;

  @override
  State<_Home> createState() => _HomeState();
}

class _HomeState extends State<_Home> {
  int _tab = 0;

  @override
  void initState() {
    super.initState();
    widget.repo.refresh();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _tab,
        children: [
          FeedScreen(repo: widget.repo),
          BlindSpotsScreen(repo: widget.repo),
          SourcesScreen(repo: widget.repo),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _tab,
        onDestinationSelected: (i) => setState(() => _tab = i),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.newspaper_outlined),
            selectedIcon: Icon(Icons.newspaper),
            label: 'Vesti',
          ),
          NavigationDestination(
            icon: Icon(Icons.visibility_off_outlined),
            selectedIcon: Icon(Icons.visibility_off),
            label: 'Slepe tačke',
          ),
          NavigationDestination(
            icon: Icon(Icons.library_books_outlined),
            selectedIcon: Icon(Icons.library_books),
            label: 'Izvori',
          ),
        ],
      ),
    );
  }
}
