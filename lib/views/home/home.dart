import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:vector_academy/views/home/home_dashboard.dart';
import 'package:vector_academy/views/subject/subject_page.dart';
import 'package:vector_academy/views/exam/exam_page.dart';
import 'package:vector_academy/views/study_planner/study_planner_page.dart';
import 'package:vector_academy/views/common/profile_page.dart';
import 'package:vector_academy/controllers/controllers.dart';
import 'package:vector_academy/config/app_config.dart';
import 'package:vector_academy/components/ui/themes/light_theme.dart';

class Home extends StatelessWidget {
  const Home({super.key});

  @override
  Widget build(BuildContext context) {
    final pages = [
      HomeDashboard(),
      const SubjectPage(embeddedInTab: true),
      const ExamPage(),
      const StudyPlannerPage(),
      const ProfilePage(embeddedInTab: true),
    ];

    return GetBuilder<MainNavigationController>(
      builder: (controller) => PopScope(
        canPop: false,
        child: Scaffold(
          backgroundColor: backgroundColor,
          body: IndexedStack(index: controller.currentIndex, children: pages),
          bottomNavigationBar: NavigationBar(
            selectedIndex: controller.currentIndex,
            onDestinationSelected: controller.changeIndex,
            destinations: [
              const NavigationDestination(
                icon: Icon(Icons.home_outlined),
                selectedIcon: Icon(Icons.home_rounded),
                label: 'Home',
              ),
              NavigationDestination(
                icon: const Icon(Icons.menu_book_outlined),
                selectedIcon: const Icon(Icons.menu_book_rounded),
                label: 'My $subjectsLabel',
              ),
              const NavigationDestination(
                icon: Icon(Icons.quiz_outlined),
                selectedIcon: Icon(Icons.quiz_rounded),
                label: 'Exam',
              ),
              const NavigationDestination(
                icon: Icon(Icons.event_note_outlined),
                selectedIcon: Icon(Icons.event_note_rounded),
                label: 'Planner',
              ),
              const NavigationDestination(
                icon: Icon(Icons.person_outline),
                selectedIcon: Icon(Icons.person_rounded),
                label: 'Profile',
              ),
            ],
          ),
        ),
      ),
    );
  }
}
