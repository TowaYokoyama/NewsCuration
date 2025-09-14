import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';

import 'package:frontend/services/auth_service.dart';
import 'package:frontend/screens/login_screen.dart';

// --- Data Models ---
class Article {
  final int id;
  final String title;
  final String url;
  final String? publishedDate;
  final String? summary;
  final String? thumbnailUrl;

  Article({
    required this.id,
    required this.title,
    required this.url,
    this.publishedDate,
    this.summary,
    this.thumbnailUrl,
  });

  factory Article.fromJson(Map<String, dynamic> json) {
    return Article(
      id: json['id'],
      title: json['title'],
      url: json['url'],
      publishedDate: json['published_date'],
      summary: json['summary'],
      thumbnailUrl: json['thumbnail_url'],
    );
  }
}

class RecipeCategory {
  final String categoryId;
  final String categoryName;

  RecipeCategory({required this.categoryId, required this.categoryName});

  factory RecipeCategory.fromJson(Map<String, dynamic> json) {
    return RecipeCategory(
      categoryId: json['categoryId'].toString(),
      categoryName: json['categoryName'],
    );
  }
}

// --- API Services ---
const String baseUrl = kIsWeb ? 'http://localhost:8001' : 'http://10.0.2.2:8001';

Future<List<Article>> fetchArticles(String categoryId) async {
  final token = await AuthService.getToken();
  final response = await http.get(
    Uri.parse('$baseUrl/api/articles/$categoryId'),
    headers: token != null ? {'Authorization': 'Bearer $token'} : {},
  );

  if (response.statusCode == 200) {
    final List<dynamic> body = json.decode(utf8.decode(response.bodyBytes));
    return body.map((dynamic item) => Article.fromJson(item)).toList();
  } else {
    throw Exception('Failed to load articles for category $categoryId');
  }
}

Future<List<RecipeCategory>> fetchCategories(String parentCategoryName) async {
  final token = await AuthService.getToken();
  final response = await http.get(
    Uri.parse('$baseUrl/api/categories/$parentCategoryName'),
    headers: token != null ? {'Authorization': 'Bearer $token'} : {},
  );

  if (response.statusCode == 200) {
    final List<dynamic> body = json.decode(utf8.decode(response.bodyBytes));
    return body.map((dynamic item) => RecipeCategory.fromJson(item)).toList();
  } else {
    throw Exception('Failed to load categories for $parentCategoryName');
  }
}

Future<List<Article>> fetchRecommendations() async {
  final token = await AuthService.getToken();
  final response = await http.get(
    Uri.parse('$baseUrl/api/articles/me/recommendations'),
    headers: token != null ? {'Authorization': 'Bearer $token'} : {},
  );
  if (response.statusCode == 200) {
    final List<dynamic> body = json.decode(utf8.decode(response.bodyBytes));
    return body.map((dynamic item) => Article.fromJson(item)).toList();
  } else {
    throw Exception('Failed to load recommendations');
  }
}

Future<List<Article>> fetchFavorites() async {
  final token = await AuthService.getToken();
  final response = await http.get(
    Uri.parse('$baseUrl/api/articles/me/favorites'),
    headers: token != null ? {'Authorization': 'Bearer $token'} : {},
  );
  if (response.statusCode == 200) {
    final List<dynamic> body = json.decode(utf8.decode(response.bodyBytes));
    return body.map((dynamic item) => Article.fromJson(item)).toList();
  } else {
    throw Exception('Failed to load favorites');
  }
}

// --- Main Application ---
void main() => runApp(const MyApp());

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
      home: const AuthCheckScreen(),
    );
  }
}

// --- Auth Check Screen ---
class AuthCheckScreen extends StatefulWidget {
  const AuthCheckScreen({super.key});

  @override
  State<AuthCheckScreen> createState() => _AuthCheckScreenState();
}

