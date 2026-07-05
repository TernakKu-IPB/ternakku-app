class LivestockModel {
  final int id;
  final int farmId;
  final String? tagId;
  final String? name;
  final String? picture;
  final int animalTypeId;
  final String gender;
  final DateTime? birthDate;
  final String status;
  final int? fatherId;
  final int? motherId;
  final DateTime createdAt;
  final DateTime updatedAt;

  final Map<String, dynamic>? animalType;

  LivestockModel({
    required this.id,
    required this.farmId,
    this.tagId,
    this.name,
    this.picture,
    required this.animalTypeId,
    required this.gender,
    this.birthDate,
    required this.status,
    this.fatherId,
    this.motherId,
    required this.createdAt,
    required this.updatedAt,
    this.animalType,
  });

  factory LivestockModel.fromJson(Map<String, dynamic> json) {
    return LivestockModel(
      id: json['id'],
      farmId: json['farmId'],
      tagId: json['tagId'],
      name: json['name'],
      picture: json['picture'],
      animalTypeId: json['animalTypeId'],
      gender: json['gender'] ?? 'unknown',
      birthDate: json['birthDate'] == null ? null : DateTime.parse(json['birthDate']),
      status: json['status'] ?? 'active',
      fatherId: json['fatherId'],
      motherId: json['motherId'],
      createdAt: DateTime.parse(json['createdAt']),
      updatedAt: DateTime.parse(json['updatedAt']),
      animalType: json['animalType'] as Map<String, dynamic>?,
    );
  }
}