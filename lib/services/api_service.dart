import 'package:supabase_flutter/supabase_flutter.dart';

class ApiService {
  static final _supabase = Supabase.instance.client;

  // Get news articles for the homepage
  static Future<List<Map<String, dynamic>>> getNewsArticles({
    required String category,
    int? limit = 50,
  }) async {
    try {
      print("Fetching news for category: '$category'");
      final supabase = Supabase.instance.client;

      // For "For You" category, use personalized recommendations
      if (category.trim().toLowerCase() == 'for you') {
        return await getPersonalizedRecommendations(limit: limit ?? 50);
      }

      // Start building the query
      var query = supabase.from('news_articles').select('*');

      // Only apply category filter if not "All"
      if (category.trim().toLowerCase() != 'all') {
        query = query.eq('keyword', category.trim());
      }

      // Apply randomization for all queries to show different news on each refresh
      var response = await query.limit(200);  // Get a larger pool of articles
      final articles = List<Map<String, dynamic>>.from(response);

      // Shuffle the articles for randomness
      articles.shuffle();

      // Take only the number we need
      final limitedArticles = articles.take(limit ?? 50).toList();

      print("Fetched ${limitedArticles.length} random news articles for $category");
      return _deduplicateArticles(limitedArticles);
    } catch (error) {
      print("Error fetching news articles: $error");
      throw Exception('Failed to fetch news articles: $error');
    }
  }

