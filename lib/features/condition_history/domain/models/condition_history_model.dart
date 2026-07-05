class ConditionHistoryModel {
  final int id;
  final int livestockId;
  final int conditionTypeId;
  final DateTime recordDate;
  final String? notes;
  final DateTime createdAt;
  final DateTime updatedAt;

  // Relasi (bisa null tergantung response API)
  final Map<String, dynamic>? livestock;
  final Map<String, dynamic>? conditionType;

  ConditionHistoryModel({
    required this.id,
    required this.livestockId,
    required this.conditionTypeId,
    required this.recordDate,
    this.notes,
    required this.createdAt,
    required this.updatedAt,
    this.livestock,
    this.conditionType,
  });

  factory ConditionHistoryModel.fromJson(Map<String, dynamic> json) {
    return ConditionHistoryModel(
      id: json['id'],
      livestockId: json['livestockId'],
      conditionTypeId: json['conditionTypeId'],
      recordDate: DateTime.parse(json['recordDate']),
      notes: json['notes'],
      createdAt: DateTime.parse(json['createdAt']),
      updatedAt: DateTime.parse(json['updatedAt']),
      livestock: json['livestock'] as Map<String, dynamic>?,
      conditionType: json['conditionType'] as Map<String, dynamic>?,
    );
  }
}
