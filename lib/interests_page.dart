import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class InterestsPage extends StatefulWidget {
  const InterestsPage({super.key});

  @override
  State<InterestsPage> createState() => _InterestsPageState();
}

class _InterestsPageState extends State<InterestsPage> {
  final Map<String, bool> _selectedCategories = {
    'General': false,
    'Business': false,
    'Technology': false,
    'Entertainment': false,
    'Sports': false,
    'Health': false,
    'Science': false,
    'Politics': false,
    'Environment': false,
    'Travel': false,
    'Food': false,
    'Education': false,
    'Finance': false,
    'World': false,
    'Culture': false,
    'Crime': false,
  };

  Future<void> _updatePreferences(String category, bool isSelected) async {
    final supabase = Supabase.instance.client;
    final userId = supabase.auth.currentUser?.id;

    if (userId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('User not authenticated')),
      );
      return;
    }

    try {
      // Fetch the current categories
      final response = await supabase
          .from('user_preferences')
          .select('categories')
          .eq('user_id', userId)
          .single();

      List<String> currentCategories = List<String>.from(response['categories'] ?? []);

      if (isSelected) {
        if (!currentCategories.contains(category)) {
          currentCategories.add(category);
        }
      } else {
        currentCategories.remove(category);
      }

      // Update the categories in Supabase
      await supabase
          .from('user_preferences')
          .update({'categories': currentCategories})
          .eq('user_id', userId);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error updating preferences: $e')),
      );
    }
  }

  Future<void> _clearAllSelections() async {
    final supabase = Supabase.instance.client;
    final userId = supabase.auth.currentUser?.id;

    if (userId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('User not authenticated')),
      );
      return;
    }

    setState(() {
      _selectedCategories.forEach((key, value) => _selectedCategories[key] = false);
    });

    try {
      await supabase
          .from('user_preferences')
          .update({'categories': []})
          .eq('user_id', userId);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error clearing preferences: $e')),
      );
    }
  }

  Future<void> _saveAndProceed() async {
    final supabase = Supabase.instance.client;
    final userId = supabase.auth.currentUser?.id;

    if (userId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('User not authenticated')),
      );
      return;
    }

    try {
      // Update is_first_time to false so the user isn't redirected here again
      await supabase
          .from('user_preferences')
          .update({'is_first_time': false})
          .eq('user_id', userId);

      // Navigate to HomePage
      if (mounted) {
        Navigator.pushReplacementNamed(context, '/home');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error saving preferences: $e')),
      );
    }
  }

  Widget _buildCategoryButton(String category, IconData icon) {
    return ElevatedButton(
      onPressed: () {
        setState(() {
          _selectedCategories[category] = !_selectedCategories[category]!;
        });
        _updatePreferences(category, _selectedCategories[category]!);
      },
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF474545),
        minimumSize: const Size(140, 140),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
          side: const BorderSide(
            color: Color(0xFFffadb9),
            width: 7,
          ),
        ),
      ),
      child: Stack(
        children: [
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 70, color: const Color(0xFFff425e)),
              const SizedBox(height: 10),
              Text(
                category,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 14.5,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          if (_selectedCategories[category]!)
            const Positioned(
              right: 10,
              top: 10,
              child: Icon(
                Icons.check_circle,
                color: Colors.green,
                size: 24,
              ),
            ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        // Prevent going back to the login page
        return false;
      },
      child: Scaffold(
        backgroundColor: const Color(0xFFff425e),
        body: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(20.0),
                child: Text(
                  'Select News Categories',
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 23,
                  ),
                ),
              ),
              Expanded(
                child: GridView.count(
                  padding: const EdgeInsets.all(20),
                  crossAxisCount: 2,
                  mainAxisSpacing: 15,
                  crossAxisSpacing: 15,
                  childAspectRatio: 1,
                  children: [
                    _buildCategoryButton('General', Icons.public),
                    _buildCategoryButton('Business', Icons.business),
                    _buildCategoryButton('Technology', Icons.science),
                    _buildCategoryButton('Entertainment', Icons.movie),
                    _buildCategoryButton('Sports', Icons.sports),
                    _buildCategoryButton('Health', Icons.health_and_safety),
                    _buildCategoryButton('Science', Icons.biotech),
                    _buildCategoryButton('Politics', Icons.gavel),
                    _buildCategoryButton('Environment', Icons.nature),
                    _buildCategoryButton('Travel', Icons.travel_explore),
                    _buildCategoryButton('Food', Icons.restaurant),
                    _buildCategoryButton('Education', Icons.school),
                    _buildCategoryButton('Finance', Icons.attach_money),
                    _buildCategoryButton('World', Icons.language),
                    _buildCategoryButton('Culture', Icons.museum),
                    _buildCategoryButton('Crime', Icons.security),
                  ],
                ),
              ),
              Container(
                decoration: BoxDecoration(color: Colors.white, boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.2),
                    spreadRadius: 5,
                    blurRadius: 7,
                    offset: const Offset(0, 3),
                  )
                ]),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 30),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(right: 15.0),
                        child: ElevatedButton(
                          onPressed: _clearAllSelections,
                          style: ElevatedButton.styleFrom(
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                            backgroundColor: Colors.white,
                            shadowColor: Colors.black.withOpacity(0.8),
                            elevation: 5,
                            padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
                          ),
                          child: const Text(
                            'Clear All',
                            style: TextStyle(color: Color(0xFFff425e), fontSize: 16),
                          ),
                        ),
                      ),
                      ElevatedButton(
                        onPressed: _saveAndProceed,
                        style: ElevatedButton.styleFrom(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          elevation: 5,
                          backgroundColor: const Color(0xFFff425e),
                          padding: const EdgeInsets.symmetric(horizontal: 45, vertical: 15),
                        ),
                        child: const Text(
                          'Save',
                          style: TextStyle(color: Colors.white, fontSize: 18),
                        ),
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