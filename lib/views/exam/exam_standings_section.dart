import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:vector_academy/components/ui/freshman_page_scaffold.dart';
import 'package:vector_academy/components/ui/themes/light_theme.dart';
import 'package:vector_academy/controllers/leaderboard/leaderboard_controller.dart';
import 'package:vector_academy/models/models.dart';

/// Competition rankings for the Exam tab — list layout (no podium).
class ExamStandingsSection extends StatelessWidget {
  const ExamStandingsSection({super.key});

  @override
  Widget build(BuildContext context) {
    final registered = Get.isRegistered<LeaderboardController>();
    if (!registered) {
      Get.put(LeaderboardController());
    }

    return GetBuilder<LeaderboardController>(
      builder: (controller) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (controller.isShowingOfflineData) _OfflineNotice(),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
              child: _CompetitionPicker(controller: controller),
            ),
            Expanded(child: _StandingsBody(controller: controller)),
          ],
        );
      },
    );
  }
}

class _OfflineNotice extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: secondaryColor.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: secondaryColor.withValues(alpha: 0.35)),
      ),
      child: Row(
        children: [
          Icon(Icons.cloud_off_outlined, size: 18, color: secondaryVariant),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Offline — showing saved standings',
              style: theme.textTheme.bodySmall?.copyWith(
                color: onSurfaceColor,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CompetitionPicker extends StatelessWidget {
  const _CompetitionPicker({required this.controller});

  final LeaderboardController controller;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (controller.isLoadingCompetitions && controller.competitions.isEmpty) {
      return FreshmanSurfaceCard(
        child: Row(
          children: [
            SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: primaryColor,
              ),
            ),
            const SizedBox(width: 12),
            Text(
              'Loading competitions…',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: onSurfaceVariant,
              ),
            ),
          ],
        ),
      );
    }

    if (controller.competitions.isEmpty) {
      return FreshmanSurfaceCard(
        child: Text(
          'No competitions available yet.',
          style: theme.textTheme.bodyMedium?.copyWith(color: onSurfaceVariant),
        ),
      );
    }

    return FreshmanSurfaceCard(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<int>(
          value: controller.selectedCompetitionId,
          isExpanded: true,
          hint: Text(
            'Choose a competition',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: onSurfaceVariant,
            ),
          ),
          icon: Icon(Icons.keyboard_arrow_down_rounded, color: primaryColor),
          items: controller.competitions.map((competition) {
            final id = competition['id'] as int;
            final name =
                competition['name'] as String? ?? 'Unknown competition';
            final isClosed = competition['isClosed'] == true;
            return DropdownMenuItem<int>(
              value: id,
              child: Text(
                isClosed ? '$name (closed)' : name,
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            );
          }).toList(),
          onChanged: controller.selectCompetition,
        ),
      ),
    );
  }
}

class _StandingsBody extends StatelessWidget {
  const _StandingsBody({required this.controller});

  final LeaderboardController controller;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (controller.selectedCompetitionId == null) {
      return _EmptyMessage(
        icon: Icons.leaderboard_outlined,
        message: 'Select a competition to see standings',
      );
    }

    if (controller.isLoading && controller.leaderboardEntries.isEmpty) {
      return Center(
        child: CircularProgressIndicator(color: primaryColor),
      );
    }

    if (controller.error != null && controller.leaderboardEntries.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, size: 48, color: errorColor),
              const SizedBox(height: 12),
              Text(
                controller.error!,
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 16),
              OutlinedButton(
                onPressed: controller.refreshLeaderboard,
                child: const Text('Try again'),
              ),
            ],
          ),
        ),
      );
    }

    final entries = controller.leaderboardEntries;
    if (entries.isEmpty) {
      return RefreshIndicator(
        color: primaryColor,
        onRefresh: controller.refreshLeaderboard,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          children: const [
            SizedBox(height: 120),
            _EmptyMessage(
              icon: Icons.groups_outlined,
              message: 'No rankings yet for this competition',
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      color: primaryColor,
      onRefresh: controller.refreshLeaderboard,
      child: ListView.builder(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
        itemCount: entries.length + 1,
        itemBuilder: (context, index) {
          if (index == 0) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _YourStandingStrip(entry: controller.myScoreEntry),
            );
          }
          return Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: _StandingRow(entry: entries[index - 1]),
          );
        },
      ),
    );
  }
}

class _YourStandingStrip extends StatelessWidget {
  const _YourStandingStrip({required this.entry});

  final LeaderboardEntry? entry;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: primaryColor.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: primaryColor.withValues(alpha: 0.25)),
      ),
      child: Row(
        children: [
          Text(
            'Your standing',
            style: theme.textTheme.labelLarge?.copyWith(
              color: primaryColor,
              fontWeight: FontWeight.w700,
            ),
          ),
          const Spacer(),
          if (entry == null)
            Text(
              'Not ranked yet',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: onSurfaceVariant,
              ),
            )
          else ...[
            Text(
              '#${entry!.rank}',
              style: theme.textTheme.headlineSmall?.copyWith(
                color: primaryColor,
              ),
            ),
            const SizedBox(width: 12),
            Text(
              '${entry!.score.toStringAsFixed(0)}%',
              style: theme.textTheme.titleMedium?.copyWith(
                color: onSurfaceColor,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _StandingRow extends StatelessWidget {
  const _StandingRow({required this.entry});

  final LeaderboardEntry entry;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return FreshmanSurfaceCard(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      child: Row(
        children: [
          SizedBox(
            width: 44,
            child: Text(
              '${entry.rank}',
              style: theme.textTheme.headlineSmall?.copyWith(
                color: onSurfaceColor,
              ),
            ),
          ),
          CircleAvatar(
            radius: 18,
            backgroundColor: primaryColor.withValues(alpha: 0.12),
            backgroundImage:
                entry.userImage != null && entry.userImage!.isNotEmpty
                    ? NetworkImage(entry.userImage!)
                    : null,
            child: entry.userImage == null || entry.userImage!.isEmpty
                ? Text(
                    entry.userName.isNotEmpty
                        ? entry.userName[0].toUpperCase()
                        : '?',
                    style: theme.textTheme.titleSmall?.copyWith(
                      color: primaryColor,
                      fontWeight: FontWeight.w700,
                    ),
                  )
                : null,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              entry.userName,
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w600,
                color: onSurfaceColor,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Text(
            '${entry.score.toStringAsFixed(0)}%',
            style: theme.textTheme.titleMedium?.copyWith(
              color: secondaryVariant,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyMessage extends StatelessWidget {
  const _EmptyMessage({required this.icon, required this.message});

  final IconData icon;
  final String message;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 48, color: onSurfaceVariant.withValues(alpha: 0.5)),
            const SizedBox(height: 12),
            Text(
              message,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
