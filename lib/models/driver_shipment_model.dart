class DriverDashboardStats {
  final int assigned;
  final int inProgress;
  final int completed;

  DriverDashboardStats({
    required this.assigned,
    required this.inProgress,
    required this.completed,
  });

  factory DriverDashboardStats.fromJson(Map<String, dynamic> json) {
    return DriverDashboardStats(
      // Handle both PascalCase (C# default) and camelCase (JSON default)
      assigned: json['Assigned'] ?? json['assigned'] ?? 0,
      inProgress: json['InProgress'] ?? json['inProgress'] ?? 0,
      completed: json['Completed'] ?? json['completed'] ?? 0,
    );
  }
}

class ShipmentRow {
  final int id;
  final String shipmentNo;
  final String orderNo;
  final String route;
  final String status;
  final int stops;
  final DateTime? startedAt;
  final DateTime? deliveredAt;
  final DateTime? updatedAt;
  final String customerName;
  final String originWarehouse;
  final String destinationWarehouse;

  ShipmentRow({
    required this.id,
    required this.shipmentNo,
    required this.orderNo,
    required this.route,
    required this.status,
    required this.stops,
    this.startedAt,
    this.deliveredAt,
    this.updatedAt,
    required this.customerName,
    required this.originWarehouse,
    required this.destinationWarehouse,
  });

  factory ShipmentRow.fromJson(Map<String, dynamic> json) {
    return ShipmentRow(
      id: json['Id'] ?? json['id'] ?? 0,
      shipmentNo: json['ShipmentNo'] ?? json['shipmentNo'] ?? '',
      orderNo: json['OrderNo'] ?? json['orderNo'] ?? '',
      route: json['Route'] ?? json['route'] ?? '',
      status: json['Status'] ?? json['status'] ?? '',
      stops: json['Stops'] ?? json['stops'] ?? 0,
      startedAt: json['StartedAt'] != null
          ? DateTime.tryParse(json['StartedAt'])
          : (json['startedAt'] != null
                ? DateTime.tryParse(json['startedAt'])
                : null),
      deliveredAt: json['DeliveredAt'] != null
          ? DateTime.tryParse(json['DeliveredAt'])
          : (json['deliveredAt'] != null
                ? DateTime.tryParse(json['deliveredAt'])
                : null),
      updatedAt: json['UpdatedAt'] != null
          ? DateTime.tryParse(json['UpdatedAt'])
          : (json['updatedAt'] != null
                ? DateTime.tryParse(json['updatedAt'])
                : null),
      customerName: json['CustomerName'] ?? json['customerName'] ?? '',
      originWarehouse: json['OriginWarehouse'] ?? json['originWarehouse'] ?? '',
      destinationWarehouse:
          json['DestinationWarehouse'] ?? json['destinationWarehouse'] ?? '',
    );
  }

  String get statusText {
    switch (status) {
      case 'Pending':
        return 'Chờ nhận';
      case 'Assigned':
        return 'Đã nhận';
      case 'OnRoute':
        return 'Đang chạy';
      case 'AtWarehouse':
        return 'Tại kho';
      case 'ArrivedDestination':
        return 'Đến điểm trả';
      case 'Delivered':
        return 'Hoàn thành';
      default:
        return status;
    }
  }
}

class RouteStopLite {
  final int routeStopId;
  final int seq;
  final String stopName;
  final DateTime? plannedETA;
  final DateTime? arrivedAt;
  final DateTime? departedAt;
  final String stopStatus;
  final String? note;

  RouteStopLite({
    required this.routeStopId,
    required this.seq,
    required this.stopName,
    this.plannedETA,
    this.arrivedAt,
    this.departedAt,
    required this.stopStatus,
    this.note,
  });

  factory RouteStopLite.fromJson(Map<String, dynamic> json) {
    return RouteStopLite(
      routeStopId: json['RouteStopId'] ?? json['routeStopId'] ?? 0,
      seq: json['Seq'] ?? json['seq'] ?? 0,
      stopName: json['StopName'] ?? json['stopName'] ?? '',
      plannedETA: json['PlannedETA'] != null
          ? DateTime.tryParse(json['PlannedETA'])
          : (json['plannedETA'] != null
                ? DateTime.tryParse(json['plannedETA'])
                : null),
      arrivedAt: json['ArrivedAt'] != null
          ? DateTime.tryParse(json['ArrivedAt'])
          : (json['arrivedAt'] != null
                ? DateTime.tryParse(json['arrivedAt'])
                : null),
      departedAt: json['DepartedAt'] != null
          ? DateTime.tryParse(json['DepartedAt'])
          : (json['departedAt'] != null
                ? DateTime.tryParse(json['departedAt'])
                : null),
      stopStatus: json['StopStatus'] ?? json['stopStatus'] ?? '',
      note: json['Note'] ?? json['note'],
    );
  }

  String get statusText {
    switch (stopStatus) {
      case 'Waiting':
        return 'Chờ đến';
      case 'Arrived':
        return 'Đã đến';
      case 'Departed':
        return 'Đã rời';
      default:
        return stopStatus;
    }
  }
}

class ShipmentRunHeader {
  final int shipmentId;
  final String shipmentNo;
  final String orderNo;
  final String customerName;
  final String route;
  final String status;
  final int? currentStopSeq;
  final DateTime? startedAt;
  final DateTime? deliveredAt;

  ShipmentRunHeader({
    required this.shipmentId,
    required this.shipmentNo,
    required this.orderNo,
    required this.customerName,
    required this.route,
    required this.status,
    this.currentStopSeq,
    this.startedAt,
    this.deliveredAt,
  });

  factory ShipmentRunHeader.fromJson(Map<String, dynamic> json) {
    return ShipmentRunHeader(
      shipmentId: json['ShipmentId'] ?? json['shipmentId'] ?? 0,
      shipmentNo: json['ShipmentNo'] ?? json['shipmentNo'] ?? '',
      orderNo: json['OrderNo'] ?? json['orderNo'] ?? '',
      customerName: json['CustomerName'] ?? json['customerName'] ?? '',
      route: json['Route'] ?? json['route'] ?? '',
      status: json['Status'] ?? json['status'] ?? '',
      currentStopSeq: json['CurrentStopSeq'] ?? json['currentStopSeq'],
      startedAt: json['StartedAt'] != null
          ? DateTime.tryParse(json['StartedAt'])
          : (json['startedAt'] != null
                ? DateTime.tryParse(json['startedAt'])
                : null),
      deliveredAt: json['DeliveredAt'] != null
          ? DateTime.tryParse(json['DeliveredAt'])
          : (json['deliveredAt'] != null
                ? DateTime.tryParse(json['deliveredAt'])
                : null),
    );
  }
}

class ShipmentDetail {
  final ShipmentRunHeader header;
  final List<RouteStopLite> stops;
  final String vehicleNo;
  final String driverName;
  final String? notes;

  ShipmentDetail({
    required this.header,
    required this.stops,
    required this.vehicleNo,
    required this.driverName,
    this.notes,
  });

  factory ShipmentDetail.fromJson(Map<String, dynamic> json) {
    return ShipmentDetail(
      header: ShipmentRunHeader.fromJson(
        json['Header'] ?? json['header'] ?? {},
      ),
      stops:
          ((json['Stops'] ?? json['stops']) as List?)
              ?.map((e) => RouteStopLite.fromJson(e))
              .toList() ??
          [],
      vehicleNo: json['VehicleNo'] ?? json['vehicleNo'] ?? '',
      driverName: json['DriverName'] ?? json['driverName'] ?? '',
      notes: json['Notes'] ?? json['notes'],
    );
  }
}
