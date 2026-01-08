import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/warehouse_model.dart';
import '../models/order_draft_model.dart';
import '../providers/auth_provider.dart';
import '../services/api_service.dart';

class CreateOrderScreen extends StatefulWidget {
  const CreateOrderScreen({super.key});

  @override
  State<CreateOrderScreen> createState() => _CreateOrderScreenState();
}

class _CreateOrderScreenState extends State<CreateOrderScreen> {
  final _formKey = GlobalKey<FormState>();
  final ApiService _apiService = ApiService();

  // Loading states
  bool _isLoadingWarehouses = true;
  bool _isSubmitting = false;

  // All warehouses from API
  List<Warehouse> _allWarehouses = [];

  // Zone selections
  ZoneId? _selectedSendZone;
  ZoneId? _selectedReceiveZone;

  // Warehouse selections
  Warehouse? _selectedSendWarehouse;
  Warehouse? _selectedReceiveWarehouse;

  // Filtered warehouses based on zone selection
  List<Warehouse> _sendWarehouses = [];
  List<Warehouse> _receiveWarehouses = [];

  // Other form fields
  bool _needPickup = false;
  final _pickupAddressController = TextEditingController();
  final _packageDescController = TextEditingController();
  DateTime _selectedDate = DateTime.now();

  // Calculated fees
  double _routeFee = 0;
  double _pickupFee = 0;
  double _totalFee = 0;

  @override
  void initState() {
    super.initState();
    _loadWarehouses();
  }

  @override
  void dispose() {
    _pickupAddressController.dispose();
    _packageDescController.dispose();
    super.dispose();
  }

  Future<void> _loadWarehouses() async {
    setState(() => _isLoadingWarehouses = true);

    try {
      final warehouseData = await _apiService.getWarehouses();
      _allWarehouses = warehouseData.map((w) => Warehouse.fromJson(w)).toList();
    } catch (e) {
      print('Error loading warehouses: $e');
    }

    setState(() => _isLoadingWarehouses = false);
  }

  void _onSendZoneChanged(ZoneId? zone) {
    setState(() {
      _selectedSendZone = zone;
      _selectedSendWarehouse = null;
      _updateWarehouseLists();
      _calculateFees();
    });
  }

  void _onReceiveZoneChanged(ZoneId? zone) {
    setState(() {
      _selectedReceiveZone = zone;
      _selectedReceiveWarehouse = null;
      _updateWarehouseLists();
      _calculateFees();
    });
  }

  void _onSendWarehouseChanged(Warehouse? warehouse) {
    setState(() {
      _selectedSendWarehouse = warehouse;
      // Re-filter receive warehouses to exclude this one if same zone
      _updateWarehouseLists();
      _calculateFees();
    });
  }

  void _onReceiveWarehouseChanged(Warehouse? warehouse) {
    setState(() {
      _selectedReceiveWarehouse = warehouse;
      _calculateFees();
    });
  }

  void _updateWarehouseLists() {
    // Update send warehouses
    if (_selectedSendZone != null) {
      _sendWarehouses = _allWarehouses
          .where((w) => w.zoneId == _selectedSendZone)
          .toList();
    } else {
      _sendWarehouses = [];
    }

    // Update receive warehouses - exclude already selected send warehouse if same zone
    if (_selectedReceiveZone != null) {
      _receiveWarehouses = _allWarehouses
          .where((w) => w.zoneId == _selectedReceiveZone)
          .where(
            (w) =>
                _selectedSendWarehouse == null ||
                w.id != _selectedSendWarehouse!.id,
          )
          .toList();
    } else {
      _receiveWarehouses = [];
    }
  }

  void _onNeedPickupChanged(bool? value) {
    setState(() {
      _needPickup = value ?? false;
      if (!_needPickup) {
        _pickupAddressController.clear();
      }
      _calculateFees();
    });
  }

  void _calculateFees() {
    // Route fee based on zone distance
    if (_selectedSendZone != null && _selectedReceiveZone != null) {
      final distance = (_selectedSendZone!.index - _selectedReceiveZone!.index)
          .abs();
      _routeFee = 100000 + (distance * 50000);
    } else {
      _routeFee = 0;
    }

    // Pickup fee
    _pickupFee = _needPickup ? 100000 : 0;

    // Total
    _totalFee = _routeFee + _pickupFee;
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );

