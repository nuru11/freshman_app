import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:vector_academy/controllers/leaderboard/leaderboard_controller.dart';
import 'package:vector_academy/models/models.dart';
import 'package:vector_academy/utils/utils.dart';
import 'package:vector_academy/views/views.dart';

class LeaderboardPage extends StatelessWidget {
  const LeaderboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    // Get or create controller instance
    Get.isRegistered<LeaderboardController>()
        ? Get.find<LeaderboardController>()
        : Get.put(LeaderboardController());

    return GetBuilder<LeaderboardController>(
      builder: (controller) {
        final currentIndex = controller.selectedTabIndex;

        return DefaultTabController(
          length: 4,
          initialIndex: currentIndex,
          child: _TabControllerListener(
            controller: controller,
            child: Scaffold(
              backgroundColor: const Color(0xFFF5F7FA),
              appBar: AppBar(
                title: const Text(
                  'Leaderboard',
                  style: TextStyle(
                    color: Colors.black87,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                backgroundColor: Colors.white,
                elevation: 0,
                automaticallyImplyLeading: false,
                bottom: TabBar(
                  indicatorColor: Theme.of(context).colorScheme.primary,
                  indicatorWeight: 3,
                  labelColor: Theme.of(context).colorScheme.primary,
                  unselectedLabelColor: Colors.grey[600],
                  labelStyle: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                  unselectedLabelStyle: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                  ),
                  tabs: const [
                    Tab(
                      icon: Icon(Icons.emoji_events_rounded, size: 22),
                      text: 'Competition',
                    ),
                    Tab(icon: Icon(Icons.quiz_rounded, size: 22), text: 'Exam'),
                    Tab(
                      icon: Icon(Icons.assessment_rounded, size: 22),
                      text: 'My Score',
                    ),
                    Tab(
                      icon: Icon(Icons.auto_stories_rounded, size: 22),
                      text: 'Success Stories',
                    ),
                  ],
                ),
              ),
              body: SafeArea(
                child: Column(
                  children: [
                    if (controller.isShowingOfflineData)
                      _buildOfflineNotice(),
                    // Selection Dropdown
                    if (currentIndex <= 1)
                      _buildSelectionDropdown(context, controller),

                    // Leaderboard Content
                    Expanded(
                      child: IndexedStack(
                        index: currentIndex,
                        children: [
                          _buildLeaderboardList(context, controller),
                          _buildLeaderboardList(context, controller),
                          _buildMyScoreTab(context, controller),
                          _buildSuccessStoriesTab(context, controller),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  static Widget _buildSelectionDropdown(
    BuildContext context,
    LeaderboardController controller,
  ) {
    // Show loading state for competitions or exams
    final isLoadingData = controller.selectedType == LeaderboardType.competition
        ? controller.isLoadingCompetitions
        : controller.isLoadingExams;

    if (isLoadingData) {
      return Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              blurRadius: 12,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(
                  Theme.of(context).colorScheme.primary,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Text(
              controller.selectedType == LeaderboardType.competition
                  ? 'Loading competitions...'
                  : 'Loading exams...',
              style: TextStyle(color: Colors.grey[600], fontSize: 15),
            ),
          ],
        ),
      );
    }

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 12,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          isExpanded: true,
          value: controller.selectedType == LeaderboardType.competition
              ? controller.selectedCompetitionId?.toString()
              : controller.selectedExamId?.toString(),
          hint: Text(
            controller.selectedType == LeaderboardType.competition
                ? 'Select Competition'
                : 'Select Exam',
            style: TextStyle(color: Colors.grey[600], fontSize: 15),
          ),
          items: controller.selectedType == LeaderboardType.competition
              ? [
                  ...controller.competitions.map((comp) {
                    // Ensure the ID is valid
                    final id = comp['id'];
                    if (id == null || id is! int) {
                      return null;
                    }
                    
                    return DropdownMenuItem<String>(
                      value: id.toString(),
                      child: Row(
                        children: [
                          Icon(
                            Icons.emoji_events_rounded,
                            size: 20,
                            color: Colors.grey[700],
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              comp['name'] as String? ?? 'Unknown Competition',
                              style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w500,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (comp['isClosed'] == true)
                            Container(
                              margin: const EdgeInsets.only(left: 8),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.grey[200],
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: const Text(
                                'Closed',
                                style: TextStyle(
                                  fontSize: 10,
                                  color: Colors.grey,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                        ],
                      ),
                    );
                  }).whereType<DropdownMenuItem<String>>(), // Filter out nulls
                ]
              : [
                  ...controller.exams.map((exam) {
                    return DropdownMenuItem<String>(
                      value: exam.id.toString(),
                      child: Row(
                        children: [
                          Icon(
                            Icons.quiz_rounded,
                            size: 20,
                            color: Colors.grey[700],
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              exam.name,
                              style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w500,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    );
                  }),
                ],
          onChanged: (value) {
            if (value != null) {
              try {
                final id = int.parse(value);
                if (controller.selectedType == LeaderboardType.competition) {
                  controller.selectCompetition(id);
                } else {
                  controller.selectExam(id);
                }
              } catch (e) {
                logger.e('Failed to parse selection ID: $e');
              }
            }
          },
          icon: Icon(
            Icons.keyboard_arrow_down_rounded,
            color: Colors.grey[600],
          ),
          style: TextStyle(color: Colors.grey[800], fontSize: 15),
        ),
      ),
    );
  }

  static Widget _buildOfflineNotice() {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 10, 16, 0),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF7E6),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFFFD89C)),
      ),
      child: const Row(
        children: [
          Icon(Icons.wifi_off_rounded, size: 16, color: Color(0xFF8A5A00)),
          SizedBox(width: 8),
          Expanded(
            child: Text(
              "You're offline – showing saved data",
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Color(0xFF8A5A00),
              ),
            ),
          ),
        ],
      ),
    );
  }

  static Widget _buildLeaderboardList(
    BuildContext context,
    LeaderboardController controller,
  ) {
    if (controller.isLoading) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(
                Theme.of(context).colorScheme.primary,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Loading leaderboard...',
              style: TextStyle(color: Colors.grey[600], fontSize: 14),
            ),
          ],
        ),
      );
    }

    if (controller.error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.red[50],
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.error_outline_rounded,
                  size: 48,
                  color: Colors.red[400],
                ),
              ),
              const SizedBox(height: 20),
              Text(
                'Error loading leaderboard',
                style: TextStyle(
                  color: Colors.grey[800],
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                controller.error ?? 'Unknown error',
                style: TextStyle(color: Colors.grey[600], fontSize: 13),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: () => controller.refreshLeaderboard(),
                icon: const Icon(Icons.refresh_rounded),
                label: const Text('Retry'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 12,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (controller.selectedType == LeaderboardType.competition &&
        controller.selectedCompetitionId == null) {
      return _buildEmptyState(
        context,
        'Select a competition to view leaderboard',
        Icons.emoji_events_rounded,
      );
    }

    if (controller.selectedType == LeaderboardType.exam &&
        controller.selectedExamId == null) {
      return _buildEmptyState(
        context,
        'Select an exam to view leaderboard',
        Icons.quiz_rounded,
      );
    }

    if (controller.leaderboardEntries.isEmpty) {
      return _buildEmptyState(
        context,
        'No leaderboard data available',
        Icons.leaderboard_rounded,
      );
    }

    final topThree =
        controller.leaderboardEntries.where((e) => e.rank <= 3).toList()
          ..sort((a, b) => a.rank.compareTo(b.rank));
    final rest = controller.leaderboardEntries
        .where((e) => e.rank > 3)
        .toList();

    return RefreshIndicator(
      onRefresh: () => controller.refreshLeaderboard(),
      color: Theme.of(context).colorScheme.primary,
      child: CustomScrollView(
        slivers: [
          // Podium for Top 3
          if (topThree.length >= 3)
            SliverToBoxAdapter(child: _buildPodium(context, topThree))
          else if (topThree.isNotEmpty)
            SliverToBoxAdapter(child: _buildPodium(context, topThree)),

          // Rest of the leaderboard
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
            sliver: SliverList(
              delegate: SliverChildBuilderDelegate((context, index) {
                final entry = rest[index];
                return _buildLeaderboardItem(context, entry, index);
              }, childCount: rest.length),
            ),
          ),
        ],
      ),
    );
  }

  static Widget _buildMyScoreTab(
    BuildContext context,
    LeaderboardController controller,
  ) {
    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      child: Column(
        children: [
          _buildMyScoreCard(context, controller),
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  static Widget _buildSuccessStoriesTab(
    BuildContext context,
    LeaderboardController controller,
  ) {
    final stories = controller.successStories;
    if (stories.isEmpty) {
      return _buildEmptyState(
        context,
        'No success stories available',
        Icons.auto_stories_rounded,
      );
    }

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
      children: [
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.06),
                blurRadius: 10,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Success Stories',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 10),
              ...stories.map((story) => _buildStoryTile(context, story)),
            ],
          ),
        ),
      ],
    );
  }

  static Widget _buildMyScoreCard(
    BuildContext context,
    LeaderboardController controller,
  ) {
    final myEntry = controller.myScoreEntry;
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () => Get.to(() => const UserScorePage()),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.06),
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: myEntry == null
                ? Row(
                    children: [
                      Icon(
                        Icons.assessment_rounded,
                        color: Colors.grey[700],
                        size: 22,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'My Score: not available yet in this leaderboard.',
                          style: TextStyle(
                            color: Colors.grey[700],
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  )
                : Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Theme.of(
                            context,
                          ).colorScheme.primary.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          Icons.person_pin_circle_rounded,
                          color: Theme.of(context).colorScheme.primary,
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'My Score',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: Colors.black54,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Rank #${myEntry.rank}  •  ${myEntry.score.toStringAsFixed(1)}%',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.black87,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
          ),
        ),
      ),
    );
  }

