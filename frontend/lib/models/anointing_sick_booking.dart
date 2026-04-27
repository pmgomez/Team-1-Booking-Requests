import 'document.dart';

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
  final String? preferredPriest;
  final String? additionalNotes;
  final String status;
  final String? adminNotes;
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
    this.preferredPriest,
    this.additionalNotes,
    this.status = 'pending',
    this.adminNotes,
    this.approvedBy,
    this.approvedAt,
    this.createdAt,
    this.updatedAt,
    this.documents,
  });

  factory AnointingSickBooking.fromJson(Map<String, dynamic> json) {
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
      preferredPriest: json['preferredPriest'],
      additionalNotes: json['additionalNotes'],
      status: json['status'] ?? 'pending',
      adminNotes: json['adminNotes'],
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
      if (preferredPriest != null) 'preferredPriest': preferredPriest,
      if (additionalNotes != null) 'additionalNotes': additionalNotes,
      if (status != null) 'status': status,
      if (adminNotes != null) 'adminNotes': adminNotes,
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
    String? preferredPriest,
    String? additionalNotes,
    String? status,
    String? adminNotes,
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
      preferredPriest: preferredPriest ?? this.preferredPriest,
      additionalNotes: additionalNotes ?? this.additionalNotes,
      status: status ?? this.status,
      adminNotes: adminNotes ?? this.adminNotes,
      approvedBy: approvedBy ?? this.approvedBy,
      approvedAt: approvedAt ?? this.approvedAt,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      documents: documents ?? this.documents,
    );
  }
}