class _AuthCheckScreenState extends State<AuthCheckScreen> with TickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _rotationAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );
    
    _scaleAnimation = Tween<double>(
      begin: 0.5,
      end: 1.2,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.elasticOut,
    ));

    _rotationAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));

    _animationController.repeat(reverse: true);
    _checkAuthStatus();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _checkAuthStatus() async {
    await Future.delayed(const Duration(seconds: 2)); // Show splash animation
    final token = await AuthService.getToken();
    if (!mounted) return;
    if (token != null) {
      Navigator.of(context).pushReplacement(
        PageRouteBuilder(
          pageBuilder: (context, animation, secondaryAnimation) => const HomeScreen(),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return FadeTransition(
              opacity: animation,
              child: ScaleTransition(
                scale: animation,
                child: child,
              ),
            );
          },
          transitionDuration: const Duration(milliseconds: 800),
        ),
      );
    } else {
      Navigator.of(context).pushReplacement(
        PageRouteBuilder(
          pageBuilder: (context, animation, secondaryAnimation) => const LoginScreen(),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return FadeTransition(
              opacity: animation,
              child: SlideTransition(
                position: Tween<Offset>(
                  begin: const Offset(0.0, 1.0),
                  end: Offset.zero,
                ).animate(animation),
                child: child,
              ),
            );
          },
          transitionDuration: const Duration(milliseconds: 600),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.blue.shade800,
              Colors.purple.shade700,
              Colors.pink.shade600,
            ],
          ),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              AnimatedBuilder(
                animation: _animationController,
                builder: (context, child) {
                  return Transform.scale(
                    scale: _scaleAnimation.value,
                    child: Transform.rotate(
                      angle: _rotationAnimation.value * 2 * 3.14159,
                      child: Container(
                        width: 100,
                        height: 100,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.white.withOpacity(0.3),
                              blurRadius: 20,
                              spreadRadius: 5,
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.newspaper,
                          size: 50,
                          color: Colors.blue,
                        ),
                      ),
                    ),
                  );
                },
              ),
              const SizedBox(height: 30),
              Text(
                'News Curation',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  shadows: [
                    Shadow(
                      color: Colors.black.withOpacity(0.3),
                      offset: const Offset(0, 2),
                      blurRadius: 4,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              const CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
              ),
            ],
          ),
        ),
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

