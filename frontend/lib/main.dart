
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';
import 'package:shared_preferences/shared_preferences.dart'; // 追加

import 'package:frontend/services/auth_service.dart'; // 追加
import 'package:frontend/screens/login_screen.dart'; // 追加

// --- Data Model ---
class Article {
  final int id; // 追加
  final String title;
  final String url;
  final String? publishedDate;
  final String? summary;
  final String? thumbnailUrl;
  final String? sentiment;

  Article({
    required this.id, // 追加
    required this.title,
    required this.url,
    this.publishedDate,
    this.summary,
    this.thumbnailUrl,
    this.sentiment,
  });

  factory Article.fromJson(Map<String, dynamic> json) {
    return Article(
      id: json['id'], // 追加
      title: json['title'],
      url: json['url'],
      publishedDate: json['published_date'],
      summary: json['summary'],
      thumbnailUrl: json['thumbnail_url'],
      sentiment: json['sentiment'],
    );
  }
}

// --- API Service ---
Future<List<Article>> fetchArticles(String category) async {
  const String baseUrl = kIsWeb ? 'http://localhost:8001' : 'http://10.0.2.2:8001';
  final token = await AuthService.getToken(); // トークン取得
  final response = await http.get(
    Uri.parse('$baseUrl/api/articles/$category'),
    headers: token != null ? {'Authorization': 'Bearer $token'} : {}, // ヘッダーにトークン追加
  );

  if (response.statusCode == 200) {
    final List<dynamic> body = json.decode(utf8.decode(response.bodyBytes));
    return body.map((dynamic item) => Article.fromJson(item)).toList();
  } else if (response.statusCode == 401) {
    // 認証エラーの場合、ログイン画面へリダイレクト
    throw Exception('Unauthorized. Please log in again.');
  } else {
    throw Exception('Failed to load articles for category $category');
  }
}

// --- Main Application ---
void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'News Curation App',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),
      home: const AuthCheckScreen(), // 起動時に認証状態をチェックする画面を追加
    );
  }
}

// --- Auth Check Screen ---
class AuthCheckScreen extends StatefulWidget {
  const AuthCheckScreen({super.key});

  @override
  State<AuthCheckScreen> createState() => _AuthCheckScreenState();
}

class _AuthCheckScreenState extends State<AuthCheckScreen> {
  @override
  void initState() {
    super.initState();
    _checkAuthStatus();
  }

  Future<void> _checkAuthStatus() async {
    final token = await AuthService.getToken();
    if (mounted) {
      if (token != null) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => const HomeScreen()),
        );
      } else {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => const LoginScreen()),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: CircularProgressIndicator(), // 認証チェック中はローディング表示
      ),
    );
  }
}

// --- Home Screen with Tabs ---
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late List<GlobalKey<_ArticleListViewState>> _tabKeys;

  final List<String> _categories = ['gamba_osaka', 'soccer', 'coffee', 'programming'];
  final List<String> _tabLabels = ['ガンバ大阪', 'サッカー全般', 'コーヒー', 'プログラミング'];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _categories.length, vsync: this);
    _tabKeys = List.generate(_categories.length, (_) => GlobalKey<_ArticleListViewState>());
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _handleRefresh() {
    // Get the state of the currently active ArticleListView and call its refresh method
    _tabKeys[_tabController.index].currentState?.refreshArticles();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('News Curation'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _handleRefresh,
            tooltip: 'Refresh Articles',
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await AuthService.deleteToken();
              if (mounted) {
                Navigator.of(context).pushReplacement(
                  MaterialPageRoute(builder: (context) => const LoginScreen()),
                );
              }
            },
          ),
        ], // ログアウトボタンを追加
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true, // タブが増えたのでスクロール可能にする
          tabs: _tabLabels.map((label) => Tab(text: label)).toList(),
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: _categories.asMap().entries.map((entry) {
          final index = entry.key;
          final category = entry.value;
          return ArticleListView(key: _tabKeys[index], category: category);
        }).toList(),
      ),
    );
  }
}

// --- Reusable Article List View for a Category ---
class ArticleListView extends StatefulWidget {
  final String category;
  const ArticleListView({super.key, required this.category});

  @override
  State<ArticleListView> createState() => _ArticleListViewState();
}

class _ArticleListViewState extends State<ArticleListView> {
  late Future<List<Article>> futureArticles;

  @override
  void initState() {
    super.initState();
    futureArticles = fetchArticles(widget.category);
  }

  Future<void> refreshArticles() async {
    setState(() {
      futureArticles = fetchArticles(widget.category);
    });
  }

  // URLを起動するメソッド
  Future<void> _launchUrl(String url) async {
    final uri = Uri.parse(url);
    if (!await launchUrl(uri)) {
      // エラー処理: スナックバーなどでユーザーに通知
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not launch $url')),
      );
    }
  }

  // 感情に応じてアイコンを返すヘルパーメソッド
  Icon _getSentimentIcon(String? sentiment) {
    switch (sentiment) {
      case 'positive':
        return const Icon(Icons.sentiment_very_satisfied, color: Colors.green);
      case 'negative':
        return const Icon(Icons.sentiment_very_dissatisfied, color: Colors.red);
      default:
        return const Icon(Icons.sentiment_neutral, color: Colors.grey);
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<Article>>(
      future: futureArticles,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        } else if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        } else if (snapshot.hasData && snapshot.data!.isNotEmpty) {
          final articles = snapshot.data!;
          return ListView.builder(
            itemCount: articles.length,
            itemBuilder: (context, index) {
              final article = articles[index];
              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
                child: ListTile(
                  // サムネイル画像
                  leading: article.thumbnailUrl != null
                      ? SizedBox(
                          width: 100,
                          child: Image.network(
                            article.thumbnailUrl!,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) => 
                                const Icon(Icons.image_not_supported),
                          ),
                        )
                      : const SizedBox(width: 100, child: Icon(Icons.image)),
                  // 記事タイトル
                  title: Text(article.title, style: const TextStyle(fontWeight: FontWeight.bold)),
                  // 概要と公開日
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(article.summary ?? 'No summary available'),
                      const SizedBox(height: 4),
                      Text(article.publishedDate ?? '', style: Theme.of(context).textTheme.bodySmall),
                    ],
                  ),
                  // 感情アイコン
                  trailing: _getSentimentIcon(article.sentiment),
                  onTap: () => _launchUrl(article.url),
                ),
              );
            },
          );
        } else {
          return const Center(child: Text('No articles found.'));
        }
      },
    );
  }
}
