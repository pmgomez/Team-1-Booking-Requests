import 'document.dart';
import 'note.dart';

class AnointingSickBooking {
  final int? id;
  final int parishId;
  final String? parishName;
  final int userId;
  final String? sickPersonName;
  final String? contactPersonName;
  final String? contactEmail;
  final String? contactPhone;
  final String? location;
  final String? locationAddress;
  final String? preferredDate;
  final String? preferredTimeSlot;
  final int? priestId;
  final String? priestName;
  final List<Note>? notes;
  final String status;
  final int? approvedBy;
  final String? approvedAt;
  final String? createdAt;
  final String? updatedAt;
  final List<Document>? documents;

  AnointingSickBooking({
    this.id,
    required this.parishId,
    this.parishName,
    required this.userId,
    this.sickPersonName,
    this.contactPersonName,
    this.contactEmail,
    this.contactPhone,
    this.location,
    this.locationAddress,
    this.preferredDate,
    this.preferredTimeSlot,
    this.priestId,
    this.priestName,
    this.notes,
    this.status = 'pending',
    this.approvedBy,
    this.approvedAt,
    this.createdAt,
    this.updatedAt,
    this.documents,
  });

  factory AnointingSickBooking.fromJson(Map<String, dynamic> json) {
    List<Note>? notesList;
    if (json['notes'] != null) {
      notesList = (json['notes'] as List)
          .map((note) => Note.fromJson(note as Map<String, dynamic>))
          .toList();
    }

    return AnointingSickBooking(
      id: json['id'],
      parishId: json['parishId'],
      parishName: json['parish']?['name'],
      userId: json['userId'],
      sickPersonName: json['sickPersonName'],
      contactPersonName: json['contactPersonName'],
      contactEmail: json['contactEmail'],
      contactPhone: json['contactPhone'],
      location: json['location'],
      locationAddress: json['locationAddress'],
      preferredDate: json['preferredDate'],
      preferredTimeSlot: json['preferredTimeSlot'],
      priestId: json['priestId'],
      priestName: json['priest']?['firstName'] != null
          ? '${json['priest']['firstName']} ${json['priest']['lastName']}'
          : json['priestName'],
      notes: notesList,
      status: json['status'] ?? 'pending',
      approvedBy: json['approvedBy'],
      approvedAt: json['approvedAt'],
      createdAt: json['createdAt'],
      updatedAt: json['updatedAt'],
      documents: json['documents'] != null
          ? (json['documents'] as List).map((doc) => Document.fromJson(doc)).toList()
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      'parishId': parishId,
      'userId': userId,
      if (sickPersonName != null) 'sickPersonName': sickPersonName,
      if (contactPersonName != null) 'contactPersonName': contactPersonName,
      if (contactEmail != null) 'contactEmail': contactEmail,
      if (contactPhone != null) 'contactPhone': contactPhone,
      if (location != null) 'location': location,
      if (locationAddress != null) 'locationAddress': locationAddress,
      if (preferredDate != null) 'preferredDate': preferredDate,
      if (preferredTimeSlot != null) 'preferredTimeSlot': preferredTimeSlot,
      if (priestId != null) 'priestId': priestId,
      if (notes != null) 'notes': notes!.map((n) => n.toJson()).toList(),
      if (status != null) 'status': status,
    };
  }

  AnointingSickBooking copyWith({
    int? id,
    int? parishId,
    String? parishName,
    int? userId,
    String? sickPersonName,
    String? contactPersonName,
    String? contactEmail,
    String? contactPhone,
    String? location,
    String? locationAddress,
    String? preferredDate,
    String? preferredTimeSlot,
    int? priestId,
    String? priestName,
    List<Note>? notes,
    String? status,
    int? approvedBy,
    String? approvedAt,
    String? createdAt,
    String? updatedAt,
    List<Document>? documents,
  }) {
    return AnointingSickBooking(
      id: id ?? this.id,
      parishId: parishId ?? this.parishId,
      parishName: parishName ?? this.parishName,
      userId: userId ?? this.userId,
      sickPersonName: sickPersonName ?? this.sickPersonName,
      contactPersonName: contactPersonName ?? this.contactPersonName,
      contactEmail: contactEmail ?? this.contactEmail,
      contactPhone: contactPhone ?? this.contactPhone,
      location: location ?? this.location,
      locationAddress: locationAddress ?? this.locationAddress,
      preferredDate: preferredDate ?? this.preferredDate,
      preferredTimeSlot: preferredTimeSlot ?? this.preferredTimeSlot,
      priestId: priestId ?? this.priestId,
      priestName: priestName ?? this.priestName,
      notes: notes ?? this.notes,
      status: status ?? this.status,
      approvedBy: approvedBy ?? this.approvedBy,
      approvedAt: approvedAt ?? this.approvedAt,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      documents: documents ?? this.documents,
    );
  }
}
