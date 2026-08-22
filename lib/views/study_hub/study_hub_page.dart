import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:vector_academy/components/components.dart';
import 'package:vector_academy/controllers/study_hub/study_hub_controller.dart';
import 'package:vector_academy/controllers/study_planner/study_planner_controller.dart';
import 'package:vector_academy/views/study_hub/challenge_tab.dart';
import 'package:vector_academy/views/study_hub/pomodoro_tab.dart';
import 'package:vector_academy/views/study_hub/reading_plan_tab.dart';
import 'package:vector_academy/views/study_planner/study_planner_page.dart';

class StudyHubPage extends StatelessWidget {
  const StudyHubPage({super.key});

  @override
  Widget build(BuildContext context) {
    return GetBuilder<StudyHubController>(
      builder: (hub) {
        final isPlanner = hub.tabIndex == 0;
        return FreshmanPageScaffold(
          embeddedInTab: true,
          showBack: false,
          title: 'Study',
          subtitle: 'Planner, focus timer, and premium reading tools',
          floatingActionButton: isPlanner
              ? FloatingActionButton.extended(
                  onPressed: () =>
                      Get.find<StudyPlannerController>().showAddPlanDialog(),
                  icon: const Icon(Icons.add, color: Colors.white),
                  label: const Text(
                    'Add Plan',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  backgroundColor: primaryColor,
                )
              : null,
          body: Column(
            children: [
              _buildTabs(context, hub),
              Expanded(child: _buildBody(hub.tabIndex)),
            ],
          ),
        );
      },
    );
  }

  Widget _buildTabs(BuildContext context, StudyHubController hub) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
      child: Row(
        children: List.generate(StudyHubController.tabLabels.length, (index) {
          final selected = hub.tabIndex == index;
          return Expanded(
            child: Padding(
              padding: EdgeInsets.only(right: index < 3 ? 6 : 0),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () => hub.selectTab(index),
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    decoration: BoxDecoration(
                      color: selected
                          ? primaryColor.withValues(alpha: 0.12)
                          : surfaceColor,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: selected ? primaryColor : borderColor,
                      ),
                    ),
                    child: Text(
                      StudyHubController.tabLabels[index],
                      textAlign: TextAlign.center,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.labelMedium?.copyWith(
                        color: selected ? primaryColor : onSurfaceVariant,
                        fontWeight: selected
                            ? FontWeight.w700
                            : FontWeight.w500,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          );
        }),
      ),
    );
  }

  Widget _buildBody(int index) {
    return switch (index) {
      0 => const StudyPlannerPage(embeddedInHub: true),
      1 => const PomodoroTab(),
      2 => const ReadingPlanTab(),
      _ => const ChallengeTab(),
    };
  }
}
