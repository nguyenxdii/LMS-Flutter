import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:lms_flutter/models/order_tracking_model.dart';
import 'package:lms_flutter/services/api_service.dart';

class OrderDetailScreen extends StatefulWidget {
  final int orderId;
  final int customerId;

  const OrderDetailScreen({
    super.key,
    required this.orderId,
    required this.customerId,
  });

  @override
  State<OrderDetailScreen> createState() => _OrderDetailScreenState();
}

class _OrderDetailScreenState extends State<OrderDetailScreen> {
  OrderTracking? _order;
  bool _isLoading = true;
  String? _errorMessage;

  final _currencyFormat = NumberFormat.currency(locale: 'vi_VN', symbol: 'đ');
  final _dateFormat = DateFormat('dd/MM/yyyy HH:mm');

  @override
  void initState() {
    super.initState();
    _loadOrderTracking();
  }

  Future<void> _loadOrderTracking() async {
    setState(() => _isLoading = true);

    final apiService = ApiService();
    final data = await apiService.getOrderTracking(
      widget.orderId,
      widget.customerId,
    );

    if (mounted) {
      setState(() {
        if (data != null) {
          _order = OrderTracking.fromJson(data);
        } else {
          _errorMessage = 'Không thể tải thông tin đơn hàng';
        }
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 242, 249, 255),
      appBar: AppBar(
        title: const Text('Chi Tiết Đơn Hàng'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_errorMessage != null || _order == null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              _errorMessage ?? 'Lỗi không xác định',
              style: TextStyle(fontSize: 16, color: Colors.grey[600]),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadOrderTracking,
              child: const Text('Thử lại'),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadOrderTracking,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // tiêu đề - thông tin đơn hàng
            _buildOrderHeader(),
            const SizedBox(height: 20),

            // các điểm dừng lộ trình (nếu có chuyến hàng)
            if (_order!.shipment != null) ...[
              _buildRouteStopsSection(),
              const SizedBox(height: 20),
            ],

            // thông tin vận chuyển
            _buildShippingInfoSection(),
          ],
        ),
      ),
    );
  }

