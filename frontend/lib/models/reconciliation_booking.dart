class ReconciliationBooking {
  final int? id;
  final int parishId;
  final int userId;
  final String? penitentName;
  final String? contactEmail;
  final String? contactPhone;
  final String? preferredDate;
  final String? preferredTimeSlot;
  final String? additionalNotes;
  final String status;
  final String? adminNotes;
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
    this.additionalNotes,
    this.status = 'pending',
    this.adminNotes,
    this.approvedBy,
    this.approvedAt,
    this.createdAt,
    this.updatedAt,
    this.parishName,
  });

  factory ReconciliationBooking.fromJson(Map<String, dynamic> json) {
    return ReconciliationBooking(
      id: json['id'],
      parishId: json['parishId'],
      userId: json['userId'],
      penitentName: json['penitentName'],
      contactEmail: json['contactEmail'],
      contactPhone: json['contactPhone'],
      preferredDate: json['preferredDate'],
      preferredTimeSlot: json['preferredTimeSlot'],
      additionalNotes: json['additionalNotes'],
      status: json['status'] ?? 'pending',
      adminNotes: json['adminNotes'],
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
      if (additionalNotes != null) 'additionalNotes': additionalNotes,
      if (status != null) 'status': status,
      if (adminNotes != null) 'adminNotes': adminNotes,
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
    String? additionalNotes,
    String? status,
    String? adminNotes,
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
      additionalNotes: additionalNotes ?? this.additionalNotes,
      status: status ?? this.status,
      adminNotes: adminNotes ?? this.adminNotes,
      approvedBy: approvedBy ?? this.approvedBy,
      approvedAt: approvedAt ?? this.approvedAt,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
