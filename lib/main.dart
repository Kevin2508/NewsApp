import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:newsapp/google_sign_in_handler.dart';
import 'package:newsapp/google_sign_in_page.dart';
import 'package:newsapp/home_page.dart';
import 'package:newsapp/login_page.dart';
import 'package:newsapp/register_page.dart';
import 'package:newsapp/splash_screen.dart';
import 'package:newsapp/interests_page.dart'; // Import the new InterestsPage
import 'package:supabase_flutter/supabase_flutter.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Supabase
  await Supabase.initialize(
    url: 'https://epbwesqrwnpjexbsrftl.supabase.co',
    anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImVwYndlc3Fyd25wamV4YnNyZnRsIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NDIxMjczMjAsImV4cCI6MjA1NzcwMzMyMH0.de8-fcXPn8CBHoHcRM7j0SPfxuFWOxqm4yftIDyoCQ8', // Replace with your new API key
  );

  // Set preferred orientations
  SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]).then((_) {
    runApp(const MyApp());
  });
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Newsly',
      theme: ThemeData(useMaterial3: true),
      initialRoute: '/splash',
      routes: {
        '/splash': (context) => SplashScreen(),
        '/login': (context) => LoginPage(),
        '/home': (context) => HomePage(),
        '/register': (context) => RegisterPage(),
        '/signin': (context) => const GoogleSignInPage(),
        '/auth': (context) => const GoogleSignInHandler(),
        '/interests': (context) => const InterestsPage(), // Add the new route
      },
      onUnknownRoute: (settings) {
        return MaterialPageRoute(
          builder: (context) => Scaffold(
            body: Center(child: Text('Page not found: ${settings.name}')),
          ),
        );
      },
    );
  }
}