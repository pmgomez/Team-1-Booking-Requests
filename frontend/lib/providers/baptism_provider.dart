import 'package:flutter/foundation.dart';

import '../models/baptism_booking.dart';
import '../services/baptism_service.dart';

class BaptismProvider extends ChangeNotifier {
  final BaptismService _baptismService = BaptismService();

  List<BaptismBooking> _bookings = [];
  BaptismBooking? _selectedBooking;
  bool _isLoading = false;
  String? _errorMessage;
  Map<String, dynamic>? _availableSlots;

  List<BaptismBooking> get bookings => _bookings;
  BaptismBooking? get selectedBooking => _selectedBooking;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  Map<String, dynamic>? get availableSlots => _availableSlots;

  Future<void> loadAllBaptismBookings({
    int? page,
    int? limit,
    String? status,
    int? parishId,
    String? startDate,
    String? endDate,
  }) async {
    _setLoading(true);
    _setErrorMessage(null);

    final result = await _baptismService.getAllBaptismBookings(
      page: page,
      limit: limit,
      status: status,
      parishId: parishId,
      startDate: startDate,
      endDate: endDate,
    );

    if (result.success && result.data != null) {
      _bookings = result.data!;
      _setLoading(false);
      notifyListeners();
    } else {
      _setLoading(false);
      _setErrorMessage(result.message ?? 'Failed to load baptism bookings');
      notifyListeners();
    }
  }

  Future<void> loadBaptismBookingById({
    required int id,
  }) async {
    _setLoading(true);
    _setErrorMessage(null);

    final result = await _baptismService.getBaptismBookingById(
      id: id,
    );

    if (result.success && result.data != null) {
      _selectedBooking = result.data;
      _setLoading(false);
      notifyListeners();
    } else {
      _setLoading(false);
      _setErrorMessage(result.message ?? 'Failed to load baptism booking');
      notifyListeners();
    }
  }

  Future<bool> createBaptismBooking({
    required int parishId,
    required String childFullName,
    required String dateOfBirth,
    required String fatherName,
    required String motherName,
    required String contactEmail,
    required String contactPhone,
    required String preferredDate,
    required String preferredTimeSlot,
    int? priestId,
    List<Map<String, dynamic>>? notes,
    List<Map<String, String>>? godparents,
    String? uploadedFile,
    String? filePath,
    String? fileUrl,
    int? fileSize,
    String? mimeType,
    String? documentType,
  }) async {
    _setLoading(true);
    _setErrorMessage(null);

    final result = await _baptismService.createBaptismBooking(
      parishId: parishId,
      childFullName: childFullName,
      dateOfBirth: dateOfBirth,
      fatherName: fatherName,
      motherName: motherName,
      contactEmail: contactEmail,
      contactPhone: contactPhone,
      preferredDate: preferredDate,
      preferredTimeSlot: preferredTimeSlot,
      priestId: priestId,
      notes: notes,
      godparents: godparents,
      uploadedFile: uploadedFile,
      filePath: filePath,
      fileUrl: fileUrl,
      fileSize: fileSize,
      mimeType: mimeType,
      documentType: documentType,
    );

    if (result.success && result.data != null) {
      _bookings.add(result.data!);
      _setLoading(false);
      notifyListeners();
      return true;
    } else {
      _setLoading(false);
      _setErrorMessage(result.message ?? 'Failed to create baptism booking');
      notifyListeners();
      return false;
    }
  }

  Future<bool> updateBaptismStatus({
    required int id,
    required String status,
    String? adminNotes,
  }) async {
    _setLoading(true);
    _setErrorMessage(null);

    final result = await _baptismService.updateBaptismStatus(
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
      _setErrorMessage(result.message ?? 'Failed to update baptism status');
      notifyListeners();
      return false;
    }
  }

  Future<bool> cancelBaptismBooking({
    required int id,
  }) async {
    _setLoading(true);
    _setErrorMessage(null);

    final result = await _baptismService.cancelBaptismBooking(
      id: id,
    );

    if (result.success) {
      _bookings.removeWhere((b) => b.id == id);
      if (_selectedBooking?.id == id) {
        _selectedBooking = null;
      }
      _setLoading(false);
      notifyListeners();
      return true;
    } else {
      _setLoading(false);
      _setErrorMessage(result.message ?? 'Failed to cancel baptism booking');
      notifyListeners();
      return false;
    }
  }

  Future<void> loadAvailableSlots({
    required int parishId,
    required String date,
  }) async {
    _setLoading(true);
    _setErrorMessage(null);

    final result = await _baptismService.getAvailableSlots(
      parishId: parishId,
      date: date,
    );

    if (result.success && result.data != null) {
      _availableSlots = {
        'parishId': parishId,
        'date': date,
        'slots': result.data,
      };
      _setLoading(false);
      notifyListeners();
    } else {
      _setLoading(false);
      _setErrorMessage(result.message ?? 'Failed to load available slots');
      notifyListeners();
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
