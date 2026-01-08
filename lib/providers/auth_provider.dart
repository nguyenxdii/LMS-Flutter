import 'package:flutter/material.dart';
import '../models/user_model.dart';
import '../services/api_service.dart';

class AuthProvider with ChangeNotifier {
  final ApiService _apiService = ApiService();
  UserModel? _user;
  bool _isLoading = false;

  UserModel? get user => _user;
  bool get isLoading => _isLoading;

  /// Đăng nhập người dùng
  Future<bool> login(String username, String password) async {
    _setLoading(true);

    try {
      final user = await _apiService.login(username, password);

      if (user != null) {
        print('✅ Login successful - CCCD: ${user.cccd}'); // DEBUG
        print('✅ LicenseType: ${user.licenseType}'); // DEBUG

        _user = user;
        _setLoading(false);
        return true;
      }

      _setLoading(false);
      return false;
    } catch (e) {
      print('❌ Login error: $e'); // DEBUG
      _setLoading(false);
      return false;
    }
  }

  /// Đăng xuất người dùng
  void logout() {
    _user = null;
    notifyListeners();
  }

  /// Cập nhật thông tin user
  void updateUserInfo({
    String? fullName,
    String? phone,
    String? email,
    String? address,
    String? cccd,
    String? licenseType,
  }) {
    if (_user != null) {
      _user = _user!.copyWith(
        fullName: fullName,
        phone: phone,
        email: email,
        address: address,
        cccd: cccd,
        licenseType: licenseType,
      );
      notifyListeners();
    }
  }

  /// Cập nhật avatar
  void updateUserAvatar(String avatarBase64) {
    if (_user != null) {
      _user = _user!.copyWith(avatarBase64: avatarBase64);
      notifyListeners();
    }
  }

  /// Helper method để set loading state
  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }
}
