import 'package:flutter/foundation.dart';

import '../models/funeral_mass_booking.dart';
import '../services/funeral_mass_service.dart';

class FuneralMassProvider extends ChangeNotifier {
  final FuneralMassService _funeralMassService = FuneralMassService();

  List<FuneralMassBooking> _bookings = [];
  FuneralMassBooking? _selectedBooking;
  bool _isLoading = false;
  String? _errorMessage;

  List<FuneralMassBooking> get bookings => _bookings;
  FuneralMassBooking? get selectedBooking => _selectedBooking;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  Future<void> loadAllFuneralMassBookings({
    required String token,
    int? page,
    int? limit,
    String? status,
    int? parishId,
  }) async {
    _setLoading(true);
    _setErrorMessage(null);

    final result = await _funeralMassService.getAllFuneralMassBookings(
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
      _setErrorMessage(result.message ?? 'Failed to load funeral mass bookings');
      notifyListeners();
    }
  }

  Future<bool> createFuneralMassBooking({
    required String token,
    required int parishId,
    required String deceasedFullName,
    required String representativeName,
    required String contactEmail,
    required String contactPhone,
    required String preferredDate,
    required String preferredTimeSlot,
    String? dateOfDeath,
    String? wakeStartDate,
    String? wakeEndDate,
    String? wakeLocation,
    int? priestId,
    List<Map<String, dynamic>>? notes,
  }) async {
    _setLoading(true);
    _setErrorMessage(null);

    final result = await _funeralMassService.createFuneralMassBooking(
      token: token,
      parishId: parishId,
      deceasedFullName: deceasedFullName,
      representativeName: representativeName,
      contactEmail: contactEmail,
      contactPhone: contactPhone,
      preferredDate: preferredDate,
      preferredTimeSlot: preferredTimeSlot,
      dateOfDeath: dateOfDeath,
      wakeStartDate: wakeStartDate,
      wakeEndDate: wakeEndDate,
      wakeLocation: wakeLocation,
      priestId: priestId,
      notes: notes,
    );

    if (result.success && result.data != null) {
      _bookings.add(result.data!);
      _setLoading(false);
      notifyListeners();
      return true;
    } else {
      _setLoading(false);
      _setErrorMessage(result.message ?? 'Failed to create funeral mass booking');
      notifyListeners();
      return false;
    }
  }

  Future<bool> updateFuneralMassStatus({
    required String token,
    required int id,
    required String status,
    String? adminNotes,
  }) async {
    _setLoading(true);
    _setErrorMessage(null);

    final result = await _funeralMassService.updateFuneralMassStatus(
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
      _setErrorMessage(result.message ?? 'Failed to update funeral mass status');
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
