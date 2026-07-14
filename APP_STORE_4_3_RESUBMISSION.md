# App Store Connect — Freshman (4.3 remediation)

Use this when rebuilding and resubmitting **Freshman** (`com.freshmantricks.app`) after Guideline 4.3(a).

## Build commands

```bash
# From freshman_mobile-main
flutter pub get
dart run flutter_launcher_icons -f flutter_launcher_icons-freshman.yaml

# iOS (use freshman scheme / flavor)
flutter build ipa --flavor freshman --dart-define=FLAVOR=freshman

# Android
flutter build appbundle --flavor freshman --dart-define=FLAVOR=freshman
```

Version in `pubspec.yaml`: **1.0.14+14**

**UI structure note (important for 4.3):** This build uses a Campus Academic design distinct from Entrance Tricks — paper surfaces, Fraunces/Jakarta typography, Material 3 `NavigationBar`, login brand-band + form sheet, home course **grid** (not vertical exam subject list), and paper AppBars (no shared full-bleed gradient page shell).

## App Store listing (paste / adapt)

**Name:** Freshman  
**Subtitle:** University first-year courses & study tools  
**Category:** Education  

**Promotional text:**  
Study university first-year courses with organized materials, practice quizzes, and a study planner built for freshmen.

**Description:**  
Freshman is made for **university first-year students**, not high-school entrance exam prep.

With Freshman you can:
- Browse first-year **courses** by academic year / program track
- Watch lecture videos and read notes offline
- Practice with **course quizzes**
- Plan study sessions with the built-in **study planner**
- Follow campus and academic news updates

Content is scoped to the Freshman catalog (`com.freshman_tricks.app`) — university curricula for freshman year, distinct from separate entrance-exam products.

**Keywords (example):** university,freshman,first year,courses,lecture,study,ethiopia,quiz,notes  

**Privacy Policy URL:** Host a Freshman-specific page (use `support@freshmantricks.com` / freshmantricks.com wording from the in-app privacy dialog).

**Screenshots to capture (must match the build):**
1. Login — teal brand band + bottom form sheet (not centered grey form)  
2. Home — greeting header + 2-column **course grid** + campus updates  
3. My Courses — paper list of courses (not gradient tile grid)  
4. Study Planner — paper AppBar  
5. About — paper cards with university freshman mission  

Avoid Entrance Tricks screenshots (Exams tab, Leaderboard, hamburger+Telegram twin icons, purple gradient pages).

---

## Resolution Center reply (Guideline 4.3(a))

Copy/adapt after uploading the differentiated build:

---

Hello App Review Team,

Thank you for the feedback on Guideline 4.3(a).

We have redesigned and resubmitted **Freshman** (`com.freshmantricks.app`) as a **distinct university first-year courses app**, not a high-school entrance exam product.

**Audience & concept**
- Freshman serves **university freshman (Year 1)** students with first-year course materials.
- Our separate entrance-exam product targets **high-school students** preparing for university entrance exams — a different audience and curriculum.

**What reviewers can verify in this build**
1. Bundle ID: `com.freshmantricks.app` (display name **Freshman**)
2. Material 3 bottom **NavigationBar**: Home · My Courses · News · Planner · Profile (no Exams or Leaderboard)
3. Login layout: brand band + sheet form (not Entrance’s centered grey stack)
4. Home: branded greeting + **2-column course grid** (not vertical subject cards + Telegram twin icons)
5. Labels: **Course** / **Year**; About/FAQ/Support use paper AppBars (no full-bleed gradient shell)
6. Typography and palette: Fraunces + Plus Jakarta Sans; paper `#F7F4EF` / deep teal `#0B5F56`
7. Content catalog filtered by backend package `com.freshman_tricks.app` with university-year programs

We acknowledge a shared learning-platform technical foundation with related education apps, but this submission delivers a **different product concept, metadata, UX, and content catalog** focused on university freshmen.

**Demo path**
1. Launch Freshman  
2. Register/login with the demo account below  
3. Home → confirm Freshman / first-year messaging  
4. Open **My Courses** → open a first-year course → open a video or note  
5. Open **About** → confirm university freshman positioning  

**Demo account**  
Username/phone: `[ADD DEMO PHONE]`  
Password/OTP: `[ADD DEMO CREDENTIALS]`

Please let us know if any additional information would help.

Thank you,  
[Your Name]

---

## Backend CMS (production)

On the API server:

```bash
python manage.py ensure_freshman_content --with-sample-courses
```

Then in Django Admin, confirm:
- Grades with `app_package = com.freshman_tricks.app` use university Year names (not Grade 11/12)
- Subjects linked to those grades look like first-year **courses**
- App Header texts say Freshman / first-year (not Entrance Tricks)
