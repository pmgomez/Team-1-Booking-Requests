import 'note.dart';

class MassIntention {
  final int? id;
  final String? type;
  final String? intentionDetails;
  final String? donorName;
  final String? dateRequested;
  final int? parishId;
  final String? parishName;
  final String? massSchedule;
  final String? preferredTime;
  final String? preferredPriest;
  final List<Note>? notes;
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
    this.parishName,
    this.massSchedule,
    this.preferredTime,
    this.preferredPriest,
    this.notes,
    this.status,
    this.submittedBy,
    this.createdAt,
    this.updatedAt,
  });

  factory MassIntention.fromJson(Map<String, dynamic> json) {
    List<Note>? notesList;
    if (json['notes'] != null) {
      notesList = (json['notes'] as List).map((note) {
        if (note is Map<String, dynamic>) {
          return Note.fromJson(note);
        } else if (note is String) {
          return Note(content: note);
        }
        return Note(content: note.toString());
      }).toList();
    }

    return MassIntention(
      id: json['id'],
      type: json['type'],
      intentionDetails: json['intentionDetails'],
      donorName: json['donorName'],
      dateRequested: json['dateRequested'],
      parishId: json['parishId'],
      parishName: json['parishName'],
      massSchedule: json['massSchedule'],
      preferredTime: json['preferredTime'],
      preferredPriest: json['preferredPriest'],
      notes: notesList,
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
      if (preferredTime != null) 'preferredTime': preferredTime,
      if (preferredPriest != null) 'preferredPriest': preferredPriest,
      if (notes != null) 'notes': notes!.map((n) => n.toJson()).toList(),
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
    String? preferredTime,
    String? preferredPriest,
    List<Note>? notes,
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
      preferredTime: preferredTime ?? this.preferredTime,
      preferredPriest: preferredPriest ?? this.preferredPriest,
      notes: notes ?? this.notes,
      status: status ?? this.status,
      submittedBy: submittedBy ?? this.submittedBy,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
