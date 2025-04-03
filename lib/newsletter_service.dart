// lib/services/newsletter_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';

class NewsletterService {
  static final _supabase = Supabase.instance.client;

  // MailerSend configuration
  static const String _mailerSendApiKey = 'mlsn.a0adcc7ceb0f8956176d29470ae874db5ec409766d31c1e075c64c2abcbf00ad';
  static const String _senderEmail = 'MS_36pPlO@trial-eqvygm0zw18l0p7w.mlsender.net';
  static const String _senderName = 'NewslyEmailService';

  // Subscribe user to newsletter
  static Future<bool> subscribeToNewsletter({
    required String email,
    required List<String> categories,
    required int emailsPerDay, // Number of emails per day (1-10)
  }) async {
    try {
      final user = _supabase.auth.currentUser;

      if (user == null) {
        throw Exception('User not authenticated');
      }

      // Validate emails per day
      int validEmailsPerDay = emailsPerDay.clamp(1, 10);

      // Check if already subscribed
      final existing = await _supabase
          .from('newsletter_subscriptions')
          .select()
          .eq('user_id', user.id)
          .maybeSingle();

      if (existing != null) {
        // Update existing subscription
        await _supabase
            .from('newsletter_subscriptions')
            .update({
          'email': email,
          'categories': categories,
          'emails_per_day': validEmailsPerDay,
          'is_active': true,
          'updated_at': DateTime.now().toIso8601String(),
        })
            .eq('user_id', user.id);
      } else {
        // Create new subscription
        await _supabase
            .from('newsletter_subscriptions')
            .insert({
          'user_id': user.id,
          'email': email,
          'categories': categories,
          'emails_per_day': validEmailsPerDay,
          'is_active': true,
          'created_at': DateTime.now().toIso8601String(),
          'updated_at': DateTime.now().toIso8601String(),
          'last_email_count': 0,
        });
      }

      // Send welcome email
      await _sendWelcomeEmail(email, validEmailsPerDay, categories);

      return true;
    } catch (e) {
      print('Error subscribing to newsletter: $e');
      return false;
    }
  }

  // Send welcome email to new subscribers
  static Future<void> _sendWelcomeEmail(String email, int emailsPerDay, List<String> categories) async {
    try {
      // Create welcome email content
      String emailContent = '''
        <div style="font-family: Arial, sans-serif; max-width: 600px; margin: 0 auto;">
          <div style="background-color: #ff425e; padding: 20px; text-align: center; color: white;">
            <h1>Welcome to Newsly Newsletter!</h1>
          </div>
          <div style="padding: 20px;">
            <p>Hello,</p>
            <p>Thank you for subscribing to our newsletter service!</p>
            <p>You'll receive <strong>${emailsPerDay} email${emailsPerDay > 1 ? 's' : ''}</strong> per day with the latest news from your selected categories:</p>
            <p><strong>${categories.join(', ')}</strong></p>
            <p>We're excited to keep you informed with the latest news in your areas of interest.</p>
          </div>
          <div style="background-color: #f9f9f9; padding: 20px; text-align: center; font-size: 12px; color: #666;">
            <p>You're receiving this email because you subscribed to the Newsly newsletter.</p>
            <p>To update your preferences or unsubscribe, please open the Newsly app and go to Newsletter settings.</p>
          </div>
        </div>
      ''';

      // Send the email using MailerSend
      await sendEmailWithMailerSend(
        toEmail: email,
        toName: 'Newsly Subscriber',
        subject: 'Welcome to Newsly Newsletter!',
        htmlContent: emailContent,
      );

    } catch (e) {
      print('Error sending welcome email: $e');
    }
  }

  // Unsubscribe from newsletter
  static Future<bool> unsubscribeFromNewsletter() async {
    try {
      final user = _supabase.auth.currentUser;

      if (user == null) {
        throw Exception('User not authenticated');
      }

      await _supabase
          .from('newsletter_subscriptions')
          .update({'is_active': false})
          .eq('user_id', user.id);

      return true;
    } catch (e) {
      print('Error unsubscribing from newsletter: $e');
      return false;
    }
  }

  // Get newsletter preferences
  static Future<Map<String, dynamic>?> getNewsletterPreferences() async {
    try {
      final user = _supabase.auth.currentUser;

      if (user == null) {
        throw Exception('User not authenticated');
      }

      final response = await _supabase
          .from('newsletter_subscriptions')
          .select()
          .eq('user_id', user.id)
          .maybeSingle();

      return response;
    } catch (e) {
      print('Error getting newsletter preferences: $e');
      return null;
    }
  }

