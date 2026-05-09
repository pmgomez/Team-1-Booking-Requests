import 'package:flutter/foundation.dart';
import '../models/priest.dart';
import '../services/admin_service.dart';

class PriestProvider extends ChangeNotifier {
  final AdminService _adminService = AdminService();

  List<Priest> _priests = [];
  bool _isLoading = false;
  String? _errorMessage;
  int? _currentParishId;

  List<Priest> get priests => _priests;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  int? get currentParishId => _currentParishId;

  Future<void> loadPriestsByParish(int parishId, {String? token}) async {
    if (_currentParishId == parishId && _priests.isNotEmpty) {
      return;
    }

    _setLoading(true);
    _setErrorMessage(null);
    _currentParishId = parishId;

    final response = await _adminService.getPriestsByParish(token ?? '', parishId: parishId);

    if (response.success && response.data != null) {
      _priests = response.data!.map((json) => Priest.fromJson(json)).toList();
      _setLoading(false);
      notifyListeners();
    } else {
      _setLoading(false);
      _setErrorMessage(response.message ?? 'Failed to load priests');
      notifyListeners();
    }
  }

  void clearPriests() {
    _priests = [];
    _currentParishId = null;
    notifyListeners();
  }

  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void _setErrorMessage(String? message) {
    _errorMessage = message;
    notifyListeners();
  }
}