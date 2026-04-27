import 'document.dart';

class FuneralMassBooking {
  final int? id;
  final int parishId;
  final String? parishName;
  final int userId;
  final String? deceasedFullName;
  final String? dateOfDeath;
  final String? representativeName;
  final String? contactEmail;
  final String? contactPhone;
  final String? wakeStartDate;
  final String? wakeEndDate;
  final String? wakeLocation;
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

  FuneralMassBooking({
    this.id,
    required this.parishId,
    this.parishName,
    required this.userId,
    this.deceasedFullName,
    this.dateOfDeath,
    this.representativeName,
    this.contactEmail,
    this.contactPhone,
    this.wakeStartDate,
    this.wakeEndDate,
    this.wakeLocation,
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

  factory FuneralMassBooking.fromJson(Map<String, dynamic> json) {
    return FuneralMassBooking(
      id: json['id'],
      parishId: json['parishId'],
      parishName: json['parish']?['name'],
      userId: json['userId'],
      deceasedFullName: json['deceasedFullName'],
      dateOfDeath: json['dateOfDeath'],
      representativeName: json['representativeName'],
      contactEmail: json['contactEmail'],
      contactPhone: json['contactPhone'],
      wakeStartDate: json['wakeStartDate'],
      wakeEndDate: json['wakeEndDate'],
      wakeLocation: json['wakeLocation'],
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
      if (deceasedFullName != null) 'deceasedFullName': deceasedFullName,
      if (dateOfDeath != null) 'dateOfDeath': dateOfDeath,
      if (representativeName != null) 'representativeName': representativeName,
      if (contactEmail != null) 'contactEmail': contactEmail,
      if (contactPhone != null) 'contactPhone': contactPhone,
      if (wakeStartDate != null) 'wakeStartDate': wakeStartDate,
      if (wakeEndDate != null) 'wakeEndDate': wakeEndDate,
      if (wakeLocation != null) 'wakeLocation': wakeLocation,
      if (preferredDate != null) 'preferredDate': preferredDate,
      if (preferredTimeSlot != null) 'preferredTimeSlot': preferredTimeSlot,
      if (preferredPriest != null) 'preferredPriest': preferredPriest,
      if (additionalNotes != null) 'additionalNotes': additionalNotes,
      if (status != null) 'status': status,
      if (adminNotes != null) 'adminNotes': adminNotes,
    };
  }

  FuneralMassBooking copyWith({
    int? id,
    int? parishId,
    String? parishName,
    int? userId,
    String? deceasedFullName,
    String? dateOfDeath,
    String? representativeName,
    String? contactEmail,
    String? contactPhone,
    String? wakeStartDate,
    String? wakeEndDate,
    String? wakeLocation,
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
    return FuneralMassBooking(
      id: id ?? this.id,
      parishId: parishId ?? this.parishId,
      parishName: parishName ?? this.parishName,
      userId: userId ?? this.userId,
      deceasedFullName: deceasedFullName ?? this.deceasedFullName,
      dateOfDeath: dateOfDeath ?? this.dateOfDeath,
      representativeName: representativeName ?? this.representativeName,
      contactEmail: contactEmail ?? this.contactEmail,
      contactPhone: contactPhone ?? this.contactPhone,
      wakeStartDate: wakeStartDate ?? this.wakeStartDate,
      wakeEndDate: wakeEndDate ?? this.wakeEndDate,
      wakeLocation: wakeLocation ?? this.wakeLocation,
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
