// viewmodels/course_viewmodel.dart - Simplified version
import 'package:flutter/material.dart';
import 'package:safarsync_mobileapp/backend/models/course_model.dart';
import 'package:safarsync_mobileapp/backend/repositories/course_repository.dart';
import 'package:safarsync_mobileapp/backend/utils/view_state.dart';

class CourseViewModel extends ChangeNotifier {
  ViewState _coursesState = ViewState.initial;
  ViewState get coursesState => _coursesState;

  List<CourseModel> _courses = [];
  List<CourseModel> get courses => _courses;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  // Fetch all courses
  Future<void> fetchCourses() async {
    _coursesState = ViewState.loading;
    notifyListeners();

    try {
      final response = await CourseRepository.fetchCourses();

      if (response['success'] == true) {
        _courses = response['courses'] as List<CourseModel>;
        _coursesState = _courses.isEmpty ? ViewState.empty : ViewState.loaded;
        _errorMessage = null;
      } else {
        _errorMessage = response['message'];
        _coursesState = ViewState.error;
      }
    } catch (e) {
      _errorMessage = 'Failed to fetch courses: ${e.toString()}';
      _coursesState = ViewState.error;
    }

    notifyListeners();
  }
}
