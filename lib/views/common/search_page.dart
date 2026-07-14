import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:vector_academy/controllers/controllers.dart';
import 'package:vector_academy/components/components.dart';

class SearchPage extends StatelessWidget {
  const SearchPage({super.key});

  @override
  Widget build(BuildContext context) {
    Get.put(SearchPageController());
    return GetBuilder<SearchPageController>(
      builder: (controller) => Scaffold(
        appBar: AppBar(
          leading: const AppBackLeading(),
          title: Text('Search'),
          backgroundColor: Colors.transparent,
          elevation: 0,
        ),
        body: Column(
          children: [
            // Search Input
            Padding(
              padding: EdgeInsets.all(20),
              child: SearchTextField(
                controller: controller.searchController,
                hint: 'Search subjects, exams, notes...',
                onChanged: (query) => controller.search(query),
                onSubmitted: (query) => controller.search(query),
              ),
            ),

            // Search Results
            Expanded(
              child: controller.isLoading
                  ? _buildLoadingState()
                  : controller.searchQuery.isEmpty
                  ? _buildEmptyState(context)
                  : controller.searchResults.isEmpty
                  ? _buildNoResultsState(context)
                  : _buildSearchResults(context, controller),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoadingState() {
    return ListView.separated(
      padding: EdgeInsets.all(20),
      itemCount: 5,
      separatorBuilder: (context, index) => SizedBox(height: 12),
      itemBuilder: (context, index) => LoadingListTile(),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.search,
            size: 80,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
          SizedBox(height: 16),
          Text(
            'Search for anything',
            style: Theme.of(
              context,
            ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w600),
          ),
          SizedBox(height: 8),
          Text(
            'Find subjects, exams, notes, and more',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildNoResultsState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.search_off,
            size: 80,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
          SizedBox(height: 16),
          Text(
            'No results found',
            style: Theme.of(
              context,
            ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w600),
          ),
          SizedBox(height: 8),
          Text(
            'Try searching with different keywords',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildSearchResults(
    BuildContext context,
    SearchPageController controller,
  ) {
    return ListView.separated(
      padding: EdgeInsets.all(20),
      itemCount: controller.searchResults.length,
      separatorBuilder: (context, index) => SizedBox(height: 12),
      itemBuilder: (context, index) {
        final result = controller.searchResults[index];
        return _buildSearchResultItem(context, result, controller);
      },
    );
  }

  Widget _buildSearchResultItem(
    BuildContext context,
    Map<String, dynamic> result,
    SearchPageController controller,
  ) {
    IconData getIcon() {
      switch (result['type']) {
        case 'subject':
          return Icons.book_outlined;
        case 'exam':
          return Icons.quiz_outlined;
        case 'note':
          return Icons.description_outlined;
        case 'video':
          return Icons.play_circle_outlined;
        default:
          return Icons.search;
      }
    }

    Color getIconColor() {
      switch (result['type']) {
        case 'subject':
          return Theme.of(context).colorScheme.primary;
        case 'exam':
          return Theme.of(context).colorScheme.secondary;
        case 'note':
          return const Color(0xFF3B82F6);
        case 'video':
          return const Color(0xFFF59E0B);
        default:
          return Theme.of(context).colorScheme.onSurfaceVariant;
      }
    }

    return CustomCard(
      onTap: () => controller.openResult(result),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: getIconColor().withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(getIcon(), color: getIconColor(), size: 24),
          ),
          SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  result['title'],
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  result['subtitle'] ?? '',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
                SizedBox(height: 8),
                StatusBadge(
                  text: result['type'].toUpperCase(),
                  status: BadgeStatus.neutral,
                ),
              ],
            ),
          ),
          Icon(
            Icons.arrow_forward_ios,
            size: 16,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ],
      ),
    );
  }
}
