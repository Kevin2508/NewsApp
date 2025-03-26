import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class GoogleSignInPage extends StatefulWidget {
  const GoogleSignInPage({super.key});

  @override
  _GoogleSignInPageState createState() => _GoogleSignInPageState();
}

class _GoogleSignInPageState extends State<GoogleSignInPage> {
  bool _isBusy = false;
  final SupabaseClient _supabase = Supabase.instance.client;

  @override
  void initState() {
    super.initState();
    _supabase.auth.onAuthStateChange.listen((data) {
      if (data.event == AuthChangeEvent.signedIn && mounted) {
        Navigator.pushReplacementNamed(context, '/home');
      }
    });
  }

  Future<void> _signInWithGoogle() async {
    setState(() => _isBusy = true);
    try {
      await _supabase.auth.signInWithOAuth(
        OAuthProvider.google,
        redirectTo: 'com.example.newsapp://login-callback/',
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Google Sign-In failed: $e')),
      );
    } finally {
      if (mounted) setState(() => _isBusy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Google Sign-In')),
      body: Center(
        child: _isBusy
            ? const CircularProgressIndicator()
            : ElevatedButton.icon(
          style: ElevatedButton.styleFrom(
            minimumSize: const Size(250, 50),
            backgroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(15),
              side: BorderSide(color: Color(0xFFff425e), width: 2),
            ),
          ),
          onPressed: _signInWithGoogle,
          icon: Image.asset(
            'assets/images/google_logo.png',
            height: 24,
            width: 24,
          ),
          label: const Text(
            'Continue with Google',
            style: TextStyle(color: Colors.black, fontSize: 16),
          ),
        ),
      ),
    );
  }
}