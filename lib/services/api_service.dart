import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/user_model.dart';

class ApiService {
  // URL cơ sở của API
  static const String baseUrl =
      'https://resourcefully-preprudent-luigi.ngrok-free.dev/api';

  /// Đăng nhập với username và password
  Future<UserModel?> login(String username, String password) async {
    final url = Uri.parse('$baseUrl/auth/login');

    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'Username': username, 'Password': password}),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return UserModel.fromJson(data);
      }
      return null;
    } catch (e) {
      // Log error nếu cần
      return null;
    }
  }

  /// Cập nhật thông tin khách hàng
  Future<bool> updateCustomerProfile({
    required int customerId,
    required String fullName,
    String? phone,
    String? email,
    String? address,
  }) async {
    final url = Uri.parse('$baseUrl/profile/customer/update');

    try {
      final body = {
        'CustomerId': customerId,
        'FullName': fullName,
        if (phone != null) 'Phone': phone,
        if (email != null) 'Email': email,
        if (address != null) 'Address': address,
      };

      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(body),
      );

      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  /// Upload avatar khách hàng
  Future<bool> updateCustomerAvatar({
    required int customerId,
    required String avatarBase64,
  }) async {
    final url = Uri.parse('$baseUrl/profile/customer/avatar');

    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'CustomerId': customerId,
          'AvatarBase64': avatarBase64,
        }),
      );

      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  /// Đổi mật khẩu khách hàng
  Future<bool> changeCustomerPassword({
    required int accountId,
    required String oldPassword,
    required String newPassword,
  }) async {
    final url = Uri.parse('$baseUrl/profile/customer/change-password');

    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'AccountId': accountId,
          'OldPassword': oldPassword,
          'NewPassword': newPassword,
        }),
      );

      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  // ===== DRIVER APIs =====

  /// Cập nhật thông tin tài xế
  /// Returns a Map with 'success' (bool) and 'message' (String)
  Future<Map<String, dynamic>> updateDriverProfile({
    required int driverId,
    required String fullName,
    String? phone,
    String? cccd,
    String? licenseType,
  }) async {
    final url = Uri.parse('$baseUrl/profile/driver/update');

    try {
      final body = {
        'DriverId': driverId,
        'FullName': fullName,
        if (phone != null) 'Phone': phone,
        if (cccd != null) 'CitizenId': cccd,
        if (licenseType != null) 'LicenseType': licenseType,
      };

      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(body),
      );

      if (response.statusCode == 200) {
        return {'success': true, 'message': 'Cập nhật thành công'};
      } else {
        // Try to parse error message from response body
        try {
          final errorData = jsonDecode(response.body);
          final errorMessage =
              errorData['Message'] ??
              errorData['message'] ??
              'Cập nhật thất bại';
          return {'success': false, 'message': errorMessage};
        } catch (_) {
          // If response is plain text, use it directly
          return {
            'success': false,
            'message': response.body.isNotEmpty
                ? response.body
                : 'Cập nhật thất bại',
          };
        }
      }
    } catch (e) {
      return {'success': false, 'message': 'Lỗi kết nối: $e'};
    }
  }

  /// Upload avatar tài xế
  Future<bool> updateDriverAvatar({
    required int driverId,
    required String avatarBase64,
  }) async {
    final url = Uri.parse('$baseUrl/profile/driver/avatar');

    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'DriverId': driverId, 'AvatarBase64': avatarBase64}),
      );

      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  /// Đổi mật khẩu tài xế
  Future<bool> changeDriverPassword({
    required int accountId,
    required String oldPassword,
    required String newPassword,
  }) async {
    final url = Uri.parse('$baseUrl/profile/driver/change-password');

    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'AccountId': accountId,
          'OldPassword': oldPassword,
          'NewPassword': newPassword,
        }),
      );

      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  /// Lấy danh sách đơn hàng của khách hàng
  Future<List<Map<String, dynamic>>> getCustomerOrders(int customerId) async {
    final url = Uri.parse('$baseUrl/order/history?customerId=$customerId');

    try {
      print('🔍 Calling API: $url'); // DEBUG
      final response = await http.get(url);

      print('📡 Response status: ${response.statusCode}'); // DEBUG
      print('📦 Response body: ${response.body}'); // DEBUG

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        print('✅ Parsed ${data.length} orders'); // DEBUG
        return data.cast<Map<String, dynamic>>();
      }
      print('❌ API returned status: ${response.statusCode}'); // DEBUG
      return [];
    } catch (e) {
      print('💥 Error: $e'); // DEBUG
      return [];
    }
  }

  // ===== WAREHOUSE APIs =====

  /// Lấy tất cả kho hàng
  Future<List<Map<String, dynamic>>> getWarehouses() async {
    final url = Uri.parse('$baseUrl/order/warehouses');

    try {
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data.cast<Map<String, dynamic>>();
      }
      return [];
    } catch (e) {
      print('Error fetching warehouses: $e');
      return [];
    }
  }

  /// Lấy kho hàng theo vùng
  /// zoneId: 0=Bắc, 1=Trung, 2=Nam
  Future<List<Map<String, dynamic>>> getWarehousesByZone(int zoneId) async {
    final url = Uri.parse('$baseUrl/order/warehouses?zoneId=$zoneId');

    try {
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data.cast<Map<String, dynamic>>();
      }
      return [];
    } catch (e) {
      print('Error fetching warehouses by zone: $e');
      return [];
    }
  }

  /// Lấy danh sách các vùng
  Future<List<Map<String, dynamic>>> getZones() async {
    final url = Uri.parse('$baseUrl/order/zones');

    try {
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data.cast<Map<String, dynamic>>();
      }
      return [];
    } catch (e) {
      print('Error fetching zones: $e');
      return [];
    }
  }

  /// Tạo đơn hàng mới
  /// Returns: Map với 'success' (bool), 'message' (String), và 'order' (Map nếu thành công)
  Future<Map<String, dynamic>> createOrder(
    Map<String, dynamic> orderDraft,
  ) async {
    final url = Uri.parse('$baseUrl/order/create');

    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(orderDraft),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return {
          'success': true,
          'message': 'Tạo đơn hàng thành công',
          'order': data,
        };
      } else {
        try {
          final errorData = jsonDecode(response.body);
          return {
            'success': false,
            'message':
                errorData['Message'] ??
                errorData['message'] ??
                'Tạo đơn hàng thất bại',
          };
        } catch (_) {
          return {
            'success': false,
            'message': response.body.isNotEmpty
                ? response.body
                : 'Tạo đơn hàng thất bại',
          };
        }
      }
    } catch (e) {
      return {'success': false, 'message': 'Lỗi kết nối: $e'};
    }
  }
}
