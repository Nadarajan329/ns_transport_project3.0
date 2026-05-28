class TripModel {
  final String? id;
  final String driverId;
  final String vehicleNumber;
  final DateTime tripDate;
  final String fromLocation;
  final String toLocation;
  final String? loadType;
  final String customerName;
  final double rentAmount;
  final double fuelExpense;
  final double tollExpense;
  final double foodExpense;
  final double otherExpense;
  final double advanceAmount;
  final double? totalExpense;
  final double? remainingBalance;
  final double? netProfit;
  final String? notes;
  final String? billImage;
  final String? receiptImage;
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
    required this.customerName,
    required this.rentAmount,
    required this.fuelExpense,
    required this.tollExpense,
    required this.foodExpense,
    required this.otherExpense,
    required this.advanceAmount,
    this.totalExpense,
    this.remainingBalance,
    this.netProfit,
    this.notes,
    this.billImage,
    this.receiptImage,
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
      customerName: json['customer_name'] as String,
      rentAmount: (json['rent_amount'] as num).toDouble(),
      fuelExpense: (json['fuel_expense'] as num).toDouble(),
      tollExpense: (json['toll_expense'] as num).toDouble(),
      foodExpense: (json['food_expense'] as num).toDouble(),
      otherExpense: (json['other_expense'] as num).toDouble(),
      advanceAmount: (json['advance_amount'] as num).toDouble(),
      totalExpense: json['total_expense'] != null ? (json['total_expense'] as num).toDouble() : null,
      remainingBalance: json['remaining_balance'] != null ? (json['remaining_balance'] as num).toDouble() : null,
      netProfit: json['net_profit'] != null ? (json['net_profit'] as num).toDouble() : null,
      notes: json['notes'] as String?,
      billImage: json['bill_image'] as String?,
      receiptImage: json['receipt_image'] as String?,
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
      'customer_name': customerName,
      'rent_amount': rentAmount,
      'fuel_expense': fuelExpense,
      'toll_expense': tollExpense,
      'food_expense': foodExpense,
      'other_expense': otherExpense,
      'advance_amount': advanceAmount,
      if (totalExpense != null) 'total_expense': totalExpense,
      if (remainingBalance != null) 'remaining_balance': remainingBalance,
      if (netProfit != null) 'net_profit': netProfit,
      if (notes != null) 'notes': notes,
      if (billImage != null) 'bill_image': billImage,
      if (receiptImage != null) 'receipt_image': receiptImage,
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
    String? customerName,
    double? rentAmount,
    double? fuelExpense,
    double? tollExpense,
    double? foodExpense,
    double? otherExpense,
    double? advanceAmount,
    double? totalExpense,
    double? remainingBalance,
    double? netProfit,
    String? notes,
    String? billImage,
    String? receiptImage,
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
      customerName: customerName ?? this.customerName,
      rentAmount: rentAmount ?? this.rentAmount,
      fuelExpense: fuelExpense ?? this.fuelExpense,
      tollExpense: tollExpense ?? this.tollExpense,
      foodExpense: foodExpense ?? this.foodExpense,
      otherExpense: otherExpense ?? this.otherExpense,
      advanceAmount: advanceAmount ?? this.advanceAmount,
      totalExpense: totalExpense ?? this.totalExpense,
      remainingBalance: remainingBalance ?? this.remainingBalance,
      netProfit: netProfit ?? this.netProfit,
      notes: notes ?? this.notes,
      billImage: billImage ?? this.billImage,
      receiptImage: receiptImage ?? this.receiptImage,
      documentUrls: documentUrls ?? this.documentUrls,
      status: status ?? this.status,
      ownerComment: ownerComment ?? this.ownerComment,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
