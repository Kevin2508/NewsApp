import 'package:flutter/material.dart';
import 'package:newsapp/recommendations.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:newsapp/profile_page.dart';
import 'package:newsapp/notification_page.dart';
import 'package:newsapp/search_page.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:shimmer/shimmer.dart'; // Add shimmer for loading effect

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  String? _selectedCategory = 'All';
  final List<String> _categories = [
    'All',
    'General',
    'Business',
    'Technology',
    'Entertainment',
    'Sports',
    'Health',
    'Science',
    'Politics',
    'Environment',
    'Travel',
    'Food',
    'Education',
    'Finance',
    'World',
    'Culture',
    'Crime',
    'Bollywood',
  ];
  final ScrollController _scrollController = ScrollController();

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFFF5F7FA), // Light greyish-blue
              Color(0xFFE5E7EB), // Slightly darker grey
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Custom AppBar/Header with Shadow
              Material(
                elevation: 4,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                  color: Colors.white,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(left: 85.0),
                        child: Image.asset('assets/images/Logo.png', width: 40, height: 40),
                      ),
                      Padding(
                        padding: const EdgeInsets.only(right: 40.0),
                        child: const Text(
                          'Newsly',
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: Colors.black,
                          ),
                        ),
                      ),
                      Row(
                        children: [
                          IconButton(
                            icon: const Icon(Icons.notifications, color: Color(0xFFff425e)),
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(builder: (context) => const NotificationPage()),
                              );
                            },
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.recommend, color: Colors.grey),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const RecommendationsPage(),
                      settings: RouteSettings(arguments: _selectedCategory),
                    ),
                  );
                },
              ),
              // Category Chips (Horizontally Scrollable)
              Container(
                height: 40,
                padding: const EdgeInsets.symmetric(vertical: 4.0),
                color: Colors.white,
                child: ListView.builder(
                  controller: _scrollController,
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 12.0),
                  itemCount: _categories.length,
                  itemBuilder: (context, index) {
                    final category = _categories[index];
                    final isSelected = _selectedCategory == category;
                    return Padding(
                      padding: const EdgeInsets.only(right: 8.0),
                      child: ChoiceChip(
                        label: Padding(
                          padding: const EdgeInsets.only(bottom: 4.0),
                          child: Text(
                            category,
                            style: TextStyle(
                              color: isSelected ? Colors.white : Colors.black87,
                              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                              fontSize: 14,
                            ),
                          ),
                        ),
                        selected: isSelected,
                        onSelected: (selected) {
                          if (selected) {
                            setState(() {
                              _selectedCategory = category;
                              final selectedIndex = _categories.indexOf(category);
                              _scrollController.animateTo(
                                selectedIndex * 90.0,
                                duration: const Duration(milliseconds: 300),
                                curve: Curves.easeInOut,
                              );
                            });
                          }
                        },
                        selectedColor: const Color(0xFFff425e),
                        backgroundColor: Colors.grey[100],
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                          side: BorderSide(
                            color: isSelected ? const Color(0xFFff425e) : Colors.grey[300]!,
                          ),
                        ),
                        elevation: isSelected ? 2 : 0,
                        pressElevation: 4,
                      ),
                    );
                  },
                ),
              ),
              // News Feed (using Supabase)
              Expanded(
                child: NewsFeed(selectedCategory: _selectedCategory),
              ),
              // Footer/Bottom Navigation with Shadow
              Material(
                elevation: 4,
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 8.0),
                  color: Colors.white,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.home, color: Color(0xFFff425e)),
                        onPressed: () {},
                      ),
                      IconButton(
                        icon: const Icon(Icons.search, color: Colors.grey),
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => const SearchPage()),
                          );
                        },
                      ),
                      IconButton(
                        icon: const Icon(Icons.person, color: Colors.grey),
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => const ProfilePage()),
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class NewsFeed extends StatefulWidget {
  final String? selectedCategory;

  const NewsFeed({super.key, this.selectedCategory});

  @override
  _NewsFeedState createState() => _NewsFeedState();
}

class _NewsFeedState extends State<NewsFeed> {
  final PageController _pageController = PageController();
  late Future<Map<String, dynamic>> _articlesFuture;

