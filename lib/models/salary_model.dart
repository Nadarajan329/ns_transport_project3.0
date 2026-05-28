class SalaryModel {
  final String? id;
  final String driverId;
  final double totalSalary;
  final double paidAmount;
  final double advanceAmount;
  final double? remainingBalance;
  final int month;
  final int year;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  SalaryModel({
    this.id,
    required this.driverId,
    required this.totalSalary,
    required this.paidAmount,
    required this.advanceAmount,
    this.remainingBalance,
    required this.month,
    required this.year,
    this.createdAt,
    this.updatedAt,
  });

  factory SalaryModel.fromJson(Map<String, dynamic> json) {
    return SalaryModel(
      id: json['id'] as String?,
      driverId: json['driver_id'] as String,
      totalSalary: (json['total_salary'] as num).toDouble(),
      paidAmount: (json['paid_amount'] as num).toDouble(),
      advanceAmount: (json['advance_amount'] as num).toDouble(),
      remainingBalance: json['remaining_balance'] != null ? (json['remaining_balance'] as num).toDouble() : null,
      month: json['month'] as int,
      year: json['year'] as int,
      createdAt: json['created_at'] != null ? DateTime.parse(json['created_at'] as String) : null,
      updatedAt: json['updated_at'] != null ? DateTime.parse(json['updated_at'] as String) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      'driver_id': driverId,
      'total_salary': totalSalary,
      'paid_amount': paidAmount,
      'advance_amount': advanceAmount,
      if (remainingBalance != null) 'remaining_balance': remainingBalance,
      'month': month,
      'year': year,
      if (createdAt != null) 'created_at': createdAt!.toIso8601String(),
      if (updatedAt != null) 'updated_at': updatedAt!.toIso8601String(),
    };
  }

  double get baseSalary => totalSalary;
  double get advances => advanceAmount;
  double get netSalary => remainingBalance ?? (totalSalary - paidAmount - advanceAmount);
  String get status => netSalary <= 0 ? 'paid' : 'pending';

  SalaryModel copyWith({
    String? id,
    String? driverId,
    double? totalSalary,
    double? paidAmount,
    double? advanceAmount,
    double? remainingBalance,
    int? month,
    int? year,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return SalaryModel(
      id: id ?? this.id,
      driverId: driverId ?? this.driverId,
      totalSalary: totalSalary ?? this.totalSalary,
      paidAmount: paidAmount ?? this.paidAmount,
      advanceAmount: advanceAmount ?? this.advanceAmount,
      remainingBalance: remainingBalance ?? this.remainingBalance,
      month: month ?? this.month,
      year: year ?? this.year,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
