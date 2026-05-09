import 'package:flutter/foundation.dart';
import 'package:file_picker/file_picker.dart';

import '../models/eucharist_booking.dart';
import '../services/eucharist_service.dart';

class EucharistProvider extends ChangeNotifier {
  final EucharistService _eucharistService = EucharistService();

  List<EucharistBooking> _bookings = [];
  EucharistBooking? _selectedBooking;
  bool _isLoading = false;
  String? _errorMessage;

  List<EucharistBooking> get bookings => _bookings;
  EucharistBooking? get selectedBooking => _selectedBooking;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  Future<void> loadAllEucharistBookings({
    required String token,
    int? page,
    int? limit,
    String? status,
    int? parishId,
  }) async {
    _setLoading(true);
    _setErrorMessage(null);

    final result = await _eucharistService.getAllEucharistBookings(
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
      _setErrorMessage(result.message ?? 'Failed to load eucharist bookings');
      notifyListeners();
    }
  }

  Future<bool> createEucharistBooking({
    required String token,
    required int parishId,
    required String communicantName,
    required String fatherName,
    required String motherName,
    required String contactEmail,
    required String contactPhone,
    required String preferredDate,
    required String preferredTimeSlot,
    int? priestId,
    List<Map<String, dynamic>>? notes,
    List<Map<String, dynamic>>? documents,
  }) async {
    _setLoading(true);
    _setErrorMessage(null);

    final result = await _eucharistService.createEucharistBooking(
      token: token,
      parishId: parishId,
      communicantName: communicantName,
      fatherName: fatherName,
      motherName: motherName,
      contactEmail: contactEmail,
      contactPhone: contactPhone,
      preferredDate: preferredDate,
      preferredTimeSlot: preferredTimeSlot,
      priestId: priestId,
      notes: notes,
      documents: documents,
    );

    if (result.success && result.data != null) {
      _bookings.add(result.data!);
      _setLoading(false);
      notifyListeners();
      return true;
    } else {
      _setLoading(false);
      _setErrorMessage(result.message ?? 'Failed to create eucharist booking');
      notifyListeners();
      return false;
    }
  }

  Future<bool> updateEucharistStatus({
    required String token,
    required int id,
    required String status,
    String? adminNotes,
  }) async {
    _setLoading(true);
    _setErrorMessage(null);

    final result = await _eucharistService.updateEucharistStatus(
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
      _setErrorMessage(result.message ?? 'Failed to update eucharist status');
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
    required PlatformFile file,
    String? documentType,
  }) async {
    _setLoading(true);
    _setErrorMessage(null);

    final result = await _eucharistService.attachDocumentToBooking(
      bookingId: bookingId,
      token: token,
      file: file,
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
