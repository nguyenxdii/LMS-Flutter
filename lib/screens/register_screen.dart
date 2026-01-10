import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _picker = ImagePicker();

  // Role selection
  String?
  _selectedRole; // null initially, 'customer' or 'driver' after selection

  // Common fields
  final _fullNameController = TextEditingController();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _phoneController = TextEditingController();

  // Customer fields
  final _emailController = TextEditingController();
  final _addressController = TextEditingController();

  // Driver fields
  final _cccdController = TextEditingController();
  String? _selectedLicenseType; // Dropdown selection
  final List<String> _licenseTypes = ['B2', 'C', 'D', 'E', 'FC', 'FD', 'FE'];

  // Avatar
  File? _avatarImage;
  bool _isLoading = false;

  @override
  void dispose() {
    _fullNameController.dispose();
    _usernameController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _addressController.dispose();
    _cccdController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          title: const Text(
            'Đăng Ký Tài Khoản',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          centerTitle: true,
          backgroundColor: Colors.white,
          foregroundColor: Colors.blue,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new, size: 20),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Role Selection
                const Text(
                  'Chọn loại tài khoản',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.blue,
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: _buildRoleCard(
                        role: 'customer',
                        icon: Icons.person_rounded,
                        label: 'Khách Hàng',
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _buildRoleCard(
                        role: 'driver',
                        icon: Icons.local_shipping_rounded,
                        label: 'Tài Xế',
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 32),

                // Show form only after role selection
                if (_selectedRole != null) ...[
                  // Avatar Section
                  Center(
                    child: Column(
                      children: [
                        CircleAvatar(
                          radius: 50,
                          backgroundColor: Colors.blue.shade50,
                          backgroundImage: _avatarImage != null
                              ? FileImage(_avatarImage!)
                              : null,
                          child: _avatarImage == null
                              ? Icon(
                                  Icons.person,
                                  size: 50,
                                  color: Colors.blue.shade200,
                                )
                              : null,
                        ),
                        const SizedBox(height: 12),
                        TextButton(
                          onPressed: _pickImage,
                          child: const Text(
                            "Nhấn vào đây để tải ảnh đại diện",
                            style: TextStyle(
                              color: Colors.blue,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 32),

                  // Common Fields
                  _buildTextField(
                    controller: _fullNameController,
                    label: 'Họ và Tên',
                    icon: Icons.person_outline,
                    validator: (value) =>
                        value?.isEmpty ?? true ? 'Vui lòng nhập họ tên' : null,
                  ),
                  const SizedBox(height: 16),

                  _buildTextField(
                    controller: _usernameController,
                    label: 'Tên Tài Khoản',
                    icon: Icons.account_circle_outlined,
                    validator: (value) => value?.isEmpty ?? true
                        ? 'Vui lòng nhập tên tài khoản'
                        : null,
                  ),
                  const SizedBox(height: 16),

                  _buildTextField(
                    controller: _passwordController,
                    label: 'Mật Khẩu',
                    icon: Icons.lock_outline,
                    obscureText: true,
                    validator: (value) {
                      if (value?.isEmpty ?? true) {
                        return 'Vui lòng nhập mật khẩu';
                      }
                      if (value!.length < 6)
                        return 'Mật khẩu phải có ít nhất 6 ký tự';
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),

                  _buildTextField(
                    controller: _confirmPasswordController,
                    label: 'Nhập Lại Mật Khẩu',
                    icon: Icons.lock_outline,
                    obscureText: true,
                    validator: (value) {
                      if (value?.isEmpty ?? true) {
                        return 'Vui lòng nhập lại mật khẩu';
                      }
                      if (value != _passwordController.text) {
                        return 'Mật khẩu không khớp';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),

                  // Customer-specific fields
                  if (_selectedRole == 'customer') ...[
                    _buildTextField(
                      controller: _addressController,
                      label: 'Địa Chỉ',
                      icon: Icons.location_on_outlined,
                      maxLines: 3,
                      validator: (value) => value?.isEmpty ?? true
                          ? 'Vui lòng nhập địa chỉ'
                          : null,
                    ),
                    const SizedBox(height: 16),
                    _buildTextField(
                      controller: _phoneController,
                      label: 'Số Điện Thoại',
                      icon: Icons.phone_outlined,
                      keyboardType: TextInputType.phone,
                      validator: (value) => value?.isEmpty ?? true
                          ? 'Vui lòng nhập số điện thoại'
                          : null,
                    ),
                    const SizedBox(height: 16),
                    _buildTextField(
                      controller: _emailController,
                      label: 'Email',
                      icon: Icons.email_outlined,
                      keyboardType: TextInputType.emailAddress,
                      validator: (value) {
                        if (value?.isEmpty ?? true) {
                          return 'Vui lòng nhập email';
                        }
                        if (!value!.contains('@')) return 'Email không hợp lệ';
                        return null;
                      },
                    ),
                  ],

                  // Driver-specific fields
                  if (_selectedRole == 'driver') ...[
                    _buildTextField(
                      controller: _phoneController,
                      label: 'Số Điện Thoại',
                      icon: Icons.phone_outlined,
                      keyboardType: TextInputType.phone,
                      validator: (value) => value?.isEmpty ?? true
                          ? 'Vui lòng nhập số điện thoại'
                          : null,
                    ),
                    const SizedBox(height: 16),
                    // GPLX Dropdown
                    DropdownButtonFormField<String>(
                      value: _selectedLicenseType,
                      decoration: InputDecoration(
                        labelText: 'Giấy Phép Lái Xe',
                        prefixIcon: const Icon(
                          Icons.badge_outlined,
                          color: Colors.blue,
                        ),
                        filled: true,
                        fillColor: Colors.white,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(
                            color: Colors.blue.shade100,
                            width: 1,
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(
                            color: Colors.blue,
                            width: 2,
                          ),
                        ),
                      ),
                      items: _licenseTypes.map((String type) {
                        return DropdownMenuItem<String>(
                          value: type,
                          child: Text(type),
                        );
                      }).toList(),
                      onChanged: (String? newValue) {
                        setState(() {
                          _selectedLicenseType = newValue;
                        });
                      },
                      validator: (value) =>
                          value == null ? 'Vui lòng chọn loại bằng lái' : null,
                    ),
                    const SizedBox(height: 16),
                    _buildTextField(
                      controller: _cccdController,
                      label: 'CCCD',
                      icon: Icons.credit_card,
                      keyboardType: TextInputType.number,
                      validator: (value) =>
                          value?.isEmpty ?? true ? 'Vui lòng nhập CCCD' : null,
                    ),
                  ],

                  const SizedBox(height: 40),

                  // Register Button
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _register,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        foregroundColor: Colors.white,
                        elevation: 2,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      child: _isLoading
                          ? const SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Text(
                              'ĐĂNG KÝ',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                    ),
                  ),
                  const SizedBox(height: 24),
                ],

                // Login Link (always visible)
                Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text(
                        'Đã có tài khoản? ',
                        style: TextStyle(color: Colors.grey),
                      ),
                      TextButton(
                        onPressed: () => Navigator.of(context).pop(),
                        child: const Text(
                          'Đăng nhập ngay',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.blue,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildRoleCard({
    required String role,
    required IconData icon,
    required String label,
  }) {
    final isSelected = _selectedRole == role;
    return GestureDetector(
      onTap: () => setState(() => _selectedRole = role),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? Colors.blue : Colors.grey.shade300,
            width: 2,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: Colors.blue.withOpacity(0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ]
              : [],
        ),
        child: Column(
          children: [
            Icon(icon, size: 40, color: isSelected ? Colors.blue : Colors.grey),
            const SizedBox(height: 8),
            Text(
              label,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: isSelected ? Colors.blue : Colors.grey.shade800,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType? keyboardType,
    bool obscureText = false,
    int maxLines = 1,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      obscureText: obscureText,
      maxLines: maxLines,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: Colors.blue),
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.blue.shade100, width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.blue, width: 2),
        ),
      ),
      validator: validator,
    );
  }

  Future<void> _pickImage() async {
    final XFile? image = await _picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 512,
      maxHeight: 512,
      imageQuality: 85,
    );

    if (image != null) {
      setState(() {
        _avatarImage = File(image.path);
      });
    }
  }

  Future<void> _register() async {
    if (_formKey.currentState?.validate() != true) {
      return;
    }

    setState(() => _isLoading = true);

    // TODO: Implement registration logic
    await Future.delayed(const Duration(seconds: 2));

    if (!mounted) return;
    setState(() => _isLoading = false);

    // Show success message
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Đăng ký thành công! (Demo)'),
        backgroundColor: Colors.green,
      ),
    );

    // Navigate back to login
    await Future.delayed(const Duration(seconds: 1));
    if (mounted) {
      Navigator.of(context).pop();
    }
  }
}