    if (picked != null) {
      setState(() => _selectedDate = picked);
    }
  }

  void _resetForm() {
    _formKey.currentState?.reset();
    setState(() {
      _selectedSendZone = null;
      _selectedReceiveZone = null;
      _selectedSendWarehouse = null;
      _selectedReceiveWarehouse = null;
      _sendWarehouses = [];
      _receiveWarehouses = [];
      _needPickup = false;
      _pickupAddressController.clear();
      _packageDescController.clear();
      _selectedDate = DateTime.now();
      _routeFee = 0;
      _pickupFee = 0;
      _totalFee = 0;
    });

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Đã tải lại form')));
  }

  Future<void> _submitOrder() async {
    if (!_formKey.currentState!.validate()) return;

    if (_selectedSendWarehouse == null || _selectedReceiveWarehouse == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Vui lòng chọn đầy đủ kho gửi và kho nhận'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    if (_needPickup && _pickupAddressController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Vui lòng nhập địa chỉ lấy hàng'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final customerId = authProvider.user?.customerId;

    if (customerId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Không tìm thấy thông tin khách hàng'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Calculate fees before showing confirmation
    _calculateFees();

    // Show confirmation dialog
    final confirmed = await _showConfirmationDialog();
    if (confirmed != true) return;

    setState(() => _isSubmitting = true);

    final orderDraft = OrderDraft(
      customerId: customerId,
      originWarehouseId: _selectedSendWarehouse!.id,
      destWarehouseId: _selectedReceiveWarehouse!.id,
      needPickup: _needPickup,
      pickupAddress: _needPickup ? _pickupAddressController.text.trim() : null,
      packageDescription: _packageDescController.text.trim().isEmpty
          ? null
          : _packageDescController.text.trim(),
      desiredTime: _selectedDate,
      routeFee: _routeFee,
      pickupFee: _pickupFee,
      totalFee: _totalFee,
    );

    final result = await _apiService.createOrder(orderDraft.toJson());

    setState(() => _isSubmitting = false);

    if (!mounted) return;

    if (result['success'] == true) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Row(
            children: [
              Icon(Icons.check_circle, color: Colors.green, size: 28),
              SizedBox(width: 10),
              Text('Thành công'),
            ],
          ),
          content: const Text('Đơn hàng của bạn đã được tạo thành công!'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                Navigator.of(context).pop();
              },
              child: const Text('OK'),
            ),
          ],
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result['message'] ?? 'Tạo đơn hàng thất bại'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<bool?> _showConfirmationDialog() {
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.receipt_long, color: Colors.blue, size: 28),
            SizedBox(width: 10),
            Text('Xác nhận đơn hàng'),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildConfirmRow('Kho gửi:', _selectedSendWarehouse?.name ?? ''),
              _buildConfirmRow(
                'Khu vực gửi:',
                _selectedSendZone?.displayName ?? '',
              ),
              const Divider(),
              _buildConfirmRow(
                'Kho nhận:',
                _selectedReceiveWarehouse?.name ?? '',
              ),
              _buildConfirmRow(
                'Khu vực nhận:',
                _selectedReceiveZone?.displayName ?? '',
              ),
              const Divider(),
              if (_needPickup) ...[
                _buildConfirmRow('Lấy hàng tận nơi:', 'Có'),
                _buildConfirmRow(
                  'Địa chỉ:',
                  _pickupAddressController.text.trim(),
                ),
              ] else
                _buildConfirmRow('Lấy hàng tận nơi:', 'Không'),
              if (_packageDescController.text.trim().isNotEmpty)
                _buildConfirmRow('Mô tả:', _packageDescController.text.trim()),
              _buildConfirmRow(
                'Ngày gửi:',
                '${_selectedDate.day.toString().padLeft(2, '0')}/${_selectedDate.month.toString().padLeft(2, '0')}/${_selectedDate.year}',
              ),
              const Divider(height: 24),
              _buildConfirmRow('Phí tuyến:', _formatCurrency(_routeFee)),
              _buildConfirmRow('Phí lấy hàng:', _formatCurrency(_pickupFee)),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'TỔNG CỘNG:',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  Text(
                    _formatCurrency(_totalFee),
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                      color: Colors.blue,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        actions: [
          OutlinedButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
            ),
            child: const Text('Xác nhận thanh toán'),
          ),
        ],
      ),
    );
  }

  Widget _buildConfirmRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(label, style: const TextStyle(color: Colors.grey)),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }

  String _formatCurrency(double amount) {
    final formatted = amount
        .toStringAsFixed(0)
        .replaceAllMapped(RegExp(r'(\d)(?=(\d{3})+(?!\d))'), (m) => '${m[1]},');
    return '$formatted đ';
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Tạo Đơn Hàng'),
          backgroundColor: Colors.blue,
          foregroundColor: Colors.white,
        ),
        body: _isLoadingWarehouses
            ? const Center(child: CircularProgressIndicator())
            : Form(
                key: _formKey,
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // ===========================================
                      // SECTION A: THÔNG TIN GỬI HÀNG
                      // ===========================================
                      _buildSectionHeader('Thông tin gửi hàng', Icons.send),
                      const SizedBox(height: 12),

                      // Khu vực gửi
                      _buildLabel('Khu vực gửi'),
                      _buildZoneDropdown(
                        value: _selectedSendZone,
                        onChanged: _onSendZoneChanged,
                        hint: 'Chọn khu vực gửi hàng',
                      ),
                      const SizedBox(height: 12),

                      // Kho gửi
                      _buildLabel('Kho gửi hàng'),
                      _buildWarehouseDropdown(
                        value: _selectedSendWarehouse,
                        warehouses: _sendWarehouses,
                        onChanged: _onSendWarehouseChanged,
                        hint: _selectedSendZone == null
                            ? 'Vui lòng chọn khu vực trước'
                            : 'Chọn kho gửi hàng',
                        enabled: _selectedSendZone != null,
                      ),
                      const SizedBox(height: 20),

                      // ===========================================
                      // SECTION B: THÔNG TIN NHẬN HÀNG
                      // ===========================================
                      _buildSectionHeader(
                        'Thông tin nhận hàng',
                        Icons.inventory_2,
                      ),
                      const SizedBox(height: 12),

                      // Khu vực nhận
                      _buildLabel('Khu vực nhận'),
                      _buildZoneDropdown(
                        value: _selectedReceiveZone,
                        onChanged: _onReceiveZoneChanged,
                        hint: 'Chọn khu vực nhận hàng',
                      ),
                      const SizedBox(height: 12),

                      // Kho nhận
                      _buildLabel('Kho nhận hàng'),
                      _buildWarehouseDropdown(
                        value: _selectedReceiveWarehouse,
                        warehouses: _receiveWarehouses,
                        onChanged: _onReceiveWarehouseChanged,
                        hint: _selectedReceiveZone == null
                            ? 'Vui lòng chọn khu vực trước'
                            : 'Chọn kho nhận hàng',
                        enabled: _selectedReceiveZone != null,
                      ),
                      const SizedBox(height: 20),

                      // ===========================================
                      // SECTION C: DỊCH VỤ & THÔNG TIN KHÁC
                      // ===========================================
                      _buildSectionHeader(
                        'Dịch vụ bổ sung',
                        Icons.local_shipping,
                      ),
                      const SizedBox(height: 12),

                      // Lấy hàng tận nơi
                      Container(
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey.shade300),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: CheckboxListTile(
                          title: Row(
                            children: [
                              const Text('Lấy hàng tận nơi'),
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.orange.shade100,
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  '+ 100,000 đ',
                                  style: TextStyle(
                                    color: Colors.orange.shade800,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          value: _needPickup,
                          onChanged: _onNeedPickupChanged,
                          controlAffinity: ListTileControlAffinity.leading,
                        ),
                      ),

                      // Địa chỉ lấy hàng (chỉ hiển thị khi tick)
                      if (_needPickup) ...[
                        const SizedBox(height: 12),
                        _buildLabel('Địa chỉ lấy hàng'),
                        TextFormField(
                          controller: _pickupAddressController,
                          maxLines: 2,
                          decoration: InputDecoration(
                            hintText: 'Nhập địa chỉ lấy hàng...',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            prefixIcon: const Icon(Icons.location_on),
                          ),
                          validator: _needPickup
                              ? (value) => (value?.isEmpty ?? true)
                                    ? 'Vui lòng nhập địa chỉ lấy hàng'
                                    : null
                              : null,
                        ),
                      ],
                      const SizedBox(height: 12),

                      // Ghi chú / Mô tả hàng hóa
                      _buildLabel('Mô tả hàng hóa'),
                      TextFormField(
                        controller: _packageDescController,
                        maxLines: 2,
                        decoration: InputDecoration(
                          hintText: 'Mô tả hàng hóa (không bắt buộc)...',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          prefixIcon: const Icon(Icons.description),
                        ),
                      ),
                      const SizedBox(height: 12),

                      // Ngày gửi hàng
                      _buildLabel('Ngày gửi hàng'),
                      InkWell(
                        onTap: _pickDate,
                        child: InputDecorator(
                          decoration: InputDecoration(
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            prefixIcon: const Icon(Icons.calendar_today),
                          ),
                          child: Text(
                            '${_selectedDate.day.toString().padLeft(2, '0')}/${_selectedDate.month.toString().padLeft(2, '0')}/${_selectedDate.year}',
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),

                      // ===========================================
                      // SECTION D: TỔNG KẾT PHÍ
                      // ===========================================
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [Colors.blue.shade50, Colors.blue.shade100],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.blue.shade200),
                        ),
                        child: Column(
                          children: [
                            _buildFeeRow('Phí vận chuyển (Tuyến):', _routeFee),
                            const SizedBox(height: 8),
                            _buildFeeRow('Phí lấy hàng:', _pickupFee),
                            const Divider(height: 20),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text(
                                  'Tổng phí:',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                Text(
                                  _formatCurrency(_totalFee),
                                  style: const TextStyle(
                                    fontSize: 22,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.blue,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),

                      // ===========================================
                      // BUTTONS
                      // ===========================================
                      // Tải lại button
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton.icon(
                          onPressed: _resetForm,
                          icon: const Icon(Icons.refresh),
                          label: const Text('Tải lại'),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),

                      // Xác nhận và thanh toán
                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: ElevatedButton.icon(
                          onPressed: _isSubmitting ? null : _submitOrder,
                          icon: _isSubmitting
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : const Icon(Icons.check_circle),
                          label: const Text(
                            'Xác nhận - Thanh toán',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                    ],
                  ),
                ),
              ),
      ),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(icon, color: Colors.blue),
          const SizedBox(width: 8),
          Text(
            title,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.blue,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Text(
        text,
        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
      ),
    );
  }

  Widget _buildZoneDropdown({
    required ZoneId? value,
    required void Function(ZoneId?) onChanged,
    required String hint,
  }) {
    return DropdownButtonFormField<ZoneId>(
      value: value,
      decoration: InputDecoration(
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 12,
        ),
      ),
      hint: Text(hint),
      items: ZoneId.values.map((zone) {
        return DropdownMenuItem<ZoneId>(
          value: zone,
          child: Text(zone.displayName),
        );
      }).toList(),
      onChanged: onChanged,
    );
  }

  Widget _buildWarehouseDropdown({
    required Warehouse? value,
    required List<Warehouse> warehouses,
    required void Function(Warehouse?) onChanged,
    required String hint,
    required bool enabled,
  }) {
    return DropdownButtonFormField<Warehouse>(
      value: value,
      decoration: InputDecoration(
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 12,
        ),
        enabled: enabled,
      ),
      hint: Text(hint),
      items: warehouses.map((warehouse) {
        return DropdownMenuItem<Warehouse>(
          value: warehouse,
          child: Text(warehouse.name),
        );
      }).toList(),
      onChanged: enabled ? onChanged : null,
    );
  }

  Widget _buildFeeRow(String label, double amount) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(fontSize: 14)),
        Text(
          _formatCurrency(amount),
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
        ),
      ],
    );
  }
}