class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
  late TabController _tabController;
  late AnimationController _fabAnimationController;
  late Animation<double> _fabScaleAnimation;
  late Animation<double> _appBarAnimation;
  
  final GlobalKey<_ArticleListViewState> _programmingListKey = GlobalKey<_ArticleListViewState>();
  final GlobalKey<_ArticleListViewState> _recommendationsListKey = GlobalKey<_ArticleListViewState>();
  final GlobalKey<_ArticleListViewState> _favoritesListKey = GlobalKey<_ArticleListViewState>();

  final List<String> _categories = ['recommend', 'favorite', 'coffee', 'cooking', 'programming'];
  final List<String> _tabLabels = ['おすすめ', 'お気に入り', 'コーヒー', '料理', 'プログラミング'];
  final List<IconData> _tabIcons = [
    Icons.recommend,
    Icons.favorite,
    Icons.coffee,
    Icons.restaurant,
    Icons.code,
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _categories.length, vsync: this);
    _tabController.addListener(() => setState(() {}));
    
    _fabAnimationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    
    _fabScaleAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _fabAnimationController,
      curve: Curves.elasticOut,
    ));

    _appBarAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _fabAnimationController,
      curve: Curves.easeInOut,
    ));

    _fabAnimationController.forward();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _fabAnimationController.dispose();
    super.dispose();
  }

  void _handleRefresh() {
    // Animate refresh button
    _fabAnimationController.reverse().then((_) {
      _fabAnimationController.forward();
    });

    switch (_categories[_tabController.index]) {
      case 'programming':
        _programmingListKey.currentState?.refreshArticles();
        break;
      case 'recommend':
        _recommendationsListKey.currentState?.refreshArticles();
        break;
      case 'favorite':
        _favoritesListKey.currentState?.refreshArticles();
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentCategory = _categories[_tabController.index];
    final bool canRefresh = ['programming', 'recommend', 'favorite'].contains(currentCategory);

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.blue.shade50,
              Colors.purple.shade50,
              Colors.white,
            ],
          ),
        ),
        child: NestedScrollView(
          headerSliverBuilder: (BuildContext context, bool innerBoxIsScrolled) {
            return [
              SliverAppBar(
                expandedHeight: 160.0,
                floating: false,
                pinned: true,
                elevation: 0,
                backgroundColor: Colors.transparent,
                flexibleSpace: FlexibleSpaceBar(
                  title: AnimatedBuilder(
                    animation: _appBarAnimation,
                    builder: (context, child) {
                      return Transform.scale(
                        scale: 0.7 + (_appBarAnimation.value * 0.3),
                        child: Text(
                          'News Curation',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            shadows: [
                              Shadow(
                                color: Colors.black.withOpacity(0.3),
                                offset: const Offset(0, 1),
                                blurRadius: 3,
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                  background: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          Colors.blue.shade700,
                          Colors.purple.shade600,
                          Colors.pink.shade500,
                        ],
                      ),
                    ),
                    child: SafeArea(
                      child: Padding(
                        padding: const EdgeInsets.all(20.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Spacer(),
                            Text(
                              'こんにちは！',
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.9),
                                fontSize: 16,
                              ),
                            ),
                            const Text(
                              '今日のニュースをチェックしましょう',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 20,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                actions: [
                  if (canRefresh)
                    AnimatedBuilder(
                      animation: _fabScaleAnimation,
                      builder: (context, child) {
                        return Transform.scale(
                          scale: _fabScaleAnimation.value,
                          child: IconButton(
                            icon: const Icon(Icons.refresh, color: Colors.white),
                            onPressed: _handleRefresh,
                            tooltip: 'リフレッシュ',
                          ),
                        );
                      },
                    ),
                  IconButton(
                    icon: const Icon(Icons.logout, color: Colors.white),
                    onPressed: () async {
                      showDialog(
                        context: context,
                        builder: (context) => AlertDialog(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                          ),
                          title: const Text('ログアウト'),
                          content: const Text('本当にログアウトしますか？'),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(context),
                              child: const Text('キャンセル'),
                            ),
                            ElevatedButton(
                              onPressed: () async {
                                await AuthService.deleteToken();
                                if (mounted) {
                                  Navigator.of(context).pushReplacement(
                                    PageRouteBuilder(
                                      pageBuilder: (context, animation, secondaryAnimation) => const LoginScreen(),
                                      transitionsBuilder: (context, animation, secondaryAnimation, child) {
                                        return FadeTransition(
                                          opacity: animation,
                                          child: SlideTransition(
                                            position: Tween<Offset>(
                                              begin: const Offset(-1.0, 0.0),
                                              end: Offset.zero,
                                            ).animate(animation),
                                            child: child,
                                          ),
                                        );
                                      },
                                      transitionDuration: const Duration(milliseconds: 500),
                                    ),
                                  );
                                }
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.red,
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                              ),
                              child: const Text('ログアウト'),
                            ),
                          ],
                        ),
                      );
                    },
                    tooltip: 'ログアウト',
                  ),
                ],
                bottom: PreferredSize(
                  preferredSize: const Size.fromHeight(60),
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(30),
                        topRight: Radius.circular(30),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.grey.withOpacity(0.1),
                          blurRadius: 10,
                          offset: const Offset(0, -2),
                        ),
                      ],
                    ),
                    child: TabBar(
                      controller: _tabController,
                      isScrollable: true,
                      indicatorColor: Colors.blue.shade600,
                      indicatorWeight: 3,
                      indicatorSize: TabBarIndicatorSize.label,
                      labelColor: Colors.blue.shade700,
                      unselectedLabelColor: Colors.grey.shade500,
                      labelStyle: const TextStyle(fontWeight: FontWeight.bold),
                      tabs: List.generate(_tabLabels.length, (index) {
                        return Tab(
                          icon: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            child: Icon(
                              _tabIcons[index],
                              color: _tabController.index == index 
                                ? Colors.blue.shade600 
                                : Colors.grey.shade400,
                            ),
                          ),
                          text: _tabLabels[index],
                        );
                      }),
                    ),
                  ),
                ),
              ),
            ];
          },
          body: Container(
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(30),
                topRight: Radius.circular(30),
              ),
            ),
            child: TabBarView(
              controller: _tabController,
              children: _categories.map((String category) {
                switch (category) {
                  case 'programming':
                    return ArticleListView(key: _programmingListKey, categoryId: 'programming', source: ArticleSource.fetch, allowFavoriting: true);
                  case 'recommend':
                    return ArticleListView(key: _recommendationsListKey, categoryId: 'recommend', source: ArticleSource.recommendations, allowFavoriting: true);
                  case 'favorite':
                    return ArticleListView(key: _favoritesListKey, categoryId: 'favorite', source: ArticleSource.favorites, allowFavoriting: true);
                  default:
                    return CategoryListView(parentCategoryName: category);
                }
              }).toList(),
            ),
          ),
        ),
      ),
    );
  }
}

