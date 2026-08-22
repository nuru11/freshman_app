import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:vector_academy/controllers/controllers.dart';
import 'package:vector_academy/models/models.dart';
import 'package:vector_academy/services/services.dart';
import 'package:vector_academy/utils/device/device.dart';
import 'package:vector_academy/utils/storages/storages.dart';
import 'package:vector_academy/utils/utils.dart';

class AddPlanController extends GetxController {
  late TextEditingController titleController;
  late TextEditingController descriptionController;

  DateTime? selectedDate;
  TimeOfDay? startTime;
  TimeOfDay? endTime;
  Set<int> selectedDays = <int>{}; // Days of week (1=Monday, 7=Sunday)

  List<Subject> courses = [];
  Subject? selectedCourse;
  /// Preserves legacy free-text subject when it doesn't match a course.
  String? legacySubjectName;
  bool isLoadingCourses = false;

  final formKey = GlobalKey<FormState>();
  bool isSubmitting = false;

  final List<String> dayNames = [
    'Mon',
    'Tue',
    'Wed',
    'Thu',
    'Fri',
    'Sat',
    'Sun',
  ];

  StudyPlan? plan; // If provided, we're editing

  String get selectedSubjectName {
    if (selectedCourse != null) return selectedCourse!.name;
    return legacySubjectName ?? '';
  }

  /// Resolves [selectedCourse] against the current [courses] list by id
  /// so DropdownButtonFormField always gets an item from its items list.
  Subject? get selectedCourseForDropdown {
    if (selectedCourse == null) return null;
    for (final course in courses) {
      if (course.id == selectedCourse!.id) return course;
    }
    return null;
  }

  @override
  void onInit() {
    super.onInit();
    // Get plan from arguments if editing
    final args = Get.arguments;
    plan = args is StudyPlan ? args : null;

    // Initialize controllers
    if (plan != null) {
      titleController = TextEditingController(text: plan!.title);
      descriptionController = TextEditingController(text: plan!.description);
      // Stored times are Western; convert to Ethiopian for display
      selectedDate = plan!.startDate ?? plan!.dueDate;
      startTime = plan!.startDate != null
          ? EthiopianTime.toEthiopian(TimeOfDay.fromDateTime(plan!.startDate!))
          : (plan!.dueDate != null
                ? EthiopianTime.toEthiopian(
                    TimeOfDay.fromDateTime(plan!.dueDate!),
                  )
                : null);
      endTime = plan!.endDate != null
          ? EthiopianTime.toEthiopian(TimeOfDay.fromDateTime(plan!.endDate!))
          : null;
      selectedDays = Set<int>.from(plan!.repeatDays);
      if (plan!.subject.isNotEmpty) {
        legacySubjectName = plan!.subject;
      }
    } else {
      titleController = TextEditingController();
      descriptionController = TextEditingController();
      selectedDate = null;
      startTime = null;
      endTime = null;
      selectedDays = <int>{};
    }

    loadCourses();
  }

  Future<void> loadCourses() async {
    isLoadingCourses = true;
    update();

    try {
      // Prefer cache first for fast UI
      final cached = await HiveSubjectsStorage().read('subjects');
      if (cached.isNotEmpty) {
        courses = cached;
        _syncSelectedCourse();
        isLoadingCourses = false;
        update();
      }

      final user = await HiveUserStorage().getUser();
      final device = await UserDevice.getDeviceInfo(user?.phoneNumber ?? '');
      final fetched = await SubjectsService().getSubjects(
        device.id,
        gradeId: user?.grade.id ?? 0,
      );
      courses = fetched;
      await HiveSubjectsStorage().write('subjects', courses);
      _syncSelectedCourse();
    } catch (e) {
      logger.e('Failed to load courses: $e');
      if (courses.isEmpty) {
        try {
          courses = await HiveSubjectsStorage().read('subjects');
          _syncSelectedCourse();
        } catch (_) {}
      }
    } finally {
      isLoadingCourses = false;
      update();
    }
  }

  void _syncSelectedCourse() {
    final name = legacySubjectName ?? plan?.subject;
    if (name == null || name.isEmpty) return;

    for (final course in courses) {
      if (course.name == name) {
        selectedCourse = course;
        legacySubjectName = null;
        return;
      }
    }
  }

  void selectCourse(Subject? course) {
    selectedCourse = course;
    if (course != null) {
      legacySubjectName = null;
    }
    update();
  }

  @override
  void onClose() {
    titleController.dispose();
    descriptionController.dispose();
    super.onClose();
  }

