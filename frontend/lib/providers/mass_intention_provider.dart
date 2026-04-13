import 'package:flutter/foundation.dart';

import '../models/mass_intention.dart';
import '../services/mass_intention_service.dart';

class MassIntentionProvider extends ChangeNotifier {
  final MassIntentionService _massIntentionService = MassIntentionService();

  List<MassIntention> _intentions = [];
  MassIntention? _selectedIntention;
  bool _isLoading = false;
  String? _errorMessage;

  List<MassIntention> get intentions => _intentions;
  MassIntention? get selectedIntention => _selectedIntention;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  Future<void> loadAllMassIntentions({
    int? page,
    int? limit,
    String? status,
    int? parishId,
    String? type,
  }) async {
    _setLoading(true);
    _setErrorMessage(null);

    final result = await _massIntentionService.getAllMassIntentions(
      page: page,
      limit: limit,
      status: status,
      parishId: parishId,
      type: type,
    );

    if (result.success && result.data != null) {
      _intentions = result.data!;
      _setLoading(false);
      notifyListeners();
    } else {
      _setLoading(false);
      _setErrorMessage(result.message ?? 'Failed to load mass intentions');
      notifyListeners();
    }
  }

  Future<void> loadMassIntentionById({
    required int id,
  }) async {
    _setLoading(true);
    _setErrorMessage(null);

    final result = await _massIntentionService.getMassIntentionById(
      id: id,
    );

    if (result.success && result.data != null) {
      _selectedIntention = result.data;
      _setLoading(false);
      notifyListeners();
    } else {
      _setLoading(false);
      _setErrorMessage(result.message ?? 'Failed to load mass intention');
      notifyListeners();
    }
  }

  Future<bool> createMassIntention({
    required String type,
    required String intentionDetails,
    required String donorName,
    required String dateRequested,
    required int parishId,
    required String massSchedule,
    String? preferredPriest,
    String? notes,
  }) async {
    _setLoading(true);
    _setErrorMessage(null);

    final result = await _massIntentionService.createMassIntention(
      type: type,
      intentionDetails: intentionDetails,
      donorName: donorName,
      dateRequested: dateRequested,
      parishId: parishId,
      massSchedule: massSchedule,
      preferredPriest: preferredPriest,
      notes: notes,
    );

    if (result.success && result.data != null) {
      _intentions.add(result.data!);
      _setLoading(false);
      notifyListeners();
      return true;
    } else {
      _setLoading(false);
      _setErrorMessage(result.message ?? 'Failed to create mass intention');
      notifyListeners();
      return false;
    }
  }

  Future<bool> updateMassIntentionStatus({
    required int id,
    required String status,
    String? adminNotes,
  }) async {
    _setLoading(true);
    _setErrorMessage(null);

    final result = await _massIntentionService.updateMassIntentionStatus(
      id: id,
      status: status,
      adminNotes: adminNotes,
    );

    if (result.success && result.data != null) {
      final index = _intentions.indexWhere((i) => i.id == id);
      if (index != -1) {
        _intentions[index] = result.data!;
      }
      if (_selectedIntention?.id == id) {
        _selectedIntention = result.data;
      }
      _setLoading(false);
      notifyListeners();
      return true;
    } else {
      _setLoading(false);
      _setErrorMessage(result.message ?? 'Failed to update mass intention status');
      notifyListeners();
      return false;
    }
  }

  void clearError() {
    _setErrorMessage(null);
    notifyListeners();
  }

  void clearSelection() {
    _selectedIntention = null;
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
