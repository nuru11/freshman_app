import 'package:get/get.dart';
import 'api.dart';
import 'exceptions.dart';
import '../../utils/utils.dart';
import '../../models/models.dart';

/// Study Planner API Service
///
/// Expected API Endpoints:
/// - GET /app/study-plans/ - Get all study plans (authenticated)
/// - GET /app/study-plans/{id}/ - Get single study plan (authenticated)
/// - POST /app/study-plans/ - Create study plan (authenticated)
/// - PUT /app/study-plans/{id}/ - Update study plan (authenticated)
/// - PATCH /app/study-plans/{id}/ - Partial update (e.g., toggle completion) (authenticated)
/// - DELETE /app/study-plans/{id}/ - Delete study plan (authenticated)
///
/// Expected Request/Response Format (snake_case):
/// {
///   "id": 1,
///   "title": "Study Math Chapter 5",
///   "description": "Review and practice problems",
///   "subject": "Mathematics",
///   "due_date": "2024-01-15T14:30:00Z",
///   "completed_dates": ["2024-01-15", "2024-01-22"],  // Dates when plan was completed (YYYY-MM-DD)
///   "created_at": "2024-01-10T10:00:00Z",
///   "repeat_days": [1, 3, 5]  // 1=Monday, 7=Sunday
/// }
class StudyPlannerService extends GetxController {
  final ApiClient apiClient = ApiClient();

  // Get all study plans for the authenticated user
  Future<List<StudyPlan>> getStudyPlans() async {
    try {
      final response = await apiClient.get(
        '/app/study-plans/',
        authenticated: true,
      );

      logger.d('Study plans response: ${response.data}');

      if (response.statusCode == 200) {
        if (response.data is List) {
          return (response.data as List)
              .map((e) => StudyPlan.fromJson(e))
              .toList();
        }
        return [];
      }

      throw ApiException(
        response.data['detail'] ?? 'Failed to load study plans',
      );
    } catch (e) {
      logger.e('Error getting study plans: $e');
      if (e is ApiException) rethrow;
      throw ApiException('Failed to load study plans');
    }
  }

  // Get a single study plan by ID
  Future<StudyPlan?> getStudyPlanById(int id) async {
    try {
      final response = await apiClient.get(
        '/app/study-plans/$id/',
        authenticated: true,
      );

      if (response.statusCode == 200) {
        return StudyPlan.fromJson(response.data);
      }

      return null;
    } catch (e) {
      logger.e('Error getting study plan: $e');
      return null;
    }
  }

  // Create a new study plan
  Future<StudyPlan> createStudyPlan(StudyPlan plan) async {
    try {
      final response = await apiClient.post(
        '/app/study-plans/',
        data: _planToApiJson(plan),
        authenticated: true,
      );

      logger.d('Create study plan response: ${response.data}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        return StudyPlan.fromJson(response.data);
      }

      throw ApiException(
        response.data['detail'] ??
            response.data['error']?['message'] ??
            'Failed to create study plan',
      );
    } catch (e) {
      logger.e('Error creating study plan: $e');
      if (e is ApiException) rethrow;
      throw ApiException('Failed to create study plan');
    }
  }

  // Update an existing study plan
  Future<StudyPlan> updateStudyPlan(StudyPlan plan) async {
    try {
      final response = await apiClient.put(
        '/app/study-plans/${plan.id}/',
        data: _planToApiJson(plan),
        authenticated: true,
      );

      logger.d('Update study plan response: ${response.data}');

      if (response.statusCode == 200) {
        return StudyPlan.fromJson(response.data);
      }

      throw ApiException(
        response.data['detail'] ??
            response.data['error']?['message'] ??
            'Failed to update study plan',
      );
    } catch (e) {
      logger.e('Error updating study plan: $e');
      if (e is ApiException) rethrow;
      throw ApiException('Failed to update study plan');
    }
  }

  // Delete a study plan
  Future<bool> deleteStudyPlan(int id) async {
    try {
      final response = await apiClient.delete(
        '/app/study-plans/$id/',
        authenticated: true,
      );

      if (response.statusCode == 200 || response.statusCode == 204) {
        return true;
      }

      throw ApiException(
        response.data['detail'] ?? 'Failed to delete study plan',
      );
    } catch (e) {
      logger.e('Error deleting study plan: $e');
      if (e is ApiException) rethrow;
      throw ApiException('Failed to delete study plan');
    }
  }

  // Update plan completion dates
  Future<StudyPlan> updatePlanCompletion(
    int id,
    List<String> completedDates,
  ) async {
    try {
      final response = await apiClient.patch(
        '/app/study-plans/$id/',
        data: {'completed_dates': completedDates},
        authenticated: true,
      );

      logger.d(
        'Update completion response: ${response.statusCode} - ${response.data}',
      );

      if (response.statusCode == 200) {
        return StudyPlan.fromJson(response.data);
      }

      // Handle 404 (endpoint not found) - return mock response for development
      if (response.statusCode == 404) {
        logger.w('Study plans endpoint not found, using mock response');
        // Return a mock updated plan (for development/testing)
        // In production, this should throw an error
        throw ApiException('Study plans API endpoint not available');
      }

      throw ApiException(
        response.data['detail'] ??
            response.data['error']?['message'] ??
            'Failed to update plan completion (Status: ${response.statusCode})',
      );
    } catch (e) {
      logger.e('Error updating plan completion: $e');
      if (e is ApiException) rethrow;

      // Check if it's a network error
      if (e.toString().contains('SocketException') ||
          e.toString().contains('Connection') ||
          e.toString().contains('Failed host lookup')) {
        throw ApiException('Network error: Unable to connect to server');
      }

      throw ApiException('Failed to update plan completion: ${e.toString()}');
    }
  }

  // Convert StudyPlan to API JSON format (snake_case)
  Map<String, dynamic> _planToApiJson(StudyPlan plan) {
    print('plan to api json: ${plan.toJson().toString()}');
    return {
      'title': plan.title,
      'description': plan.description,
      'subject': plan.subject,
      'due_date': plan.dueDate?.toIso8601String(),
      'start_date': plan.startDate?.toIso8601String(),
      'end_date': plan.endDate?.toIso8601String(),
      'completed_dates': plan.completedDates,
      'repeat_days': plan.repeatDays,
    };
  }
}
