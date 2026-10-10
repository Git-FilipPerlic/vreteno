import 'package:flutter/material.dart';

import 'data/repositories/article_repository.dart';
import 'features/feed/ui/feed_screen.dart';

void main() => runApp(VretenoApp(repo: ArticleRepository()));

class VretenoApp extends StatelessWidget {
  const VretenoApp({super.key, required this.repo});

  final ArticleRepository repo;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Vreteno',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(colorSchemeSeed: Colors.indigo, useMaterial3: true),
      home: FeedScreen(repo: repo),
    );
  }
}
