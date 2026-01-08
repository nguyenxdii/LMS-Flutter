/// Models for Order Tracking feature
/// Maps to backend Order, Shipment, and RouteStop entities

class OrderTracking {
  final int id;
  final String? orderNo;
  final int customerId;
  final DateTime createdAt;
  final int
  status; // 0=Pending, 1=Approved, 2=Completed, 3=InTransit, 4=Cancelled
  final String? cancelReason;

  // Warehouse info
  final WarehouseInfo? originWarehouse;
  final WarehouseInfo? destWarehouse;

  // Fees
  final double routeFee;
  final double pickupFee;
  final double totalFee;
  final double depositAmount;

  // Pickup
  final bool needPickup;
  final String? pickupAddress;
  final String? packageDescription;

  // Shipment
  final ShipmentInfo? shipment;

  OrderTracking({
    required this.id,
    this.orderNo,
    required this.customerId,
    required this.createdAt,
    required this.status,
    this.cancelReason,
    this.originWarehouse,
    this.destWarehouse,
    required this.routeFee,
    required this.pickupFee,
    required this.totalFee,
    required this.depositAmount,
    required this.needPickup,
    this.pickupAddress,
    this.packageDescription,
    this.shipment,
  });

  factory OrderTracking.fromJson(Map<String, dynamic> json) {
    return OrderTracking(
      id: json['Id'] ?? 0,
      orderNo: json['OrderNo'],
      customerId: json['CustomerId'] ?? 0,
      createdAt:
          DateTime.tryParse(json['CreatedAt']?.toString() ?? '') ??
          DateTime.now(),
      status: json['Status'] ?? 0,
      cancelReason: json['CancelReason'],
      originWarehouse: json['OriginWarehouse'] != null
          ? WarehouseInfo.fromJson(json['OriginWarehouse'])
          : null,
      destWarehouse: json['DestWarehouse'] != null
          ? WarehouseInfo.fromJson(json['DestWarehouse'])
          : null,
      routeFee: (json['RouteFee'] ?? 0).toDouble(),
      pickupFee: (json['PickupFee'] ?? 0).toDouble(),
      totalFee: (json['TotalFee'] ?? 0).toDouble(),
      depositAmount: (json['DepositAmount'] ?? 0).toDouble(),
      needPickup: json['NeedPickup'] ?? false,
      pickupAddress: json['PickupAddress'],
      packageDescription: json['PackageDescription'],
      shipment: json['Shipment'] != null
          ? ShipmentInfo.fromJson(json['Shipment'])
          : null,
    );
  }

  String get statusText {
    switch (status) {
      case 0:
        return 'Chờ duyệt';
      case 1:
        return 'Đã duyệt';
      case 2:
        return 'Đang vận chuyển'; // Mapping to backend logic if 2 exists
      case 3:
        return 'Hoàn tất'; // Match backend: Completed = 3
      case 4:
        return 'Đã hủy';
      default:
        return 'Đơn hàng';
    }
  }
}

class WarehouseInfo {
  final int id;
  final String name;
  final String? address;
  final int zoneId;

  WarehouseInfo({
    required this.id,
    required this.name,
    this.address,
    required this.zoneId,
  });

  factory WarehouseInfo.fromJson(Map<String, dynamic> json) {
    return WarehouseInfo(
      id: json['Id'] ?? 0,
      name: json['Name'] ?? '',
      address: json['Address'],
      zoneId: json['ZoneId'] ?? 0,
    );
  }
}

class ShipmentInfo {
  final int id;
  final int status;
  final List<RouteStop> routeStops;

  ShipmentInfo({
    required this.id,
    required this.status,
    required this.routeStops,
  });

  factory ShipmentInfo.fromJson(Map<String, dynamic> json) {
    List<RouteStop> stops = [];
    if (json['RouteStops'] != null) {
      stops = (json['RouteStops'] as List)
          .map((e) => RouteStop.fromJson(e))
          .toList();
      // Sort by Seq
      stops.sort((a, b) => a.seq.compareTo(b.seq));
    }

    return ShipmentInfo(
      id: json['Id'] ?? 0,
      status: json['Status'] ?? 0,
      routeStops: stops,
    );
  }

  String get statusText {
    switch (status) {
      case 0:
        return 'Chờ tài xế';
      case 1:
        return 'Đã nhận (Tài xế)';
      case 2:
        return 'Đang di chuyển';
      case 3:
        return 'Tại kho trung chuyển';
      case 4:
        return 'Đã đến kho đích';
      case 5:
        return 'Đã giao xong';
      case 6:
        return 'Thất bại';
      default:
        return 'Không xác định ($status)';
    }
  }
}

class RouteStop {
  final int id;
  final int seq;
  final String? stopName;
  final int status; // 0=Waiting, 1=Arrived, 2=Departed
  final DateTime? arrivedAt;
  final DateTime? departedAt;
  final String? note;
  final WarehouseInfo? warehouse;

  RouteStop({
    required this.id,
    required this.seq,
    this.stopName,
    required this.status,
    this.arrivedAt,
    this.departedAt,
    this.note,
    this.warehouse,
  });

  factory RouteStop.fromJson(Map<String, dynamic> json) {
    return RouteStop(
      id: json['Id'] ?? 0,
      seq: json['Seq'] ?? 0,
      stopName: json['StopName'],
      status: json['Status'] ?? 0,
      arrivedAt: json['ArrivedAt'] != null
          ? DateTime.tryParse(json['ArrivedAt'].toString())
          : null,
      departedAt: json['DepartedAt'] != null
          ? DateTime.tryParse(json['DepartedAt'].toString())
          : null,
      note: json['Note'],
      warehouse: json['Warehouse'] != null
          ? WarehouseInfo.fromJson(json['Warehouse'])
          : null,
    );
  }

  String get statusText {
    switch (status) {
      case 0:
        return 'Chờ';
      case 1:
        return 'Đã đến';
      case 2:
        return 'Đã rời';
      default:
        return 'N/A';
    }
  }

  /// Display name: prefer warehouse name, fallback to stopName
  String get displayName => warehouse?.name ?? stopName ?? 'Điểm dừng $seq';

  /// Is this the current active stop?
  bool get isCurrentStop => status == 1; // Arrived but not Departed
}
