import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:vector_academy/controllers/controllers.dart';
import 'package:vector_academy/models/models.dart';
import 'package:vector_academy/utils/utils.dart';

class AddPlanController extends GetxController {
  late TextEditingController titleController;
  late TextEditingController descriptionController;
  late TextEditingController subjectController;

  DateTime? selectedDate;
  TimeOfDay? startTime;
  TimeOfDay? endTime;
  Set<int> selectedDays = <int>{}; // Days of week (1=Monday, 7=Sunday)

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
      subjectController = TextEditingController(text: plan!.subject);
      // Use startDate if available, otherwise fall back to dueDate
      selectedDate = plan!.startDate ?? plan!.dueDate;
      startTime = plan!.startDate != null
          ? TimeOfDay.fromDateTime(plan!.startDate!)
          : (plan!.dueDate != null
                ? TimeOfDay.fromDateTime(plan!.dueDate!)
                : null);
      endTime = plan!.endDate != null
          ? TimeOfDay.fromDateTime(plan!.endDate!)
          : null;
      selectedDays = Set<int>.from(plan!.repeatDays);
    } else {
      titleController = TextEditingController();
      descriptionController = TextEditingController();
      subjectController = TextEditingController();
      selectedDate = null;
      startTime = null;
      endTime = null;
      selectedDays = <int>{};
    }
  }

  @override
  void onClose() {
    titleController.dispose();
    descriptionController.dispose();
    subjectController.dispose();
    super.onClose();
  }

  Future<void> selectDate(BuildContext context) async {
    final date = await showDatePicker(
      context: context,
      initialDate: selectedDate ?? DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(Duration(days: 365)),
    );
    if (date != null) {
      selectedDate = DateTime(
        date.year,
        date.month,
        date.day,
        startTime?.hour ?? 9,
        startTime?.minute ?? 0,
      );
      // Automatically set default times if not set
      startTime ??= TimeOfDay(hour: 9, minute: 0);
      endTime ??= TimeOfDay(hour: 10, minute: 0);
      update();
    }
  }

  Future<void> selectStartTime(BuildContext context) async {
    final time = await showTimePicker(
      context: context,
      initialTime: startTime ?? TimeOfDay(hour: 9, minute: 0),
    );
    if (time != null) {
      startTime = time;
      // Ensure end time is after start time
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
    final time = await showTimePicker(
      context: context,
      initialTime: endTime ?? TimeOfDay(hour: 10, minute: 0),
    );
    if (time != null) {
      if (startTime != null) {
        final startMinutes = startTime!.hour * 60 + startTime!.minute;
        final endMinutes = time.hour * 60 + time.minute;
        if (endMinutes <= startMinutes) {
          // Show error or adjust
          AppSnackbar.showError('Error', 'End time must be after start time');
          return;
        }
      }
      endTime = time;
      update();
    }
  }

  void clearDate() {
    selectedDate = null;
    startTime = null;
    endTime = null;
    update();
  }

  String getDayOfWeek(DateTime date) {
    final daysOfWeek = [
      'Monday',
      'Tuesday',
      'Wednesday',
      'Thursday',
      'Friday',
      'Saturday',
      'Sunday',
    ];
    return daysOfWeek[date.weekday - 1];
  }

  void toggleDay(int day) {
    if (selectedDays.contains(day)) {
      selectedDays.remove(day);
    } else {
      selectedDays.add(day);
    }
    update();
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

    if (selectedDate == null && selectedDays.isEmpty) {
      AppSnackbar.showError('Error', 'Please select a date or days');
      return;
    }

    logger.d('savePlan');
    isSubmitting = true;
    update();

    final controller = Get.find<StudyPlannerController>();

    try {
      // Build startDate and endDate from selected date and times
      DateTime? startDate;
      DateTime? endDate;
      DateTime? dueDate; // Keep for backward compatibility

      if (startTime != null && endTime != null) {
        var date = DateTime.now();
        startDate = DateTime(
          date.year,
          date.month,
          date.day,
          startTime!.hour,
          startTime!.minute,
        );
        endDate = DateTime(
          date.year,
          date.month,
          date.day,
          endTime!.hour,
          endTime!.minute,
        );
        // Set dueDate to endDate for backward compatibility
        dueDate = endDate;
      }

      if (plan != null) {
        // Update existing plan
        final updatedPlan = StudyPlan(
          id: plan!.id,
          title: titleController.text.trim(),
          description: descriptionController.text.trim(),
          subject: subjectController.text.trim(),
          dueDate: dueDate,
          startDate: startDate,
          endDate: endDate,
          completedDates: plan!.completedDates, // Preserve existing completions
          createdAt: plan!.createdAt,
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
          subject: subjectController.text.trim(),
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
