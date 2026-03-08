<p align="center">
  <img src="https://img.shields.io/badge/Flutter-3.11+-02569B?style=for-the-badge&logo=flutter&logoColor=white" />
  <img src="https://img.shields.io/badge/Dart-3.11+-0175C2?style=for-the-badge&logo=dart&logoColor=white" />
  <img src="https://img.shields.io/badge/Supabase-Backend-3ECF8E?style=for-the-badge&logo=supabase&logoColor=white" />
  <img src="https://img.shields.io/badge/Gemini_AI-Powered-8E75B2?style=for-the-badge&logo=google&logoColor=white" />
</p>

<h1 align="center">🔥 DareDay</h1>

<p align="center">
  <strong>A social dare-sharing app where you complete daily challenges, prove them with video, and climb the leaderboard.</strong><br/>
  Built with Flutter • Powered by Supabase & Google Gemini AI
</p>

---

## 📖 Overview

**DareDay** is a mobile-first social platform where users receive daily dares, record video proof, and share their completions in a TikTok-style vertical feed. An AI engine (Google Gemini) generates personalized challenges based on user interests and verifies video proof for authenticity. A full gamification layer — coins, gems, streaks, ranks, and a leaderboard — keeps users engaged and competitive.

---

## ✨ Features

### 🎯 Daily Dares
- A rotating daily dare pulled from the `dares_master` table, with difficulty selection (Easy / Medium / Hard / Insane).
- Countdown timer showing time remaining until the next dare.
- Options to **skip** (costs 50 pts and resets streak) or use a **Skip Token** (preserves streak).

### 🤖 AI-Powered "Grind" Mode
- Users select interests (Fitness, Social, Tech, Comedy, Travel, Gaming, Art) and the **Gemini AI** generates a personalized dare on demand.
- Three difficulty tiers with weekend 2× reward multipliers.
- AI-generated dares are safety-checked before being served.

### 📹 Video Proof & AI Verification
- Record video proof via the device camera using `image_picker`.
- **Gemini Vision** analyzes extracted video frames to verify the dare was actually completed, assigning a relevance score (0–100).
- Verified proofs are uploaded to Supabase Storage and appear on the global feed.

### 📱 TikTok-Style Vertical Feed
- Full-screen vertical video feed with swipe navigation (`PageView`).
- Toggle between **"For You"** (global) and **"Following"** feeds.
- Double-tap to react with a heart animation.
- Social sidebar with reactions, comments, and share functionality.

### 👥 Social Graph
- Search and discover users.
- Follow / unfollow with real-time UI updates.
- Mutual followers can send each other custom **friend challenges** (AI-verified for safety).
- Followers and following lists accessible from profile.

### 🏆 Gamification & Economy

| Currency | Earned By | Spent On |
|----------|-----------|----------|
| **Coins (pts)** | Completing dares (3/5/10 pts by difficulty) | Skipping dares (-50), forfeiting challenges (-100) |
| **Gems 💎** | Completing Hard dares (+1 gem) | Skip Tokens (5 gems), Streak Freezes (15 gems), Chicken Tax (5 gems) |

#### Rank System

| Rank | Threshold |
|------|-----------|
| 👻 GHOST | 0 – 49 pts |
| ⚡ CHALLENGER | 50 – 199 pts |
| 🟣 ADRENALINE JUNKIE | 200 – 499 pts |
| 🔥 DAREDEVIL | 500+ pts |

#### Streaks
- Complete a dare every day to build your **weekly progress** (7-day streak).
- After 7 consecutive days, earn a **streak bonus** and activate a score multiplier.
- **Streak Freezes** protect your streak if you miss a day (purchasable with gems).

### 🏅 Leaderboard
- **Global** leaderboard sorted by total points.
- **Friends** leaderboard filtered to people you follow.
- **Weekly** leaderboard (coming soon).
- Tap any user to visit their profile.

### 👤 Profile
- Customizable avatar (upload from gallery), username, and bio.
- Stats grid: Streak, Total Pts, Gems, Skip Tokens.
- **Memories** section showing your past dare completions with video playback.
- Settings menu: manage profile, security (password update), gem shop, invite friends, delete account.

---

## 🏗️ Architecture