  Future<void> selectStartTime(BuildContext context) async {
    final time = await EthiopianTime.showDayNightTimePicker(
      context: context,
      initialTime: startTime ?? const TimeOfDay(hour: 9, minute: 0),
    );
    if (time != null) {
      startTime = time;
      // Ensure end time is after start time (same clock)
      if (endTime != null) {
        final startMinutes = time.hour * 60 + time.minute;
        final endMinutes = endTime!.hour * 60 + endTime!.minute;
        if (endMinutes <= startMinutes) {
          // Set end time to 1 hour after start time
          endTime = TimeOfDay(hour: (time.hour + 1) % 24, minute: time.minute);
        }
      } else {
        endTime = TimeOfDay(hour: (time.hour + 1) % 24, minute: time.minute);
      }
      update();
    }
  }

  Future<void> selectEndTime(BuildContext context) async {
    final time = await EthiopianTime.showDayNightTimePicker(
      context: context,
      initialTime: endTime ?? const TimeOfDay(hour: 10, minute: 0),
    );
    if (time != null) {
      if (startTime != null) {
        final startMinutes = startTime!.hour * 60 + startTime!.minute;
        final endMinutes = time.hour * 60 + time.minute;
        if (endMinutes <= startMinutes) {
          AppSnackbar.showError('Error', 'End time must be after start time');
          return;
        }
      }
      endTime = time;
      update();
    }
  }

  void toggleDay(int day) {
    if (selectedDays.contains(day)) {
      selectedDays.remove(day);
    } else {
      selectedDays.add(day);
    }
    update();
  }

  String formatStartTimeDisplay() {
    if (startTime == null) {
      return 'No start time set';
    }
    return EthiopianTime.formatTimeOfDay(startTime!);
  }

  String formatEndTimeDisplay() {
    if (endTime == null) {
      return 'No end time set';
    }
    return EthiopianTime.formatTimeOfDay(endTime!);
  }

  Future<void> savePlan() async {
    if (isSubmitting) {
      return; // Prevent double submission
    }

    if (!formKey.currentState!.validate()) {
      return;
    }

    if (startTime == null || endTime == null) {
      AppSnackbar.showError('Error', 'Please set both start time and end time');
      return;
    }

    if (selectedDays.isEmpty) {
      AppSnackbar.showError('Error', 'Please select at least one day');
      return;
    }

    logger.d('savePlan');
    isSubmitting = true;
    update();

    final controller = Get.find<StudyPlannerController>();

    try {
      // Convert Ethiopian display times to Western for storage/notifications
      final westernStart = EthiopianTime.toWestern(startTime!);
      final westernEnd = EthiopianTime.toWestern(endTime!);

      // Build startDate and endDate from selected date and times
      final date = selectedDate ?? DateTime.now();
      final startDate = DateTime(
        date.year,
        date.month,
        date.day,
        westernStart.hour,
        westernStart.minute,
      );
      final endDate = DateTime(
        date.year,
        date.month,
        date.day,
        westernEnd.hour,
        westernEnd.minute,
      );
      // Set dueDate to endDate for backward compatibility
      final dueDate = endDate;

      final subject = selectedSubjectName;

      if (plan != null) {
        // Update existing plan
        final updatedPlan = plan!.copyWith(
          title: titleController.text.trim(),
          description: descriptionController.text.trim(),
          subject: subject,
          dueDate: dueDate,
          startDate: startDate,
          endDate: endDate,
          repeatDays: selectedDays.toList()..sort(),
        );
        logger.d('update existing plan');
        await controller.updateStudyPlan(updatedPlan, showSnackbar: false);
      } else {
        // Create new plan
        logger.d('create new plan');
        final newPlan = StudyPlan(
          id: 0, // Will be set by backend
          title: titleController.text.trim(),
          description: descriptionController.text.trim(),
          subject: subject,
          dueDate: dueDate,
          startDate: startDate,
          endDate: endDate,
          completedDates: [], // New plans start with no completions
          createdAt: DateTime.now(),
          repeatDays: selectedDays.toList()..sort(),
        );
        await controller.addStudyPlan(newPlan, showSnackbar: false);
      }

      // Navigate back to study planner page after successful save
      logger.d('routes: ${Get.key.currentState?.widget}');
      logger.d('can pop: ${Get.key.currentState?.canPop()}');

      Get.back();
      logger.d('navigate back to study planner page');

      // Show success message after navigation
      AppSnackbar.showSuccess(
        'Success',
        plan != null ? 'Study plan updated' : 'Study plan created',
      );
    } catch (e) {
      // Error is already shown by the controller
      // Don't navigate back on error
      logger.e('Error saving plan: $e');
    } finally {
      isSubmitting = false;
      update();
    }
  }
}
