import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/warehouse_model.dart';
import '../../models/order_draft_model.dart';
import '../../providers/auth_provider.dart';
import '../../services/api_service.dart';

class CreateOrderScreen extends StatefulWidget {
  const CreateOrderScreen({super.key});

  @override
  State<CreateOrderScreen> createState() => _CreateOrderScreenState();
}

class _CreateOrderScreenState extends State<CreateOrderScreen> {
  final _formKey = GlobalKey<FormState>();
  final ApiService _apiService = ApiService();

  // trạng thái loading
  bool _isLoadingWarehouses = true;
  bool _isSubmitting = false;

  // danh sách kho hàng
  List<Warehouse> _allWarehouses = [];

  // lựa chọn khu vực
  ZoneId? _selectedSendZone;
  ZoneId? _selectedReceiveZone;

  // lựa chọn kho
  Warehouse? _selectedSendWarehouse;
  Warehouse? _selectedReceiveWarehouse;

  // danh sách kho theo khu vực
  List<Warehouse> _sendWarehouses = [];
  List<Warehouse> _receiveWarehouses = [];

  // các trường form khác
  bool _needPickup = false;
  final _pickupAddressController = TextEditingController();
  final _packageDescController = TextEditingController();
  DateTime _selectedDate = DateTime.now();

  // phí vận chuyển
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

  // tải kho từ api
  Future<void> _loadWarehouses() async {
    setState(() => _isLoadingWarehouses = true);

    try {
      final warehouseData = await _apiService.getWarehouses();
      _allWarehouses = warehouseData.map((w) => Warehouse.fromJson(w)).toList();
    } catch (e) {
      debugPrint('Lỗi khi tải kho: $e');
    }

    setState(() => _isLoadingWarehouses = false);
  }

  // xử lý thay đổi khu vực gửi
  void _onSendZoneChanged(ZoneId? zone) {
    setState(() {
      _selectedSendZone = zone;
      _selectedSendWarehouse = null;
      _updateWarehouseLists();
      _calculateFees();
    });
  }

  // xử lý thay đổi khu vực nhận
  void _onReceiveZoneChanged(ZoneId? zone) {
    setState(() {
      _selectedReceiveZone = zone;
      _selectedReceiveWarehouse = null;
      _updateWarehouseLists();
      _calculateFees();
    });
  }

  // xử lý chọn kho gửi
  void _onSendWarehouseChanged(Warehouse? warehouse) {
    setState(() {
      _selectedSendWarehouse = warehouse;
      _updateWarehouseLists();
      _calculateFees();
    });
  }

  // xử lý chọn kho nhận
  void _onReceiveWarehouseChanged(Warehouse? warehouse) {
    setState(() {
      _selectedReceiveWarehouse = warehouse;
      _calculateFees();
    });
  }

