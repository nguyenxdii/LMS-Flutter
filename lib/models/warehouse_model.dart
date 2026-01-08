/// Warehouse model for the Flutter app
/// Matches the backend Warehouse entity and Zone enum

/// Zone enum: North=0, Central=1, South=2
enum ZoneId {
  north, // 0
  central, // 1
  south, // 2
}

extension ZoneIdExtension on ZoneId {
  int get value => index;

  String get displayName {
    switch (this) {
      case ZoneId.north:
        return 'Miền Bắc';
      case ZoneId.central:
        return 'Miền Trung';
      case ZoneId.south:
        return 'Miền Nam';
    }
  }

  static ZoneId fromValue(int value) {
    switch (value) {
      case 0:
        return ZoneId.north;
      case 1:
        return ZoneId.central;
      case 2:
        return ZoneId.south;
      default:
        return ZoneId.north;
    }
  }
}

/// Warehouse model matching backend [dbo].[Warehouses] table
class Warehouse {
  final int id;
  final String name;
  final String? address;
  final ZoneId zoneId;

  Warehouse({
    required this.id,
    required this.name,
    this.address,
    required this.zoneId,
  });

  factory Warehouse.fromJson(Map<String, dynamic> json) {
    return Warehouse(
      id: json['Id'] ?? json['id'] ?? 0,
      name: json['Name'] ?? json['name'] ?? '',
      address: json['Address'] ?? json['address'],
      zoneId: ZoneIdExtension.fromValue(json['ZoneId'] ?? json['zoneId'] ?? 0),
    );
  }

  Map<String, dynamic> toJson() {
    return {'Id': id, 'Name': name, 'Address': address, 'ZoneId': zoneId.value};
  }

  @override
  String toString() => name;
}