```
lib/
├── main.dart                     # App entry point, dotenv & Supabase init
├── app.dart                      # MaterialApp theme & routing
├── main_shell.dart               # Bottom navigation shell (5 tabs)
│
├── config/
│   └── supabase_config.dart      # Reads Supabase URL & anon key from .env
│
├── models/
│   ├── dare_model.dart           # DareModel + UserAttemptModel
│   ├── user_model.dart           # UserModel with rank calculation
│   ├── comment_model.dart        # Comment data model
│   ├── reaction_model.dart       # Reaction data model
│   └── dare_verification_result.dart  # AI verification result model
│
├── providers/
│   └── navigation_provider.dart  # Tab state, active grind dare, feed refresh
│
├── screens/
│   ├── auth_screen.dart          # Login / Sign-up with Supabase Auth
│   ├── feed_screen.dart          # Vertical video feed (For You / Following)
│   ├── friends_search_screen.dart # User search + follow/unfollow
│   ├── dares_screen.dart         # Daily dare, challenges, grind section
│   ├── ai_settings_screen.dart   # Interest selection + AI dare generation
│   ├── leaderboard_screen.dart   # Global / Friends / Weekly rankings
│   ├── profile_screen.dart       # User profile, stats, memories, settings
│   ├── proof_preview_screen.dart # Video preview + caption before submission
│   ├── success_screen.dart       # Post-completion celebration
│   └── verification_failure_screen.dart  # AI rejection feedback
│
├── services/
│   ├── supabase_service.dart     # All Supabase DB & Storage operations
│   └── ai_service.dart           # Gemini API: dare generation, safety check, vision verification
│
└── widgets/
    ├── auth_gate.dart            # Auth state listener (login ↔ main shell)
    ├── comments_sheet.dart       # Bottom sheet for video comments
    ├── ranking_sheet.dart        # Ranking info modal
    ├── reaction_overlay.dart     # Heart animation overlay
    └── social_bar.dart           # Sidebar: reactions, comments, share buttons
```

---

## 🛠️ Tech Stack

| Layer | Technology |
|-------|-----------|
| **Framework** | Flutter (Dart 3.11+) |
| **State Management** | Provider |
| **Backend / Database** | Supabase (PostgreSQL + Auth + Storage) |
| **AI Engine** | Google Gemini API (Gemma 3 27B IT) |
| **Video Playback** | `video_player` + `chewie` |
| **Media Capture** | `image_picker` + `video_thumbnail` |
| **Fonts** | Google Fonts (Spline Sans) |
| **Environment Config** | `flutter_dotenv` |
| **Sharing** | `share_plus` |

---

## 🚀 Getting Started

### Prerequisites

- [Flutter SDK](https://flutter.dev/docs/get-started/install) (3.11+)
- A [Supabase](https://supabase.com) project with the required tables (see [Database Schema](#-database-schema))
- A [Google AI Studio](https://aistudio.google.com/) API key for Gemini

### 1. Clone the Repository

```bash
git clone https://github.com/sxfxr/DareDay.git
cd DareDay/dare_day
```

### 2. Create Environment File

Create a `.env` file in the project root (`dare_day/.env`):

```env
SUPABASE_URL=https://your-project.supabase.co
SUPABASE_ANON_KEY=your-supabase-anon-key
GEMINI_API_KEY=your-gemini-api-key
```

> ⚠️ **Never commit `.env` to version control.** It is already in `.gitignore`.

### 3. Install Dependencies

```bash
flutter pub get
```

### 4. Run the App

```bash
# Android
flutter run

# iOS
flutter run --device-id <your-ios-device-id>

# Web (limited — video features may not work)
flutter run -d chrome
```

---

## 🗄️ Database Schema

The app expects the following Supabase tables:

| Table | Purpose |
|-------|---------|
| `profiles` | User profiles (username, bio, avatar, coins, gems, streak, etc.) |
| `dares_master` | Master list of all dares (title, instructions, difficulty, xp_reward) |
| `daily_challenges` | Scheduled daily dare assignments by date |
| `user_attempts` | Video proof submissions linked to users and dares |
| `social_graph` | Follow relationships (`follower_id` → `following_id`) |
| `friend_challenges` | Custom dares sent between mutual followers |
| `reactions` | User reactions on attempt videos |
| `comments` | User comments on attempt videos |
| `leaderboard` | View/materialized view for ranked user standings |

### Storage Buckets

| Bucket | Purpose |
|--------|---------|
| `proof_videos` | Uploaded video proof files |
| `avatars` | User profile pictures |

---

## 🎨 Design System

DareDay uses a **dark neon aesthetic** with glassmorphism and glow effects:

| Token | Value | Usage |
|-------|-------|-------|
| `backgroundDark` | `#0F0814` | Scaffold background |
| `primaryPurple` | `#A855F7` | Primary accent, buttons, badges |
| `neonCyan` | `#22D3EE` | Secondary accent, stats, highlights |
| `surfaceDark` | `#191022` | Cards, dialogs, inputs |
| `pinkAccent` | `#EC4899` | Challenge badges, gradients |
| `goldMetallic` | `#FFD700` | DAREDEVIL rank, skip tokens |

---

## 🔐 Security

- **API keys** are stored in a local `.env` file, loaded at runtime via `flutter_dotenv`.
- `.env` is listed in `.gitignore` and is **never committed** to the repository.
- Supabase **Row-Level Security (RLS)** policies should be configured on all tables.
- Custom dares are **AI-verified for safety** before being delivered to recipients.

---

## 📄 License

This project is private and not currently published under an open-source license.

---

<p align="center">
  Built with 💜 using Flutter & Supabase
</p>
