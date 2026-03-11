import 'package:flutter/material.dart';
import 'package:safarsync_mobileapp/backend/models/service_model.dart';
import 'package:safarsync_mobileapp/backend/repositories/service_repository.dart';
import 'package:safarsync_mobileapp/backend/utils/view_state.dart';

class ServiceViewModel extends ChangeNotifier {
  ViewState _servicesState = ViewState.initial;
  ViewState get servicesState => _servicesState;

  List<ServiceModel> _services = [];
  List<ServiceModel> get services => _services;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  // Fetch all services
  Future<void> fetchServices() async {
    _servicesState = ViewState.loading;
    notifyListeners();

    try {
      final response = await ServiceRepository.fetchServices();

      if (response['success'] == true) {
        _services = response['services'] as List<ServiceModel>;
        _servicesState = _services.isEmpty ? ViewState.empty : ViewState.loaded;
        _errorMessage = null;
      } else {
        _errorMessage = response['message'];
        _servicesState = ViewState.error;
      }
    } catch (e) {
      _errorMessage = 'Failed to fetch services: ${e.toString()}';
      _servicesState = ViewState.error;
    }

    notifyListeners();
  }
}