  @override
  void initState() {
    super.initState();
    _articlesFuture = _fetchArticles();
  }

  @override
  void didUpdateWidget(NewsFeed oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.selectedCategory != widget.selectedCategory) {
      _refreshArticles();
    }
  }

  Future<Map<String, dynamic>> _fetchArticles() async {
    final supabase = Supabase.instance.client;
    final userId = supabase.auth.currentUser?.id;
    if (userId == null) {
      throw Exception('User not authenticated');
    }
    final results = await Future.wait([
      supabase
          .from('user_preferences')
          .select('categories')
          .eq('user_id', userId)
          .single(),
      supabase
          .from('news_articles') // Updated table name
          .select()
          .order('published_at', ascending: false),
    ]);
    final preferences = results[0] as Map<String, dynamic>;
    final articles = results[1] as List<Map<String, dynamic>>;
    return {
      'categories': preferences['categories'] as List<dynamic>? ?? [],
      'articles': articles,
    };
  }
  Future<void> _refreshArticles() async {
    setState(() {
      _articlesFuture = _fetchArticles();
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Map<String, dynamic>>(
      future: _articlesFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Shimmer.fromColors(
            baseColor: Colors.grey[300]!,
            highlightColor: Colors.grey[100]!,
            child: ListView.builder(
              physics: const NeverScrollableScrollPhysics(),
              itemCount: 3, // Show 3 shimmer placeholders
              itemBuilder: (context, index) {
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8.0),
                  child: Column(
                    children: [
                      Container(
                        height: MediaQuery.of(context).size.height * 0.6,
                        color: Colors.white,
                      ),
                      Container(
                        height: 60,
                        margin: const EdgeInsets.all(16.0),
                        color: Colors.white,
                      ),
                    ],
                  ),
                );
              },
            ),
          );
        }
        if (snapshot.hasError) {
          print("Error fetching articles: ${snapshot.error}");
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.error_outline, size: 50, color: Colors.red),
                SizedBox(height: 10),
                Text(
                  'Oops! Something went wrong.',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 5),
                Text(
                  'Please check your connection or try again later.',
                  style: TextStyle(fontSize: 14, color: Colors.grey),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          );
        }
        if (!snapshot.hasData || snapshot.data!['articles'].isEmpty) {
          print("No articles found in Supabase");
          return const Center(child: Text('No news available'));
        }

        final userCategories = snapshot.data!['categories'] as List<dynamic>;
        final allArticles = snapshot.data!['articles'] as List<Map<String, dynamic>>;

        List<Map<String, dynamic>> articles;
        if (widget.selectedCategory == 'All') {
          articles = userCategories.isEmpty
              ? allArticles
              : allArticles.where((article) {
            final articleKeyword = article['keyword']?.toString();
            return articleKeyword != null && userCategories.contains(articleKeyword);
          }).toList();
        } else {
          articles = allArticles.where((article) {
            final articleKeyword = article['keyword']?.toString();
            return articleKeyword != null && articleKeyword == widget.selectedCategory;
          }).toList();
        }

        if (articles.isEmpty) {
          return Center(
            child: Text(
              widget.selectedCategory == 'All'
                  ? 'No articles match your selected categories'
                  : 'No articles available for ${widget.selectedCategory}',
            ),
          );
        }

        print("Total articles loaded: ${articles.length}");
        for (var article in articles) {
          print("Article image URL: ${article['image_url']}");
        }

        return RefreshIndicator(
          onRefresh: _refreshArticles,
          color: const Color(0xFFff425e),
          child: PageView.builder(
            controller: _pageController,
            scrollDirection: Axis.vertical,
            physics: const AlwaysScrollableScrollPhysics(),
            itemCount: articles.length,
            onPageChanged: (int page) {
              print("Swiped to page: $page");
            },
            itemBuilder: (context, index) {
              final article = articles[index];
              return NewsArticle(article: article);
            },
          ),
        );
      },
    );
  }
}

class NewsArticle extends StatelessWidget {
  final Map<String, dynamic> article;

  const NewsArticle({super.key, required this.article});

