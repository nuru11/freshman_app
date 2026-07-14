import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:vector_academy/controllers/controllers.dart';
import 'package:vector_academy/models/models.dart';
import 'package:vector_academy/components/components.dart';

class StudyPlannerPage extends StatelessWidget {
  const StudyPlannerPage({super.key});

  @override
  Widget build(BuildContext context) {
    return GetBuilder<StudyPlannerController>(
      builder: (controller) => FreshmanPageScaffold(
        embeddedInTab: true,
        showBack: false,
        title: 'Study Planner',
        subtitle: 'Your week at a glance',
        floatingActionButton: FloatingActionButton.extended(
          onPressed: () => controller.showAddPlanDialog(),
          icon: const Icon(Icons.add, color: Colors.white),
          label: const Text(
            'Add Plan',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
          ),
          backgroundColor: primaryColor,
        ),
        body: Column(
          children: [
            if (controller.isShowingOfflineData) _buildOfflineNotice(),
            Expanded(
              child: controller.isLoading
                  ? Center(child: CircularProgressIndicator(color: primaryColor))
                  : RefreshIndicator(
                      color: primaryColor,
                      onRefresh: () => controller.loadStudyPlans(),
                      child: CustomScrollView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        slivers: [
                          SliverToBoxAdapter(
                            child: _buildDayFilter(context, controller),
                          ),
                          if (controller.filteredPlans.isNotEmpty)
                            SliverToBoxAdapter(
                              child: _buildSectionHeader(
                                context,
                                _getFilterTitle(controller.selectedFilterDate),
                              ),
                            ),
                          if (controller.filteredPlans.isNotEmpty)
                            SliverPadding(
                              padding: const EdgeInsets.fromLTRB(16, 0, 16, 88),
                              sliver: SliverList.separated(
                                itemCount: controller.filteredPlans.length,
                                separatorBuilder: (_, __) =>
                                    const SizedBox(height: 8),
                                itemBuilder: (context, index) => _buildPlanCard(
                                  context,
                                  controller.filteredPlans[index],
                                  controller,
                                ),
                              ),
                            ),
                          if (controller.filteredPlans.isEmpty)
                            SliverFillRemaining(
                              hasScrollBody: false,
                              child: _buildEmptyState(context, controller),
                            ),
                        ],
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDayFilter(
    BuildContext context,
    StudyPlannerController controller,
  ) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final selectedDate = controller.selectedFilterDate ?? today;

    final days = List.generate(7, (index) => today.add(Duration(days: index)));

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Row(
          children: days.map((date) {
            final isSelected = selectedDate.year == date.year &&
                selectedDate.month == date.month &&
                selectedDate.day == date.day;
            final isToday = date.year == today.year &&
                date.month == today.month &&
                date.day == today.day;

            return GestureDetector(
              onTap: () => controller.setFilterDate(date),
              child: Container(
                margin: const EdgeInsets.only(right: 8),
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: isSelected
                      ? primaryColor
                      : surfaceColor,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: isSelected
                        ? primaryColor
                        : isToday
                            ? primaryColor
                            : borderColor,
                    width: isToday && !isSelected ? 1.5 : 1,
                  ),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      _getDayAbbreviation(date.weekday),
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: isSelected
                            ? Colors.white
                            : isToday
                                ? primaryColor
                                : onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${date.day}',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: isSelected
                            ? Colors.white
                            : isToday
                                ? primaryColor
                                : onSurfaceColor,
                      ),
                    ),
                    if (isToday && !isSelected)
                      Container(
                        margin: const EdgeInsets.only(top: 4),
                        width: 4,
                        height: 4,
                        decoration: BoxDecoration(
                          color: primaryColor,
                          shape: BoxShape.circle,
                        ),
                      ),
                  ],
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildOfflineNotice() {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 0),
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

  String _getDayAbbreviation(int weekday) {
    const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    return days[weekday - 1];
  }

  String _getFilterTitle(DateTime? date) {
    if (date == null) return "Today's Schedule";

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final tomorrow = today.add(const Duration(days: 1));
    final filterDate = DateTime(date.year, date.month, date.day);

    if (filterDate == today) return "Today's Schedule";
    if (filterDate == tomorrow) return "Tomorrow's Schedule";

    const daysOfWeek = [
      'Monday',
      'Tuesday',
      'Wednesday',
      'Thursday',
      'Friday',
      'Saturday',
      'Sunday',
    ];
    return "${daysOfWeek[date.weekday - 1]}'s Schedule";
  }

  Widget _buildSectionHeader(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 10),
      child: Row(
        children: [
          Icon(Icons.calendar_today_rounded, color: primaryColor, size: 18),
          const SizedBox(width: 8),
          Text(
            title,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: onSurfaceColor,
                  fontWeight: FontWeight.w700,
                ),
          ),
        ],
      ),
    );
  }

  Widget _buildPlanCard(
    BuildContext context,
    StudyPlan plan,
    StudyPlannerController controller,
  ) {
    final filterDate = controller.selectedFilterDate;
    final targetDate = filterDate ?? DateTime.now();
    final targetDateOnly = DateTime(
      targetDate.year,
      targetDate.month,
      targetDate.day,
    );
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final isCompleted = plan.isCompletedForDate(targetDateOnly);

    bool isOverdue = false;
    final endDateTime = plan.endDate ?? plan.dueDate;
    if (!isCompleted && endDateTime != null) {
      if (targetDateOnly.isBefore(today)) {
        isOverdue = true;
      } else if (targetDateOnly.year == today.year &&
          targetDateOnly.month == today.month &&
          targetDateOnly.day == today.day) {
        final effectiveDate = plan.effectiveDate;
        final isRepeatingOnToday =
            plan.isRepeating &&
            plan.repeatDays.contains(targetDateOnly.weekday);
        final isNonRepeatingOnToday = !plan.isRepeating &&
            effectiveDate != null &&
            effectiveDate.year == today.year &&
            effectiveDate.month == today.month &&
            effectiveDate.day == today.day;

        if (isRepeatingOnToday || isNonRepeatingOnToday) {
          final planEndDateTime = DateTime(
            today.year,
            today.month,
            today.day,
            endDateTime.hour,
            endDateTime.minute,
          );
          if (planEndDateTime.isBefore(now)) isOverdue = true;
        }
      }
    }

    final borderTint = isOverdue
        ? secondaryColor
        : isCompleted
            ? primaryColor.withValues(alpha: 0.35)
            : borderColor;

    return FreshmanSurfaceCard(
      onTap: () => controller.showPlanDetails(plan),
      child: Container(
        decoration: BoxDecoration(
          border: Border(
            left: BorderSide(
              color: isOverdue
                  ? secondaryColor
                  : isCompleted
                      ? primaryColor
                      : Colors.transparent,
              width: (isOverdue || isCompleted) ? 3 : 0,
            ),
          ),
        ),
        child: Row(
          children: [
            GestureDetector(
              onTap: () {
                controller.togglePlanCompletion(
                  plan,
                  controller.selectedFilterDate,
                );
              },
              behavior: HitTestBehavior.opaque,
              child: Container(
                width: 32,
                height: 32,
                alignment: Alignment.center,
                child: Container(
                  width: 22,
                  height: 22,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: isCompleted ? primaryColor : borderTint,
                      width: 2,
                    ),
                    color: isCompleted ? primaryColor : Colors.transparent,
                  ),
                  child: isCompleted
                      ? const Icon(Icons.check, color: Colors.white, size: 14)
                      : null,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    plan.title,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: isCompleted ? onSurfaceVariant : onSurfaceColor,
                      decoration:
                          isCompleted ? TextDecoration.lineThrough : null,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (plan.description.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      plan.description,
                      style: TextStyle(
                        fontSize: 13,
                        color: onSurfaceVariant,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(
                        Icons.access_time_rounded,
                        size: 14,
                        color: isOverdue ? secondaryColor : onSurfaceVariant,
                      ),
                      const SizedBox(width: 4),
                      Flexible(
                        flex: 2,
                        child: Text(
                          _formatTimeRange(plan),
                          style: TextStyle(
                            fontSize: 12,
                            color: plan.effectiveDate != null
                                ? (isOverdue
                                    ? secondaryColor
                                    : onSurfaceVariant)
                                : onSurfaceVariant.withValues(alpha: 0.6),
                            fontWeight:
                                isOverdue ? FontWeight.w600 : FontWeight.normal,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (plan.subject.isNotEmpty) ...[
                        const SizedBox(width: 12),
                        Icon(
                          Icons.menu_book_rounded,
                          size: 14,
                          color: onSurfaceVariant,
                        ),
                        const SizedBox(width: 4),
                        Flexible(
                          flex: 3,
                          child: Text(
                            plan.subject,
                            style: TextStyle(
                              fontSize: 12,
                              color: onSurfaceVariant,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ],
                  ),
                  if (plan.isRepeating) ...[
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(
                          Icons.repeat_rounded,
                          size: 14,
                          color: primaryColor,
                        ),
                        const SizedBox(width: 4),
                        Flexible(
                          child: Text(
                            _formatRepeatDays(plan.repeatDays),
                            style: TextStyle(
                              fontSize: 12,
                              color: primaryColor,
                              fontWeight: FontWeight.w500,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
            Icon(Icons.chevron_right_rounded, color: secondaryColor, size: 22),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(
    BuildContext context,
    StudyPlannerController controller,
  ) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.event_note_outlined,
              size: 56,
              color: onSurfaceVariant,
            ),
            const SizedBox(height: 16),
            Text(
              'No plans for this day',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: onSurfaceColor,
                    fontWeight: FontWeight.w700,
                  ),
            ),
            const SizedBox(height: 6),
            Text(
              'Add a study block to keep your week on track',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: onSurfaceVariant,
                  ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: () => controller.showAddPlanDialog(),
              icon: const Icon(Icons.add),
              label: const Text('Create Plan'),
              style: FilledButton.styleFrom(
                backgroundColor: primaryColor,
                foregroundColor: Colors.white,
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatTimeRange(StudyPlan plan) {
    if (plan.startDate == null &&
        plan.endDate == null &&
        plan.dueDate == null) {
      return 'No date set';
    }

    final startDate = plan.startDate;
    final endDate = plan.endDate;
    final dueDate = plan.dueDate;

    if (startDate != null && endDate != null) {
      final startTime =
          '${startDate.hour.toString().padLeft(2, '0')}:${startDate.minute.toString().padLeft(2, '0')}';
      final endTime =
          '${endDate.hour.toString().padLeft(2, '0')}:${endDate.minute.toString().padLeft(2, '0')}';

      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      final startDateOnly =
          DateTime(startDate.year, startDate.month, startDate.day);

      if (startDateOnly == today) {
        return 'Today, $startTime - $endTime';
      } else if (startDateOnly == today.add(const Duration(days: 1))) {
        return 'Tomorrow, $startTime - $endTime';
      } else {
        const daysOfWeek = [
          'Monday',
          'Tuesday',
          'Wednesday',
          'Thursday',
          'Friday',
          'Saturday',
          'Sunday',
        ];
        final dayOfWeek = daysOfWeek[startDate.weekday - 1];
        return '$dayOfWeek, ${startDate.day}/${startDate.month}/${startDate.year} $startTime - $endTime';
      }
    } else if (startDate != null) {
      return _formatDateTime(startDate);
    } else if (endDate != null) {
      return _formatDateTime(endDate);
    } else if (dueDate != null) {
      return _formatDateTime(dueDate);
    }

    return 'No date set';
  }

  String _formatDateTime(DateTime dateTime) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final date = DateTime(dateTime.year, dateTime.month, dateTime.day);

    const daysOfWeek = [
      'Monday',
      'Tuesday',
      'Wednesday',
      'Thursday',
      'Friday',
      'Saturday',
      'Sunday',
    ];
    final dayOfWeek = daysOfWeek[dateTime.weekday - 1];
    final time =
        '${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';

    if (date == today) {
      return 'Today, $dayOfWeek $time';
    } else if (date == today.add(const Duration(days: 1))) {
      return 'Tomorrow, $dayOfWeek $time';
    } else {
      return '$dayOfWeek, ${dateTime.day}/${dateTime.month}/${dateTime.year} $time';
    }
  }

  String _formatRepeatDays(List<int> days) {
    if (days.isEmpty) return '';

    const dayNames = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    final sortedDays = List<int>.from(days)..sort();

    if (sortedDays.length == 7) {
      return 'Every day';
    } else if (sortedDays.length == 5 &&
        sortedDays.contains(1) &&
        sortedDays.contains(2) &&
        sortedDays.contains(3) &&
        sortedDays.contains(4) &&
        sortedDays.contains(5)) {
      return 'Weekdays';
    } else if (sortedDays.length == 2 &&
        sortedDays.contains(6) &&
        sortedDays.contains(7)) {
      return 'Weekends';
    } else {
      return 'Repeats: ${sortedDays.map((d) => dayNames[d - 1]).join(', ')}';
    }
  }
}
