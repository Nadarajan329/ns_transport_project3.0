class AdvanceHistoryModel {
  final String? id;
  final String driverId;
  final double amount;
  final String type; // 'given_by_owner', 'deducted_for_expense', 'expense_adjustment'
  final String? description;
  final String? tripId;
  final DateTime? createdAt;

  AdvanceHistoryModel({
    this.id,
    required this.driverId,
    required this.amount,
    required this.type,
    this.description,
    this.tripId,
    this.createdAt,
  });

  factory AdvanceHistoryModel.fromJson(Map<String, dynamic> json) {
    return AdvanceHistoryModel(
      id: json['id'] as String?,
      driverId: json['driver_id'] as String,
      amount: (json['amount'] as num).toDouble(),
      type: json['type'] as String,
      description: json['description'] as String?,
      tripId: json['trip_id'] as String?,
      createdAt: json['created_at'] != null ? DateTime.parse(json['created_at'] as String) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      'driver_id': driverId,
      'amount': amount,
      'type': type,
      if (description != null) 'description': description,
      if (tripId != null) 'trip_id': tripId,
      if (createdAt != null) 'created_at': createdAt!.toIso8601String(),
    };
  }
}