// --- Enhanced Category List View ---
class CategoryListView extends StatefulWidget {
  final String parentCategoryName;
  const CategoryListView({super.key, required this.parentCategoryName});

  @override
  State<CategoryListView> createState() => _CategoryListViewState();
}

class _CategoryListViewState extends State<CategoryListView> with TickerProviderStateMixin {
  late Future<List<RecipeCategory>> futureCategories;
  late AnimationController _listAnimationController;

  @override
  void initState() {
    super.initState();
    futureCategories = fetchCategories(widget.parentCategoryName);
    _listAnimationController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _listAnimationController.forward();
  }

  @override
  void dispose() {
    _listAnimationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<RecipeCategory>>(
      future: futureCategories,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.blue.shade600),
                ),
                const SizedBox(height: 16),
                Text(
                  '読み込み中...',
                  style: TextStyle(
                    color: Colors.grey.shade600,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
          );
        } else if (snapshot.hasError) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.error_outline,
                  size: 64,
                  color: Colors.red.shade400,
                ),
                const SizedBox(height: 16),
                Text(
                  'エラーが発生しました',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey.shade800,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Error: ${snapshot.error}',
                  style: TextStyle(
                    color: Colors.grey.shade600,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          );
        } else if (snapshot.hasData && snapshot.data!.isNotEmpty) {
          final categories = snapshot.data!;
          return AnimatedBuilder(
            animation: _listAnimationController,
            builder: (context, child) {
              return ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: categories.length,
                itemBuilder: (context, index) {
                  final category = categories[index];
                  final animation = Tween<double>(begin: 0.0, end: 1.0).animate(
                    CurvedAnimation(
                      parent: _listAnimationController,
                      curve: Interval(
                        index * 0.1,
                        1.0,
                        curve: Curves.easeOutBack,
                      ),
                    ),
                  );

                  return SlideTransition(
                    position: Tween<Offset>(
                      begin: const Offset(1.0, 0.0),
                      end: Offset.zero,
                    ).animate(animation),
                    child: FadeTransition(
                      opacity: animation,
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              Colors.white,
                              Colors.blue.shade50,
                            ],
                          ),
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.grey.withOpacity(0.1),
                              blurRadius: 10,
                              offset: const Offset(0, 5),
                            ),
                          ],
                        ),
                        child: Material(
                          color: Colors.transparent,
                          borderRadius: BorderRadius.circular(20),
                          child: InkWell(
                            borderRadius: BorderRadius.circular(20),
                            onTap: () => Navigator.push(
                              context,
                              PageRouteBuilder(
                                pageBuilder: (context, animation, secondaryAnimation) => ArticleListPage(
                                  categoryName: category.categoryName,
                                  categoryId: category.categoryId,
                                ),
                                transitionsBuilder: (context, animation, secondaryAnimation, child) {
                                  return SlideTransition(
                                    position: Tween<Offset>(
                                      begin: const Offset(1.0, 0.0),
                                      end: Offset.zero,
                                    ).animate(CurvedAnimation(
                                      parent: animation,
                                      curve: Curves.easeInOut,
                                    )),
                                    child: child,
                                  );
                                },
                                transitionDuration: const Duration(milliseconds: 300),
                              ),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(20),
                              child: Row(
                                children: [
                                  Container(
                                    width: 50,
                                    height: 50,
                                    decoration: BoxDecoration(
                                      gradient: LinearGradient(
                                        colors: [
                                          Colors.blue.shade400,
                                          Colors.purple.shade400,
                                        ],
                                      ),
                                      borderRadius: BorderRadius.circular(15),
                                    ),
                                    child: const Icon(
                                      Icons.category,
                                      color: Colors.white,
                                      size: 24,
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: Text(
                                      category.categoryName,
                                      style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.grey.shade800,
                                      ),
                                    ),
                                  ),
                                  Icon(
                                    Icons.arrow_forward_ios,
                                    color: Colors.grey.shade400,
                                    size: 20,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  );
                },
              );
            },
          );
        } else {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.inbox_outlined,
                  size: 64,
                  color: Colors.grey.shade400,
                ),
                const SizedBox(height: 16),
                Text(
                  'カテゴリーが見つかりません',
                  style: TextStyle(
                    fontSize: 18,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          );
        }
      },
    );
  }
}

