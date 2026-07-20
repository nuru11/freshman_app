import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:vector_academy/components/components.dart';
import 'package:vector_academy/controllers/controllers.dart';
import 'package:vector_academy/models/models.dart';
import 'package:vector_academy/utils/utils.dart';
import 'package:vector_academy/views/views.dart';
import 'package:vector_academy/flavors/flavor_config.dart';
import 'package:vector_academy/config/app_config.dart';
import 'package:vector_academy/config/support_config.dart';
import 'package:url_launcher/url_launcher.dart';

class HomeDashboard extends StatelessWidget {
  HomeDashboard({super.key});

  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  String _greeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good morning';
    if (hour < 17) return 'Good afternoon';
    return 'Good evening';
  }

  @override
  Widget build(BuildContext context) {
    Get.put(HomeDashboardController());
    Get.put(NavigationDrawerController());
    Get.put(NotificationsController());

    return GetBuilder<HomeDashboardController>(
      builder: (controller) => Scaffold(
        key: _scaffoldKey,
        backgroundColor: backgroundColor,
        drawer: _buildDrawer(context),
        body: SafeArea(
          child: Column(
            children: [
              _buildHeader(context, controller),
              _buildSearch(context, controller),
              if (controller.hasSearchQuery)
                Expanded(child: _buildSearchResults(context, controller))
              else
                Expanded(
                  child: RefreshIndicator(
                    onRefresh: controller.refreshData,
                    child: CustomScrollView(
                      physics: const AlwaysScrollableScrollPhysics(
                        parent: BouncingScrollPhysics(),
                      ),
                      slivers: [
                        SliverToBoxAdapter(
                          child: _buildYearChip(context, controller),
                        ),
                        SliverToBoxAdapter(
                          child: _buildSectionTitle(
                            context,
                            'Your $subjectsLabel',
                          ),
                        ),
                        _buildCourseGrid(context, controller),
                        SliverToBoxAdapter(
                          child: _buildSectionTitle(context, 'Campus updates'),
                        ),
                        SliverToBoxAdapter(
                          child: _buildCampusUpdates(context, controller),
                        ),
                        const SliverToBoxAdapter(child: SizedBox(height: 24)),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(
    BuildContext context,
    HomeDashboardController controller,
  ) {
    final theme = Theme.of(context);
    final name = controller.user?.firstName ?? 'Student';
    final yearName = controller.user?.grade.name;

    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 4),
      child: Row(
        children: [
          IconButton(
            onPressed: () => _scaffoldKey.currentState?.openDrawer(),
            icon: const Icon(Icons.menu_rounded),
          ),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Image.asset(
              FlavorConfig.logoAsset,
              width: 36,
              height: 36,
              fit: BoxFit.cover,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${_greeting()}, $name',
                  style: theme.textTheme.titleMedium,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  FlavorConfig.appTitle,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          if (yearName != null && yearName.isNotEmpty)
            Container(
              margin: const EdgeInsets.only(right: 4),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: secondaryColor.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: borderColor),
              ),
              child: Text(
                yearName.split('—').first.trim().length > 18
                    ? yearName.substring(0, 18)
                    : yearName.split('—').first.trim(),
                style: theme.textTheme.labelMedium?.copyWith(
                  color: secondaryColor,
                  fontWeight: FontWeight.w700,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          GetBuilder<NotificationsController>(
            builder: (notificationsController) => BadgeButton(
              showBadge: notificationsController.unreadCount > 0,
              badgeText:
                  '${notificationsController.unreadCount > 9 ? "9+" : notificationsController.unreadCount}',
              child: IconButton(
                onPressed: () => Get.to(() => const NotificationsPage()),
                icon: const Icon(Icons.notifications_none_rounded),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearch(
    BuildContext context,
    HomeDashboardController controller,
  ) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
      child: SearchTextField(
        controller: controller.homeSearchController,
        hint: 'Search courses, chapters, notes...',
        onChanged: controller.updateSearchQuery,
        onClear: controller.clearSearch,
      ),
    );
  }

  Widget _buildYearChip(
    BuildContext context,
    HomeDashboardController controller,
  ) {
    final yearName = controller.user?.grade.name;
    if (yearName == null || yearName.isEmpty) {
      return const SizedBox(height: 4);
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Chip(
          avatar: Icon(Icons.school_outlined, size: 16, color: primaryColor),
          label: Text(yearName),
          backgroundColor: surfaceColor,
          side: const BorderSide(color: borderColor),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 10),
      child: Text(title, style: Theme.of(context).textTheme.headlineSmall),
    );
  }

  Widget _buildCourseGrid(
    BuildContext context,
    HomeDashboardController controller,
  ) {
    if (controller.isLoading && controller.subjects.isEmpty) {
      return const SliverFillRemaining(
        child: Center(child: CircularProgressIndicator()),
      );
    }

    if (controller.subjects.isEmpty) {
      return SliverToBoxAdapter(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(
            'No $subjectsLabel available yet for your $gradeLabel.',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: onSurfaceVariant,
                ),
          ),
        ),
      );
    }

    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      sliver: SliverGrid(
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          mainAxisSpacing: 10,
          crossAxisSpacing: 10,
          childAspectRatio: 0.78,
        ),
        delegate: SliverChildBuilderDelegate(
          (context, index) {
            final subject = controller.subjects[index];
            return _CourseTile(
              subject: subject,
              onTap: () => controller.selectSubject(subject.id),
            );
          },
          childCount: controller.subjects.length,
        ),
      ),
    );
  }

  Widget _buildCampusUpdates(
    BuildContext context,
    HomeDashboardController controller,
  ) {
    final theme = Theme.of(context);
    final updates = controller.featuredUpdates;

    if (controller.isFeaturedUpdatesLoading && updates.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(24),
        child: Center(child: CircularProgressIndicator()),
      );
    }

    if (updates.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: FreshmanSurfaceCard(
          child: Text(
            'No campus updates right now. Check Exam for practice quizzes.',
            style: theme.textTheme.bodyMedium?.copyWith(color: onSurfaceVariant),
          ),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: updates.take(4).map((item) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: FreshmanSurfaceCard(
              onTap: () => controller.openFeaturedUpdate(item),
              child: Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: primaryColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      item.type == FeaturedUpdateType.news
                          ? Icons.campaign_outlined
                          : Icons.quiz_outlined,
                      color: primaryColor,
                      size: 18,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item.title,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.titleSmall,
                        ),
                        Text(
                          item.type == FeaturedUpdateType.news
                              ? 'News'
                              : 'Practice',
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Icon(Icons.chevron_right_rounded, color: onSurfaceVariant),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildSearchResults(
    BuildContext context,
    HomeDashboardController controller,
  ) {
    if (!controller.hasAnySearchResult) {
      return Center(
        child: Text(
          'No matches found',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: onSurfaceVariant,
              ),
        ),
      );
    }

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        if (controller.chapterResults.isNotEmpty) ...[
          Text('Chapters', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          ...controller.chapterResults.map(
            (c) => ListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(c.name),
              leading: const Icon(Icons.article_outlined),
              onTap: () => controller.openChapterSearchResult(c),
            ),
          ),
          const SizedBox(height: 12),
        ],
        if (controller.videoResults.isNotEmpty) ...[
          Text('Videos', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          ...controller.videoResults.map(
            (v) => ListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(v.title),
              leading: const Icon(Icons.play_circle_outline),
              onTap: () => controller.openVideoSearchResult(v),
            ),
          ),
          const SizedBox(height: 12),
        ],
        if (controller.worksheetResults.isNotEmpty) ...[
          Text('Notes', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          ...controller.worksheetResults.map(
            (n) => ListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(n.title),
              leading: const Icon(Icons.description_outlined),
              onTap: () => controller.openWorksheetSearchResult(n),
            ),
          ),
          const SizedBox(height: 12),
        ],
        if (controller.examResults.isNotEmpty) ...[
          Text('Practice quizzes', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          ...controller.examResults.map(
            (e) => ListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(e.name),
              leading: const Icon(Icons.quiz_outlined),
              onTap: () => controller.openExam(e.id),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildDrawer(BuildContext context) {
    final theme = Theme.of(context);
    final nav = Get.find<MainNavigationController>();

    Widget item({
      required IconData icon,
      required String title,
      required VoidCallback onTap,
      bool selected = false,
    }) {
      return ListTile(
        leading: Icon(icon, color: selected ? primaryColor : onSurfaceVariant),
        title: Text(
          title,
          style: theme.textTheme.titleSmall?.copyWith(
            color: selected ? primaryColor : onSurfaceColor,
            fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
          ),
        ),
        selected: selected,
        selectedTileColor: primaryColor.withValues(alpha: 0.08),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        onTap: () {
          Navigator.of(context).pop();
          onTap();
        },
      );
    }

    return Drawer(
      backgroundColor: backgroundColor,
      child: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(12, 16, 12, 24),
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 0, 8, 16),
              child: Row(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: Image.asset(
                      FlavorConfig.logoAsset,
                      width: 44,
                      height: 44,
                      fit: BoxFit.cover,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          FlavorConfig.appTitle,
                          style: theme.textTheme.headlineSmall,
                        ),
                        Text(
                          'University freshman courses',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const Divider(),
            item(
              icon: Icons.home_outlined,
              title: 'Home',
              selected: nav.currentIndex == 0,
              onTap: () => nav.changeIndex(0),
            ),
            item(
              icon: Icons.menu_book_outlined,
              title: 'My $subjectsLabel',
              selected: nav.currentIndex == 1,
              onTap: () => nav.changeIndex(1),
            ),
            item(
              icon: Icons.quiz_outlined,
              title: 'Exam',
              selected: nav.currentIndex == 2,
              onTap: () => nav.changeIndex(2),
            ),
            item(
              icon: Icons.event_note_outlined,
              title: 'Study Planner',
              selected: nav.currentIndex == 3,
              onTap: () => nav.changeIndex(3),
            ),
            item(
              icon: Icons.person_outline,
              title: 'Profile',
              selected: nav.currentIndex == 4,
              onTap: () => nav.changeIndex(4),
            ),
            const Divider(),
            item(
              icon: Icons.download_outlined,
              title: 'Downloads',
              onTap: () => Get.to(() => const DownloadsPage()),
            ),
            item(
              icon: Icons.help_outline,
              title: 'FAQ',
              onTap: () => Get.to(() => const FAQPage()),
            ),
            item(
              icon: Icons.support_agent_outlined,
              title: 'Support',
              onTap: () => Get.to(() => const SupportPage()),
            ),
            item(
              icon: Icons.info_outline,
              title: 'About',
              onTap: () => Get.to(() => const AboutPage()),
            ),
            item(
              icon: Icons.telegram,
              title: 'Telegram',
              onTap: () async {
                await launchUrl(Uri.parse(supportTelegramUrl));
              },
            ),
            GetBuilder<NavigationDrawerController>(
              builder: (drawerController) => item(
                icon: Icons.logout,
                title: 'Log out',
                onTap: () => drawerController.logout(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CourseTile extends StatelessWidget {
  const _CourseTile({required this.subject, required this.onTap});

  final Subject subject;
  final VoidCallback onTap;

  bool get _hasIcon => subject.icon != null && subject.icon!.trim().isNotEmpty;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final chapterCount = subject.chapters.length;

    return FreshmanSurfaceCard(
      padding: const EdgeInsets.all(10),
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: _hasIcon
                  ? CachedNetworkImage(
                      imageUrl: subject.icon!,
                      fit: BoxFit.cover,
                      width: double.infinity,
                      height: double.infinity,
                      placeholder: (context, url) => Container(
                        color: primaryColor.withValues(alpha: 0.08),
                        child: const Center(
                          child: SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                        ),
                      ),
                      errorWidget: (context, url, error) =>
                          _thumbnailFallback(),
                    )
                  : _thumbnailFallback(),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            subject.name,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.titleSmall,
          ),
          const SizedBox(height: 2),
          Text(
            chapterCount == 1 ? '1 chapter' : '$chapterCount chapters',
            style: theme.textTheme.labelSmall?.copyWith(color: onSurfaceVariant),
          ),
        ],
      ),
    );
  }

  Widget _thumbnailFallback() {
    return Container(
      color: primaryColor.withValues(alpha: 0.1),
      child: Center(
        child: Icon(
          Icons.menu_book_rounded,
          color: primaryColor,
          size: 28,
        ),
      ),
    );
  }
}
