import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:vector_academy/components/components.dart';
import 'package:vector_academy/controllers/study_hub/challenge_controller.dart';
import 'package:vector_academy/models/reading_premium.dart';

class ChallengeTab extends StatelessWidget {
  const ChallengeTab({super.key});

  @override
  Widget build(BuildContext context) {
    return GetBuilder<ChallengeController>(
      builder: (controller) {
        if (controller.isLoading && controller.challenges.isEmpty) {
          return const Center(child: CircularProgressIndicator());
        }
        return RefreshIndicator(
          color: primaryColor,
          onRefresh: controller.load,
          child: controller.challenges.isEmpty
              ? ListView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  children: [
                    SizedBox(
                      height: MediaQuery.of(context).size.height * 0.4,
                      child: Center(
                        child: Text(
                          'No reading challenges yet. Admin will post group targets here.',
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: onSurfaceVariant,
                          ),
                        ),
                      ),
                    ),
                  ],
                )
              : ListView.separated(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
                  itemCount: controller.challenges.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (context, index) {
                    final challenge = controller.challenges[index];
                    return _ChallengeCard(
                      challenge: challenge,
                      onJoin: () => controller.join(challenge),
                      onAlarm: (v) => controller.toggleAlarm(challenge, v),
                    );
                  },
                ),
        );
      },
    );
  }
}

class _ChallengeCard extends StatelessWidget {
  const _ChallengeCard({
    required this.challenge,
    required this.onJoin,
    required this.onAlarm,
  });

  final ReadingChallenge challenge;
  final VoidCallback onJoin;
  final ValueChanged<bool> onAlarm;

  @override
  Widget build(BuildContext context) {
    final deadline = challenge.deadline;
    return FreshmanSurfaceCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            challenge.title,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          if (challenge.description.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(
              challenge.description,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: onSurfaceVariant,
              ),
            ),
          ],
          const SizedBox(height: 8),
          Text(
            'Target: ${challenge.targetBooks} books'
            '${deadline == null ? '' : ' by ${DateFormat.yMMMd().format(deadline.toLocal())}'}',
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
          if (challenge.rules.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              challenge.rules,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
          const SizedBox(height: 8),
          Text(
            '${challenge.membersCount} joined',
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              if (!challenge.joined)
                FilledButton(
                  onPressed: onJoin,
                  style: FilledButton.styleFrom(
                    backgroundColor: primaryColor,
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('Join'),
                )
              else
                const Text('You joined'),
              const Spacer(),
              if (challenge.joined)
                Row(
                  children: [
                    const Text('Daily alarm'),
                    Switch(
                      value: challenge.alarmEnabled,
                      activeThumbColor: primaryColor,
                      onChanged: onAlarm,
                    ),
                  ],
                ),
            ],
          ),
        ],
      ),
    );
  }
}
