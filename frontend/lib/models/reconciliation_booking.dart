import 'note.dart';

class ReconciliationBooking {
  final int? id;
  final int parishId;
  final int userId;
  final String? penitentName;
  final String? contactEmail;
  final String? contactPhone;
  final String? preferredDate;
  final String? preferredTimeSlot;
  final List<Note>? notes;
  final String status;
  final int? approvedBy;
  final String? approvedAt;
  final String? createdAt;
  final String? updatedAt;
  final String? parishName;

  ReconciliationBooking({
    this.id,
    required this.parishId,
    required this.userId,
    this.penitentName,
    this.contactEmail,
    this.contactPhone,
    this.preferredDate,
    this.preferredTimeSlot,
    this.notes,
    this.status = 'pending',
    this.approvedBy,
    this.approvedAt,
    this.createdAt,
    this.updatedAt,
    this.parishName,
  });

  factory ReconciliationBooking.fromJson(Map<String, dynamic> json) {
    List<Note>? notesList;
    if (json['notes'] != null) {
      notesList = (json['notes'] as List)
          .map((note) => Note.fromJson(note as Map<String, dynamic>))
          .toList();
    }

    return ReconciliationBooking(
      id: json['id'],
      parishId: json['parishId'],
      userId: json['userId'],
      penitentName: json['penitentName'],
      contactEmail: json['contactEmail'],
      contactPhone: json['contactPhone'],
      preferredDate: json['preferredDate'],
      preferredTimeSlot: json['preferredTimeSlot'],
      notes: notesList,
      status: json['status'] ?? 'pending',
      approvedBy: json['approvedBy'],
      approvedAt: json['approvedAt'],
      createdAt: json['createdAt'],
      updatedAt: json['updatedAt'],
      parishName: json['parish']?['name'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      'parishId': parishId,
      'userId': userId,
      if (penitentName != null) 'penitentName': penitentName,
      if (contactEmail != null) 'contactEmail': contactEmail,
      if (contactPhone != null) 'contactPhone': contactPhone,
      if (preferredDate != null) 'preferredDate': preferredDate,
      if (preferredTimeSlot != null) 'preferredTimeSlot': preferredTimeSlot,
      if (notes != null) 'notes': notes!.map((n) => n.toJson()).toList(),
      if (status != null) 'status': status,
    };
  }

  ReconciliationBooking copyWith({
    int? id,
    int? parishId,
    int? userId,
    String? penitentName,
    String? contactEmail,
    String? contactPhone,
    String? preferredDate,
    String? preferredTimeSlot,
    List<Note>? notes,
    String? status,
    int? approvedBy,
    String? approvedAt,
    String? createdAt,
    String? updatedAt,
  }) {
    return ReconciliationBooking(
      id: id ?? this.id,
      parishId: parishId ?? this.parishId,
      userId: userId ?? this.userId,
      penitentName: penitentName ?? this.penitentName,
      contactEmail: contactEmail ?? this.contactEmail,
      contactPhone: contactPhone ?? this.contactPhone,
      preferredDate: preferredDate ?? this.preferredDate,
      preferredTimeSlot: preferredTimeSlot ?? this.preferredTimeSlot,
      notes: notes ?? this.notes,
      status: status ?? this.status,
      approvedBy: approvedBy ?? this.approvedBy,
      approvedAt: approvedAt ?? this.approvedAt,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
