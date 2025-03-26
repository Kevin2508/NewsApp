import 'package:newsapp/home_page.dart';
import 'package:newsapp/login_page.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '';
class SplashScreen extends StatefulWidget {
  final Widget? child;

  const SplashScreen({super.key, this.child});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();

    Future.delayed(
      const Duration(seconds: 5),
          () async {
        // Check Supabase authentication
        final supabase = Supabase.instance.client;
        final user = supabase.auth.currentUser;

        if (user != null) {
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (context) => const HomePage()),
                (route) => false,
          );
        } else {
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (context) =>  LoginPage()),
                (route) => false,
          );
        }
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Container(
            height: double.infinity,
            width: double.infinity,
            color: Colors.white,
          ),
          Align(
            alignment: const Alignment(0, -0.2),
            child: Container(
              height: 273,
              width: 303,
              child: Image.asset(
                'assets/images/Logo.png',
              ),
            ),
          ),
          Align(
            alignment: const Alignment(0, 0.3),
            child: Text.rich(
              TextSpan(
                children: [
                  TextSpan(
                    text: 'N',
                    style: TextStyle(
                      color: Color(0xFFff425e),
                      fontSize: 55,
                      fontFamily: 'FFClanProRegular',
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  TextSpan(
                    text: 'ewsly',
                    style: TextStyle(
                      color: Color(0xFF474545),
                      fontSize: 55,
                      fontFamily: 'FFClanProRegular',
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ),
          Align(
            alignment: const Alignment(0, 0.43),
            child: Text(
              'News That Fits You',
              style: TextStyle(
                fontFamily: 'constan.ttf',
                fontSize: 18,
              ),
            ),
          ),
        ],
      ),
    );
  }
}