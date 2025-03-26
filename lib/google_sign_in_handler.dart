import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:newsapp/home_page.dart';

class GoogleSignInHandler extends StatefulWidget {
  const GoogleSignInHandler({super.key});

  @override
  _GoogleSignInHandlerState createState() => _GoogleSignInHandlerState();
}

class _GoogleSignInHandlerState extends State<GoogleSignInHandler> {
  @override
  void initState() {
    super.initState();
    _checkAuthState();
  }

  Future<void> _checkAuthState() async {
    final supabase = Supabase.instance.client;
    final session = supabase.auth.currentSession;
    print('Current session in handler: $session'); // Debug log
    if (session != null) {
      Navigator.pushReplacementNamed(context, '/home');
    } else {
      Navigator.pushReplacementNamed(context, '/login');
    }
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(child: CircularProgressIndicator()),
    );
  }
}