  Future<ImageProvider> _loadImage(String? url) async {
    try {
      if (url == null || url.isEmpty) {
        throw Exception('Image URL is null or empty');
      }
      return NetworkImage(url);
    } catch (e) {
      print("Error loading image: $url, error: $e");
      return const AssetImage('assets/placeholder.png');
    }
  }

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () async {
        final url = article['url']?.toString();
        print("Attempting to launch URL: $url");

        if (url == null || url.isEmpty) {
          print("URL is null or empty");
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('No URL available for this article')),
          );
          return;
        }

        String formattedUrl = url;
        if (!url.startsWith('http://') && !url.startsWith('https://')) {
          formattedUrl = 'https://$url';
          print("Formatted URL with scheme: $formattedUrl");
        }

        final uri = Uri.tryParse(formattedUrl);
        if (uri == null) {
          print("Failed to parse URL: $formattedUrl");
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Invalid URL format')),
          );
          return;
        }

        try {
          print("Checking if URL can be launched: $uri");
          if (await canLaunchUrl(uri)) {
            print("URL can be launched. Launching...");
            await launchUrl(
              uri,
              mode: LaunchMode.externalApplication,
            );
            print("Successfully launched URL: $uri");
          } else {
            print("Cannot launch URL externally. Opening in WebView...");
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => ArticleWebView(url: formattedUrl),
              ),
            );
          }
        } catch (e) {
          print("Error launching URL: $e");
          print("Opening in WebView as a fallback...");
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ArticleWebView(url: formattedUrl),
            ),
          );
        }
      },
      child: Column(
        children: [
          // Image (Enlarged with Gradient Overlay)
          Expanded(
            flex: 6, // Increased from 1 to 6 (60% of the space)
            child: Stack(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(12.0),
                  child: article['image_url'] != null && article['image_url'].toString().isNotEmpty
                      ? FutureBuilder<ImageProvider>(
                    future: Future.any([
                      _loadImage(article['image_url']),
                      Future.delayed(const Duration(seconds: 5), () => const AssetImage('assets/placeholder.png')),
                    ]),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return Container(
                          color: Colors.grey[300],
                          child: const Center(child: CircularProgressIndicator()),
                        );
                      }
                      if (snapshot.hasError || !snapshot.hasData) {
                        print("Failed to load image: ${article['image_url']}, error: ${snapshot.error}");
                        return Container(
                          color: Colors.grey[300],
                          child: const Icon(
                            Icons.broken_image,
                            size: 100,
                            color: Colors.grey,
                          ),
                        );
                      }
                      return Image(
                        image: snapshot.data!,
                        width: double.infinity,
                        height: double.infinity,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          print("Image error: ${article['image_url']}, error: $error");
                          return Container(
                            color: Colors.grey[300],
                            child: const Icon(
                              Icons.broken_image,
                              size: 100,
                              color: Colors.grey,
                            ),
                          );
                        },
                      );
                    },
                  )
                      : Container(
                    color: Colors.grey[300],
                    child: const Icon(
                      Icons.image_not_supported,
                      size: 100,
                      color: Colors.grey,
                    ),
                  ),
                ),
                // Gradient Overlay at the Bottom
                Positioned(
                  bottom: 0,
                  left: 0,
                  right: 0,
                  child: Container(
                    height: 100,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.transparent,
                          Colors.black.withOpacity(0.7),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Description (Reduced Space with Improved Styling)
          Expanded(
            flex: 4, // Reduced from 1 to 4 (40% of the space)
            child: Container(
              padding: const EdgeInsets.all(12.0),
              color: Colors.white,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    article['title'] ?? 'No Title',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                      color: Colors.black87,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8),
                  Expanded(
                    child: Text(
                      article['description'] ?? 'No Description',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[700],
                        height: 1.4,
                      ),
                      maxLines: 4,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class ArticleWebView extends StatefulWidget {
  final String url;

  const ArticleWebView({super.key, required this.url});

  @override
  _ArticleWebViewState createState() => _ArticleWebViewState();
}

class _ArticleWebViewState extends State<ArticleWebView> {
  late final WebViewController _controller;

  @override
  void initState() {
    super.initState();
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..loadRequest(Uri.parse(widget.url));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Article'),
      ),
      body: WebViewWidget(controller: _controller),
    );
  }
}