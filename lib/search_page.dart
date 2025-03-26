import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:webview_flutter/webview_flutter.dart';

class SearchPage extends StatefulWidget {
  const SearchPage({super.key});

  @override
  _SearchPageState createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  final TextEditingController _searchController = TextEditingController();
  List<Map<String, dynamic>> _searchResults = [];
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _searchArticles(String query) async {
    if (query.isEmpty) {
      setState(() {
        _searchResults = [];
        _errorMessage = null;
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // Query Supabase for articles where title, description, or keyword contains the search term
      final response = await Supabase.instance.client
          .from('news_articles')
          .select()
          .or(
        'title.ilike.%$query%,description.ilike.%$query%,keyword.ilike.%$query%',
      )
          .order('published_at', ascending: false);

      setState(() {
        _searchResults = response as List<Map<String, dynamic>>;
        _isLoading = false;
      });

      print("Search results for '$query': ${_searchResults.length} articles found");
    } catch (e) {
      print("Error searching articles: $e");
      setState(() {
        _errorMessage = 'Failed to search articles. Please try again.';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Search News'),
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFFff425e)),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Search Bar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 10.0),
              child: TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: 'Search for news...',
                  prefixIcon: const Icon(Icons.search, color: Color(0xFFff425e)),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12.0),
                    borderSide: const BorderSide(color: Colors.grey),
                  ),
                  filled: true,
                  fillColor: Colors.grey[100],
                ),
                onChanged: (value) {
                  _searchArticles(value.trim());
                },
              ),
            ),
            // Search Results
            Expanded(
              child: _isLoading
                  ? const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(),
                    SizedBox(height: 10),
                    Text('Searching...'),
                  ],
                ),
              )
                  : _errorMessage != null
                  ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.error_outline, size: 50, color: Colors.red),
                    const SizedBox(height: 10),
                    Text(
                      _errorMessage!,
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              )
                  : _searchResults.isEmpty
                  ? const Center(child: Text('No results found'))
                  : ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                itemCount: _searchResults.length,
                itemBuilder: (context, index) {
                  final article = _searchResults[index];
                  return SearchResultItem(article: article);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class SearchResultItem extends StatelessWidget {
  final Map<String, dynamic> article;

  const SearchResultItem({super.key, required this.article});

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
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8.0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Article Image (Thumbnail)
            article['image_url'] != null && article['image_url'].toString().isNotEmpty
                ? FutureBuilder<ImageProvider>(
              future: Future.any([
                _loadImage(article['image_url']),
                Future.delayed(const Duration(seconds: 5), () => const AssetImage('assets/placeholder.png')),
              ]),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Container(
                    width: 100,
                    height: 100,
                    color: Colors.grey[300],
                    child: const Center(child: CircularProgressIndicator()),
                  );
                }
                if (snapshot.hasError || !snapshot.hasData) {
                  print("Failed to load image: ${article['image_url']}, error: ${snapshot.error}");
                  return Container(
                    width: 100,
                    height: 100,
                    color: Colors.grey[300],
                    child: const Icon(
                      Icons.broken_image,
                      size: 50,
                      color: Colors.grey,
                    ),
                  );
                }
                return ClipRRect(
                  borderRadius: BorderRadius.circular(8.0),
                  child: Image(
                    image: snapshot.data!,
                    width: 100,
                    height: 100,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      print("Image error: ${article['image_url']}, error: $error");
                      return Container(
                        width: 100,
                        height: 100,
                        color: Colors.grey[300],
                        child: const Icon(
                          Icons.broken_image,
                          size: 50,
                          color: Colors.grey,
                        ),
                      );
                    },
                  ),
                );
              },
            )
                : Container(
              width: 100,
              height: 100,
              color: Colors.grey[300],
              child: const Icon(
                Icons.image_not_supported,
                size: 50,
                color: Colors.grey,
              ),
            ),
            const SizedBox(width: 16.0),
            // Article Title and Description
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    article['title'] ?? 'No Title',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: Colors.black87,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8.0),
                  Text(
                    article['description'] ?? 'No Description',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[700],
                    ),
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
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