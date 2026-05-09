import 'note.dart';
import 'document.dart';

class BaptismBooking {
  final int? id;
  final int? parishId;
  final String? parishName;
  final int? userId;
  final String? childFullName;
  final String? dateOfBirth;
  final String? fatherName;
  final String? motherName;
  final String? contactEmail;
  final String? contactPhone;
  final String? preferredDate;
  final String? preferredTimeSlot;
  final int? priestId;
  final String? priestName;
  final List<Note>? notes;
  final String? status;
  final int? approvedBy;
  final String? approvedAt;
  final String? createdAt;
  final String? updatedAt;
  final List<Document>? documents;

  BaptismBooking({
    this.id,
    this.parishId,
    this.parishName,
    this.userId,
    this.childFullName,
    this.dateOfBirth,
    this.fatherName,
    this.motherName,
    this.contactEmail,
    this.contactPhone,
    this.preferredDate,
    this.preferredTimeSlot,
    this.priestId,
    this.priestName,
    this.notes,
    this.status,
    this.approvedBy,
    this.approvedAt,
    this.createdAt,
    this.updatedAt,
    this.documents,
  });

  factory BaptismBooking.fromJson(Map<String, dynamic> json) {
    List<Note>? notesList;
    if (json['notes'] != null) {
      notesList = (json['notes'] as List)
          .map((note) => Note.fromJson(note as Map<String, dynamic>))
          .toList();
    }

    return BaptismBooking(
      id: json['id'],
      parishId: json['parishId'],
      parishName: json['parish']?['name'],
      userId: json['userId'],
      childFullName: json['childFullName'],
      dateOfBirth: json['dateOfBirth'],
      fatherName: json['fatherName'],
      motherName: json['motherName'],
      contactEmail: json['contactEmail'],
      contactPhone: json['contactPhone'],
      preferredDate: json['preferredDate'],
      preferredTimeSlot: json['preferredTimeSlot'],
      priestId: json['priestId'],
      priestName: json['priest']?['firstName'] != null 
          ? '${json['priest']['firstName']} ${json['priest']['lastName']}' 
          : json['priestName'],
      notes: notesList,
      status: json['status'],
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
      'childFullName': childFullName,
      if (dateOfBirth != null) 'dateOfBirth': dateOfBirth,
      if (fatherName != null) 'fatherName': fatherName,
      if (motherName != null) 'motherName': motherName,
      if (contactEmail != null) 'contactEmail': contactEmail,
      if (contactPhone != null) 'contactPhone': contactPhone,
      if (preferredDate != null) 'preferredDate': preferredDate,
      if (preferredTimeSlot != null) 'preferredTimeSlot': preferredTimeSlot,
      if (priestId != null) 'priestId': priestId,
      if (priestName != null) 'priestName': priestName,
      if (notes != null) 'notes': notes!.map((n) => n.toJson()).toList(),
      if (status != null) 'status': status,
      if (documents != null) 'documents': documents!.map((doc) => doc.toJson()).toList(),
    };
  }

  BaptismBooking copyWith({
    int? id,
    int? parishId,
    int? userId,
    String? childFullName,
    String? dateOfBirth,
    String? fatherName,
    String? motherName,
    String? contactEmail,
    String? contactPhone,
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
    return BaptismBooking(
      id: id ?? this.id,
      parishId: parishId ?? this.parishId,
      userId: userId ?? this.userId,
      childFullName: childFullName ?? this.childFullName,
      dateOfBirth: dateOfBirth ?? this.dateOfBirth,
      fatherName: fatherName ?? this.fatherName,
      motherName: motherName ?? this.motherName,
      contactEmail: contactEmail ?? this.contactEmail,
      contactPhone: contactPhone ?? this.contactPhone,
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