// --- Article List Page (for navigation from sub-categories) ---
class ArticleListPage extends StatelessWidget {
  final String categoryName;
  final String categoryId;

  const ArticleListPage({
    super.key,
    required this.categoryName,
    required this.categoryId,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(categoryName),
        backgroundColor: Colors.blue.shade600,
        foregroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: ArticleListView(categoryId: categoryId, source: ArticleSource.fetch, allowFavoriting: true),
    );
  }
}

enum ArticleSource { fetch, recommendations, favorites }

// --- Enhanced Article List View ---
class ArticleListView extends StatefulWidget {
  final String categoryId;
  final ArticleSource source;
  final bool allowFavoriting;

  const ArticleListView({
    super.key,
    required this.categoryId,
    required this.source,
    this.allowFavoriting = false,
  });

  @override
  State<ArticleListView> createState() => _ArticleListViewState();
}

class _ArticleListViewState extends State<ArticleListView> with TickerProviderStateMixin {
  late Future<List<Article>> _futureArticles;
  Set<int> _favoriteIds = {};
  late AnimationController _listAnimationController;
  late AnimationController _favoriteAnimationController;

  @override
  void initState() {
    super.initState();
    _listAnimationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _favoriteAnimationController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    _loadArticles();
  }

  @override
  void dispose() {
    _listAnimationController.dispose();
    _favoriteAnimationController.dispose();
    super.dispose();
  }

  Future<void> _loadArticles() async {
    if (widget.allowFavoriting) {
      final favIds = await AuthService.getFavoriteIds();
      if (mounted) {
        setState(() {
          _favoriteIds = favIds;
        });
      }
    }

    Future<List<Article>> loader;
    switch (widget.source) {
      case ArticleSource.fetch:
        loader = fetchArticles(widget.categoryId);
        break;
      case ArticleSource.recommendations:
        loader = fetchRecommendations();
        break;
      case ArticleSource.favorites:
        loader = fetchFavorites();
        break;
    }
    
    if(mounted) {
      setState(() {
        _futureArticles = loader;
      });
      _listAnimationController.forward();
    }
  }

