import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

class NewsFeed extends StatefulWidget {
  @override
  _NewsFeedState createState() => _NewsFeedState();
}

class _NewsFeedState extends State<NewsFeed> {
  final SupabaseClient supabase = Supabase.instance.client;
  List<Map<String, dynamic>> newsList = [];

  @override
  void initState() {
    super.initState();
    fetchNews();
  }

  Future<void> fetchNews() async {
    try {
      final response = await supabase.from('news').select().limit(20);
      setState(() {
        newsList = List<Map<String, dynamic>>.from(response);
      });
    } catch (e) {
      print('Error fetching news: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error fetching news: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      itemCount: newsList.length,
      itemBuilder: (context, index) {
        final news = newsList[index];
        return Card(
          margin: EdgeInsets.all(8.0),
          child: ListTile(
            leading: news['urlToImage'] != null && news['urlToImage'].isNotEmpty
                ? Image.network(news['urlToImage'], width: 100, height: 100, fit: BoxFit.cover)
                : null,
            title: Text(news['title'] ?? 'No Title'),
            subtitle: Text(news['published_at']?.toString() ?? ''),
            onTap: () async {
              if (await canLaunch(news['url'])) {
                await launch(news['url']);
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Could not launch ${news['url']}')),
                );
              }
            },
          ),
        );
      },
    );
  }
}