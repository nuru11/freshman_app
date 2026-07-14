import 'package:get/get.dart';
import 'package:flutter/material.dart';
import 'package:vector_academy/models/models.dart';
import 'package:vector_academy/utils/utils.dart';
import 'package:vector_academy/services/services.dart';
import 'package:vector_academy/services/notification_service.dart'
    as local_notif;
import 'package:vector_academy/services/api/exceptions.dart';
import 'package:vector_academy/utils/storages/storages.dart';
import 'package:vector_academy/utils/study_planner_reminder_permissions.dart';

class StudyPlannerController extends GetxController {
  bool _isLoading = false;
  bool get isLoading => _isLoading;
  bool _isShowingOfflineData = false;
  bool get isShowingOfflineData => _isShowingOfflineData;

  List<StudyPlan> _studyPlans = [];
  List<StudyPlan> get studyPlans => _studyPlans;

  final StudyPlannerService _studyPlannerService =
      Get.find<StudyPlannerService>();
  final HiveStudyPlanStorage _storage = HiveStudyPlanStorage();
  local_notif.LocalNotificationService? _notificationService;

  DateTime? _selectedFilterDate;
  DateTime? get selectedFilterDate => _selectedFilterDate;

  @override
  void onInit() {
    super.onInit();
    // Default to today
    final now = DateTime.now();
    _selectedFilterDate = DateTime(now.year, now.month, now.day);
    // Get notification service if available
    try {
      _notificationService = Get.find<local_notif.LocalNotificationService>();
    } catch (e) {
      logger.w(
        'LocalNotificationService not found, notifications will be disabled',
      );
    }
    loadStudyPlans();
  }

  void setFilterDate(DateTime? date) {
    if (date != null) {
      // Store date only (no time) for consistency
      _selectedFilterDate = DateTime(date.year, date.month, date.day);
    } else {
      _selectedFilterDate = null;
    }
    update();
  }

  List<StudyPlan> get todayPlans {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final tomorrow = today.add(Duration(days: 1));

    return _studyPlans.where((plan) {
      final effectiveDate = plan.effectiveDate;
      if (effectiveDate == null) {
        // Plans without date are shown if they repeat today or have no repeat days
        if (plan.isRepeating) {
          return plan.repeatDays.contains(today.weekday);
        }
        return true; // Show plans without date and no repeat days
      }
      final planDate = DateTime(
        effectiveDate.year,
        effectiveDate.month,
        effectiveDate.day,
      );
      return planDate.isAfter(today.subtract(Duration(days: 1))) &&
          planDate.isBefore(tomorrow);
    }).toList()..sort((a, b) {
      final aDate = a.effectiveDate;
      final bDate = b.effectiveDate;
      if (aDate == null && bDate == null) return 0;
      if (aDate == null) return 1; // Plans without date go to end
      if (bDate == null) return -1;
      return aDate.compareTo(bDate);
    });
  }

  List<StudyPlan> get upcomingPlans {
    final now = DateTime.now();
    final tomorrow = DateTime(now.year, now.month, now.day + 1);

    return _studyPlans.where((plan) {
      final effectiveDate = plan.effectiveDate;
      if (effectiveDate == null) {
        return false; // Plans without date are not "upcoming"
      }
      final planDate = DateTime(
        effectiveDate.year,
        effectiveDate.month,
        effectiveDate.day,
      );
      return planDate.isAfter(tomorrow.subtract(Duration(days: 1)));
    }).toList()..sort((a, b) {
      final aDate = a.effectiveDate;
      final bDate = b.effectiveDate;
      if (aDate == null && bDate == null) return 0;
      if (aDate == null) return 1;
      if (bDate == null) return -1;
      return aDate.compareTo(bDate);
    });
  }

  List<StudyPlan> get thisWeekPlans {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final weekEnd = today.add(Duration(days: 7));

    return _studyPlans.where((plan) {
      final effectiveDate = plan.effectiveDate;
      if (effectiveDate == null) return false;
      final planDate = DateTime(
        effectiveDate.year,
        effectiveDate.month,
        effectiveDate.day,
      );
      return planDate.isAfter(today.subtract(Duration(days: 1))) &&
          planDate.isBefore(weekEnd);
    }).toList();
  }

