// màn hình đơn hàng của khách hàng
import 'package:flutter/material.dart';
import 'package:lms_flutter/providers/auth_provider.dart';
import 'package:lms_flutter/screens/customer/create_order_screen.dart';
import 'package:lms_flutter/screens/customer/customer_all_orders_screen.dart';
import 'package:lms_flutter/screens/customer/order_detail_screen.dart';
import 'package:lms_flutter/services/api_service.dart';
import 'package:provider/provider.dart';

class CustomerOrdersScreen extends StatefulWidget {
  const CustomerOrdersScreen({super.key});

  @override
  State<CustomerOrdersScreen> createState() => _CustomerOrdersScreenState();
}

class _CustomerOrdersScreenState extends State<CustomerOrdersScreen> {
  List<Map<String, dynamic>> _recentOrders = []; // danh sách đơn gần đây
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadOrders();
  }

  // tải danh sách đơn hàng
  Future<void> _loadOrders() async {
    setState(() => _isLoading = true);

    final user = Provider.of<AuthProvider>(context, listen: false).user;
    if (user?.customerId != null) {
      final apiService = ApiService();
      final orders = await apiService.getCustomerOrders(user!.customerId!);

      if (mounted) {
        setState(() {
          _recentOrders = orders.take(3).toList(); // chỉ lấy 3 đơn gần nhất
          _isLoading = false;
        });
      }
    } else {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = Provider.of<AuthProvider>(context).user;

    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return RefreshIndicator(
      onRefresh: _refreshOrders,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // phần chào mừng
            _buildGreetingSection(user),
            const SizedBox(height: 25),

            // nút tạo đơn hàng
            _buildCreateOrderButton(context),
            const SizedBox(height: 30),

            // đơn hàng gần đây
            _buildRecentOrdersSection(),
          ],
        ),
      ),
    );
  }

  // widget chào mừng người dùng
  Widget _buildGreetingSection(dynamic user) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        RichText(
          text: TextSpan(
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
            children: [
              const TextSpan(text: 'Chào mừng, '),
              TextSpan(
                text: user?.fullName ?? 'Khách hàng',
                style: const TextStyle(color: Colors.blue),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // nút tạo đơn hàng mới
  Widget _buildCreateOrderButton(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: () => _navigateToCreateOrder(context),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.blue,
          foregroundColor: Colors.white,
          elevation: 5,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
          padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 20),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.2),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.add_box_outlined,
                size: 30,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 10),
            const Text(
              'Tạo Đơn Hàng Mới',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }

  // phần đơn hàng gần đây
  Widget _buildRecentOrdersSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Đơn Hàng Gần Đây',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => const CustomerAllOrdersScreen(),
                  ),
                );
              },
              child: const Text('Xem tất cả'),
            ),
          ],
        ),
        const SizedBox(height: 15),
        _recentOrders.isEmpty ? _buildEmptyState() : _buildOrderList(),
      ],
    );
  }

  // danh sách đơn hàng
  Widget _buildOrderList() {
    final customerId =
        Provider.of<AuthProvider>(context, listen: false).user?.customerId ?? 0;

    return Column(
      children: _recentOrders.map((order) {
        return GestureDetector(
          onTap: () {
            final orderId = order['Id'];
            if (orderId != null) {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => OrderDetailScreen(
                    orderId: orderId,
                    customerId: customerId,
                  ),
                ),
              );
            }
          },
          child: Container(
            margin: const EdgeInsets.only(bottom: 15),
            padding: const EdgeInsets.all(15),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Colors.grey.shade300),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // mã đơn + arrow
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      order['OrderNo'] ?? 'N/A',
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Icon(
                      Icons.chevron_right,
                      color: Colors.grey.shade400,
                      size: 20,
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                // trạng thái + ngày tạo
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        vertical: 4,
                        horizontal: 8,
                      ),
                      decoration: BoxDecoration(
                        color: _getStatusTextColor(
                          order['Status'],
                        ).withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        _getStatusText(order['Status']),
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: _getStatusTextColor(order['Status']),
                        ),
                      ),
                    ),
                    const Spacer(),
                    Icon(Icons.schedule, size: 14, color: Colors.grey.shade500),
                    const SizedBox(width: 4),
                    Text(
                      _formatDate(order['CreatedAt']),
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade500,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  // lấy text trạng thái
  String _getStatusText(dynamic status) {
    if (status == null) return 'N/A';
    switch (status.toString()) {
      case '0':
      case 'Pending':
        return 'Chờ duyệt';
      case '1':
      case 'Approved':
        return 'Đã duyệt';
      case '2':
      case 'InTransit':
        return 'Đang giao';
      case '3':
      case 'Completed':
        return 'Hoàn tất';
      case '4':
      case 'Cancelled':
        return 'Đã hủy';
      default:
        return status.toString();
    }
  }

  // lấy màu trạng thái
  Color _getStatusTextColor(dynamic status) {
    if (status == null) return Colors.grey;
    switch (status.toString()) {
      case '0':
      case 'Pending':
        return Colors.orange;
      case '1':
      case 'Approved':
        return Colors.blue;
      case '2':
      case 'InTransit':
        return Colors.purple;
      case '3':
      case 'Completed':
        return Colors.green;
      case '4':
      case 'Cancelled':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  // format ngày giờ
  String _formatDate(dynamic dateStr) {
    if (dateStr == null) return 'N/A';
    try {
      final date = DateTime.parse(dateStr.toString());
      return '${date.day.toString().padLeft(2, '0')}/'
          '${date.month.toString().padLeft(2, '0')}/'
          '${date.year} ${date.hour.toString().padLeft(2, '0')}'
          ':${date.minute.toString().padLeft(2, '0')}';
    } catch (e) {
      return dateStr.toString();
    }
  }

  // trạng thái rỗng
  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          children: [
            Icon(
              Icons.inventory_2_outlined,
              size: 80,
              color: Colors.grey.shade400,
            ),
            const SizedBox(height: 20),
            Text(
              'Chưa có đơn hàng nào',
              style: TextStyle(
                fontSize: 18,
                color: Colors.grey.shade600,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              'Tạo đơn hàng đầu tiên của bạn ngay!',
              style: TextStyle(fontSize: 14, color: Colors.grey.shade500),
            ),
          ],
        ),
      ),
    );
  }

  // chuyển đến màn hình tạo đơn
  void _navigateToCreateOrder(BuildContext context) {
    Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => const CreateOrderScreen()));
  }

  // làm mới danh sách đơn
  Future<void> _refreshOrders() async {
    await _loadOrders();
  }
}
