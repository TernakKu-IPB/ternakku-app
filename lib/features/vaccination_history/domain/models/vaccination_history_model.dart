class VaccinationHistoryModel {
  final int id;
  final int livestockId;
  final int vaccineId;
  final DateTime vaccinationDate;
  final bool isVaccinated;
  final String? batchNumber;
  final String? notes;
  final DateTime createdAt;
  final DateTime updatedAt;

  // Relasi (ada di response Get All saja)
  final Map<String, dynamic>? livestock;
  final Map<String, dynamic>? vaccine;

  VaccinationHistoryModel({
    required this.id,
    required this.livestockId,
    required this.vaccineId,
    required this.vaccinationDate,
    required this.isVaccinated,
    this.batchNumber,
    this.notes,
    required this.createdAt,
    required this.updatedAt,
    this.livestock,
    this.vaccine,
  });

  factory VaccinationHistoryModel.fromJson(Map<String, dynamic> json) {
    return VaccinationHistoryModel(
      id: json['id'],
      livestockId: json['livestockId'],
      vaccineId: json['vaccineId'],
      vaccinationDate: DateTime.parse(json['vaccinationDate']),
      isVaccinated: json['isVaccinated'] ?? false,
      batchNumber: json['batchNumber'],
      notes: json['notes'],
      createdAt: DateTime.parse(json['createdAt']),
      updatedAt: DateTime.parse(json['updatedAt']),
      livestock: json['livestock'] as Map<String, dynamic>?,
      vaccine: json['vaccine'] as Map<String, dynamic>?,
    );
  }

  VaccinationHistoryModel copyWith({
    int? id,
    int? livestockId,
    int? vaccineId,
    DateTime? vaccinationDate,
    bool? isVaccinated,
    Object? batchNumber = _sentinel,
    Object? notes = _sentinel,
    DateTime? createdAt,
    DateTime? updatedAt,
    Map<String, dynamic>? livestock,
    Map<String, dynamic>? vaccine,
  }) {
    return VaccinationHistoryModel(
      id: id ?? this.id,
      livestockId: livestockId ?? this.livestockId,
      vaccineId: vaccineId ?? this.vaccineId,
      vaccinationDate: vaccinationDate ?? this.vaccinationDate,
      isVaccinated: isVaccinated ?? this.isVaccinated,
      batchNumber: batchNumber == _sentinel ? this.batchNumber : (batchNumber as String?),
      notes: notes == _sentinel ? this.notes : (notes as String?),
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      livestock: livestock ?? this.livestock,
      vaccine: vaccine ?? this.vaccine,
    );
  }
}

const _sentinel = Object();