  List<StudyPlan> get filteredPlans {
    if (_selectedFilterDate == null) {
      return todayPlans;
    }

    final filterDate = _selectedFilterDate!;
    final filterDayOfWeek = filterDate.weekday;

    return _studyPlans.where((plan) {
      final effectiveDate = plan.effectiveDate;
      // Plans without date
      if (effectiveDate == null) {
        // Show if it repeats on the selected day
        if (plan.isRepeating && plan.repeatDays.contains(filterDayOfWeek)) {
          final now = DateTime.now();
          final today = DateTime(now.year, now.month, now.day);
          return filterDate.isAfter(today.subtract(Duration(days: 1)));
        }
        // Show plans without date and no repeat days on any day
        if (!plan.isRepeating) {
          return true;
        }
        return false;
      }

      // Check if plan is on the selected date
      final planDate = DateTime(
        effectiveDate.year,
        effectiveDate.month,
        effectiveDate.day,
      );

      // Check if plan date matches filter date
      if (planDate.year == filterDate.year &&
          planDate.month == filterDate.month &&
          planDate.day == filterDate.day) {
        return true;
      }

      // Check if plan repeats on the selected day of week
      if (plan.isRepeating && plan.repeatDays.contains(filterDayOfWeek)) {
        // Only show if the filter date is today or in the future
        final now = DateTime.now();
        final today = DateTime(now.year, now.month, now.day);
        return filterDate.isAfter(today.subtract(Duration(days: 1)));
      }

      return false;
    }).toList()..sort((a, b) {
      final aDate = a.effectiveDate;
      final bDate = b.effectiveDate;
      if (aDate == null && bDate == null) return 0;
      if (aDate == null) return 1; // Plans without date go to end
      if (bDate == null) return -1;
      return aDate.compareTo(bDate);
    });
  }

  Future<void> loadStudyPlans() async {
    _isLoading = true;
    _isShowingOfflineData = false;
    update();

    try {
      // Load from local storage first for immediate UI update
      final localPlans = await _storage.getStudyPlans();
      if (localPlans.isNotEmpty) {
        _studyPlans = localPlans;
        update();
      }

      // Try to sync with API in background
      try {
        final apiPlans = await _studyPlannerService.getStudyPlans();
        _studyPlans = apiPlans;
        // Save to local storage
        await _storage.setStudyPlans(apiPlans);
        _isShowingOfflineData = false;
        update();
        // Schedule notifications for all plans
        await _scheduleNotificationsForAllPlans();
      } catch (e) {
        logger.e('Error syncing study plans from API: $e');
        // If API fails and we have local data, use it
        if (localPlans.isEmpty) {
          AppSnackbar.showError(
            'Error',
            e is ApiException
                ? e.message
                : 'Failed to load study plans.',
          );
        } else {
          _isShowingOfflineData = true;
          // Schedule notifications for local plans
          await _scheduleNotificationsForAllPlans();
        }
      }
    } catch (e) {
      logger.e('Error loading study plans: $e');
      AppSnackbar.showError(
        'Error',
        e is ApiException ? e.message : 'Failed to load study plans',
      );
    } finally {
      _isLoading = false;
      update();
    }
  }

  void showAddPlanDialog() {
    Get.toNamed('/add-plan');
  }

  void showEditPlanPage(StudyPlan plan) {
    Get.toNamed('/add-plan', arguments: plan);
  }

  Future<void> addStudyPlan(StudyPlan plan, {bool showSnackbar = true}) async {
    try {
      final createdPlan = await _studyPlannerService.createStudyPlan(plan);
      _studyPlans.add(createdPlan);
      _sortPlans();
      // Save to local storage
      await _storage.setStudyPlans(_studyPlans);
      await StudyPlannerReminderPermissions.ensureBeforeScheduling();
      // Schedule notification for the new plan
      await _scheduleNotificationForPlan(createdPlan);
      update();
      if (showSnackbar) {
        AppSnackbar.showSuccess('Success', 'Study plan created');
      }
    } catch (e) {
      logger.e('Error creating study plan: $e');
      AppSnackbar.showError(
        'Error',
        e is ApiException ? e.message : 'Failed to create study plan',
      );
      rethrow;
    }
  }

  Future<void> updateStudyPlan(
    StudyPlan plan, {
    bool showSnackbar = true,
  }) async {
    try {
      final updatedPlan = await _studyPlannerService.updateStudyPlan(plan);
      final index = _studyPlans.indexWhere((p) => p.id == plan.id);
      if (index != -1) {
        _studyPlans[index] = updatedPlan;
        _sortPlans();
        // Save to local storage
        await _storage.setStudyPlans(_studyPlans);
        await StudyPlannerReminderPermissions.ensureBeforeScheduling();
        // Reschedule notification for the updated plan
        await _scheduleNotificationForPlan(updatedPlan);
        update();
        if (showSnackbar) {
          AppSnackbar.showSuccess('Success', 'Study plan updated');
        }
      }
    } catch (e) {
      logger.e('Error updating study plan: $e');
      AppSnackbar.showError(
        'Error',
        e is ApiException ? e.message : 'Failed to update study plan',
      );
      rethrow;
    }
  }