  // Send a test newsletter to the user
  static Future<bool> sendTestNewsletter({
    required String email,
    required List<String> categories,
    int emailNumber = 1, // Which email of the day this is (1, 2, etc.)
  }) async {
    try {
      // Get articles based on categories
      List<Map<String, dynamic>> articles = await _getArticlesForCategories(categories, 5);

      // Create article HTML
      String articlesHtml = '';
      for (var article in articles) {
        articlesHtml += '''
          <div style="margin-bottom: 20px; border-bottom: 1px solid #eee; padding-bottom: 15px;">
            <h2 style="margin: 0; color: #333;">${article['title']}</h2>
            ${article['image_url'] != null ? '<img src="${article['image_url']}" style="max-width: 100%; height: auto; margin: 10px 0;" />' : ''}
            <p style="margin: 10px 0; color: #666;">${article['description'] ?? 'No description available'}</p>
            <p><a href="${article['url']}" style="background-color: #ff425e; color: white; padding: 8px 15px; text-decoration: none; border-radius: 4px; font-size: 14px;">Read More</a></p>
          </div>
        ''';
      }

      // Current date formatted
      final now = DateTime.now();
      final dateFormatted = "${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}";

      // Create newsletter content
      String newsletterContent = '''
        <div style="font-family: Arial, sans-serif; max-width: 600px; margin: 0 auto;">
          <div style="background-color: #ff425e; padding: 20px; text-align: center; color: white;">
            <h1>Newsly Update #$emailNumber</h1>
            <p>Daily news update for $dateFormatted</p>
          </div>
          <div style="padding: 20px;">
            ${articlesHtml}
          </div>
          <div style="background-color: #f9f9f9; padding: 20px; text-align: center; font-size: 12px; color: #666;">
            <p>You're receiving this email because you subscribed to the Newsly newsletter.</p>
            <p>To update your preferences or unsubscribe, please open the Newsly app and go to Newsletter settings.</p>
          </div>
        </div>
      ''';

      // Send the email using MailerSend
      await sendEmailWithMailerSend(
        toEmail: email,
        toName: 'Newsly Subscriber',
        subject: 'Newsly News Update #$emailNumber - $dateFormatted',
        htmlContent: newsletterContent,
      );

      // Record the sent newsletter
      final user = _supabase.auth.currentUser;
      if (user != null) {
        final subscription = await _supabase
            .from('newsletter_subscriptions')
            .select('id')
            .eq('user_id', user.id)
            .maybeSingle();

        if (subscription != null) {
          await _supabase
              .from('sent_newsletters')
              .insert({
            'subscription_id': subscription['id'],
            'email': email,
            'frequency': 'daily', // Keep for compatibility
            'categories': categories,
            'subject': 'Newsly News Update #$emailNumber - $dateFormatted',
            'status': 'sent'
          });

          // Update email count
          await _supabase
              .from('newsletter_subscriptions')
              .update({
            'last_sent_at': DateTime.now().toIso8601String(),
            'last_email_count': emailNumber
          })
              .eq('id', subscription['id']);
        }
      }

      return true;
    } catch (e) {
      print('Error sending test newsletter: $e');
      return false;
    }
  }

  // Called by a daily scheduler to send emails to subscribers
  static Future<int> sendScheduledNewsletters() async {
    try {
      // Get all active subscribers
      final subscribers = await _supabase
          .from('newsletter_subscriptions')
          .select()
          .eq('is_active', true);

      if (subscribers == null || subscribers.isEmpty) {
        return 0;
      }

      int emailsSent = 0;
      final now = DateTime.now();
      final todayStart = DateTime(now.year, now.month, now.day);

      for (var subscriber in subscribers) {
        try {
          final lastSentAt = subscriber['last_sent_at'] != null
              ? DateTime.parse(subscriber['last_sent_at'])
              : null;

          final emailsPerDay = subscriber['emails_per_day'] ?? 1;
          final lastEmailCount = subscriber['last_email_count'] ?? 0;

          // Check if we've already sent the max number of emails today
          if (lastSentAt != null &&
              lastSentAt.isAfter(todayStart) &&
              lastEmailCount >= emailsPerDay) {
            continue; // Skip this subscriber, already sent max emails today
          }

          // Calculate which email number to send
          final nextEmailNumber = lastSentAt != null && lastSentAt.isAfter(todayStart)
              ? lastEmailCount + 1
              : 1; // First email of the day

          // Only proceed if we haven't hit the daily limit
          if (nextEmailNumber <= emailsPerDay) {
            final success = await sendTestNewsletter(
              email: subscriber['email'],
              categories: List<String>.from(subscriber['categories']),
              emailNumber: nextEmailNumber,
            );

            if (success) {
              emailsSent++;
            }
          }
        } catch (e) {
          print('Error processing subscriber ${subscriber['id']}: $e');
          continue; // Skip to next subscriber
        }
      }

      return emailsSent;
    } catch (e) {
      print('Error sending scheduled newsletters: $e');
      return 0;
    }
  }