  // tiêu đề đơn hàng
  Widget _buildOrderHeader() {
    final order = _order!;

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(15),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // mã đơn hàng + trạng thái
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Đơn #${order.orderNo ?? order.id}',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                _buildStatusBadge(order.status, order.statusText),
              ],
            ),
            const SizedBox(height: 12),

            // ngày tạo & tổng tiền
            Row(
              children: [
                Icon(Icons.schedule, size: 18, color: Colors.grey[600]),
                const SizedBox(width: 6),
                Text(
                  _dateFormat.format(order.createdAt),
                  style: TextStyle(color: Colors.grey[600]),
                ),
              ],
            ),

            const SizedBox(height: 8),

            Row(
              children: [
                Icon(Icons.payments, size: 18, color: Colors.grey[600]),
                const SizedBox(width: 6),
                Text(
                  'Tổng tiền: ${_currencyFormat.format(order.totalFee)}',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.green,
                  ),
                ),
              ],
            ),

            // thông tin chuyến hàng nếu có
            if (order.shipment != null) ...[
              const Divider(height: 24),
              Row(
                children: [
                  Icon(Icons.local_shipping, size: 18, color: Colors.blue[600]),
                  const SizedBox(width: 6),
                  Text(
                    'Chuyến #${order.shipment!.id}',
                    style: TextStyle(
                      color: Colors.blue[600],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    '– ${order.shipment!.statusText}',
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                ],
              ),
            ],

            // lý do hủy nếu đơn bị hủy
            if (order.status == 4 && order.cancelReason != null) ...[
              const Divider(height: 24),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red[50],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.cancel, size: 20, color: Colors.red[700]),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Lý do hủy',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.red[700],
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            order.cancelReason!,
                            style: TextStyle(color: Colors.red[900]),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildStatusBadge(int status, String text) {
    Color bgColor;
    Color textColor;

    switch (status) {
      case 0: // chờ xử lý
        bgColor = Colors.orange[100]!;
        textColor = Colors.orange[800]!;
        break;
      case 1: // đã duyệt
        bgColor = Colors.blue[100]!;
        textColor = Colors.blue[800]!;
        break;
      case 2: // đang vận chuyển
        bgColor = Colors.purple[100]!;
        textColor = Colors.purple[800]!;
        break;
      case 3: // hoàn thành
        bgColor = Colors.green[100]!;
        textColor = Colors.green[800]!;
        break;
      case 4: // đã hủy
        bgColor = Colors.red[100]!;
        textColor = Colors.red[800]!;
        break;
      default:
        bgColor = Colors.grey[200]!;
        textColor = Colors.grey[700]!;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: textColor,
          fontWeight: FontWeight.w600,
          fontSize: 13,
        ),
      ),
    );
  }

  // các điểm dừng lộ trình
  Widget _buildRouteStopsSection() {
    final stops = _order!.shipment!.routeStops;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Lịch Trình Vận Chuyển',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),

        if (stops.isEmpty)
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                'Chưa có lịch trình',
                style: TextStyle(color: Colors.grey[600]),
              ),
            ),
          )
        else
          ListView.separated(
            shrinkWrap: true, // co vừa đủ cho nội dung
            physics: const NeverScrollableScrollPhysics(), // không cho scroll
            itemCount: stops.length,
            separatorBuilder: (_, _) => const SizedBox(height: 8),
            itemBuilder: (context, index) => _buildRouteStopCard(stops[index]),
          ),
      ],
    );
  }

  Widget _buildRouteStopCard(RouteStop stop) {
    final isCurrentStop = stop.isCurrentStop;

    return Card(
      elevation: isCurrentStop ? 3 : 1,
      color: isCurrentStop ? Colors.blue[50] : null,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
        side: isCurrentStop
            ? BorderSide(color: Colors.blue[400]!, width: 2)
            : BorderSide.none,
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // hàng 1: stt + tên kho + trạng thái
            Row(
              children: [
                // số thứ tự
                Container(
                  width: 32,
                  height: 32,
                  alignment: Alignment.center, // căn content giữa container
                  decoration: BoxDecoration(
                    color: _getStopStatusColor(stop.status),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '${stop.seq}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 12),

                // tên kho
                Expanded(
                  child: Text(
                    stop.displayName,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: isCurrentStop
                          ? FontWeight.bold
                          : FontWeight.w500,
                    ),
                  ),
                ),

                // trạng thái
                Text(
                  stop.statusText,
                  style: TextStyle(
                    color: _getStopStatusColor(stop.status),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),

            // hàng 2: thời gian (xếp chồng để tránh tràn)
            if (stop.arrivedAt != null || stop.departedAt != null) ...[
              const SizedBox(height: 8),
              if (stop.arrivedAt != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Row(
                    children: [
                      const SizedBox(width: 44),
                      Icon(Icons.login, size: 16, color: Colors.grey[600]),
                      const SizedBox(width: 8),
                      Text(
                        'Đến: ${_dateFormat.format(stop.arrivedAt!)}',
                        style: TextStyle(fontSize: 13, color: Colors.grey[700]),
                      ),
                    ],
                  ),
                ),
              if (stop.departedAt != null)
                Row(
                  children: [
                    const SizedBox(width: 44),
                    Icon(Icons.logout, size: 16, color: Colors.grey[600]),
                    const SizedBox(width: 8),
                    Text(
                      'Đi:   ${_dateFormat.format(stop.departedAt!)}',
                      style: TextStyle(fontSize: 13, color: Colors.grey[700]),
                    ),
                  ],
                ),
            ],
          ],
        ),
      ),
    );
  }

  Color _getStopStatusColor(int status) {
    switch (status) {
      case 0:
        return Colors.grey; // đang chờ status == 0
      case 1:
        return Colors.blue; // đã đến status == 1
      case 2:
        return Colors.green; // đã rời đi status == 2
      default:
        return Colors.grey;
    }
  }

  // thông tin vận chuyển
  Widget _buildShippingInfoSection() {
    final order = _order!;

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Thông Tin Vận Chuyển',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),

            // điểm đi - luôn hiển thị kho gửi
            _buildInfoRow(
              icon: Icons.location_on,
              iconColor: Colors.green,
              label: 'Điểm đi',
              value: order.originWarehouse?.name ?? 'Kho gửi',
            ),
            const SizedBox(height: 12),

            // điểm đến
            _buildInfoRow(
              icon: Icons.flag,
              iconColor: Colors.red,
              label: 'Điểm đến',
              value: order.destWarehouse?.name ?? 'Kho nhận',
            ),

            // mô tả hàng hóa
            if (order.packageDescription != null &&
                order.packageDescription!.isNotEmpty) ...[
              const SizedBox(height: 12),
              _buildInfoRow(
                icon: Icons.inventory_2,
                iconColor: Colors.brown,
                label: 'Mô tả hàng',
                value: order.packageDescription!,
              ),
            ],

            const Divider(height: 24),

            // chi tiết phí
            _buildFeeRow('Phí vận chuyển', order.routeFee),
            if (order.pickupFee > 0)
              _buildFeeRow('Phí lấy hàng', order.pickupFee),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Tổng cộng',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                ),
                Text(
                  _currencyFormat.format(order.totalFee),
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: Colors.green,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 4),

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Đặt cọc (${(order.depositAmount / order.totalFee * 100).toStringAsFixed(0)}%)',
                  style: TextStyle(color: Colors.grey[600], fontSize: 13),
                ),
                Text(
                  _currencyFormat.format(order.depositAmount),
                  style: TextStyle(color: Colors.grey[700], fontSize: 14),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow({
    required IconData icon,
    required Color iconColor,
    required String label,
    required String value,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 20, color: iconColor),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(fontSize: 12, color: Colors.grey[600]),
              ),
              const SizedBox(height: 2),
              Text(value, style: const TextStyle(fontSize: 14)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildFeeRow(String label, double amount) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(color: Colors.grey[700])),
          Text(_currencyFormat.format(amount)),
        ],
      ),
    );
  }
}
