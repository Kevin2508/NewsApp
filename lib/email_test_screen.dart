// lib/email_test_screen.dart
import 'package:flutter/material.dart';
import 'package:newsapp/newsletter_service.dart';

class EmailTestScreen extends StatefulWidget {
  const EmailTestScreen({super.key});

  @override
  _EmailTestScreenState createState() => _EmailTestScreenState();
}

class _EmailTestScreenState extends State<EmailTestScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  bool _isSending = false;
  String _resultMessage = '';
  bool _isSuccess = false;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _sendTestEmail() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isSending = true;
      _resultMessage = '';
    });

    try {
      final result = await NewsletterService.sendEmailWithMailerSend(
        toEmail: _emailController.text,
        toName: 'Test User',
        subject: 'MailerSend Test Email',
        htmlContent: '''
          <div style="font-family: Arial, sans-serif; max-width: 600px; margin: 0 auto;">
            <div style="background-color: #ff425e; padding: 20px; text-align: center; color: white;">
              <h1>Test Email from Newsly</h1>
            </div>
            <div style="padding: 20px;">
              <p>Hello,</p>
              <p>This is a test email sent from the Newsly app to verify that the MailerSend integration is working correctly.</p>
              <p>If you received this email, your email service is working properly!</p>
              <p>Time sent: ${DateTime.now().toString()}</p>
            </div>
          </div>
        ''',
      );

      setState(() {
        _isSending = false;
        _isSuccess = result;
        _resultMessage = result
            ? 'Email sent successfully! Check your inbox.'
            : 'Failed to send email. Check the logs for more details.';
      });
    } catch (e) {
      setState(() {
        _isSending = false;
        _isSuccess = false;
        _resultMessage = 'Error: $e';
      });
      print('Error testing email service: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Test Email Service'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Test your MailerSend integration',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              const Text(
                'Send a test email to verify that your email service is working correctly.',
                style: TextStyle(color: Colors.grey),
              ),
              const SizedBox(height: 24),

              TextFormField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(
                  labelText: 'Recipient Email',
                  hintText: 'Enter your email address',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.email),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter an email address';
                  }
                  if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
                    return 'Please enter a valid email address';
                  }
                  return null;
                },
              ),

              const SizedBox(height: 24),

              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _isSending ? null : _sendTestEmail,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFff425e),
                    foregroundColor: Colors.white,
                  ),
                  child: _isSending
                      ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2,
                    ),
                  )
                      : const Text('Send Test Email'),
                ),
              ),

              if (_resultMessage.isNotEmpty) ...[
                const SizedBox(height: 24),
                Container(
                  padding: const EdgeInsets.all(16),
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: _isSuccess ? Colors.green[50] : Colors.red[50],
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: _isSuccess ? Colors.green : Colors.red,
                      width: 1,
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        _isSuccess ? Icons.check_circle : Icons.error,
                        color: _isSuccess ? Colors.green : Colors.red,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          _resultMessage,
                          style: TextStyle(
                            color: _isSuccess ? Colors.green[800] : Colors.red[800],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              const SizedBox(height: 24),

            ],
          ),
        ),
      ),
    );
  }
}