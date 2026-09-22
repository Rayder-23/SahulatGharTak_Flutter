import 'package:flutter/material.dart';

import '../data/repositories/provider_categories_repository.dart';
import '../models/provider/provider_category.dart';
import '../utils/api_error.dart';

class ProviderCategoriesProvider extends ChangeNotifier {
  ProviderCategoriesProvider({required ProviderCategoriesRepository repository}) : _repository = repository;

  final ProviderCategoriesRepository _repository;

  List<ProviderCategory> _categories = [];
  bool _isLoading = false;
  bool _isSaving = false;
  String? _error;

  List<ProviderCategory> get categories => List.unmodifiable(_categories);
  bool get isLoading => _isLoading;
  bool get isSaving => _isSaving;
  String? get error => _error;

  Future<void> load(int providerUid) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _categories = await _repository.fetchCategories(providerUid);
    } catch (e) {
      _error = friendlyErrorMessage(e);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> save(int providerUid, {required List<int> categoryIds, required int primaryCategoryId}) async {
    _isSaving = true;
    _error = null;
    notifyListeners();

    try {
      _categories = await _repository.replaceCategories(providerUid, categoryIds: categoryIds, primaryCategoryId: primaryCategoryId);
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