  Future<void> togglePlanCompletion(StudyPlan plan, DateTime? date) async {
    try {
      // Use selected filter date or plan's due date
      final targetDate =
          date ?? _selectedFilterDate ?? plan.dueDate ?? DateTime.now();
      // Use date only (no time) for consistency
      final targetDateOnly = DateTime(
        targetDate.year,
        targetDate.month,
        targetDate.day,
      );
      final dateStr = _dateToString(targetDateOnly);

      final isCurrentlyCompleted = plan.isCompletedForDate(targetDateOnly);
      final newCompletedDates = List<String>.from(plan.completedDates);

      // Optimistic update - update UI immediately
      final index = _studyPlans.indexWhere((p) => p.id == plan.id);
      if (index == -1) {
        logger.w('Plan not found in list');
        return;
      }

      if (isCurrentlyCompleted) {
        newCompletedDates.remove(dateStr);
      } else {
        if (!newCompletedDates.contains(dateStr)) {
          newCompletedDates.add(dateStr);
        }
      }

      logger.d('New completed dates: $newCompletedDates');
      // Create updated plan with new completion status
      final optimisticPlan = StudyPlan(
        id: plan.id,
        title: plan.title,
        description: plan.description,
        subject: plan.subject,
        dueDate: plan.dueDate,
        completedDates: newCompletedDates,
        createdAt: plan.createdAt,
        repeatDays: plan.repeatDays,
        startDate: plan.startDate,
        endDate: plan.endDate,
      );

      _studyPlans[index] = optimisticPlan;
      // Save to local storage immediately
      await _storage.setStudyPlans(_studyPlans);
      update();

      // Then sync with backend
      try {
        final updatedPlan = await _studyPlannerService.updatePlanCompletion(
          plan.id,
          newCompletedDates,
        );

        // Update with server response
        final updatedIndex = _studyPlans.indexWhere((p) => p.id == plan.id);
        if (updatedIndex != -1) {
          _studyPlans[updatedIndex] = updatedPlan;
          // Save to local storage
          await _storage.setStudyPlans(_studyPlans);
          update();
        }
      } catch (e) {
        logger.e('Error syncing plan completion with backend: $e');

        // For development: keep the optimistic update even if API fails
        // In production, you might want to revert it
        // Revert optimistic update on error
        // _studyPlans[index] = plan;
        // update();

        // Show warning but don't revert (for mock API testing)
        AppSnackbar.showError(
          'Warning',
          e is ApiException
              ? '${e.message} (Changes saved locally)'
              : 'Failed to sync with server (Changes saved locally)',
        );
      }
    } catch (e) {
      logger.e('Error toggling plan completion: $e');

      AppSnackbar.showError(
        'Error',
        e is ApiException ? e.message : 'Failed to update plan',
      );
    }
  }

