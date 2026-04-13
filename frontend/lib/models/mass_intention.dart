class MassIntention {
  final int? id;
  final String? type;
  final String? intentionDetails;
  final String? donorName;
  final String? dateRequested;
  final int? parishId;
  final String? massSchedule;
  final String? preferredPriest;
  final String? notes;
  final String? status;
  final int? submittedBy;
  final String? createdAt;
  final String? updatedAt;

  MassIntention({
    this.id,
    this.type,
    this.intentionDetails,
    this.donorName,
    this.dateRequested,
    this.parishId,
    this.massSchedule,
    this.preferredPriest,
    this.notes,
    this.status,
    this.submittedBy,
    this.createdAt,
    this.updatedAt,
  });

  factory MassIntention.fromJson(Map<String, dynamic> json) {
    return MassIntention(
      id: json['id'],
      type: json['type'],
      intentionDetails: json['intentionDetails'],
      donorName: json['donorName'],
      dateRequested: json['dateRequested'],
      parishId: json['parishId'],
      massSchedule: json['massSchedule'],
      preferredPriest: json['preferredPriest'],
      notes: json['notes'],
      status: json['status'] ?? 'pending',
      submittedBy: json['submittedBy'],
      createdAt: json['createdAt'],
      updatedAt: json['updatedAt'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      'type': type,
      'intentionDetails': intentionDetails,
      'donorName': donorName,
      'dateRequested': dateRequested,
      'parishId': parishId,
      'massSchedule': massSchedule,
      if (preferredPriest != null) 'preferredPriest': preferredPriest,
      if (notes != null) 'notes': notes,
      if (status != null) 'status': status,
      'submittedBy': submittedBy,
    };
  }

  MassIntention copyWith({
    int? id,
    String? type,
    String? intentionDetails,
    String? donorName,
    String? dateRequested,
    int? parishId,
    String? massSchedule,
    String? preferredPriest,
    String? notes,
    String? status,
    int? submittedBy,
    String? createdAt,
    String? updatedAt,
  }) {
    return MassIntention(
      id: id ?? this.id,
      type: type ?? this.type,
      intentionDetails: intentionDetails ?? this.intentionDetails,
      donorName: donorName ?? this.donorName,
      dateRequested: dateRequested ?? this.dateRequested,
      parishId: parishId ?? this.parishId,
      massSchedule: massSchedule ?? this.massSchedule,
      preferredPriest: preferredPriest ?? this.preferredPriest,
      notes: notes ?? this.notes,
      status: status ?? this.status,
      submittedBy: submittedBy ?? this.submittedBy,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
