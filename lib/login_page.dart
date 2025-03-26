import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:newsapp/register_page.dart';
import 'package:newsapp/interests_page.dart'; // Import the new InterestsPage

class BottomCurveClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    return Path()
      ..lineTo(0, size.height * 0.7)
      ..quadraticBezierTo(size.width / 2, size.height, size.width, size.height * 0.7)
      ..lineTo(size.width, 0)
      ..close();
  }

  @override
  bool shouldReclip(CustomClipper<Path> oldClipper) => false;
}

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  _LoginPageState createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  late final StreamSubscription<AuthState> _authSubscription;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _setupAuthListener();
    _checkAuthState();
  }

  void _setupAuthListener() {
    final supabase = Supabase.instance.client;
    _authSubscription = supabase.auth.onAuthStateChange.listen(
          (data) {
        final AuthChangeEvent event = data.event;
        final Session? session = data.session;
        if (event == AuthChangeEvent.signedIn && mounted) {
          _handleSuccessfulSignIn(session!.user.id);
        }
      },
      onError: (error) {
        if (mounted) {
          _showError('Authentication error: $error');
        }
      },
    );
  }

  Future<void> _checkAuthState() async {
    final supabase = Supabase.instance.client;
    final session = supabase.auth.currentSession;
    if (session != null && mounted) {
      await _handleSuccessfulSignIn(session.user.id);
    }
  }

  Future<void> _handleSuccessfulSignIn(String userId) async {
    try {
      final supabase = Supabase.instance.client;
      // Check if the user has preferences in the user_preferences table
      final response = await supabase
          .from('user_preferences')
          .select()
          .eq('user_id', userId)
          .maybeSingle();

      if (response == null) {
        // No preferences found, insert a default record and redirect to InterestsPage
        await supabase.from('user_preferences').insert({
          'user_id': userId,
          'categories': [],
          'is_first_time': true,
        });
        if (mounted) {
          Navigator.pushReplacementNamed(context, '/interests');
        }
      } else {
        // Preferences exist, check if it's the user's first time
        final isFirstTime = response['is_first_time'] as bool? ?? true;
        if (isFirstTime) {
          if (mounted) {
            Navigator.pushReplacementNamed(context, '/interests');
          }
        } else {
          if (mounted) {
            Navigator.pushReplacementNamed(context, '/home');
          }
        }
      }
    } catch (e) {
      if (mounted) {
        _showError('Error checking user preferences: $e');
      }
    }
  }

  Future<void> _handleEmailSignIn() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();

    if (email.isEmpty || password.isEmpty) {
      _showError('Please fill in all fields');
      return;
    }

    setState(() => _isLoading = true);
    try {
      final supabase = Supabase.instance.client;
      await supabase.auth.signInWithPassword(email: email, password: password);
    } on AuthException catch (e) {
      _showError('Login failed: ${e.message}');
    } catch (e) {
      _showError('An unexpected error occurred: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _handleGoogleSignIn() async {
    setState(() => _isLoading = true);
    try {
      final supabase = Supabase.instance.client;
      await supabase.auth.signInWithOAuth(
        OAuthProvider.google,
        redirectTo: 'com.example.newsapp://login-callback/',
      );
    } on AuthException catch (e) {
      _showError('Google Sign-In failed: ${e.message}');
    } catch (e) {
      _showError('An unexpected error occurred: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showError(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Stack(
          children: [
            SingleChildScrollView(
              child: OrientationBuilder(
                builder: (context, orientation) {
                  return Column(
                    children: [
                      ClipPath(
                        clipper: BottomCurveClipper(),
                        child: Container(
                          height: MediaQuery.of(context).size.height * 0.4,
                          width: double.infinity,
                          color: const Color(0xffffffff),
                          child: Center(
                            child: Image.asset(
                              'assets/images/Logo.png',
                              height: 240,
                              width: 240,
                              errorBuilder: (context, error, stackTrace) {
                                return const Icon(Icons.error, color: Colors.white);
                              },
                            ),
                          ),
                        ),
                      ),
                      SizedBox(height: MediaQuery.of(context).size.height * 0.03),
                      Padding(
                        padding: EdgeInsets.symmetric(
                          horizontal: MediaQuery.of(context).size.width * 0.05,
                        ),
                        child: Column(
                          children: [
                            TextField(
                              controller: _emailController,
                              decoration: InputDecoration(
                                labelText: 'Email Address',
                                labelStyle: const TextStyle(color: Colors.black),
                                enabledBorder: OutlineInputBorder(
                                  borderSide: const BorderSide(color: Colors.black),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderSide: const BorderSide(color: Color(0xFFff425e)),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                              ),
                              style: const TextStyle(color: Colors.black),
                              keyboardType: TextInputType.emailAddress,
                              enabled: !_isLoading,
                            ),
                            SizedBox(height: MediaQuery.of(context).size.height * 0.02),
                            TextField(
                              controller: _passwordController,
                              obscureText: true,
                              decoration: InputDecoration(
                                labelText: 'Password',
                                labelStyle: const TextStyle(color: Colors.black),
                                enabledBorder: OutlineInputBorder(
                                  borderSide: const BorderSide(color: Colors.black),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderSide: const BorderSide(color: Color(0xFFff425e)),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                              ),
                              style: const TextStyle(color: Colors.black),
                              enabled: !_isLoading,
                            ),
                            SizedBox(height: MediaQuery.of(context).size.height * 0.02),
                            ElevatedButton(
                              onPressed: _isLoading ? null : _handleEmailSignIn,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFFffffff),
                                minimumSize: Size(double.infinity, MediaQuery.of(context).size.height * 0.07),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(32)),
                              ),
                              child: _isLoading
                                  ? const CircularProgressIndicator(color: Colors.white)
                                  : const Text(
                                'Sign In',
                                style: TextStyle(
                                    color: Colors.black, fontSize: 18, fontWeight: FontWeight.bold),
                              ),
                            ),
                            SizedBox(height: MediaQuery.of(context).size.height * 0.02),
                            ElevatedButton.icon(
                              onPressed: _isLoading ? null : _handleGoogleSignIn,
                              icon: const FaIcon(FontAwesomeIcons.google, color: Colors.white, size: 20),
                              label: _isLoading
                                  ? const CircularProgressIndicator(color: Colors.white)
                                  : const Text(
                                'Continue with Google',
                                style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFFff425e),
                                minimumSize: Size(double.infinity, MediaQuery.of(context).size.height * 0.07),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(32)),
                              ),
                            ),
                            SizedBox(height: MediaQuery.of(context).size.height * 0.05),
                            RichText(
                              text: TextSpan(
                                text: 'Don\'t have an account? ',
                                style: const TextStyle(color: Colors.black, fontSize: 16, fontFamily: 'Urbanist'),
                                children: <TextSpan>[
                                  TextSpan(
                                    text: 'Sign Up',
                                    style: const TextStyle(
                                      fontFamily: 'Urbanist',
                                      color: Color(0xFFff425e),
                                      decoration: TextDecoration.underline,
                                    ),
                                    recognizer: TapGestureRecognizer()
                                      ..onTap = () {
                                        if (!_isLoading) {
                                          Navigator.push(
                                            context,
                                            MaterialPageRoute(builder: (context) => const RegisterPage()),
                                          );
                                        }
                                      },
                                  ),
                                ],
                              ),
                            ),
                            SizedBox(height: MediaQuery.of(context).size.height * 0.01),
                            RichText(
                              text: TextSpan(
                                text: 'Forgot Password?',
                                style: const TextStyle(
                                  fontFamily: 'Urbanist',
                                  color: Color(0xFFff425e),
                                  decoration: TextDecoration.underline,
                                  fontSize: 16,
                                ),
                                recognizer: TapGestureRecognizer()
                                  ..onTap = () {
                                    if (!_isLoading) {
                                      _showError('Forgot Password feature not implemented yet.');
                                    }
                                  },
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
            if (_isLoading)
              Container(
                color: Colors.black.withOpacity(0.5),
                child: const Center(child: CircularProgressIndicator()),
              ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _authSubscription.cancel();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }
}