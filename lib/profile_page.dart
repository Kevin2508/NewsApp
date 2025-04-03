import 'package:flutter/material.dart';
import 'package:newsapp/newsletter_screen.dart';
import 'package:newsapp/email_test_screen.dart';

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  void _logout(BuildContext context) {
    // Perform logout logic here (clear user session, etc.)
    // For now, we'll just navigate back to the login screen
    Navigator.pushReplacementNamed(context, '/login');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Profile"),
        backgroundColor: Colors.redAccent, // Customize the app bar color
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const CircleAvatar(
              radius: 50,
              backgroundImage: AssetImage("assets/profile_placeholder.png"), // Add a user image
            ),
            const SizedBox(height: 16),
            const Text(
              "John Doe",
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const Text("johndoe@example.com", style: TextStyle(fontSize: 16, color: Colors.grey)),
            const SizedBox(height: 24),
            ListTile(
              leading: const Icon(Icons.person),
              title: const Text("Edit Profile"),
              onTap: () {
                // Navigate to edit profile page (if you have one)
              },
            ),
            ListTile(
              leading: const Icon(Icons.settings),
              title: const Text("Settings"),
              onTap: () {
                // Navigate to settings page (if needed)
              },
            ),
            // Find the Column or ListView where you list user options, and add:
            ListTile(
              leading: const Icon(Icons.email_outlined, color: Color(0xFFff425e)),
              title: const Text('Newsletter'),
              subtitle: const Text('Subscribe to email updates'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const NewsletterScreen()),
                );
              },
            ),
          // Add this to your profile screen or a developer options screen
          ListTile(
            leading: const Icon(Icons.email),
            title: const Text('Test Email Service'),
            subtitle: const Text('Verify MailerSend integration'),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const EmailTestScreen()),
              );
            },
          ),

// Add the import
            const Spacer(),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => _logout(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red, // Logout button color
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
                child: const Text("Logout", style: TextStyle(fontSize: 18,color: Colors.white)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
