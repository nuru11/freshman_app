import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:vector_academy/controllers/controllers.dart';
import 'package:vector_academy/models/models.dart';
import 'package:vector_academy/utils/utils.dart';
import 'package:vector_academy/components/components.dart';

class NewsPage extends StatelessWidget {
  const NewsPage({super.key});

  static const _fallbackCover =
      'https://images.unsplash.com/photo-1504711434969-e33886168f5c?w=400&h=280&fit=crop';

  @override
  Widget build(BuildContext context) {
    Get.put(NewsController());
    return GetBuilder<NewsController>(
      builder: (controller) => FreshmanPageScaffold(
        embeddedInTab: true,
        showBack: false,
        title: 'Campus News',
        subtitle: 'Announcements and updates',
        actions: [
          IconButton(
            icon: const Icon(Icons.search_rounded),
            onPressed: () =>
                showSearch(context: context, delegate: NewsSearchDelegate()),
          ),
        ],
        body: RefreshIndicator(
          color: primaryColor,
          onRefresh: () => controller.loadNews(),
          child: CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [
              if (controller.isShowingOfflineData)
                SliverToBoxAdapter(child: _buildOfflineNotice()),
              if (controller.featuredNews != null)
                SliverToBoxAdapter(
                  child: _buildLeadCard(context, controller),
                ),
              _buildCategoriesSection(context, controller),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                  child: Text(
                    'Latest',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: onSurfaceColor,
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                ),
              ),
              _buildNewsList(context, controller),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLeadCard(BuildContext context, NewsController controller) {
    final featured = controller.featuredNews!;
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
      child: FreshmanSurfaceCard(
        padding: EdgeInsets.zero,
        onTap: () => controller.openNewsDetail(featured.id),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(10),
              ),
              child: AspectRatio(
                aspectRatio: 16 / 9,
                child: Image.network(
                  featured.coverImage ?? _fallbackCover,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Container(
                    color: primaryColor.withValues(alpha: 0.1),
                    child: Icon(
                      Icons.campaign_outlined,
                      color: primaryColor,
                      size: 40,
                    ),
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: primaryColor.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: borderColor),
                        ),
                        child: Text(
                          featured.category.capitalize ?? '',
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: primaryColor,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      const Spacer(),
                      Text(
                        toAgoDate(featured.createdAt),
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    featured.title.capitalize ?? '',
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: onSurfaceColor,
                      fontWeight: FontWeight.w700,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Text(
                        'Read article',
                        style: theme.textTheme.labelMedium?.copyWith(
                          color: primaryColor,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(width: 2),
                      Icon(
                        Icons.chevron_right_rounded,
                        size: 18,
                        color: secondaryColor,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOfflineNotice() {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 4),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: secondaryColor.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: secondaryColor.withValues(alpha: 0.35)),
      ),
      child: Row(
        children: [
          Icon(Icons.wifi_off_rounded, size: 16, color: secondaryColor),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              "You're offline – showing saved data",
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: secondaryColor,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoriesSection(
    BuildContext context,
    NewsController controller,
  ) {
    if (controller.categories.isEmpty) {
      return const SliverToBoxAdapter(child: SizedBox.shrink());
    }

    return SliverToBoxAdapter(
      child: SizedBox(
        height: 44,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          itemCount: controller.categories.length,
          separatorBuilder: (_, __) => const SizedBox(width: 8),
          itemBuilder: (context, index) {
            final category = controller.categories[index];
            final isSelected = index == controller.selectedCategoryIndex;

            return GestureDetector(
              onTap: () => controller.changeCategory(index),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: isSelected
                      ? primaryColor.withValues(alpha: 0.12)
                      : surfaceColor,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: isSelected ? primaryColor : borderColor,
                  ),
                ),
                child: Text(
                  category,
                  style: TextStyle(
                    color: isSelected ? primaryColor : onSurfaceVariant,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildNewsList(BuildContext context, NewsController controller) {
    if (controller.isLoading && controller.news.isEmpty) {
      return const SliverFillRemaining(
        child: Center(child: CircularProgressIndicator()),
      );
    }

    if (controller.news.isEmpty) {
      return SliverFillRemaining(
        hasScrollBody: false,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.article_outlined, size: 48, color: onSurfaceVariant),
              const SizedBox(height: 12),
              Text(
                'No campus updates yet',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: onSurfaceVariant,
                    ),
              ),
            ],
          ),
        ),
      );
    }

    return SliverPadding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      sliver: SliverList.separated(
        itemCount: controller.news.length,
        separatorBuilder: (_, __) => const SizedBox(height: 8),
        itemBuilder: (context, index) {
          final news = controller.news[index];
          return _NewsListRow(
            news: news,
            onTap: () => controller.openNewsDetail(news.id),
          );
        },
      ),
    );
  }
}

class _NewsListRow extends StatelessWidget {
  const _NewsListRow({required this.news, required this.onTap});

  final News news;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final thumb = news.coverImage ??
        'https://images.unsplash.com/photo-${1500000000000 + news.id}?w=80&h=80&fit=crop';

    return FreshmanSurfaceCard(
      onTap: onTap,
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Image.network(
              thumb,
              width: 64,
              height: 64,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => Container(
                width: 64,
                height: 64,
                color: primaryColor.withValues(alpha: 0.08),
                child: Icon(
                  Icons.image_outlined,
                  color: onSurfaceVariant,
                  size: 22,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  news.category.capitalize ?? '',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: primaryColor,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  news.title.capitalize ?? '',
                  style: theme.textTheme.titleSmall?.copyWith(
                    color: onSurfaceColor,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  toAgoDate(news.createdAt),
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          Icon(Icons.chevron_right_rounded, color: secondaryColor, size: 22),
        ],
      ),
    );
  }
}

class NewsSearchDelegate extends SearchDelegate<News> {
  @override
  List<Widget> buildActions(BuildContext context) {
    return [
      IconButton(
        onPressed: () => query = '',
        icon: const Icon(Icons.close),
      ),
    ];
  }

  @override
  Widget buildLeading(BuildContext context) {
    return IconButton(
      onPressed: () => Get.back(),
      icon: const Icon(Icons.arrow_back),
    );
  }

  @override
  Widget buildResults(BuildContext context) {
    final controller = Get.find<NewsController>();
    return FutureBuilder<List<News>>(
      future: controller.searchNews(query),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        final results = snapshot.data ?? [];
        if (results.isEmpty) {
          return Center(
            child: Text(
              'No results found',
              style: TextStyle(color: onSurfaceVariant),
            ),
          );
        }
        return _buildSearchList(context, results, controller);
      },
    );
  }

  @override
  Widget buildSuggestions(BuildContext context) {
    final controller = Get.find<NewsController>();
    return _buildSearchList(context, controller.news, controller);
  }

  Widget _buildSearchList(
    BuildContext context,
    List<News> items,
    NewsController controller,
  ) {
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: items.length,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (context, index) {
        final news = items[index];
        return _NewsListRow(
          news: news,
          onTap: () => controller.openNewsDetail(news.id),
        );
      },
    );
  }
}