  // Send immediate news update for important news in user's categories
  static Future<bool> sendBreakingNewsUpdate({
    required String email,
    required String title,
    required String description,
    required String url,
    String? imageUrl,
    required List<String> categories,
  }) async {
    try {
      // Create breaking news content
      String newsContent = '''
        <div style="font-family: Arial, sans-serif; max-width: 600px; margin: 0 auto;">
          <div style="background-color: #ff425e; padding: 20px; text-align: center; color: white;">
            <h1>Breaking News Alert</h1>
          </div>
          <div style="padding: 20px;">
            <h2 style="margin: 0; color: #333;">${title}</h2>
            ${imageUrl != null ? '<img src="${imageUrl}" style="max-width: 100%; height: auto; margin: 10px 0;" />' : ''}
            <p style="margin: 10px 0; color: #666;">${description}</p>
            <p><a href="${url}" style="background-color: #ff425e; color: white; padding: 8px 15px; text-decoration: none; border-radius: 4px; font-size: 14px;">Read Full Story</a></p>
          </div>
          <div style="background-color: #f9f9f9; padding: 20px; text-align: center; font-size: 12px; color: #666;">
            <p>You're receiving this breaking news alert because you subscribed to the Newsly newsletter for ${categories.join(', ')}.</p>
            <p>To update your preferences or unsubscribe, please open the Newsly app and go to Newsletter settings.</p>
          </div>
        </div>
      ''';

      // Send the email using MailerSend
      final result = await sendEmailWithMailerSend(
        toEmail: email,
        toName: 'Newsly Subscriber',
        subject: 'BREAKING: $title',
        htmlContent: newsContent,
      );

      return result;
    } catch (e) {
      print('Error sending breaking news update: $e');
      return false;
    }
  }

  // Helper method to get articles for specified categories
  static Future<List<Map<String, dynamic>>> _getArticlesForCategories(List<String> categories, int limit) async {
    try {
      // Get some articles from each category
      List<Map<String, dynamic>> allArticles = [];

      for (String category in categories) {
        final response = await _supabase
            .from('news_articles')
            .select()
            .eq('keyword', category)
            .order('published_at', ascending: false)
            .limit(limit ~/ categories.length + 1);

        if (response != null) {
          allArticles.addAll(List<Map<String, dynamic>>.from(response));
        }
      }

      // If we didn't get enough articles, get some random ones
      if (allArticles.length < limit) {
        final response = await _supabase
            .from('news_articles')
            .select()
            .order('published_at', ascending: false)
            .limit(limit - allArticles.length);

        if (response != null) {
          allArticles.addAll(List<Map<String, dynamic>>.from(response));
        }
      }

      // Shuffle and limit
      allArticles.shuffle();
      return allArticles.take(limit).toList();
    } catch (e) {
      print('Error getting articles: $e');
      return [];
    }
  }

  // Send email using MailerSend API
  static Future<bool> sendEmailWithMailerSend({
    required String toEmail,
    required String toName,
    required String subject,
    required String htmlContent,
  }) async {
    try {
      final url = Uri.parse('https://api.mailersend.com/v1/email');

      // Create the request body
      final body = jsonEncode({
        'from': {
          'email': _senderEmail,
          'name': _senderName,
        },
        'to': [
          {
            'email': toEmail,
            'name': toName,
          }
        ],
        'subject': subject,
        'html': htmlContent,
      });

      print('Sending email to: $toEmail');
      print('Using sender: $_senderEmail');

      // Send the request
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $_mailerSendApiKey',
        },
        body: body,
      );

      print('Response status code: ${response.statusCode}');

      if (response.statusCode == 202) {
        print('Email sent successfully');
        return true;
      } else {
        print('Failed to send email. Status code: ${response.statusCode}');
        print('Response body: ${response.body}');
        return false;
      }
    } catch (e) {
      print('Error sending email with MailerSend: $e');
      return false;
    }
  }
}