  // cập nhật danh sách kho theo khu vực
  void _updateWarehouseLists() {
    if (_selectedSendZone != null) {
      _sendWarehouses = _allWarehouses
          .where((w) => w.zoneId == _selectedSendZone)
          .toList();
    } else {
      _sendWarehouses = [];
    }

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

  // xử lý checkbox lấy hàng tận nơi
  void _onNeedPickupChanged(bool? value) {
    setState(() {
      _needPickup = value ?? false;
      if (!_needPickup) {
        _pickupAddressController.clear();
      }
      _calculateFees();
    });
  }

  // tính phí vận chuyển
  void _calculateFees() {
    if (_selectedSendZone != null && _selectedReceiveZone != null) {
      final distance = (_selectedSendZone!.index - _selectedReceiveZone!.index)
          .abs();
      _routeFee = 100000 + (distance * 50000);
    } else {
      _routeFee = 0;
    }

    _pickupFee = _needPickup ? 100000 : 0;
    _totalFee = _routeFee + _pickupFee;
  }

  // chọn ngày gửi hàng
  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 30)),
    );

    if (picked != null) {
      setState(() => _selectedDate = picked);
    }
  }

  // reset form
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

  // gửi đơn hàng
  Future<void> _submitOrder() async {
    if (!_formKey.currentState!.validate()) return;

    if (_selectedSendWarehouse == null || _selectedReceiveWarehouse == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Vui lòng chọn đầy đủ kho gửi và kho nhận'),
          backgroundColor: Color.fromARGB(255, 255, 0, 0),
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

    _calculateFees();

    // hiện dialog xác nhận
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

  // dialog xác nhận đơn hàng
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
              // đường ngang phân cách nội dung
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

              const SizedBox(height: 12),

              // thông tin thanh toán cọc
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.orange.shade50,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.orange.shade200),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.info_outline,
                          color: Colors.orange.shade700,
                          size: 16,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'Thanh toán',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                            color: Colors.orange.shade800,
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 6),

                    Row(
                      children: [
                        const Expanded(
                          child: Text(
                            'Cọc trước (35%):',
                            style: TextStyle(fontSize: 12),
                          ),
                        ),
                        Text(
                          _formatCurrency(_totalFee * 0.35),
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                            color: Colors.orange,
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 5),

                    Row(
                      children: [
                        const Expanded(
                          child: Text(
                            'Khi nhận (65%):',
                            style: TextStyle(fontSize: 12),
                          ),
                        ),
                        Text(
                          _formatCurrency(_totalFee * 0.65),
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                            color: Colors.green,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
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

  // row trong dialog xác nhận
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

  // format tiền tệ
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
        backgroundColor: const Color.fromARGB(255, 242, 249, 255),
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
                  padding: const EdgeInsets.all(15),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // phần a: thông tin gửi hàng
                      _buildSectionHeader('Thông tin gửi hàng', Icons.send),
                      const SizedBox(height: 12),

                      _buildLabel('Khu vực gửi'),
                      _buildZoneDropdown(
                        value: _selectedSendZone,
                        onChanged: _onSendZoneChanged,
                        hint: 'Chọn khu vực gửi hàng',
                      ),
                      const SizedBox(height: 12),

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

                      // phần b: thông tin nhận hàng
                      _buildSectionHeader(
                        'Thông tin nhận hàng',
                        Icons.inventory_2,
                      ),
                      const SizedBox(height: 12),

                      _buildLabel('Khu vực nhận'),
                      _buildZoneDropdown(
                        value: _selectedReceiveZone,
                        onChanged: _selectedSendWarehouse != null
                            ? _onReceiveZoneChanged
                            : null,
                        hint: _selectedSendWarehouse == null
                            ? 'Vui lòng chọn kho gửi trước'
                            : 'Chọn khu vực nhận hàng',
                        enabled: _selectedSendWarehouse != null,
                      ),
                      const SizedBox(height: 12),

                      _buildLabel('Kho nhận hàng'),
                      _buildWarehouseDropdown(
                        value: _selectedReceiveWarehouse,
                        warehouses: _receiveWarehouses,
                        onChanged: _onReceiveWarehouseChanged,
                        hint: _selectedReceiveZone == null
                            ? 'Vui lòng chọn khu vực nhận trước'
                            : 'Chọn kho nhận hàng',
                        enabled: _selectedReceiveZone != null,
                      ),
                      const SizedBox(height: 20),

                      // phần c: dịch vụ bổ sung
                      _buildSectionHeader(
                        'Dịch vụ bổ sung',
                        Icons.local_shipping,
                      ),
                      const SizedBox(height: 12),

                      // checkbox lấy hàng tận nơi
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
                                // badge + 100,000 đ
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
                          // checkbox bên trái
                          controlAffinity: ListTileControlAffinity.leading,
                        ),
                      ),

                      // input địa chỉ lấy hàng
                      if (_needPickup) ...[
                        const SizedBox(height: 12),
                        _buildLabel('Địa chỉ lấy hàng'),
                        TextFormField(
                          controller: _pickupAddressController,
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

                      // mô tả hàng hóa
                      _buildLabel('Mô tả hàng hóa'),
                      TextFormField(
                        controller: _packageDescController,
                        decoration: InputDecoration(
                          hintText: 'Mô tả hàng hóa (không bắt buộc)',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          prefixIcon: const Icon(Icons.description),
                        ),
                      ),
                      const SizedBox(height: 12),

                      // ngày gửi hàng
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
                          // format ngày gửi hàng dd/mm/yyyy
                          child: Text(
                            '${_selectedDate.day.toString().padLeft(2, '0')}/'
                            '${_selectedDate.month.toString().padLeft(2, '0')}/'
                            '${_selectedDate.year}',
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),

                      // phần d: tổng kết phí
                      Container(
                        padding: const EdgeInsets.all(15),
                        decoration: BoxDecoration(
                          // nền gradient chuyển màu
                          gradient: LinearGradient(
                            colors: [Colors.blue.shade50, Colors.blue.shade100],
                            // bắt đầu từ góc trên bên trái
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
                            const Divider(height: 20), // đường kẻ
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

                      // nút tải lại
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

                      // nút xác nhận
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

  // header cho mỗi section
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

  // label cho input
  Widget _buildLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Text(
        text,
        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
      ),
    );
  }

  // dropdown chọn khu vực
  Widget _buildZoneDropdown({
    required ZoneId? value,
    required void Function(ZoneId?)? onChanged,
    required String hint,
    bool enabled = true,
  }) {
    return DropdownButtonFormField<ZoneId>(
      initialValue: value,
      decoration: InputDecoration(
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 12,
        ),
        enabled: enabled,
      ),
      hint: Text(hint),
      items: ZoneId.values.map((zone) {
        return DropdownMenuItem<ZoneId>(
          value: zone,
          child: Text(zone.displayName),
        );
      }).toList(),
      onChanged: enabled ? onChanged : null,
    );
  }

  // dropdown chọn kho
  Widget _buildWarehouseDropdown({
    required Warehouse? value,
    required List<Warehouse> warehouses,
    required void Function(Warehouse?) onChanged,
    required String hint,
    required bool enabled,
  }) {
    return DropdownButtonFormField<Warehouse>(
      initialValue: value,
      decoration: InputDecoration(
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
        contentPadding: const EdgeInsets.symmetric(
          vertical: 12,
          horizontal: 16,
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

  // row hiển thị phí
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