  static Widget _buildStoryTile(BuildContext context, SuccessStory story) {
    return InkWell(
      onTap: () => Get.toNamed(VIEWS.successStoryDetail.path, arguments: story),
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
        margin: const EdgeInsets.only(bottom: 4),
        child: Row(
          children: [
            Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                Icons.emoji_events_rounded,
                size: 18,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    story.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                  ),
                  if ((story.studentName ?? '').isNotEmpty)
                    Text(
                      story.studentName!,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                    ),
                ],
              ),
            ),
            Icon(Icons.chevron_right_rounded, color: Colors.grey[500]),
          ],
        ),
      ),
    );
  }

  static Widget _buildPodium(
    BuildContext context,
    List<LeaderboardEntry> topThree,
  ) {
    final primaryColor = Theme.of(context).colorScheme.primary;

    // Ensure we have at least 3 entries, pad with nulls if needed
    final entries = List<LeaderboardEntry?>.filled(3, null);
    for (int i = 0; i < topThree.length && i < 3; i++) {
      entries[i] = topThree[i];
    }

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            primaryColor.withValues(alpha: 0.1),
            primaryColor.withValues(alpha: 0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: primaryColor.withValues(alpha: 0.2),
          width: 1.5,
        ),
      ),
      child: Column(
        children: [
          Text(
            'Top Performers',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.grey[800],
            ),
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              // 2nd Place
              if (entries[1] != null)
                Expanded(
                  child: _buildPodiumItem(context, entries[1]!, 2, false),
                )
              else
                const Expanded(child: SizedBox()),

              const SizedBox(width: 8),

              // 1st Place
              if (entries[0] != null)
                Expanded(child: _buildPodiumItem(context, entries[0]!, 1, true))
              else
                const Expanded(child: SizedBox()),

              const SizedBox(width: 8),

              // 3rd Place
              if (entries[2] != null)
                Expanded(
                  child: _buildPodiumItem(context, entries[2]!, 3, false),
                )
              else
                const Expanded(child: SizedBox()),
            ],
          ),
        ],
      ),
    );
  }

  static Widget _buildPodiumItem(
    BuildContext context,
    LeaderboardEntry entry,
    int rank,
    bool isFirst,
  ) {
    final rankColors = [
      const Color(0xFFFFD700),
      const Color(0xFFC0C0C0),
      const Color(0xFFCD7F32),
    ];
    final heights = [140.0, 110.0, 100.0];
    final avatarSizes = [56.0, 48.0, 44.0];

    return Column(
      children: [
        // Crown for 1st place
        if (isFirst)
          Container(
            margin: const EdgeInsets.only(bottom: 8),
            child: Icon(
              Icons.workspace_premium_rounded,
              color: rankColors[0],
              size: 32,
            ),
          )
        else
          const SizedBox(height: 40),

        // Avatar
        Container(
          width: avatarSizes[rank - 1],
          height: avatarSizes[rank - 1],
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: rankColors[rank - 1], width: 3),
            boxShadow: [
              BoxShadow(
                color: rankColors[rank - 1].withValues(alpha: 0.3),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: CircleAvatar(
            radius: avatarSizes[rank - 1] / 2,
            backgroundColor: Colors.grey[200],
            backgroundImage: entry.userImage != null
                ? NetworkImage(entry.userImage!)
                : null,
            child: entry.userImage == null
                ? Text(
                    entry.userName.isNotEmpty
                        ? entry.userName[0].toUpperCase()
                        : '?',
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontWeight: FontWeight.bold,
                      fontSize: avatarSizes[rank - 1] / 2,
                    ),
                  )
                : null,
          ),
        ),

        const SizedBox(height: 8),

        // Name
        Text(
          entry.userName,
          style: TextStyle(
            fontSize: isFirst ? 14 : 12,
            fontWeight: isFirst ? FontWeight.bold : FontWeight.w600,
            color: Colors.grey[800],
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          textAlign: TextAlign.center,
        ),

        const SizedBox(height: 4),

        // Score
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: rankColors[rank - 1].withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            '${entry.score.toStringAsFixed(1)}%',
            style: TextStyle(
              fontSize: isFirst ? 16 : 14,
              fontWeight: FontWeight.bold,
              color: rankColors[rank - 1],
            ),
          ),
        ),

        const SizedBox(height: 12),

        // Podium base
        Container(
          height: heights[rank - 1],
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                rankColors[rank - 1],
                rankColors[rank - 1].withValues(alpha: 0.7),
              ],
            ),
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(12),
              topRight: Radius.circular(12),
            ),
            boxShadow: [
              BoxShadow(
                color: rankColors[rank - 1].withValues(alpha: 0.3),
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Center(
            child: Text(
              '#$rank',
              style: const TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
        ),
      ],
    );
  }

  static Widget _buildLeaderboardItem(
    BuildContext context,
    LeaderboardEntry entry,
    int index,
  ) {
    final primaryColor = Theme.of(context).colorScheme.primary;

    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: Duration(milliseconds: 300 + (index * 50)),
      curve: Curves.easeOut,
      builder: (context, value, child) {
        return Opacity(
          opacity: value,
          child: Transform.translate(
            offset: Offset(0, 20 * (1 - value)),
            child: child,
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            // Rank Badge
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: Colors.grey[100],
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Text(
                  '#${entry.rank}',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey[700],
                  ),
                ),
              ),
            ),
            const SizedBox(width: 16),

            // User Avatar
            CircleAvatar(
              radius: 26,
              backgroundColor: Colors.grey[200],
              backgroundImage: entry.userImage != null
                  ? NetworkImage(entry.userImage!)
                  : null,
              child: entry.userImage == null
                  ? Text(
                      entry.userName.isNotEmpty
                          ? entry.userName[0].toUpperCase()
                          : '?',
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    )
                  : null,
            ),
            const SizedBox(width: 16),

            // User Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    entry.userName,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (entry.examName != null ||
                      entry.competitionName != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      entry.examName ?? entry.competitionName ?? '',
                      style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ],
              ),
            ),

            // Score
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    primaryColor.withValues(alpha: 0.15),
                    primaryColor.withValues(alpha: 0.1),
                  ],
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '${entry.score.toStringAsFixed(1)}%',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: primaryColor,
                    ),
                  ),
                  Text(
                    'Score',
                    style: TextStyle(
                      fontSize: 10,
                      color: Colors.grey[600],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  static Widget _buildEmptyState(
    BuildContext context,
    String message,
    IconData icon,
  ) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 64, color: Colors.grey[400]),
            ),
            const SizedBox(height: 24),
            Text(
              message,
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class _TabControllerListener extends StatefulWidget {
  final LeaderboardController controller;
  final Widget child;

  const _TabControllerListener({required this.controller, required this.child});

  @override
  State<_TabControllerListener> createState() => _TabControllerListenerState();
}

class _TabControllerListenerState extends State<_TabControllerListener> {
  TabController? _tabController;
  bool _listenerAdded = false;
  int _lastLeaderboardTabIndex = 0;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final tabController = DefaultTabController.of(context);

    if (_tabController != tabController && !_listenerAdded) {
      _tabController = tabController;
      _listenerAdded = true;

      // Listen to tab changes and sync with controller
      tabController.addListener(_handleTabChange);
    }
  }

  void _handleTabChange() {
    if (_tabController != null && !_tabController!.indexIsChanging) {
      final index = _tabController!.index;

      if (index <= 1) {
        _lastLeaderboardTabIndex = index;
        widget.controller.onTabChanged(index);
        return;
      }

      if (index == 2) {
        Get.to(() => const UserScorePage());
        _tabController!.animateTo(_lastLeaderboardTabIndex);
        return;
      }

      widget.controller.onTabChanged(index);
    }
  }

  @override
  void dispose() {
    if (_listenerAdded && _tabController != null) {
      _tabController!.removeListener(_handleTabChange);
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}
