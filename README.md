# Study Mate 📚🎓

Welcome to **Study Mate** - "Learn Smarter • Achieve Faster". 

Study Mate is a comprehensive, multi-role educational platform built with Flutter and Firebase. It provides a highly interactive and gamified learning environment for students while offering powerful management tools for teachers, administrators, and sponsors. The app aims to provide a secure, fast, and personalized digital learning experience.

---

## 🌟 Key Features

The application supports four main user roles, each with a dedicated and tailored dashboard:

### 🎒 1. Students
- **Personalized E-Learning:** Access to curated courses, classes, and lessons.
- **AI Buddy (Tutor):** Integrated with Google Gemini AI for instant on-demand homework help and tutoring (`AI Buddy / Chat`).
- **Gamification & Games:** Features multiple interactive learning games such as Puzzle Games and Memory Match Games.
- **Knowledge Arena & Quizzes:** Compete and test knowledge with an extensive interactive quiz system.
- **Communication:** Real-time chat with Teachers, Admins, and a Community Chat for peer-to-peer discussions.
- **Utility Tools:** Built-in to-do planner, event calendar, job portal minigames, and progress tracking.

### 🧑‍🏫 2. Teachers
- **Course Management:** Create, manage, and distribute classes and lessons seamlessly.
- **Assessment Creation:** Build distinct quizzes and interactive minigames for students.
- **Student Tracking:** Track and evaluate student progress using comprehensive insights.
- **Communication:** Facilitate 1-on-1 chats with students to answer questions, and communicate with administrators.
- **Verified Educator Status:** Go through an admin-approval registration pipeline ensuring quality control.

### 🏢 3. Administrators
- **Platform Management:** A centralized dashboard to oversee platform operations, view platform health, and control the News Feed.
- **User Verification:** Review and approve the registration applications of Teachers and Sponsors.
- **Moderation:** Monitor the community interactions and manage comprehensive role chat inboxes.
- **Funding Overview:** Monitor sponsorship history, requests, and funding flow.

### 🤝 4. Sponsors
- **Student Sponsorship:** Review verified student profiles and provide funding/sponsorship for educational needs.
- **Impact Dashboard:** Track the real-world impact of your funding.
- **Communication:** Direct chat channels with administrators for coordination.

---

## 🛠️ Tech Stack & Architecture

- **Frontend Framework:** [Flutter](https://flutter.dev/) (Apples targeting Android, iOS, Web, and Desktop)
- **Language:** [Dart](https://dart.dev/)
- **Backend & Database:** [Firebase](https://firebase.google.com/)
  - **Firebase Auth:** Secure Authentication (Email/Password, Google Sign-in, OTP functionality).
  - **Cloud Firestore:** Real-time NoSQL database holding users, chats, courses, and platform data.
  - **Cloud Functions:** Serverless functions for handling background tasks and push notifications.
  - **Firebase Storage:** Handling media and file uploads.
- **Key Integrations:**
  - `google_generative_ai`: Gemini integration for the AI Buddy.
  - `dash_chat_2` & `youtube_player_flutter`: Real-time chat UI architecture and standard video playback.
  - `table_calendar`: For scheduling and planning modules.
  - **UI/UX Extensions:** Utilizes `google_fonts`, `animate_do`, and `lottie` for fluid, dynamic micro-animations to improve the learner's experience. Features Light and Dark mode globally.

---

## 📂 Project Structure Overview

```text
lib/
├── core/            # Application core features (Colors, Themes, Page Transitions, Constants)
├── screens/         # Contains all role-based UI screens
│   ├── admin/       # Administrator features (Dashboard, Verifications, Community)
│   ├── auth/        # Login, Registration, Password Resets, Role Selection
│   ├── sponsor/     # Sponsor Dashboard, Funding Portal, Impact Tracker
│   ├── student/     # Student Dashboard, AI Buddy, Courses, Games, Quizzes
│   ├── teacher/     # Teacher Dashboard, Class Creation, Student Tracking
│   ├── onboarding/  # Initial App Walkthroughs
│   └── support/     # Customer Support tools
├── services/        # Service logic classes (Auth, AI Tutor Service)
├── widgets/         # Reusable presentation widgets
├── main.dart        # Entry point of the application
└── firebase_options.dart # Generated Firebase configurations
```

---

## 🚀 Getting Started

### Prerequisites
- [Flutter SDK](https://docs.flutter.dev/get-started/install) (`^3.11.0`)
- Dart SDK
- Firebase CLI installed and logged in.

### Installation

1. **Clone the repository:**
   ```bash
   git clone <repository-url>
   cd computing_group_project
   ```

2. **Install Flutter dependencies:**
   ```bash
   flutter pub get
   ```

3. **Set up environment variables:**
   - Add a `.env` file in the root directory and ensure variables like the Gemini API keys are placed safely within:
     ```env
     GEMINI_API_KEY=your_gemini_api_key_here
     ```

4. **Run the App:**
   ```bash
   flutter run
   ```

*(Note: Depending on your targeted platform, make sure you configure standard Firebase platform integration files. Currently, `firebase_options.dart` covers automatic initialization.)*

---

## 🎨 Theme & Accessibility

The app features an adaptive user interface that responds seamlessly to **System Themes** utilizing Material 3.
Colors revolve around a sleek primary accent `Color(0xFF5C71D1)`, dynamically blending light backgrounds (`#F8F9FD`) and specialized dark modes (`#141625`). Includes custom clamping scroll physics to ensure the smoothest user interaction out-of-the-box.

---

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.
