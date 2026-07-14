class ShareUtils {
  /// Base URL for deep links
  static const String baseUrl = 'freshmantricks.com';

  /// Custom scheme for deep links
  static const String customScheme = 'freshmantricks';

  /// Generate a shareable link for news
  static String generateNewsLink(int newsId, {bool useCustomScheme = false}) {
    final scheme = useCustomScheme ? customScheme : 'https';
    final host = useCustomScheme ? '' : baseUrl;
    final separator = useCustomScheme ? '://' : '://';

    return '$scheme$separator$host/news-detail?id=$newsId';
  }

  /// Generate a shareable link for subject/course
  static String generateSubjectLink(
    int subjectId, {
    bool useCustomScheme = false,
  }) {
    final scheme = useCustomScheme ? customScheme : 'https';
    final host = useCustomScheme ? '' : baseUrl;
    final separator = useCustomScheme ? '://' : '://';

    return '$scheme$separator$host/subject-detail?id=$subjectId';
  }

  /// Generate a shareable link for chapter
  static String generateChapterLink(
    int chapterId, {
    bool useCustomScheme = false,
  }) {
    final scheme = useCustomScheme ? customScheme : 'https';
    final host = useCustomScheme ? '' : baseUrl;
    final separator = useCustomScheme ? '://' : '://';

    return '$scheme$separator$host/chapter-detail?id=$chapterId';
  }

  /// Generate a shareable link for quiz/practice
  static String generateExamLink(int examId, {bool useCustomScheme = false}) {
    final scheme = useCustomScheme ? customScheme : 'https';
    final host = useCustomScheme ? '' : baseUrl;
    final separator = useCustomScheme ? '://' : '://';

    return '$scheme$separator$host/exams/$examId';
  }

  /// Generate a shareable link for success story
  static String generateSuccessStoryLink(
    int storyId, {
    bool useCustomScheme = false,
  }) {
    final scheme = useCustomScheme ? customScheme : 'https';
    final host = useCustomScheme ? '' : baseUrl;
    final separator = useCustomScheme ? '://' : '://';

    return '$scheme$separator$host/success-story-detail?id=$storyId';
  }
}
