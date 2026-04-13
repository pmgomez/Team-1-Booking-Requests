import 'package:flutter/foundation.dart';

import '../models/confirmation_booking.dart';
import '../services/confirmation_service.dart';

class ConfirmationProvider extends ChangeNotifier {
  final ConfirmationService _confirmationService = ConfirmationService();

  List<ConfirmationBooking> _bookings = [];
  ConfirmationBooking? _selectedBooking;
  bool _isLoading = false;
  String? _errorMessage;

  List<ConfirmationBooking> get bookings => _bookings;
  ConfirmationBooking? get selectedBooking => _selectedBooking;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  Future<void> loadAllConfirmationBookings({
    required String token,
    int? page,
    int? limit,
    String? status,
    int? parishId,
  }) async {
    _setLoading(true);
    _setErrorMessage(null);

    final result = await _confirmationService.getAllConfirmationBookings(
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
      _setErrorMessage(result.message ?? 'Failed to load confirmation bookings');
      notifyListeners();
    }
  }

  Future<bool> createConfirmationBooking({
    required String token,
    required int parishId,
    required String confirmandName,
    required String fatherName,
    required String motherName,
    required String contactEmail,
    required String contactPhone,
    required String preferredDate,
    required String preferredTimeSlot,
    String? preferredPriest,
    String? additionalNotes,
  }) async {
    _setLoading(true);
    _setErrorMessage(null);

    final result = await _confirmationService.createConfirmationBooking(
      token: token,
      parishId: parishId,
      confirmandName: confirmandName,
      fatherName: fatherName,
      motherName: motherName,
      contactEmail: contactEmail,
      contactPhone: contactPhone,
      preferredDate: preferredDate,
      preferredTimeSlot: preferredTimeSlot,
      preferredPriest: preferredPriest,
      additionalNotes: additionalNotes,
    );

    if (result.success && result.data != null) {
      _bookings.add(result.data!);
      _setLoading(false);
      notifyListeners();
      return true;
    } else {
      _setLoading(false);
      _setErrorMessage(result.message ?? 'Failed to create confirmation booking');
      notifyListeners();
      return false;
    }
  }

  Future<bool> updateConfirmationStatus({
    required String token,
    required int id,
    required String status,
    String? adminNotes,
  }) async {
    _setLoading(true);
    _setErrorMessage(null);

    final result = await _confirmationService.updateConfirmationStatus(
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
      _setErrorMessage(result.message ?? 'Failed to update confirmation status');
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
