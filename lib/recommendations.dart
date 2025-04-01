import 'package:flutter/material.dart';
import 'package:newsapp/services/api_service.dart';
import 'package:url_launcher/url_launcher.dart';

class RecommendationsPage extends StatefulWidget {
  const RecommendationsPage({super.key});

  @override
  _RecommendationsPageState createState() => _RecommendationsPageState();
}

class _RecommendationsPageState extends State<RecommendationsPage> {
  List<Map<String, dynamic>> _recommendations = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final String selectedCategory =
          ModalRoute.of(context)?.settings.arguments as String? ?? 'General';
      print("Initializing with category: $selectedCategory");
      _fetchRecommendations(selectedCategory);
    });
  }

  Future<void> _fetchRecommendations(String category) async {
    try {
      final recommendations = await ApiService.getRecommendations(category, 5);
      print("Fetched recommendations count: ${recommendations.length}");

      setState(() {
        _recommendations = recommendations;
        _isLoading = false;
      });
    } catch (e) {
      print("Error in fetchRecommendations: $e");
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to load recommendations: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    print("Building UI - isLoading: $_isLoading, recommendations count: ${_recommendations.length}");
    return Scaffold(
      appBar: AppBar(title: const Text('Recommendations')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _recommendations.isEmpty
            ? const Center(child: Text("No recommendations found!"))
            : ListView.builder(
          itemCount: _recommendations.length,
          itemBuilder: (context, index) {
            final recommendation = _recommendations[index];
            print("Rendering item $index: ${recommendation['title']}");
            return ListTile(
              title: Text(recommendation['title'] ?? 'No Title'),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(recommendation['description'] ?? ''),
                  Text('Author: ${recommendation['author'] ?? 'Unknown'}'),
                  Text('Published: ${recommendation['published_at'] ?? ''}'),
                ],
              ),
              leading: recommendation['image_url'] != null && recommendation['image_url'].isNotEmpty
                  ? Image.network(recommendation['image_url'], width: 50, height: 50, fit: BoxFit.cover)
                  : null,
              onTap: () {
                launchUrl(Uri.parse(recommendation['url']));
              },
            );

          },
        ),
      ),
    );
  }
}