  Future<void> refreshArticles() async {
    _listAnimationController.reset();
    await _loadArticles();
  }

  Future<void> _launchUrl(String url) async {
    final uri = Uri.parse(url);
    if (!await launchUrl(uri)) {
      if(mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.error_outline, color: Colors.white),
                const SizedBox(width: 8),
                Text('URLを開けませんでした: $url'),
              ],
            ),
            backgroundColor: Colors.red.shade600,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            margin: const EdgeInsets.all(16),
          ),
        );
      }
    }
  }

  Future<void> _toggleFavorite(int articleId) async {
    _favoriteAnimationController.forward().then((_) {
      _favoriteAnimationController.reverse();
    });

    final isFavorited = _favoriteIds.contains(articleId);
    if (isFavorited) {
      await AuthService.removeFavorite(articleId);
      setState(() {
        _favoriteIds.remove(articleId);
      });
       if(mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Row(
              children: [
                Icon(Icons.heart_broken, color: Colors.white),
                SizedBox(width: 8),
                Text('お気に入りから削除しました'),
              ],
            ),
            backgroundColor: Colors.orange.shade600,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            margin: const EdgeInsets.all(16),
            duration: const Duration(seconds: 2),
          ),
        );
       }
    } else {
      await AuthService.addFavorite(articleId);
      setState(() {
        _favoriteIds.add(articleId);
      });
      if(mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Row(
              children: [
                Icon(Icons.favorite, color: Colors.white),
                SizedBox(width: 8),
                Text('お気に入りに追加しました'),
              ],
            ),
            backgroundColor: Colors.green.shade600,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            margin: const EdgeInsets.all(16),
            duration: const Duration(seconds: 2),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<Article>>(
      future: _futureArticles,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.blue.shade600),
                ),
                const SizedBox(height: 16),
                Text(
                  '記事を読み込み中...',
                  style: TextStyle(
                    color: Colors.grey.shade600,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
          );
        } else if (snapshot.hasError) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.error_outline,
                  size: 64,
                  color: Colors.red.shade400,
                ),
                const SizedBox(height: 16),
                Text(
                  'エラーが発生しました',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey.shade800,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '${snapshot.error}',
                  style: TextStyle(
                    color: Colors.grey.shade600,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 20),
                ElevatedButton.icon(
                  onPressed: () {
                    setState(() {
                      _loadArticles();
                    });
                  },
                  icon: const Icon(Icons.refresh),
                  label: const Text('再試行'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue.shade600,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
              ],
            ),
          );
        } else if (snapshot.hasData && snapshot.data!.isNotEmpty) {
          final articles = snapshot.data!;
          return AnimatedBuilder(
            animation: _listAnimationController,
            builder: (context, child) {
              return ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: articles.length,
                itemBuilder: (context, index) {
                  final article = articles[index];
                  final isFavorited = _favoriteIds.contains(article.id);
                  
                  final animation = Tween<double>(begin: 0.0, end: 1.0).animate(
                    CurvedAnimation(
                      parent: _listAnimationController,
                      curve: Interval(
                        index * 0.05,
                        1.0,
                        curve: Curves.easeOutQuart,
                      ),
                    ),
                  );

                  return SlideTransition(
                    position: Tween<Offset>(
                      begin: const Offset(0.0, 0.3),
                      end: Offset.zero,
                    ).animate(animation),
                    child: FadeTransition(
                      opacity: animation,
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.grey.withOpacity(0.1),
                              blurRadius: 15,
                              offset: const Offset(0, 5),
                            ),
                          ],
                        ),
                        child: Material(
                          color: Colors.transparent,
                          borderRadius: BorderRadius.circular(20),
                          child: InkWell(
                            borderRadius: BorderRadius.circular(20),
                            onTap: () => _launchUrl(article.url),
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // Thumbnail
                                  Container(
                                    width: 80,
                                    height: 80,
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(15),
                                      gradient: LinearGradient(
                                        colors: [
                                          Colors.grey.shade200,
                                          Colors.grey.shade100,
                                        ],
                                      ),
                                    ),
                                    child: ClipRRect(
                                      borderRadius: BorderRadius.circular(15),
                                      child: article.thumbnailUrl != null && article.thumbnailUrl!.isNotEmpty
                                          ? Image.network(
                                              article.thumbnailUrl!,
                                              fit: BoxFit.cover,
                                              errorBuilder: (context, error, stackTrace) => 
                                                  Icon(
                                                    Icons.image_not_supported,
                                                    color: Colors.grey.shade400,
                                                    size: 30,
                                                  ),
                                            )
                                          : Icon(
                                              Icons.article_outlined,
                                              color: Colors.grey.shade400,
                                              size: 30,
                                            ),
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  
                                  // Content
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          article.title,
                                          style: TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.grey.shade800,
                                            height: 1.3,
                                          ),
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        const SizedBox(height: 8),
                                        if (article.summary != null && article.summary!.isNotEmpty)
                                          Text(
                                            article.summary!,
                                            style: TextStyle(
                                              fontSize: 14,
                                              color: Colors.grey.shade600,
                                              height: 1.4,
                                            ),
                                            maxLines: 2,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        const SizedBox(height: 8),
                                        if (article.publishedDate != null)
                                          Row(
                                            children: [
                                              Icon(
                                                Icons.access_time,
                                                size: 14,
                                                color: Colors.grey.shade400,
                                              ),
                                              const SizedBox(width: 4),
                                              Text(
                                                article.publishedDate!,
                                                style: TextStyle(
                                                  fontSize: 12,
                                                  color: Colors.grey.shade500,
                                                ),
                                              ),
                                            ],
                                          ),
                                      ],
                                    ),
                                  ),
                                  
                                  // Favorite Button
                                  if (widget.allowFavoriting)
                                    AnimatedBuilder(
                                      animation: _favoriteAnimationController,
                                      builder: (context, child) {
                                        return Transform.scale(
                                          scale: 1.0 + (_favoriteAnimationController.value * 0.3),
                                          child: Container(
                                            decoration: BoxDecoration(
                                              color: isFavorited 
                                                  ? Colors.red.shade50 
                                                  : Colors.grey.shade50,
                                              borderRadius: BorderRadius.circular(12),
                                            ),
                                            child: IconButton(
                                              icon: AnimatedSwitcher(
                                                duration: const Duration(milliseconds: 300),
                                                child: Icon(
                                                  isFavorited ? Icons.favorite : Icons.favorite_border,
                                                  key: ValueKey(isFavorited),
                                                  color: isFavorited ? Colors.red.shade600 : Colors.grey.shade400,
                                                  size: 22,
                                                ),
                                              ),
                                              tooltip: isFavorited ? 'お気に入りから削除' : 'お気に入りに追加',
                                              onPressed: () async {
                                                await _toggleFavorite(article.id);
                                                if (!isFavorited && widget.source == ArticleSource.favorites) {
                                                  // If unfavoriting from the favorites tab, remove the item from the list
                                                  // This requires getting the current list from the future
                                                  _futureArticles.then((articles) {
                                                    articles.removeWhere((element) => element.id == article.id);
                                                    setState(() {
                                                      _futureArticles = Future.value(articles);
                                                    });
                                                  });
                                                }
                                              },
                                            ),
                                          ),
                                        );
                                      },
                                    ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  );
                },
              );
            },
          );
        } else {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.inbox_outlined,
                  size: 64,
                  color: Colors.grey.shade400,
                ),
                const SizedBox(height: 16),
                Text(
                  '記事が見つかりません',
                  style: TextStyle(
                    fontSize: 18,
                    color: Colors.grey.shade600,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '後でもう一度お試しください',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey.shade500,
                  ),
                ),
              ],
            ),
          );
        }
      },
    );
  }
  }