# 📰 Newsly – Personalized News App

**Newsly** is an intelligent, cross-platform mobile app that delivers personalized news articles based on your interests. Built with **Flutter**, **Supabase**, and **Python**, it leverages NLP techniques like **TF-IDF** and **Latent Semantic Analysis (LSA)** to provide content that actually matters to you — not just clickbait.

> “Don’t scroll endlessly — let Newsly serve you what you care about.”

---

## 🚀 Features

- 🔐 **Secure Auth** — Google Sign-In and Email/Password support via Supabase
- 🧠 **Smart Recommendations** — Based on content similarity using TF-IDF + LSA
- 📚 **Real-Time News Feed** — Articles updated dynamically from a Supabase backend
- 📩 **Email Delivery** — Get curated news sent directly to your inbox
- 🌐 **Responsive UI** — Smooth and consistent across Android, iOS, and Web

---

## 🛠️ Tech Stack

| Frontend    | Backend           | Intelligence Layer   |
|-------------|-------------------|-----------------------|
| Flutter/Dart| Supabase + Firebase | Python (NLP, LSA, TF-IDF) |

---

<h2>📸 Screenshots</h2>

<div style="display: flex; flex-wrap: nowrap; gap: 12px;">
  <img src="./assets/screenshots/splash.jpeg" alt="Splash" width="200"/>
  <img src="./assets/screenshots/home.jpeg" alt="Home" width="200"/>
  <img src="./assets/screenshots/search.jpeg" alt="Search" width="200"/>
  <img src="./assets/screenshots/profile.jpeg" alt="Profile" width="200"/>
  <img src="./assets/screenshots/email.jpeg" alt="Email" width="200"/>
</div>

---

## 📦 Installation

```bash
# Clone the repo
git clone https://github.com/your-username/newsly.git
cd newsly

# Install dependencies
flutter pub get

# Run the app
flutter run