  String _dateToString(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  void _sortPlans() {
    _studyPlans.sort((a, b) {
      final aDate = a.effectiveDate;
      final bDate = b.effectiveDate;
      if (aDate == null && bDate == null) return 0;
      if (aDate == null) return 1; // Plans without date go to end
      if (bDate == null) return -1;
      return aDate.compareTo(bDate);
    });
  }

  void showPlanDetails(StudyPlan plan) {
    Get.dialog(
      AlertDialog(
        title: Text(plan.title),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              if (plan.description.isNotEmpty) ...[
                Text(
                  'Description',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                SizedBox(height: 8),
                Text(plan.description),
                SizedBox(height: 16),
              ],
              if (plan.subject.isNotEmpty) ...[
                Row(
                  children: [
                    Icon(Icons.book_rounded, size: 20),
                    SizedBox(width: 8),
                    Text(
                      'Subject: ${plan.subject}',
                      style: TextStyle(fontSize: 16),
                    ),
                  ],
                ),
                SizedBox(height: 16),
              ],
              if (plan.isRepeating) ...[
                Row(
                  children: [
                    Icon(Icons.repeat_rounded, size: 20, color: Colors.blue),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Repeats: ${_formatRepeatDays(plan.repeatDays)}',
                        style: TextStyle(fontSize: 16, color: Colors.blue),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 16),
              ],
              Row(
                children: [
                  Icon(Icons.access_time_rounded, size: 20),
                  SizedBox(width: 8),
                  Text(
                    plan.endDate != null
                        ? 'End: ${_formatDateTime(plan.endDate!)}'
                        : plan.startDate != null
                        ? 'Start: ${_formatDateTime(plan.startDate!)}'
                        : plan.dueDate != null
                        ? 'Due: ${_formatDateTime(plan.dueDate!)}'
                        : 'No date set',
                    style: TextStyle(fontSize: 16),
                  ),
                ],
              ),
              SizedBox(height: 16),
              // Show completion status for selected date
              Builder(
                builder: (context) {
                  final filterDate =
                      _selectedFilterDate ?? plan.dueDate ?? DateTime.now();
                  final filterDateOnly = DateTime(
                    filterDate.year,
                    filterDate.month,
                    filterDate.day,
                  );
                  final isCompleted = plan.isCompletedForDate(filterDateOnly);
                  return Row(
                    children: [
                      Icon(
                        isCompleted
                            ? Icons.check_circle
                            : Icons.radio_button_unchecked,
                        size: 20,
                        color: isCompleted ? Colors.green : Colors.grey,
                      ),
                      SizedBox(width: 8),
                      Text(
                        isCompleted ? 'Completed' : 'Pending',
                        style: TextStyle(
                          fontSize: 16,
                          color: isCompleted ? Colors.green : Colors.grey,
                        ),
                      ),
                      if (plan.completedDates.isNotEmpty) ...[
                        SizedBox(width: 8),
                        Text(
                          '(${plan.completedDates.length} completed)',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ],
                  );
                },
              ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Get.back(), child: Text('Close')),
          TextButton(
            onPressed: () {
              Get.back();
              showEditPlanPage(plan);
            },
            child: Text('Edit'),
          ),
          TextButton(
            onPressed: () {
              deleteStudyPlan(plan);
              Get.back();
            },
            child: Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  Future<void> deleteStudyPlan(StudyPlan plan) async {
    try {
      final success = await _studyPlannerService.deleteStudyPlan(plan.id);
      if (success) {
        _studyPlans.removeWhere((p) => p.id == plan.id);
        // Save to local storage
        await _storage.setStudyPlans(_studyPlans);
        // Cancel notifications for the deleted plan
        await _cancelNotificationForPlan(plan.id);
        update();
        AppSnackbar.showSuccess('Success', 'Study plan deleted');
      }
    } catch (e) {
      logger.e('Error deleting study plan: $e');
      // Save to local storage even if API fails (offline support)
      try {
        _studyPlans.removeWhere((p) => p.id == plan.id);
        await _storage.setStudyPlans(_studyPlans);
        // Cancel notifications for the deleted plan
        await _cancelNotificationForPlan(plan.id);
        update();
      } catch (storageError) {
        logger.e('Error saving to local storage: $storageError');
      }
      AppSnackbar.showError(
        'Error',
        e is ApiException
            ? '${e.message} (Deleted locally)'
            : 'Failed to delete study plan (Deleted locally)',
      );
      rethrow;
    }
  }

  String _formatDateTime(DateTime dateTime) {
    return '${dateTime.day}/${dateTime.month}/${dateTime.year} ${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
  }

  String _formatRepeatDays(List<int> days) {
    if (days.isEmpty) return '';

    final dayNames = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
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
      return sortedDays.map((d) => dayNames[d - 1]).join(', ');
    }
  }

  /// Schedule notification for a single plan
  Future<void> _scheduleNotificationForPlan(StudyPlan plan) async {
    if (_notificationService == null) return;
    try {
      await _notificationService!.scheduleStudyPlanNotification(plan);
    } catch (e) {
      logger.e('Error scheduling notification for plan ${plan.id}: $e');
    }
  }

  /// Schedule notifications for all plans
  Future<void> _scheduleNotificationsForAllPlans() async {
    if (_notificationService == null) return;
    try {
      await _notificationService!.scheduleAllStudyPlans(_studyPlans);
    } catch (e) {
      logger.e('Error scheduling notifications for all plans: $e');
    }
  }

  /// Cancel notification for a plan
  Future<void> _cancelNotificationForPlan(int planId) async {
    if (_notificationService == null) return;
    try {
      await _notificationService!.cancelStudyPlanNotifications(planId);
    } catch (e) {
      logger.e('Error cancelling notification for plan $planId: $e');
    }
  }
}
