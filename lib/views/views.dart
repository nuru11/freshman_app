export 'auth/login.dart';
export 'auth/register.dart';
export 'auth/forgot_password.dart';
export 'auth/verify_phone.dart';
export 'home/home_dashboard.dart';
export 'subject/subject_detail.dart';
export 'subject/chapter_detail.dart';
export 'exam/exam_page.dart';
export 'news/news_page.dart';
export 'leaderboard/leaderboard_page.dart';
export 'common/profile_page.dart';
export 'common/edit_profile_page.dart';
export 'common/video_player_screen.dart';
export 'common/pdf_reader_screen.dart';
export 'subject/subject_page.dart';
export 'common/search_page.dart';
export 'common/notifications_page.dart';
export 'exam/exam_detail_page.dart';
export 'exam/exam_result_page.dart';
export 'news/news_detail_page.dart';
export 'quiz/quiz_detail_page.dart';
export 'quiz/quiz_taking_page.dart';
export 'downloads/downloads_page.dart';
export 'support/support_page.dart';
export 'about/about_page.dart';
export 'faq/faq_page.dart';
export 'study_planner/study_planner_page.dart';
export 'study_planner/add_plan_page.dart';
export 'payment/payment_page.dart';
export 'payment_history_screen.dart';
export 'success_stories/success_stories_page.dart';
export 'success_stories/success_story_detail_page.dart';
export 'common/user_score_page.dart';
export 'agent/agent_apply_page.dart';
export 'agent/agent_status_page.dart';

enum VIEWS {
  home('/home'),
  login('/login'),
  register('/register'),
  forgotPassword('/forgotPassword'),
  verifyPhone('/verifyPhone'),
  verifyEmail('/verifyEmail'),
  resetPassword('/resetPassword'),
  subjectDetail('/subject-detail'),
  chapterDetail('/chapter-detail'),
  videoPlayer('/video-player'),
  pdfReader('/pdf-reader'),
  editProfile('/edit-profile'),
  videos('/videos'),
  notes('/notes'),
  examDetail('/exam-detail'),
  newsDetail('/news-detail'),
  downloads('/downloads'),
  subjects('/subjects'),
  support('/support'),
  about('/about'),
  faq('/faq'),
  payments('/payments'),
  subjectCheckout('/subject-checkout'),
  paymentHistory('/payment-history'),
  successStories('/success-stories'),
  successStoryDetail('/success-story-detail'),
  userScore('/user-score'),
  agentApply('/agent-apply'),
  agentStatus('/agent-status');

  final String path;

  const VIEWS(this.path);
}
