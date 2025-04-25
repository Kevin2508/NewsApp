import 'dart:math';

import 'package:flutter/material.dart';
import 'package:newsapp/recommendations.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:newsapp/profile_page.dart';
import 'package:newsapp/notification_page.dart';
import 'package:newsapp/search_page.dart';
import 'package:newsapp/services/api_service.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:shimmer/shimmer.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  String? _selectedCategory = 'For You'; // Changed default to "For You"
  final List<String> _categories = [
    'For You', // Added "For You" as first option
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
                      const Padding(
                        padding: EdgeInsets.only(right: 80.0),
                        child: Text(
                          'Newsly',
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: Colors.black,
                          ),
                        ),
                      ),


                    ],
                  ),
                ),
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

              // News Feed (using updated service for "For You" content)
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
  late Future<List<Map<String, dynamic>>> _articlesFuture;

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
  static Future<void> populateRecommendations() async {
    try {
      final supabase = Supabase.instance.client;

      // Get all news articles
      final articles = await supabase
          .from('news_articles')
          .select('id, title, description, url, image_url, published_at, keyword')
          .order('published_at', ascending: false);

      // Batch process to add to recommendations table
      for (var article in articles) {
        // Calculate a random similarity score
        final random = Random();
        final similarityScore = 0.5 + (random.nextDouble() * 0.5); // Between 0.5 and 1.0
        final popularityScore = random.nextDouble() * 100; // Between 0 and 100

        // Create recommendation entry
        final recommendation = {
          'title': article['title'],
          'description': article['description'],
          'url': article['url'],
          'image_url': article['image_url'],
          'published_at': article['published_at'],
          'category': article['keyword'],
          'similarity_score': similarityScore,
          'popularity_score': popularityScore,
          'source_article_id': article['id'],
          'is_personalized': false,
        };

        // Insert recommendation
        await supabase
            .from('recommendations')
            .upsert(recommendation, onConflict: 'url');
      }

      print("Successfully populated recommendations table");
    } catch (e) {
      print("Error populating recommendations: $e");
    }
  }
  Future<List<Map<String, dynamic>>> _fetchArticles() async {
    final category = widget.selectedCategory ?? 'All';
    try {
      // Use the new getNewsArticles method
      return await ApiService.getNewsArticles(category: category);
    } catch (e) {
      print("Error fetching articles: $e");
      rethrow;
    }
  }

  Future<void> _refreshArticles() async {
    setState(() {
      // Fetch fresh data
      _articlesFuture = _fetchArticles();
    });

    // Wait for the future to complete before returning
    await _articlesFuture;
    return;
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: _articlesFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return _buildLoadingShimmer();
        }
        if (snapshot.hasError) {
          return _buildErrorView(snapshot.error);
        }
        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return _buildEmptyView();
        }

        final articles = snapshot.data!;
        print("Displaying ${articles.length} articles");

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
              return NewsArticle(article: articles[index]);
            },
          ),
        );
      },
    );
  }

  Widget _buildLoadingShimmer() {
    return Shimmer.fromColors(
      baseColor: Colors.grey[300]!,
      highlightColor: Colors.grey[100]!,
      child: ListView.builder(
        physics: const NeverScrollableScrollPhysics(),
        itemCount: 3,
        itemBuilder: (_, __) => Container(
          height: MediaQuery.of(context).size.height * 0.6,
          margin: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    );
  }

  Widget _buildErrorView(dynamic error) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, size: 50, color: Colors.red),
          const SizedBox(height: 10),
          const Text(
            'Oops! Something went wrong.',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 5),
          Text(
            'Error: ${error.toString()}',
            style: const TextStyle(fontSize: 14, color: Colors.grey),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.article_outlined, size: 70, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            'No articles for ${widget.selectedCategory}',
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
        ],
      ),
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
      return const AssetImage('assets/placeholder.png',);
    }
  }

  String _formatPublishedDate(String? dateString) {
    if (dateString == null || dateString.isEmpty) {
      return 'Date unknown';
    }

    try {
      final DateTime now = DateTime.now();
      final DateTime publishedDate = DateTime.parse(dateString);
      final Duration difference = now.difference(publishedDate);

      if (difference.inDays > 365) {
        final int years = (difference.inDays / 365).floor();
        return '$years ${years == 1 ? 'year' : 'years'} ago';
      } else if (difference.inDays > 30) {
        final int months = (difference.inDays / 30).floor();
        return '$months ${months == 1 ? 'month' : 'months'} ago';
      } else if (difference.inDays > 0) {
        return '${difference.inDays} ${difference.inDays == 1 ? 'day' : 'days'} ago';
      } else if (difference.inHours > 0) {
        return '${difference.inHours} ${difference.inHours == 1 ? 'hour' : 'hours'} ago';
      } else if (difference.inMinutes > 0) {
        return '${difference.inMinutes} ${difference.inMinutes == 1 ? 'minute' : 'minutes'} ago';
      } else {
        return 'Just now';
      }
    } catch (e) {
      print("Error formatting date: $e");
      return 'Invalid date';
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
            flex: 6,
            child: Stack(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(12.0),
                  child: article['image_url'] != null && article['image_url'].toString().isNotEmpty
                      ? FutureBuilder<ImageProvider>(
                    future: Future.any([
                      _loadImage(article['image_url']),
                      Future.delayed(const Duration(seconds: 5), () => const AssetImage('assets/placeholder.png',)),
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
                    padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        // Category tag
                        if (article['category'] != null && article['category'].toString().isNotEmpty)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
                            decoration: BoxDecoration(
                              color: const Color(0xFFff425e),
                              borderRadius: BorderRadius.circular(4.0),
                            ),
                            child: Text(
                              article['category'].toString(),
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 12.0,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        const SizedBox(height: 8.0),
                        // Publication date
                        Text(
                          _formatPublishedDate(article['published_at']?.toString()),
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 12.0,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Description (Reduced Space with Improved Styling)
          Expanded(
            flex: 4,
            child: Container(
              padding: const EdgeInsets.all(16.0),
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
                  const SizedBox(height: 8),
                  // Source and author info
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          article['source'] ?? '',
                          style: const TextStyle(
                            color: Color(0xFFff425e),
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (article['author'] != null && article['author'].toString().isNotEmpty)
                        Expanded(
                          child: Text(
                            'By ${article['author']}',
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 12,
                              fontStyle: FontStyle.italic,
                            ),
                            textAlign: TextAlign.right,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  // Action buttons

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
  bool _isLoading = true;
  String _pageTitle = 'Article';

  @override
  void initState() {
    super.initState();
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (String url) {
            setState(() {
              _isLoading = true;
            });
          },
          onPageFinished: (String url) {
            _controller.getTitle().then((title) {
              if (mounted && title != null && title.isNotEmpty) {
                setState(() {
                  _pageTitle = title;
                  _isLoading = false;
                });
              } else {
                setState(() {
                  _isLoading = false;
                });
              }
            });
          },
          onWebResourceError: (WebResourceError error) {
            print('WebView error: ${error.description}');
            setState(() {
              _isLoading = false;
            });
          },
        ),
      )
      ..loadRequest(Uri.parse(widget.url));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          _pageTitle,
          style: const TextStyle(fontSize: 16),
          overflow: TextOverflow.ellipsis,
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              _controller.reload();
            },
          ),
          IconButton(
            icon: const Icon(Icons.open_in_browser),
            onPressed: () async {
              final Uri url = Uri.parse(widget.url);
              if (await canLaunchUrl(url)) {
                await launchUrl(url, mode: LaunchMode.externalApplication);
              }
            },
          ),
        ],
      ),
      body: Stack(
        children: [
          WebViewWidget(controller: _controller),
          if (_isLoading)
            const Center(
              child: CircularProgressIndicator(),
            ),
        ],
      ),
    );
  }
}