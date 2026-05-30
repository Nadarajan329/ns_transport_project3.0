class TripModel {
  final String? id;
  final String driverId;
  final String vehicleNumber;
  final DateTime tripDate;
  final String fromLocation;
  final String toLocation;
  final String? loadType;
  final String loadTonnage;
  final double rentAmount;
  final double loadingExpense;
  final double unloadingExpense;
  final double otherExpense;
  final List<Map<String, dynamic>>? otherExpenseDetails;
  final double advanceAmount;
  final double? totalExpense;
  final double? remainingBalance;
  final double? netProfit;
  final String? notes;
  final List<String>? billImages;
  final List<String>? receiptImages;
  final List<String>? documentUrls;
  final String status; // 'draft', 'submitted', 'approved', 'rejected'
  final String? ownerComment;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  TripModel({
    this.id,
    required this.driverId,
    required this.vehicleNumber,
    required this.tripDate,
    required this.fromLocation,
    required this.toLocation,
    this.loadType,
    required this.loadTonnage,
    required this.rentAmount,
    required this.loadingExpense,
    required this.unloadingExpense,
    required this.otherExpense,
    this.otherExpenseDetails,
    required this.advanceAmount,
    this.totalExpense,
    this.remainingBalance,
    this.netProfit,
    this.notes,
    this.billImages,
    this.receiptImages,
    this.documentUrls,
    required this.status,
    this.ownerComment,
    this.createdAt,
    this.updatedAt,
  });

  factory TripModel.fromJson(Map<String, dynamic> json) {
    return TripModel(
      id: json['id'] as String?,
      driverId: json['driver_id'] as String,
      vehicleNumber: json['vehicle_number'] as String,
      tripDate: DateTime.parse(json['trip_date'] as String),
      fromLocation: json['from_location'] as String,
      toLocation: json['to_location'] as String,
      loadType: json['load_type'] as String?,
      loadTonnage: json['load_tonnage'] as String? ?? '',
      rentAmount: (json['rent_amount'] as num?)?.toDouble() ?? 0.0,
      loadingExpense: (json['loading_expense'] as num?)?.toDouble() ?? 0.0,
      unloadingExpense: (json['unloading_expense'] as num?)?.toDouble() ?? 0.0,
      otherExpense: (json['other_expense'] as num?)?.toDouble() ?? 0.0,
      otherExpenseDetails: json['other_expense_details'] != null 
          ? (json['other_expense_details'] as List).map((e) => Map<String, dynamic>.from(e as Map)).toList() 
          : null,
      advanceAmount: (json['advance_amount'] as num?)?.toDouble() ?? 0.0,
      totalExpense: (json['total_expense'] as num?)?.toDouble(),
      remainingBalance: (json['remaining_balance'] as num?)?.toDouble(),
      netProfit: (json['net_profit'] as num?)?.toDouble(),
      notes: json['notes'] as String?,
      billImages: json['bill_images'] != null ? List<String>.from(json['bill_images']) : null,
      receiptImages: json['receipt_images'] != null ? List<String>.from(json['receipt_images']) : null,
      documentUrls: (json['document_urls'] as List<dynamic>?)?.map((e) => e as String).toList(),
      status: json['status'] as String,
      ownerComment: json['owner_comment'] as String?,
      createdAt: json['created_at'] != null ? DateTime.parse(json['created_at'] as String) : null,
      updatedAt: json['updated_at'] != null ? DateTime.parse(json['updated_at'] as String) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      'driver_id': driverId,
      'vehicle_number': vehicleNumber,
      'trip_date': tripDate.toIso8601String(),
      'from_location': fromLocation,
      'to_location': toLocation,
      if (loadType != null) 'load_type': loadType,
      'load_tonnage': loadTonnage,
      'rent_amount': rentAmount,
      'loading_expense': loadingExpense,
      'unloading_expense': unloadingExpense,
      'other_expense': otherExpense,
      if (otherExpenseDetails != null) 'other_expense_details': otherExpenseDetails,
      'advance_amount': advanceAmount,
      if (totalExpense != null) 'total_expense': totalExpense,
      if (remainingBalance != null) 'remaining_balance': remainingBalance,
      if (netProfit != null) 'net_profit': netProfit,
      if (notes != null) 'notes': notes,
      if (billImages != null) 'bill_images': billImages,
      if (receiptImages != null) 'receipt_images': receiptImages,
      if (documentUrls != null) 'document_urls': documentUrls,
      'status': status,
      if (ownerComment != null) 'owner_comment': ownerComment,
      if (createdAt != null) 'created_at': createdAt!.toIso8601String(),
      if (updatedAt != null) 'updated_at': updatedAt!.toIso8601String(),
    };
  }

  TripModel copyWith({
    String? id,
    String? driverId,
    String? vehicleNumber,
    DateTime? tripDate,
    String? fromLocation,
    String? toLocation,
    String? loadType,
    String? loadTonnage,
    double? rentAmount,
    double? loadingExpense,
    double? unloadingExpense,
    double? otherExpense,
    List<Map<String, dynamic>>? otherExpenseDetails,
    double? advanceAmount,
    double? totalExpense,
    double? remainingBalance,
    double? netProfit,
    String? notes,
    List<String>? billImages,
    List<String>? receiptImages,
    List<String>? documentUrls,
    String? status,
    String? ownerComment,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return TripModel(
      id: id ?? this.id,
      driverId: driverId ?? this.driverId,
      vehicleNumber: vehicleNumber ?? this.vehicleNumber,
      tripDate: tripDate ?? this.tripDate,
      fromLocation: fromLocation ?? this.fromLocation,
      toLocation: toLocation ?? this.toLocation,
      loadType: loadType ?? this.loadType,
      loadTonnage: loadTonnage ?? this.loadTonnage,
      rentAmount: rentAmount ?? this.rentAmount,
      loadingExpense: loadingExpense ?? this.loadingExpense,
      unloadingExpense: unloadingExpense ?? this.unloadingExpense,
      otherExpense: otherExpense ?? this.otherExpense,
      otherExpenseDetails: otherExpenseDetails ?? this.otherExpenseDetails,
      advanceAmount: advanceAmount ?? this.advanceAmount,
      totalExpense: totalExpense ?? this.totalExpense,
      remainingBalance: remainingBalance ?? this.remainingBalance,
      netProfit: netProfit ?? this.netProfit,
      notes: notes ?? this.notes,
      billImages: billImages ?? this.billImages,
      receiptImages: receiptImages ?? this.receiptImages,
      documentUrls: documentUrls ?? this.documentUrls,
      status: status ?? this.status,
      ownerComment: ownerComment ?? this.ownerComment,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
