class Priest {
  final int id;
  final String firstName;
  final String lastName;
  final String email;

  Priest({
    required this.id,
    required this.firstName,
    required this.lastName,
    required this.email,
  });

  factory Priest.fromJson(Map<String, dynamic> json) {
    return Priest(
      id: json['id'],
      firstName: json['firstName'],
      lastName: json['lastName'],
      email: json['email'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'firstName': firstName,
      'lastName': lastName,
      'email': email,
    };
  }

  String get fullName => '$firstName $lastName';
}