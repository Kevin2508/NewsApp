// lib/newsletter_screen.dart
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:newsapp/newsletter_service.dart';

class NewsletterScreen extends StatefulWidget {
  const NewsletterScreen({super.key});

  @override
  _NewsletterScreenState createState() => _NewsletterScreenState();
}

class _NewsletterScreenState extends State<NewsletterScreen> {
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;
  bool _isSending = false;
  bool _isSubscribed = false;
  final List<String> _selectedCategories = [];
  int _emailsPerDay = 1; // Default to 1 email per day
  final TextEditingController _emailController = TextEditingController();

  final List<String> _availableCategories = [
    'General', 'Business', 'Technology', 'Entertainment', 'Sports',
    'Health', 'Science', 'Politics', 'Environment', 'Travel',
    'Food', 'Education', 'Finance', 'World', 'Culture'
  ];

  final _supabase = Supabase.instance.client;

  @override
  void initState() {
    super.initState();
    _loadPreferences();

    // Set default email from authenticated user
    final user = _supabase.auth.currentUser;
    if (user?.email != null) {
      _emailController.text = user!.email!;
    }
  }

  Future<void> _loadPreferences() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final user = _supabase.auth.currentUser;
      if (user == null) return;

      final response = await _supabase
          .from('newsletter_subscriptions')
          .select()
          .eq('user_id', user.id)
          .maybeSingle();

