class User {
  final int? id;
  final String email;
  final String firstName;
  final String lastName;
  final String? phone;
  final String role;
  final int? assignedParishId;
  final int? preferredParishId;
  final bool isActive;
  final bool mustChangePassword;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  User({
    this.id,
    required this.email,
    required this.firstName,
    required this.lastName,
    this.phone,
    required this.role,
    this.assignedParishId,
    this.preferredParishId,
    required this.isActive,
    this.mustChangePassword = false,
    this.createdAt,
    this.updatedAt,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'],
      email: json['email'],
      firstName: json['firstName'],
      lastName: json['lastName'],
      phone: json['phone'],
      role: json['role'],
      assignedParishId: json['assignedParishId'],
      preferredParishId: json['preferredParishId'],
      isActive: json['isActive'] ?? true,
      mustChangePassword: json['mustChangePassword'] ?? false,
      createdAt: json['createdAt'] != null ? DateTime.parse(json['createdAt']) : null,
      updatedAt: json['updatedAt'] != null ? DateTime.parse(json['updatedAt']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'firstName': firstName,
      'lastName': lastName,
      'phone': phone,
      'role': role,
      'assignedParishId': assignedParishId,
      'preferredParishId': preferredParishId,
      'isActive': isActive,
      'mustChangePassword': mustChangePassword,
      'createdAt': createdAt?.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
    };
  }

  String get fullName => '$firstName $lastName';

  /// Check if user belongs to a parish (not diocese-level)
  bool get hasParish => assignedParishId != null || preferredParishId != null;

  /// Get the effective parish ID (assigned first, then preferred)
  int? get effectiveParishId => assignedParishId ?? preferredParishId;

  User copyWith({
    int? id,
    String? email,
    String? firstName,
    String? lastName,
    String? phone,
    String? role,
    int? assignedParishId,
    int? preferredParishId,
    bool? isActive,
    bool? mustChangePassword,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return User(
      id: id ?? this.id,
      email: email ?? this.email,
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      phone: phone ?? this.phone,
      role: role ?? this.role,
      assignedParishId: assignedParishId ?? this.assignedParishId,
      preferredParishId: preferredParishId ?? this.preferredParishId,
      isActive: isActive ?? this.isActive,
      mustChangePassword: mustChangePassword ?? this.mustChangePassword,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}