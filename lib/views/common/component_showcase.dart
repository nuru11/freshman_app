import 'package:flutter/material.dart';
import 'package:vector_academy/components/components.dart';

class ComponentShowcase extends StatelessWidget {
  const ComponentShowcase({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: const AppBackLeading(),
        title: Text('Component Showcase'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionTitle('Cards'),
            Row(
              children: [
                Expanded(
                  child: StatCard(
                    icon: Icons.quiz_outlined,
                    title: 'Total Exams',
                    value: '15',
                    subtitle: 'Completed this month',
                  ),
                ),
                SizedBox(width: 16),
                Expanded(
                  child: StatCard(
                    icon: Icons.grade_outlined,
                    title: 'Average Score',
                    value: '85%',
                    iconColor: Theme.of(context).colorScheme.secondary,
                    valueColor: Theme.of(context).colorScheme.secondary,
                  ),
                ),
              ],
            ),

            SizedBox(height: 16),

            ProgressCard(
              title: 'Physics Course',
              subtitle: 'Chapter 5: Thermodynamics',
              progress: 0.75,
              leading: Icon(
                Icons.science_outlined,
                size: 32,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),

            SizedBox(height: 16),

            MediaCard(
              title: 'Introduction to Quantum Mechanics',
              subtitle: 'Physics • Chapter 1',
              duration: '15:30',
              isCompleted: true,
              onTap: () {},
              onDownload: () {},
            ),

            SizedBox(height: 24),

            _buildSectionTitle('List Tiles'),
            CustomCard(
              padding: EdgeInsets.all(8),
              child: Column(
                children: [
                  StatListTile(
                    icon: Icons.video_library_outlined,
                    title: 'Videos Watched',
                    value: '142',
                    onTap: () {},
                  ),
                  Divider(height: 1),
                  ProgressListTile(
                    icon: Icons.book_outlined,
                    title: 'Course Progress',
                    subtitle: 'Mathematics - Advanced Calculus',
                    progress: 0.68,
                    onTap: () {},
                  ),
                  Divider(height: 1),
                  ActionListTile(
                    icon: Icons.settings_outlined,
                    title: 'Settings',
                    subtitle: 'App preferences and configuration',
                    badge: NotificationBadge(count: 3, child: Container()),
                    onTap: () {},
                  ),
                ],
              ),
            ),

            SizedBox(height: 24),

            _buildSectionTitle('Buttons'),
            Column(
              children: [
                PrimaryButton(
                  text: 'Primary Button',
                  icon: Icon(Icons.play_arrow),
                  onPressed: () {},
                ),
                SizedBox(height: 12),
                SecondaryButton(
                  text: 'Secondary Button',
                  icon: Icon(Icons.download),
                  onPressed: () {},
                ),
                SizedBox(height: 12),
                OutlineButton(
                  text: 'Outline Button',
                  icon: Icon(Icons.bookmark_border),
                  onPressed: () {},
                ),
              ],
            ),

            SizedBox(height: 24),

            _buildSectionTitle('Avatars'),
            Row(
              children: [
                ProfileAvatar(name: 'John Doe', size: 60, isOnline: true),
                SizedBox(width: 16),
                IconAvatar(icon: Icons.school, size: 60),
                SizedBox(width: 16),
                GroupAvatar(
                  names: ['Alice', 'Bob', 'Charlie', 'David', 'Eva'],
                  size: 60,
                ),
              ],
            ),

            SizedBox(height: 24),

            _buildSectionTitle('Badges'),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                StatusBadge(text: 'Completed', status: BadgeStatus.success),
                StatusBadge(text: 'In Progress', status: BadgeStatus.warning),
                StatusBadge(text: 'Failed', status: BadgeStatus.error),
                StatusBadge(text: 'New', status: BadgeStatus.info),
                StatusBadge(text: 'Pending', status: BadgeStatus.neutral),
              ],
            ),

            SizedBox(height: 16),

            Row(
              children: [
                ProgressBadge(progress: 0.75),
                SizedBox(width: 16),
                ScoreBadge(score: 85),
                SizedBox(width: 16),
                LevelBadge(level: 12, label: 'LVL'),
              ],
            ),

            SizedBox(height: 24),

            _buildSectionTitle('Input Fields'),
            PhoneTextField(),
            SizedBox(height: 16),
            PasswordTextField(),
            SizedBox(height: 16),
            OTPTextField(),
            SizedBox(height: 16),
            SearchTextField(hint: 'Search courses...'),

            SizedBox(height: 24),

            _buildSectionTitle('Loading States'),
            LoadingListTile(),
            SizedBox(height: 16),
            SkeletonCard(height: 200),

            SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: EdgeInsets.only(bottom: 16),
      child: Text(
        title,
        style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
      ),
    );
  }
}
