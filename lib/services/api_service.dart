import 'package:supabase_flutter/supabase_flutter.dart';

class ApiService {
  static Future<Map<String, dynamic>> getArticleDetails(int articleId) async {
    final supabase = Supabase.instance.client;
    try {
      print("Fetching article details for article_id: $articleId");
      final response = await supabase
          .from('news_articles')
          .select('id, title, url')
          .eq('id', articleId)
          .single();
      print("Article details response: $response");
      return response;
    } catch (e) {
      print("Error fetching article details for ID $articleId: $e");
      return {'id': articleId, 'title': 'Error loading article', 'url': '#'};
    }
  }

  static Future<List<Map<String, dynamic>>> getRecommendations(String category, int topN) async {
    final supabase = Supabase.instance.client;
    try {
      print("Fetching recommendations for category: '$category' with limit: $topN");
      final List<dynamic> data = await supabase
          .from('recommendations')
          .select('*')  // Now fetching full article details
          .eq('category', category.trim())
          .order('similarity_score', ascending: false)
          .limit(topN);
      print("Supabase recommendations response: $data");
      return List<Map<String, dynamic>>.from(data);
    } catch (error) {
      print("Supabase Error for category '$category': $error");
      throw Exception('Failed to fetch recommendations');
    }
  }
}