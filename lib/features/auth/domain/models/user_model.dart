class UserModel {
  final int id;
  final String username;
  final String email;
  final String fullName;
  final String? picture;
  final DateTime? birthDate;
  final String? gender;
  final bool isVerified;

  UserModel({
    required this.id,
    required this.username,
    required this.email,
    required this.fullName,
    this.picture,
    this.birthDate,
    this.gender,
    required this.isVerified,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'],
      username: json['username'],
      email: json['email'],
      fullName: json['fullName'],
      picture: json['picture'],
      birthDate: json['birthDate'] != null ? DateTime.parse(json['birthDate']) : null,
      gender: json['gender'],
      isVerified: json['isVerified'] ?? false,
    );
  }

  // Berguna untuk update status secara lokal tanpa perlu hit API lagi
  UserModel copyWith({
    int? id,
    String? username,
    String? email,
    String? fullName,
    String? picture,
    DateTime? birthDate,
    String? gender,
    bool? isVerified,
  }) {
    return UserModel(
      id: id ?? this.id,
      username: username ?? this.username,
      email: email ?? this.email,
      fullName: fullName ?? this.fullName,
      picture: picture ?? this.picture,
      birthDate: birthDate ?? this.birthDate,
      gender: gender ?? this.gender,
      isVerified: isVerified ?? this.isVerified,
    );
  }
}