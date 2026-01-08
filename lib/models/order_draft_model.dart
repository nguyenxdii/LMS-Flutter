/// OrderDraft model for creating new orders
/// Matches backend LMS.BUS.Dtos.OrderDraft

class OrderDraft {
  final int customerId;
  final int originWarehouseId;
  final int destWarehouseId;
  final bool needPickup;
  final String? pickupAddress;
  final String? packageDescription;
  final DateTime? desiredTime;

  // Client-side calculated fees (for preview only, backend recalculates)
  final double routeFee;
  final double pickupFee;
  final double totalFee;

  OrderDraft({
    required this.customerId,
    required this.originWarehouseId,
    required this.destWarehouseId,
    required this.needPickup,
    this.pickupAddress,
    this.packageDescription,
    this.desiredTime,
    this.routeFee = 0,
    this.pickupFee = 0,
    this.totalFee = 0,
  });

  Map<String, dynamic> toJson() {
    return {
      'CustomerId': customerId,
      'OriginWarehouseId': originWarehouseId,
      'DestWarehouseId': destWarehouseId,
      'NeedPickup': needPickup,
      'PickupAddress': pickupAddress,
      'PackageDescription': packageDescription,
      'DesiredTime': desiredTime?.toIso8601String(),
      'RouteFee': routeFee,
      'PickupFee': pickupFee,
      'TotalFee': totalFee,
    };
  }

  OrderDraft copyWith({
    int? customerId,
    int? originWarehouseId,
    int? destWarehouseId,
    bool? needPickup,
    String? pickupAddress,
    String? packageDescription,
    DateTime? desiredTime,
    double? routeFee,
    double? pickupFee,
    double? totalFee,
  }) {
    return OrderDraft(
      customerId: customerId ?? this.customerId,
      originWarehouseId: originWarehouseId ?? this.originWarehouseId,
      destWarehouseId: destWarehouseId ?? this.destWarehouseId,
      needPickup: needPickup ?? this.needPickup,
      pickupAddress: pickupAddress ?? this.pickupAddress,
      packageDescription: packageDescription ?? this.packageDescription,
      desiredTime: desiredTime ?? this.desiredTime,
      routeFee: routeFee ?? this.routeFee,
      pickupFee: pickupFee ?? this.pickupFee,
      totalFee: totalFee ?? this.totalFee,
    );
  }
}
