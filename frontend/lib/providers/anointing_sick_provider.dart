import 'package:flutter/foundation.dart';

import '../models/anointing_sick_booking.dart';
import '../services/anointing_sick_service.dart';

class AnointingSickProvider extends ChangeNotifier {
  final AnointingSickService _anointingSickService = AnointingSickService();

  List<AnointingSickBooking> _bookings = [];
  AnointingSickBooking? _selectedBooking;
  bool _isLoading = false;
  String? _errorMessage;

  List<AnointingSickBooking> get bookings => _bookings;
  AnointingSickBooking? get selectedBooking => _selectedBooking;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  Future<void> loadAllAnointingSickBookings({
    required String token,
    int? page,
    int? limit,
    String? status,
    int? parishId,
  }) async {
    _setLoading(true);
    _setErrorMessage(null);

    final result = await _anointingSickService.getAllAnointingSickBookings(
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
      _setErrorMessage(result.message ?? 'Failed to load anointing bookings');
      notifyListeners();
    }
  }

  Future<bool> createAnointingSickBooking({
    required String token,
    required int parishId,
    required String sickPersonName,
    required String contactPersonName,
    required String contactEmail,
    required String contactPhone,
    required String location,
    String? locationAddress,
    String? preferredDate,
    String? preferredTimeSlot,
    int? priestId,
    List<Map<String, dynamic>>? notes,
  }) async {
    _setLoading(true);
    _setErrorMessage(null);

    final result = await _anointingSickService.createAnointingSickBooking(
      token: token,
      parishId: parishId,
      sickPersonName: sickPersonName,
      contactPersonName: contactPersonName,
      contactEmail: contactEmail,
      contactPhone: contactPhone,
      location: location,
      locationAddress: locationAddress,
      preferredDate: preferredDate,
      preferredTimeSlot: preferredTimeSlot,
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
      _setErrorMessage(result.message ?? 'Failed to create anointing booking');
      notifyListeners();
      return false;
    }
  }

  Future<bool> updateAnointingSickStatus({
    required String token,
    required int id,
    required String status,
    String? adminNotes,
  }) async {
    _setLoading(true);
    _setErrorMessage(null);

    final result = await _anointingSickService.updateAnointingSickStatus(
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
      _setErrorMessage(result.message ?? 'Failed to update anointing status');
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
