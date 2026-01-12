import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../services/api_service.dart';
import '../auth/login_screen.dart';

class CustomerAccountScreen extends StatefulWidget {
  const CustomerAccountScreen({super.key});

  @override
  State<CustomerAccountScreen> createState() => _CustomerAccountScreenState();
}

class _CustomerAccountScreenState extends State<CustomerAccountScreen>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  // Chế độ sửa
  bool _isEditingProfile = false;
  bool _isEditingPassword = false;
  bool _isLoading = false;

  // Controllers cho thông tin cá nhân
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _addressController = TextEditingController();

  // Controllers cho mật khẩu
  final _oldPasswordController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _showOldPassword = false;
  bool _showNewPassword = false;

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _addressController.dispose();
    _oldPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final authProvider = Provider.of<AuthProvider>(context);
    final user = authProvider.user;

    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            _AvatarSection(
              user: user,
              isEditing: _isEditingProfile,
              onAvatarTap: () {
                if (_isEditingProfile) {
                  _pickAndUploadAvatar(user?.customerId ?? 0);
                }
              },
            ),
            const SizedBox(height: 25),

            _ProfileCard(
              user: user,
              isEditing: _isEditingProfile,
              isEnabled: !_isEditingPassword,
              isLoading: _isLoading,
              nameController: _nameController,
              phoneController: _phoneController,
              emailController: _emailController,
              addressController: _addressController,
              onEdit: () => _startEditingProfile(user),
              onCancel: () => _handleCancelProfile(user),
              onSave: _saveProfile,
            ),
            const SizedBox(height: 15),

            _PasswordCard(
              user: user,
              isEditing: _isEditingPassword,
              isEnabled: !_isEditingProfile,
              isLoading: _isLoading,
              oldPasswordController: _oldPasswordController,
              newPasswordController: _newPasswordController,
              confirmPasswordController: _confirmPasswordController,
              showOldPassword: _showOldPassword,
              showNewPassword: _showNewPassword,
              onToggleOldPassword: (val) =>
                  setState(() => _showOldPassword = val),
              onToggleNewPassword: (val) =>
                  setState(() => _showNewPassword = val),
              onEdit: () => _startEditingPassword(),
              onCancel: _handleCancelPassword,
              onSave: _savePassword,
            ),
            const SizedBox(height: 25),

            _LogoutButton(onLogout: _handleLogout),
          ],
        ),
      ),
    );
  }

  void _startEditingProfile(dynamic user) {
    if (_isEditingPassword) return;
    setState(() {
      _isEditingProfile = true;
      _nameController.text = user?.fullName ?? "";
      _phoneController.text = user?.phone ?? "";
      _emailController.text = user?.email ?? "";
      _addressController.text = user?.address ?? "";
    });
  }

  void _startEditingPassword() {
    if (_isEditingProfile) return;
    setState(() {
      _isEditingPassword = true;
      _oldPasswordController.clear();
      _newPasswordController.clear();
      _confirmPasswordController.clear();
    });
  }

  Future<bool> _showDiscardDialog() async {
    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Hủy thay đổi?"),
        content: const Text(
          "Bạn có thay đổi chưa lưu. Bạn có chắc chắn muốn hủy không?",
        ),
        actions: [
          OutlinedButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text("Không"),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text("Có, hủy", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
    return result ?? false;
  }

  void _handleCancelProfile(dynamic user) async {
    final hasChanges =
        _nameController.text != (user?.fullName ?? "") ||
        _phoneController.text != (user?.phone ?? "") ||
        _emailController.text != (user?.email ?? "") ||
        _addressController.text != (user?.address ?? "");

    if (hasChanges) {
      final confirm = await _showDiscardDialog();
      if (!confirm) return;
    }

    setState(() => _isEditingProfile = false);
  }

  void _handleCancelPassword() async {
    final hasInput =
        _oldPasswordController.text.isNotEmpty ||
        _newPasswordController.text.isNotEmpty ||
        _confirmPasswordController.text.isNotEmpty;

    if (hasInput) {
      final confirm = await _showDiscardDialog();
      if (!confirm) return;
    }

    setState(() {
      _isEditingPassword = false;
      _oldPasswordController.clear();
      _newPasswordController.clear();
      _confirmPasswordController.clear();
    });
  }

  Future<void> _saveProfile() async {
    final scaffoldMessenger = ScaffoldMessenger.of(context);
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final user = authProvider.user;

    if (_nameController.text.trim().isEmpty) {
      _showMessage("Vui lòng nhập họ tên");
      return;
    }
    if (_phoneController.text.trim().isEmpty) {
      _showMessage("Vui lòng nhập số điện thoại");
      return;
    }
    if (_phoneController.text.trim().length != 10) {
      _showMessage("Số điện thoại phải có 10 số");
      return;
    }
    if (_emailController.text.trim().isEmpty) {
      _showMessage("Vui lòng nhập email");
      return;
    }
    if (!_emailController.text.trim().contains('@')) {
      _showMessage("Email không hợp lệ");
      return;
    }
    if (_addressController.text.trim().isEmpty) {
      _showMessage("Vui lòng nhập địa chỉ");
      return;
    }

    setState(() => _isLoading = true);

    final apiService = ApiService();
    final success = await apiService.updateCustomerProfile(
      customerId: user?.customerId ?? 0,
      fullName: _nameController.text.trim(),
      phone: _phoneController.text.trim(),
      email: _emailController.text.trim(),
      address: _addressController.text.trim(),
    );

    if (!mounted) return;
    setState(() => _isLoading = false);

    if (success) {
      authProvider.updateUserInfo(
        fullName: _nameController.text.trim(),
        phone: _phoneController.text.trim(),
        email: _emailController.text.trim(),
        address: _addressController.text.trim(),
      );
      setState(() => _isEditingProfile = false);
      scaffoldMessenger.showSnackBar(
        const SnackBar(
          content: Text("Cập nhật thành công!"),
          backgroundColor: Colors.green,
        ),
      );
    } else {
      scaffoldMessenger.showSnackBar(
        const SnackBar(
          content: Text("Cập nhật thất bại!"),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _savePassword() async {
    final scaffoldMessenger = ScaffoldMessenger.of(context);
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final user = authProvider.user;

    if (_oldPasswordController.text.isEmpty) {
      _showMessage("Vui lòng nhập mật khẩu cũ");
      return;
    }
    if (_newPasswordController.text.length < 6) {
      _showMessage("Mật khẩu mới phải từ 6 ký tự");
      return;
    }
    if (_newPasswordController.text != _confirmPasswordController.text) {
      _showMessage("Mật khẩu xác nhận không khớp");
      return;
    }

    setState(() => _isLoading = true);

    final apiService = ApiService();
    final success = await apiService.changeCustomerPassword(
      accountId: user?.accountId ?? 0,
      oldPassword: _oldPasswordController.text,
      newPassword: _newPasswordController.text,
    );

    if (!mounted) return;
    setState(() => _isLoading = false);

    if (success) {
      setState(() => _isEditingPassword = false);
      scaffoldMessenger.showSnackBar(
        const SnackBar(
          content: Text("Đổi mật khẩu thành công!"),
          backgroundColor: Colors.green,
        ),
      );
    } else {
      scaffoldMessenger.showSnackBar(
        const SnackBar(
          content: Text("Đổi mật khẩu thất bại!"),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _pickAndUploadAvatar(int customerId) async {
    // hiện thông báo trên snackbar
    final scaffoldMessenger = ScaffoldMessenger.of(context);
    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    try {
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 512,
        maxHeight: 512,
        imageQuality: 85,
      );

      if (image == null) return;

      scaffoldMessenger.showSnackBar(
        const SnackBar(
          content: Text("Đang tải ảnh lên..."),
          duration: Duration(seconds: 1),
        ),
      );

      final bytes = await File(image.path).readAsBytes();
      final base64Image = base64Encode(bytes);

      final apiService = ApiService();
      final success = await apiService.updateCustomerAvatar(
        customerId: customerId,
        avatarBase64: base64Image,
      );

      if (!mounted) return;

      if (success) {
        authProvider.updateUserAvatar(base64Image);
        scaffoldMessenger.showSnackBar(
          const SnackBar(
            content: Text("Cập nhật ảnh thành công!"),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        scaffoldMessenger.showSnackBar(
          const SnackBar(
            content: Text("Cập nhật ảnh thất bại!"),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      scaffoldMessenger.showSnackBar(
        SnackBar(content: Text("Lỗi: $e"), backgroundColor: Colors.red),
      );
    }
  }

  void _showMessage(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _handleLogout() async {
    if (!mounted) return;

    final shouldLogout = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Xác nhận đăng xuất"),
        content: const Text("Bạn có chắc chắn muốn đăng xuất không?"),
        actions: [
          OutlinedButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text("Hủy"),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color.fromARGB(255, 0, 157, 255),
            ),
            child: const Text(
              "Đăng xuất",
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );

    if (shouldLogout != true || !mounted) return;

    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (route) => false,
    );

    context.read<AuthProvider>().logout();
  }
}

// widget phần avatar
class _AvatarSection extends StatelessWidget {
  final dynamic user;
  final bool isEditing;
  final VoidCallback onAvatarTap;

  // constructor
  const _AvatarSection({
    required this.user,
    required this.isEditing,
    required this.onAvatarTap,
  });

  @override
  Widget build(BuildContext context) {
    Widget avatarWidget;

    if (user?.avatarBase64 != null && user.avatarBase64.isNotEmpty) {
      try {
        avatarWidget = Container(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: Colors.blue, width: 1),
          ),
          child: CircleAvatar(
            radius: 50,
            backgroundImage: MemoryImage(base64Decode(user.avatarBase64)),
            backgroundColor: Colors.grey[300],
          ),
        );
      } catch (e) {
        avatarWidget = _defaultAvatar();
      }
    } else {
      avatarWidget = _defaultAvatar();
    }

    return Column(
      children: [
        GestureDetector(
          onTap: onAvatarTap,
          child: Stack(
            children: [
              avatarWidget,
              if (isEditing)
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: Colors.blue,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 2),
                    ),
                    child: const Icon(
                      Icons.edit,
                      size: 16,
                      color: Colors.white,
                    ),
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 15),
        Text(
          user?.fullName ?? "Khách hàng",
          style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
        ),
        Text(
          "@${user?.username ?? ''}",
          style: TextStyle(fontSize: 14, color: Colors.grey[600]),
        ),
      ],
    );
  }

  Widget _defaultAvatar() {
    return Container(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: Colors.blue, width: 1),
      ),
      child: const CircleAvatar(
        radius: 50,
        backgroundColor: Colors.blue,
        child: Icon(Icons.person, size: 50, color: Colors.white),
      ),
    );
  }
}

// widget thẻ thông tin cá nhân
class _ProfileCard extends StatelessWidget {
  final dynamic user;
  final bool isEditing;
  final bool isEnabled;
  final bool isLoading;
  final TextEditingController nameController;
  final TextEditingController phoneController;
  final TextEditingController emailController;
  final TextEditingController addressController;
  final VoidCallback onEdit;
  final VoidCallback onCancel;
  final VoidCallback onSave;

  // constructor
  const _ProfileCard({
    required this.user,
    required this.isEditing,
    this.isEnabled = true,
    required this.isLoading,
    required this.nameController,
    required this.phoneController,
    required this.emailController,
    required this.addressController,
    required this.onEdit,
    required this.onCancel,
    required this.onSave,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.blue.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(),
          const SizedBox(height: 8),
          if (isEditing) _buildEditMode() else _buildViewMode(),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          "Thông tin cá nhân",
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: Colors.grey.shade700,
          ),
        ),
        if (!isEditing)
          IconButton(
            icon: Icon(
              Icons.edit,
              size: 20,
              color: isEnabled ? Colors.blue : Colors.grey,
            ),
            onPressed: isEnabled ? onEdit : null,
          ),
      ],
    );
  }

  Widget _buildViewMode() {
    return Column(
      children: [
        _InfoRow(
          icon: Icons.person,
          label: "Họ tên",
          value: user?.fullName ?? "Chưa cập nhật",
        ),
        _InfoRow(
          icon: Icons.phone,
          label: "Số điện thoại",
          value: user?.phone ?? "Chưa cập nhật",
        ),
        _InfoRow(
          icon: Icons.email,
          label: "Email",
          value: user?.email ?? "Chưa cập nhật",
        ),
        _InfoRow(
          icon: Icons.location_on,
          label: "Địa chỉ",
          value: user?.address ?? "Chưa cập nhật",
        ),
      ],
    );
  }

  Widget _buildEditMode() {
    return Column(
      children: [
        _EditField(
          icon: Icons.person,
          label: "Họ tên",
          controller: nameController,
        ),
        _EditField(
          icon: Icons.phone,
          label: "Số điện thoại",
          controller: phoneController,
          keyboardType: TextInputType.phone,
        ),
        _EditField(
          icon: Icons.email,
          label: "Email",
          controller: emailController,
          keyboardType: TextInputType.emailAddress,
        ),
        _EditField(
          icon: Icons.location_on,
          label: "Địa chỉ",
          controller: addressController,
        ),

        const SizedBox(height: 12),

        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            OutlinedButton(
              onPressed: isLoading ? null : onCancel,
              child: const Text("Hủy"),
            ),
            const SizedBox(width: 8),
            ElevatedButton(
              onPressed: isLoading ? null : onSave,
              style: ElevatedButton.styleFrom(backgroundColor: Colors.blue),
              child: isLoading
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2, // độ dày đường viền
                        color: Colors.white,
                      ),
                    )
                  : const Text("Lưu", style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ],
    );
  }
}

// widget thẻ mật khẩu
class _PasswordCard extends StatelessWidget {
  final dynamic user;
  final bool isEditing;
  final bool isEnabled;
  final bool isLoading;
  final TextEditingController oldPasswordController;
  final TextEditingController newPasswordController;
  final TextEditingController confirmPasswordController;
  final bool showOldPassword;
  final bool showNewPassword;
  final Function(bool) onToggleOldPassword;
  final Function(bool) onToggleNewPassword;
  final VoidCallback onEdit;
  final VoidCallback onCancel;
  final VoidCallback onSave;

  const _PasswordCard({
    required this.user,
    required this.isEditing,
    this.isEnabled = true,
    required this.isLoading,
    required this.oldPasswordController,
    required this.newPasswordController,
    required this.confirmPasswordController,
    required this.showOldPassword,
    required this.showNewPassword,
    required this.onToggleOldPassword,
    required this.onToggleNewPassword,
    required this.onEdit,
    required this.onCancel,
    required this.onSave,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.blue.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(),
          const SizedBox(height: 8),
          _InfoRow(
            icon: Icons.account_circle,
            label: "Tài khoản",
            value: user?.username ?? "",
          ),
          if (isEditing) _buildEditMode() else _buildViewMode(),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          "Thông tin tài khoản",
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: Colors.grey[700],
          ),
        ),
        if (!isEditing)
          IconButton(
            icon: Icon(
              Icons.edit,
              size: 20,
              color: isEnabled ? Colors.blue : Colors.grey,
            ),
            onPressed: isEnabled ? onEdit : null,
          ),
      ],
    );
  }

  Widget _buildViewMode() {
    return const _InfoRow(
      icon: Icons.lock,
      label: "Mật khẩu",
      value: "•••••••••••",
    );
  }

  Widget _buildEditMode() {
    return Column(
      children: [
        const SizedBox(height: 12),
        _PasswordField(
          label: "Mật khẩu cũ",
          controller: oldPasswordController,
          showPassword: showOldPassword,
          onToggle: () => onToggleOldPassword(!showOldPassword),
        ),
        _PasswordField(
          label: "Mật khẩu mới",
          controller: newPasswordController,
          showPassword: showNewPassword,
          onToggle: () => onToggleNewPassword(!showNewPassword),
        ),
        _PasswordField(
          label: "Xác nhận mật khẩu",
          controller: confirmPasswordController,
          showPassword: showNewPassword,
        ),

        const SizedBox(height: 12),

        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            OutlinedButton(
              onPressed: isLoading ? null : onCancel,
              child: const Text("Hủy"),
            ),
            const SizedBox(width: 8),
            ElevatedButton(
              onPressed: isLoading ? null : onSave,
              style: ElevatedButton.styleFrom(backgroundColor: Colors.blue),
              child: isLoading
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Text(
                      "Đổi mật khẩu",
                      style: TextStyle(color: Colors.white),
                    ),
            ),
          ],
        ),
      ],
    );
  }
}

// các widget hỗ trợ
class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, size: 20, color: Colors.blue),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                ),
                const SizedBox(height: 2),
                Text(value, style: const TextStyle(fontSize: 15)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _EditField extends StatelessWidget {
  final IconData icon;
  final String label;
  final TextEditingController controller;
  final TextInputType? keyboardType;

  const _EditField({
    required this.icon,
    required this.label,
    required this.controller,
    this.keyboardType,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Icon(icon, size: 20, color: Colors.blue),
          const SizedBox(width: 12),
          Expanded(
            child: TextField(
              controller: controller,
              keyboardType: keyboardType,
              decoration: InputDecoration(
                labelText: label,
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(
                  vertical: 8,
                  horizontal: 0,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PasswordField extends StatelessWidget {
  final String label;
  final TextEditingController controller;
  final bool showPassword;
  final VoidCallback? onToggle;

  const _PasswordField({
    required this.label,
    required this.controller,
    required this.showPassword,
    this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          const Icon(Icons.lock, size: 20, color: Colors.blue),
          const SizedBox(width: 12),
          Expanded(
            child: TextField(
              controller: controller,
              obscureText: !showPassword,
              decoration: InputDecoration(
                labelText: label,
                isDense: true, // thu gọn textfield
                contentPadding: const EdgeInsets.symmetric(
                  vertical: 8,
                  horizontal: 0,
                ),
                suffixIcon: onToggle != null
                    ? IconButton(
                        icon: Icon(
                          showPassword
                              ? Icons.visibility
                              : Icons.visibility_off,
                          size: 20,
                        ),
                        onPressed: onToggle,
                      )
                    : null,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _LogoutButton extends StatelessWidget {
  final VoidCallback onLogout;

  const _LogoutButton({required this.onLogout});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: onLogout,
        icon: const Icon(Icons.logout),
        label: const Text("Đăng Xuất"),
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color.fromARGB(255, 0, 157, 255),
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      ),
    );
  }
}
