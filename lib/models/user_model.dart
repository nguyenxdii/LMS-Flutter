class UserModel {
  final int accountId;
  final String username;
  final String role;
  final int? customerId;
  final int? driverId;
  final String? fullName;
  final String? phone;
  final String? email;
  final String? address;
  final String? avatarBase64;
  // Driver-specific fields
  final String? cccd;
  final String? licenseType;

  UserModel({
    required this.accountId,
    required this.username,
    required this.role,
    this.customerId,
    this.driverId,
    this.fullName,
    this.phone,
    this.email,
    this.address,
    this.avatarBase64,
    this.cccd,
    this.licenseType,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      accountId: json['AccountId'] ?? 0,
      username: json['Username'] ?? '',
      role: json['Role'] ?? '',
      customerId: json['CustomerId'],
      driverId: json['DriverId'],
      fullName: json['FullName'] ?? json['CustomerName'] ?? json['DriverName'],
      phone: json['Phone'],
      email: json['Email'],
      address: json['Address'],
      avatarBase64: json['AvatarData'],
      cccd: json['CCCD'],
      licenseType: json['LicenseType'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'AccountId': accountId,
      'Username': username,
      'Role': role,
      'CustomerId': customerId,
      'DriverId': driverId,
      'FullName': fullName,
      'Phone': phone,
      'Email': email,
      'Address': address,
      'AvatarData': avatarBase64,
      'CCCD': cccd,
      'LicenseType': licenseType,
    };
  }

  UserModel copyWith({
    int? accountId,
    String? username,
    String? role,
    int? customerId,
    int? driverId,
    String? fullName,
    String? phone,
    String? email,
    String? address,
    String? avatarBase64,
    String? cccd,
    String? licenseType,
  }) {
    return UserModel(
      accountId: accountId ?? this.accountId,
      username: username ?? this.username,
      role: role ?? this.role,
      customerId: customerId ?? this.customerId,
      driverId: driverId ?? this.driverId,
      fullName: fullName ?? this.fullName,
      phone: phone ?? this.phone,
      email: email ?? this.email,
      address: address ?? this.address,
      avatarBase64: avatarBase64 ?? this.avatarBase64,
      cccd: cccd ?? this.cccd,
      licenseType: licenseType ?? this.licenseType,
    );
  }
}