      if (response != null) {
        setState(() {
          _isSubscribed = response['is_active'] ?? false;
          _emailController.text = response['email'] ?? _emailController.text;
          _emailsPerDay = response['emails_per_day'] ?? 1;

          if (response['categories'] != null) {
            _selectedCategories.clear();
            for (var category in response['categories']) {
              _selectedCategories.add(category.toString());
            }
          }
        });
      }
    } catch (e) {
      print('Error loading newsletter preferences: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _savePreferences() async {
    if (!_formKey.currentState!.validate() || _selectedCategories.isEmpty) {
      if (_selectedCategories.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Please select at least one category'))
        );
      }
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final user = _supabase.auth.currentUser;
      if (user == null) throw Exception('User not authenticated');

      final existing = await _supabase
          .from('newsletter_subscriptions')
          .select()
          .eq('user_id', user.id)
          .maybeSingle();

      if (existing != null) {
        await _supabase
            .from('newsletter_subscriptions')
            .update({
          'email': _emailController.text,
          'categories': _selectedCategories,
          'emails_per_day': _emailsPerDay,
          'is_active': true,
          'updated_at': DateTime.now().toIso8601String(),
        })
            .eq('user_id', user.id);
      } else {
        await _supabase
            .from('newsletter_subscriptions')
            .insert({
          'user_id': user.id,
          'email': _emailController.text,
          'categories': _selectedCategories,
          'emails_per_day': _emailsPerDay,
          'is_active': true,
          'created_at': DateTime.now().toIso8601String(),
          'updated_at': DateTime.now().toIso8601String(),
          'last_email_count': 0,
        });
      }

      setState(() {
        _isSubscribed = true;
      });

      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Newsletter preferences saved!'))
      );
    } catch (e) {
      print('Error saving newsletter preferences: $e');
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: ${e.toString()}'))
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _unsubscribe() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final user = _supabase.auth.currentUser;
      if (user == null) throw Exception('User not authenticated');

      await _supabase
          .from('newsletter_subscriptions')
          .update({'is_active': false})
          .eq('user_id', user.id);

      setState(() {
        _isSubscribed = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Successfully unsubscribed'))
      );
    } catch (e) {
      print('Error unsubscribing: $e');
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: ${e.toString()}'))
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _sendTestNewsletter() async {
    setState(() {
      _isSending = true;
    });

    try {
      final result = await NewsletterService.sendTestNewsletter(
        email: _emailController.text,
        categories: _selectedCategories,
        emailNumber: 1,
      );

      if (result) {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Test newsletter sent successfully!'))
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Failed to send test newsletter'))
        );
      }
    } catch (e) {
      print('Error sending test newsletter: $e');
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: ${e.toString()}'))
      );
    } finally {
      setState(() {
        _isSending = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Newsletter'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFFff425e)))
          : SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Banner
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFFff425e), Color(0xFFff8495)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.email_outlined, color: Colors.white, size: 32),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _isSubscribed ? 'You are subscribed!' : 'Subscribe to Newsly',
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          Text(
                            _isSubscribed
                                ? 'Edit your newsletter preferences below'
                                : 'Get the latest news in your inbox',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // Email field
              const Text(
                'Email Address',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                decoration: InputDecoration(
                  hintText: 'your.email@example.com',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                  filled: true,
                  fillColor: Colors.grey[100],
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter your email address';
                  }
                  if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
                    return 'Please enter a valid email address';
                  }
                  return null;
                },
              ),

              const SizedBox(height: 24),

              // Emails per day selector
              const Text(
                'Emails Per Day',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              const SizedBox(height: 4),
              const Text(
                'Choose how many news updates you want to receive each day',
                style: TextStyle(fontSize: 12, color: Colors.grey),
              ),
              const SizedBox(height: 8),

              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey[300]!),
                  borderRadius: BorderRadius.circular(8),
                  color: Colors.grey[100],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          '$_emailsPerDay ${_emailsPerDay == 1 ? 'email' : 'emails'} per day',
                          style: const TextStyle(fontSize: 16),
                        ),
                        Row(
                          children: [
                            // Minus button
                            IconButton(
                              onPressed: _emailsPerDay > 1
                                  ? () {
                                setState(() {
                                  _emailsPerDay--;
                                });
                              }
                                  : null,
                              icon: Icon(
                                Icons.remove_circle,
                                color: _emailsPerDay > 1 ? const Color(0xFFff425e) : Colors.grey,
                              ),
                            ),

                            // Plus button
                            IconButton(
                              onPressed: _emailsPerDay < 10
                                  ? () {
                                setState(() {
                                  _emailsPerDay++;
                                });
                              }
                                  : null,
                              icon: Icon(
                                Icons.add_circle,
                                color: _emailsPerDay < 10 ? const Color(0xFFff425e) : Colors.grey,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),

                    // Show slider
                    Slider(
                      value: _emailsPerDay.toDouble(),
                      min: 1,
                      max: 10,
                      divisions: 9,
                      activeColor: const Color(0xFFff425e),
                      inactiveColor: Colors.grey[300],
                      label: _emailsPerDay.toString(),
                      onChanged: (value) {
                        setState(() {
                          _emailsPerDay = value.toInt();
                        });
                      },
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // Categories
              const Text(
                'News Categories',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _availableCategories.map((category) {
                  final isSelected = _selectedCategories.contains(category);
                  return FilterChip(
                    label: Text(category),
                    selected: isSelected,
                    selectedColor: const Color(0xFFff425e).withOpacity(0.2),
                    backgroundColor: Colors.grey[100],
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                      side: BorderSide(
                        color: isSelected ? const Color(0xFFff425e) : Colors.grey[300]!,
                      ),
                    ),
                    onSelected: (selected) {
                      setState(() {
                        if (selected) {
                          _selectedCategories.add(category);
                        } else {
                          _selectedCategories.remove(category);
                        }
                      });
                    },
                  );
                }).toList(),
              ),

              const SizedBox(height: 32),

              // Subscribe button
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _savePreferences,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFff425e),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: Text(_isSubscribed ? 'Update Subscription' : 'Subscribe Now'),
                ),
              ),

              // Unsubscribe option
              if (_isSubscribed)
                Padding(
                  padding: const EdgeInsets.only(top: 16),
                  child: Column(
                    children: [
                      Center(
                        child: TextButton(
                          onPressed: _isLoading ? null : _unsubscribe,
                          child: const Text(
                            'Unsubscribe from newsletter',
                            style: TextStyle(color: Colors.grey),
                          ),
                        ),
                      ),

                      const SizedBox(height: 16),
                      const Divider(),
                      const SizedBox(height: 16),

                      // Test newsletter option
                      Row(
                        children: [
                          const Expanded(
                            child: Text(
                              'Send yourself a test newsletter',
                              style: TextStyle(fontSize: 14),
                            ),
                          ),
                          const SizedBox(width: 16),
                          ElevatedButton(
                            onPressed: _isSending ? null : _sendTestNewsletter,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.grey[300],
                              foregroundColor: Colors.black87,
                            ),
                            child: _isSending
                                ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(strokeWidth: 2)
                            )
                                : const Text('Send Test'),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

// Don't forget to add the import