  // Get personalized "For You" news articles based on user preferences
  static Future<List<Map<String, dynamic>>> getForYouNewsArticles({int limit = 50}) async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) {
        throw Exception('User not authenticated');
      }

      // Get user preferences
      final userPrefsResponse = await _supabase
          .from('user_preferences')
          .select('categories')
          .eq('user_id', user.id)
          .maybeSingle();

      // Extract user preferred categories
      List<dynamic> userCategories = [];
      if (userPrefsResponse != null && userPrefsResponse['categories'] != null) {
        userCategories = userPrefsResponse['categories'];
      }

      // If user has no preferences, return popular articles
      if (userCategories.isEmpty) {
        print("No user preferences found, returning popular articles");
        final data = await _supabase
            .from('news_articles')
            .select('*')
            .order('popularity_score', ascending: false)
            .limit(limit);

        return _deduplicateArticles(data);
      }

      print("Found user preferences: $userCategories");

      // For each category, get some articles
      List<Map<String, dynamic>> personalizedArticles = [];

      // Limit per category to ensure diversity
      int limitPerCategory = limit ~/ userCategories.length;
      if (limitPerCategory < 3) limitPerCategory = 3;

      // Fetch articles for each preferred category
      for (var category in userCategories) {
        final categoryArticles = await _supabase
            .from('news_articles')
            .select('*')
            .eq('keyword', category.toString())
            .order('published_at', ascending: false)
            .limit(limitPerCategory);

        personalizedArticles.addAll(List<Map<String, dynamic>>.from(categoryArticles));
      }

      // If we didn't get enough articles, backfill with some popular ones
      if (personalizedArticles.length < limit) {
        final additionalCount = limit - personalizedArticles.length;
        final additionalArticles = await _supabase
            .from('news_articles')
            .select('*')
            .order('popularity_score', ascending: false)
            .limit(additionalCount);

        personalizedArticles.addAll(List<Map<String, dynamic>>.from(additionalArticles));
      }

      print("Fetched ${personalizedArticles.length} personalized articles");

      // Deduplicate, shuffle to mix categories, and limit to requested count
      final result = _deduplicateArticles(personalizedArticles);
      result.shuffle(); // Mix up categories for better discovery

      return result.take(limit).toList();
    } catch (error) {
      print("Error fetching personalized articles: $error");
      throw Exception('Failed to fetch personalized articles: $error');
    }
  }

  // Get recommendations for a specific category
  static Future<List<Map<String, dynamic>>> getRecommendations(String category, {int limit = 50}) async {
    try {
      print("Fetching recommendations for category: '$category'");

      // For "For You" category, use personalized recommendations
      if (category.trim().toLowerCase() == 'for you') {
        return await getPersonalizedRecommendations(limit: limit);
      }

      // Build query based on category
      var query = _supabase.from('recommendations').select('*');

      // Only apply category filter if not "All"
      if (category.trim().toLowerCase() != 'all') {
        query = query.eq('category', category.trim());
      }

      // Apply sorting and limit
      var orderedQuery = query.order('similarity_score', ascending: false);

      List<dynamic> response;
      if (limit > 0) {
        response = await orderedQuery.limit(limit);
      } else {
        response = await orderedQuery;
      }

      // If we got no results and this is not "All", try the "All" category
      if (response.isEmpty && category.trim().toLowerCase() != 'all') {
        print("No recommendations found for $category, falling back to All");
        response = await _supabase
            .from('recommendations')
            .select('*')
            .order('similarity_score', ascending: false)
            .limit(limit);
      }

      // If still empty, try to get news articles instead
      if (response.isEmpty) {
        print("No recommendations found, fetching news articles instead");
        return await getNewsArticles(category: category, limit: limit);
      }

      // Convert and deduplicate
      final List<Map<String, dynamic>> recommendations = _deduplicateArticles(response);

      print("Fetched ${recommendations.length} recommendations for $category category");
      return recommendations;
    } catch (error) {
      print("Error fetching recommendations for '$category': $error");
      throw Exception('Failed to fetch recommendations: $error');
    }
  }

  // Get personalized recommendations based on user preferences
  static Future<List<Map<String, dynamic>>> getPersonalizedRecommendations({int? limit = 50}) async {
    try {
      final supabase = Supabase.instance.client;
      final user = supabase.auth.currentUser;

      if (user == null) {
        throw Exception('User not authenticated');
      }

      // Get user preferences
      final userPrefs = await supabase
          .from('user_preferences')
          .select('categories')
          .eq('user_id', user.id)
          .maybeSingle();

      List<dynamic> categories = [];
      if (userPrefs != null && userPrefs['categories'] != null) {
        categories = userPrefs['categories'];
      }

      List<Map<String, dynamic>> articles = [];

      // If user has preferences, get articles from those categories
      if (categories.isNotEmpty) {
        // Get some articles from each preferred category
        for (var category in categories) {
          final categoryArticles = await supabase
              .from('news_articles')
              .select()
              .eq('keyword', category.toString())
              .limit(limit! ~/ categories.length + 5);

          articles.addAll(List<Map<String, dynamic>>.from(categoryArticles));
        }
      }

      // If we didn't get enough articles, add random ones
      if (articles.length < (limit ?? 50)) {
        final randomArticles = await supabase
            .from('news_articles')
            .select()
            .limit((limit ?? 50) - articles.length);

        articles.addAll(List<Map<String, dynamic>>.from(randomArticles));
      }

      // Shuffle to randomize the order
      articles.shuffle();

      return _deduplicateArticles(articles).take(limit ?? 50).toList();
    } catch (error) {
      print("Error fetching personalized recommendations: $error");
      throw Exception('Failed to fetch personalized recommendations: $error');
    }
  }
  // Helper function to remove duplicates
  static List<Map<String, dynamic>> _deduplicateArticles(List<dynamic> articles) {
    final seen = <String>{};
    final result = <Map<String, dynamic>>[];

    for (var article in articles) {
      final Map<String, dynamic> articleMap = article;
      // Use title+url as a unique key
      final String title = articleMap['title']?.toString() ?? '';
      final String url = articleMap['url']?.toString() ?? '';
      final String key = "$title-$url";

      if (key.isNotEmpty && !seen.contains(key)) {
        seen.add(key);
        result.add(articleMap);
      }
    }

    return result;
  }
}