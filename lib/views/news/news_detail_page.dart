import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:get/get.dart';
import 'package:share_plus/share_plus.dart';
import 'package:vector_academy/models/models.dart';
import 'package:vector_academy/services/services.dart';
import 'package:vector_academy/utils/utils.dart';
import 'package:vector_academy/components/components.dart';

class NewsDetailPage extends StatefulWidget {
  final News? news;
  final int? newsId;

  const NewsDetailPage({super.key, this.news, this.newsId});

  @override
  State<NewsDetailPage> createState() => _NewsDetailPageState();
}

class _NewsDetailPageState extends State<NewsDetailPage> {
  News? _news;
  bool _isLoading = false;

  static const _fallbackCover =
      'https://images.unsplash.com/photo-1504711434969-e33886168f5c?w=400&h=300&fit=crop';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeNews();
    });
  }

  void _initializeNews() {
    if (widget.news != null) {
      _news = widget.news;
      setState(() {});
      return;
    }

    if (widget.newsId != null) {
      _loadNewsById(widget.newsId!);
      return;
    }

    var args = Get.parameters;
    if (args['id'] != null) {
      final id = int.tryParse(args['id']!);
      if (id != null) _loadNewsById(id);
    }
  }

  Future<void> _loadNewsById(int newsId) async {
    setState(() => _isLoading = true);

    try {
      final newsService = NewsService();
      final news = await newsService.getNewsById(newsId);
      if (news != null) {
        setState(() {
          _news = news;
          _isLoading = false;
        });
      } else {
        setState(() => _isLoading = false);
        Future.microtask(() {
          if (mounted) Get.back();
        });
      }
    } catch (e) {
      setState(() => _isLoading = false);
      Future.microtask(() {
        if (mounted) Get.back();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        backgroundColor: backgroundColor,
        body: Center(child: CircularProgressIndicator(color: primaryColor)),
      );
    }

    if (_news == null) {
      return FreshmanPageScaffold(
        title: 'Campus News',
        body: Center(
          child: Text(
            'News not found',
            style: TextStyle(color: onSurfaceVariant),
          ),
        ),
      );
    }

    final news = _news!;
    final theme = Theme.of(context);

    return FreshmanPageScaffold(
      title: news.title.capitalize ?? 'Article',
      subtitle: toAgoDate(news.createdAt),
      actions: [
        IconButton(
          icon: const Icon(Icons.share_outlined),
          onPressed: _shareNews,
        ),
      ],
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 40),
        children: [
          FreshmanSurfaceCard(
            padding: EdgeInsets.zero,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: Image.network(
                news.coverImage ?? _fallbackCover,
                height: 180,
                width: double.infinity,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(
                  height: 180,
                  color: primaryColor.withValues(alpha: 0.08),
                  child: Icon(
                    Icons.campaign_outlined,
                    color: primaryColor,
                    size: 40,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: primaryColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: borderColor),
                ),
                child: Text(
                  news.category.capitalize ?? '',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: primaryColor,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Text(
                '${_estimateReadingTime(news.content)} min read',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: onSurfaceVariant,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            news.title.capitalize ?? '',
            style: theme.textTheme.headlineSmall?.copyWith(
              color: onSurfaceColor,
              fontWeight: FontWeight.w700,
              height: 1.25,
            ),
          ),
          const SizedBox(height: 20),
          FreshmanSurfaceCard(
            child: MarkdownBody(
              data: news.content,
              styleSheet: MarkdownStyleSheet(
                h1: theme.textTheme.headlineSmall?.copyWith(
                  color: onSurfaceColor,
                  fontWeight: FontWeight.bold,
                ),
                h2: theme.textTheme.titleLarge?.copyWith(
                  color: onSurfaceColor,
                  fontWeight: FontWeight.bold,
                ),
                h3: theme.textTheme.titleMedium?.copyWith(
                  color: onSurfaceColor,
                  fontWeight: FontWeight.bold,
                ),
                p: theme.textTheme.bodyLarge?.copyWith(
                  color: onSurfaceColor,
                  height: 1.6,
                ),
                strong: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: onSurfaceColor,
                ),
                em: TextStyle(
                  fontStyle: FontStyle.italic,
                  color: onSurfaceVariant,
                ),
                code: TextStyle(
                  backgroundColor: backgroundColor,
                  color: onSurfaceColor,
                  fontSize: 14,
                  fontFamily: 'monospace',
                ),
                codeblockDecoration: BoxDecoration(
                  color: backgroundColor,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: borderColor),
                ),
                blockquote: TextStyle(
                  color: onSurfaceVariant,
                  fontStyle: FontStyle.italic,
                ),
                listBullet: TextStyle(color: primaryColor, fontSize: 16),
                tableBorder: TableBorder.all(color: borderColor, width: 1),
                tableHead: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: onSurfaceColor,
                ),
                tableBody: TextStyle(color: onSurfaceColor),
              ),
              selectable: true,
              onTapLink: (text, href, title) {
                if (href != null) logger.d('Tapped link: $href');
              },
            ),
          ),
        ],
      ),
    );
  }

  int _estimateReadingTime(String content) {
    final wordCount = content.split(' ').length;
    return (wordCount / 200).ceil().clamp(1, 60);
  }

  Future<void> _shareNews() async {
    if (_news == null) return;

    try {
      final shareLink = ShareUtils.generateNewsLink(_news!.id);
      final shareText = '${_news!.title}\n\n$shareLink';
      await Share.share(shareText, subject: _news!.title);
    } catch (e) {
      logger.e('Error sharing news: $e');
      AppSnackbar.showError(
        'Error',
        'Failed to share news',
        duration: const Duration(seconds: 2),
      );
    }
  }
}
