import 'package:flutter/foundation.dart';

import '../models/wedding_booking.dart';
import '../services/wedding_service.dart';

class WeddingProvider extends ChangeNotifier {
  final WeddingService _weddingService = WeddingService();

  List<WeddingBooking> _bookings = [];
  WeddingBooking? _selectedBooking;
  bool _isLoading = false;
  String? _errorMessage;

  List<WeddingBooking> get bookings => _bookings;
  WeddingBooking? get selectedBooking => _selectedBooking;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  Future<void> loadAllWeddingBookings({
    required String token,
    int? page,
    int? limit,
    String? status,
    int? parishId,
  }) async {
    _setLoading(true);
    _setErrorMessage(null);

    final result = await _weddingService.getAllWeddingBookings(
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
      _setErrorMessage(result.message ?? 'Failed to load wedding bookings');
      notifyListeners();
    }
  }

  Future<bool> createWeddingBooking({
    required String token,
    required int parishId,
    required String groomFullName,
    required String brideFullName,
    required String contactEmail,
    required String contactPhone,
    required String preferredDate,
    required String preferredTimeSlot,
    String? seminarSchedule,
    String? preferredPriest,
    String? additionalNotes,
    List<Map<String, dynamic>>? documents,
  }) async {
    _setLoading(true);
    _setErrorMessage(null);

    final result = await _weddingService.createWeddingBooking(
      token: token,
      parishId: parishId,
      groomFullName: groomFullName,
      brideFullName: brideFullName,
      contactEmail: contactEmail,
      contactPhone: contactPhone,
      preferredDate: preferredDate,
      preferredTimeSlot: preferredTimeSlot,
      seminarSchedule: seminarSchedule,
      preferredPriest: preferredPriest,
      additionalNotes: additionalNotes,
      documents: documents,
    );

    if (result.success && result.data != null) {
      _bookings.add(result.data!);
      _setLoading(false);
      notifyListeners();
      return true;
    } else {
      _setLoading(false);
      _setErrorMessage(result.message ?? 'Failed to create wedding booking');
      notifyListeners();
      return false;
    }
  }

  Future<bool> updateWeddingStatus({
    required String token,
    required int id,
    required String status,
    String? adminNotes,
  }) async {
    _setLoading(true);
    _setErrorMessage(null);

    final result = await _weddingService.updateWeddingStatus(
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
      _setErrorMessage(result.message ?? 'Failed to update wedding status');
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

  Future<bool> attachDocumentToBooking({
    required int bookingId,
    required String token,
    required String filePath,
    String? documentType,
  }) async {
    _setLoading(true);
    _setErrorMessage(null);

    final result = await _weddingService.attachDocumentToBooking(
      bookingId: bookingId,
      token: token,
      filePath: filePath,
      documentType: documentType,
    );

    if (result.success) {
      _setLoading(false);
      notifyListeners();
      return true;
    } else {
      _setLoading(false);
      _setErrorMessage(result.message ?? 'Failed to upload document');
      notifyListeners();
      return false;
    }
  }
}
