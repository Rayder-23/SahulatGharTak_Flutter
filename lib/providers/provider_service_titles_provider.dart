import 'package:flutter/material.dart';

import '../data/repositories/provider_service_titles_repository.dart';
import '../models/provider/provider_service_title.dart';
import '../utils/api_error.dart';

class ProviderServiceTitlesProvider extends ChangeNotifier {
  ProviderServiceTitlesProvider(
      {required ProviderServiceTitlesRepository repository})
      : _repository = repository;

  final ProviderServiceTitlesRepository _repository;

  List<ProviderServiceTitle> _serviceTitles = [];
  bool _isLoading = false;
  bool _isSaving = false;
  String? _error;

  List<ProviderServiceTitle> get serviceTitles =>
      List.unmodifiable(_serviceTitles);
  bool get isLoading => _isLoading;
  bool get isSaving => _isSaving;
  String? get error => _error;

  Future<void> load(int providerUid) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _serviceTitles = await _repository.fetchServiceTitles(providerUid);
    } catch (e) {
      _error = friendlyErrorMessage(e);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> save(int providerUid,
      {required List<int> serviceTitleIds}) async {
    _isSaving = true;
    _error = null;
    notifyListeners();

    try {
      _serviceTitles = await _repository.replaceServiceTitles(providerUid,
          serviceTitleIds: serviceTitleIds);
      return true;
    } catch (e) {
      _error = friendlyErrorMessage(e);
      return false;
    } finally {
      _isSaving = false;
      notifyListeners();
    }
  }
}
