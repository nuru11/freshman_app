import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:get/get.dart';
import 'package:share_plus/share_plus.dart';
import 'package:vector_academy/models/models.dart';
import 'package:vector_academy/services/services.dart';
import 'package:vector_academy/utils/utils.dart';
import 'package:cached_network_image/cached_network_image.dart';

class SuccessStoryDetailPage extends StatefulWidget {
  final SuccessStory? story;
  final int? storyId;

  const SuccessStoryDetailPage({super.key, this.story, this.storyId});

  @override
  State<SuccessStoryDetailPage> createState() => _SuccessStoryDetailPageState();
}

class _SuccessStoryDetailPageState extends State<SuccessStoryDetailPage> {
  SuccessStory? _story;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    // Use post-frame callback to ensure Get.arguments is available
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeStory();
    });
  }

  void _initializeStory() {
    if (widget.story != null) {
      _story = widget.story;
      setState(() {});
      return;
    }

    if (widget.storyId != null) {
      _loadStoryById(widget.storyId!);
      return;
    }

    // Try multiple ways to get arguments
    var args = Get.parameters;

    if (args['id'] != null) {
      final storyId = args['id'];
      if (storyId != null) {
        final id = int.tryParse(storyId);
        if (id != null) _loadStoryById(id);
      }
    }
  }

  Future<void> _loadStoryById(int storyId) async {
    setState(() {
      _isLoading = true;
    });

    try {
      final storyService = SuccessStoriesService();
      final story = await storyService.getSuccessStoryById(storyId);
      if (story != null) {
        setState(() {
          _story = story;
          _isLoading = false;
        });
      } else {
        setState(() {
          _isLoading = false;
        });
        Future.microtask(() {
          if (mounted) {
            Get.back();
          }
        });
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      Future.microtask(() {
        if (mounted) {
          Get.back();
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        body: Center(
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(
              Theme.of(context).colorScheme.primary,
            ),
          ),
        ),
      );
    }

    if (_story == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Success Story')),
        body: const Center(child: Text('Story not found')),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      body: CustomScrollView(
        slivers: [
          // Modern App Bar with Hero Image
          _buildModernAppBar(context),

          // Story Content
          SliverToBoxAdapter(child: _buildStoryContent(context)),
        ],
      ),
    );
  }

  Widget _buildModernAppBar(BuildContext context) {
    final story = _story!;
    return SliverAppBar(
      expandedHeight: 300,
      floating: false,
      pinned: true,
      backgroundColor: Colors.white,
      elevation: 0,
      leading: Container(
        margin: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.9),
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF2D3748)),
          onPressed: () => safePop(context: context),
        ),
      ),
      actions: [
        Container(
          margin: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.9),
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.1),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: IconButton(
            icon: const Icon(Icons.share, color: Color(0xFF2D3748)),
            onPressed: () => _shareStory(context),
          ),
        ),
      ],
      flexibleSpace: FlexibleSpaceBar(
        background: Stack(
          fit: StackFit.expand,
          children: [
            story.image != null
                ? CachedNetworkImage(
                    imageUrl: story.image!,
                    fit: BoxFit.cover,
                    placeholder: (context, url) => Container(
                      color: Colors.grey[300],
                      child: const Center(child: CircularProgressIndicator()),
                    ),
                    errorWidget: (context, url, error) => Container(
                      color: Colors.grey[300],
                      child: const Icon(
                        Icons.emoji_events_outlined,
                        color: Colors.grey,
                        size: 64,
                      ),
                    ),
                  )
                : Container(
                    color: Colors.grey[300],
                    child: const Icon(
                      Icons.emoji_events_outlined,
                      color: Colors.grey,
                      size: 64,
                    ),
                  ),
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    Colors.black.withValues(alpha: 0.3),
                    Colors.black.withValues(alpha: 0.7),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStoryContent(BuildContext context) {
    final story = _story!;
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(24),
          topRight: Radius.circular(24),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Story Title
            Text(
              story.title,
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Color(0xFF2D3748),
                height: 1.3,
              ),
            ),

            const SizedBox(height: 20),

            // Student Info Card
            if (story.studentName != null || story.achievement != null)
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF0F766E), Color(0xFF0D9488)],
                  ),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF0F766E).withValues(alpha: 0.3),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    if (story.studentPhoto != null)
                      CircleAvatar(
                        radius: 30,
                        backgroundImage: CachedNetworkImageProvider(
                          story.studentPhoto!,
                        ),
                      )
                    else
                      CircleAvatar(
                        radius: 30,
                        backgroundColor: Colors.white.withValues(alpha: 0.3),
                        child: const Icon(
                          Icons.person,
                          color: Colors.white,
                          size: 30,
                        ),
                      ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (story.studentName != null)
                            Text(
                              story.studentName!,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          if (story.achievement != null) ...[
                            const SizedBox(height: 4),
                            Text(
                              story.achievement!,
                              style: const TextStyle(
                                color: Colors.white70,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              ),

            const SizedBox(height: 20),

            // Story Meta Info
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF0F766E), Color(0xFF0D9488)],
                    ),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    story.category.name,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Icon(Icons.access_time, color: Colors.grey[500], size: 16),
                const SizedBox(width: 4),
                Text(
                  toAgoDate(story.createdAt),
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const Spacer(),
                // Reading time estimate
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    "${_estimateReadingTime(story.content)} min read",
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 32),

            // Story Content with Markdown Support
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: const Color(0xFFF8F9FA),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.grey[200]!),
              ),
              child: MarkdownBody(
                data: story.content,
                styleSheet: MarkdownStyleSheet(
                  h1: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF2D3748),
                    height: 1.3,
                  ),
                  h2: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF2D3748),
                    height: 1.3,
                  ),
                  h3: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF2D3748),
                    height: 1.3,
                  ),
                  p: const TextStyle(
                    fontSize: 16,
                    color: Color(0xFF4A5568),
                    height: 1.6,
                  ),
                  strong: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF2D3748),
                  ),
                  em: const TextStyle(
                    fontStyle: FontStyle.italic,
                    color: Color(0xFF4A5568),
                  ),
                  code: TextStyle(
                    backgroundColor: Colors.grey[200],
                    color: const Color(0xFF2D3748),
                    fontSize: 14,
                    fontFamily: 'monospace',
                  ),
                  codeblockDecoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.grey[300]!),
                  ),
                  blockquote: TextStyle(
                    color: Colors.grey[600],
                    fontStyle: FontStyle.italic,
                  ),
                  listBullet: const TextStyle(
                    color: Color(0xFF0F766E),
                    fontSize: 16,
                  ),
                  tableBorder: TableBorder.all(
                    color: Colors.grey[300]!,
                    width: 1,
                  ),
                  tableHead: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF2D3748),
                  ),
                  tableBody: const TextStyle(color: Color(0xFF4A5568)),
                ),
                selectable: true,
                onTapLink: (text, href, title) {
                  if (href != null) {
                    logger.d('Tapped link: $href');
                  }
                },
              ),
            ),

            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  int _estimateReadingTime(String content) {
    // Rough estimation: 200 words per minute
    final wordCount = content.split(' ').length;
    return (wordCount / 200).ceil().clamp(1, 60);
  }

  Future<void> _shareStory(BuildContext context) async {
    if (_story == null) return;

    try {
      final shareLink = ShareUtils.generateSuccessStoryLink(_story!.id);
      final shareText = '${_story!.title}\n\n$shareLink';

      await Share.share(shareText, subject: _story!.title);
    } catch (e) {
      logger.e('Error sharing story: $e');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to share story'),
            duration: Duration(seconds: 2),
          ),
        );
      }
    }
  }
}
