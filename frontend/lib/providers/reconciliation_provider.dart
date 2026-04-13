import 'package:flutter/foundation.dart';

import '../models/reconciliation_booking.dart';
import '../services/reconciliation_service.dart';

class ReconciliationProvider extends ChangeNotifier {
  final ReconciliationService _reconciliationService = ReconciliationService();

  List<ReconciliationBooking> _bookings = [];
  ReconciliationBooking? _selectedBooking;
  bool _isLoading = false;
  String? _errorMessage;

  List<ReconciliationBooking> get bookings => _bookings;
  ReconciliationBooking? get selectedBooking => _selectedBooking;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  Future<void> loadAllReconciliationBookings({
    required String token,
    int? page,
    int? limit,
    String? status,
    int? parishId,
  }) async {
    _setLoading(true);
    _setErrorMessage(null);

    final result = await _reconciliationService.getAllReconciliationBookings(
      token: token,
      page: page,
      limit: limit,
      status: status,
      parishId: parishId,
    );

    if (result.success && result.data != null) {
      _bookings = result.data!;
      _setLoading(false);
      notifyListeners();
    } else {
      _setLoading(false);
      _setErrorMessage(result.message ?? 'Failed to load reconciliation bookings');
      notifyListeners();
    }
  }

  Future<bool> createReconciliationBooking({
    required String token,
    required int parishId,
    required String penitentName,
    required String contactEmail,
    required String contactPhone,
    required String preferredDate,
    required String preferredTimeSlot,
    String? additionalNotes,
  }) async {
    _setLoading(true);
    _setErrorMessage(null);

    final result = await _reconciliationService.createReconciliationBooking(
      token: token,
      parishId: parishId,
      penitentName: penitentName,
      contactEmail: contactEmail,
      contactPhone: contactPhone,
      preferredDate: preferredDate,
      preferredTimeSlot: preferredTimeSlot,
      additionalNotes: additionalNotes,
    );

    if (result.success && result.data != null) {
      _bookings.add(result.data!);
      _setLoading(false);
      notifyListeners();
      return true;
    } else {
      _setLoading(false);
      _setErrorMessage(result.message ?? 'Failed to create reconciliation booking');
      notifyListeners();
      return false;
    }
  }

  Future<bool> updateReconciliationStatus({
    required String token,
    required int id,
    required String status,
    String? adminNotes,
  }) async {
    _setLoading(true);
    _setErrorMessage(null);

    final result = await _reconciliationService.updateReconciliationStatus(
      token: token,
      id: id,
      status: status,
      adminNotes: adminNotes,
    );

    if (result.success && result.data != null) {
      final index = _bookings.indexWhere((b) => b.id == id);
      if (index != -1) {
        _bookings[index] = result.data!;
      }
      if (_selectedBooking?.id == id) {
        _selectedBooking = result.data;
      }
      _setLoading(false);
      notifyListeners();
      return true;
    } else {
      _setLoading(false);
      _setErrorMessage(result.message ?? 'Failed to update reconciliation status');
      notifyListeners();
      return false;
    }
  }

  void clearError() {
    _setErrorMessage(null);
    notifyListeners();
  }

  void clearSelection() {
    _selectedBooking = null;
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
