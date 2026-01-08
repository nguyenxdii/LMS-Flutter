import 'package:flutter/material.dart';
import 'package:lms_flutter/providers/auth_provider.dart';
import 'package:lms_flutter/screens/create_order_screen.dart';
import 'package:lms_flutter/services/api_service.dart';
import 'package:provider/provider.dart';

class CustomerOrdersScreen extends StatefulWidget {
  const CustomerOrdersScreen({super.key});

  @override
  State<CustomerOrdersScreen> createState() => _CustomerOrdersScreenState();
}

class _CustomerOrdersScreenState extends State<CustomerOrdersScreen> {
  List<Map<String, dynamic>> _recentOrders = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadOrders();
  }

  Future<void> _loadOrders() async {
    setState(() => _isLoading = true);

    final user = Provider.of<AuthProvider>(context, listen: false).user;
    if (user?.customerId != null) {
      final apiService = ApiService();
      final orders = await apiService.getCustomerOrders(user!.customerId!);

      if (mounted) {
        setState(() {
          _recentOrders = orders.take(5).toList(); // Chỉ lấy 5 đơn gần nhất
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
            // Greeting Section
            _buildGreetingSection(user),
            const SizedBox(height: 25),

            // Create Order Button
            _buildCreateOrderButton(context),
            const SizedBox(height: 30),

            // Recent Orders Section
            _buildRecentOrdersSection(),
          ],
        ),
      ),
    );
  }

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
              const TextSpan(text: 'Chào mừng trở lại, '),
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

  Widget _buildCreateOrderButton(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: () => _navigateToCreateOrder(context),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.blue,
          foregroundColor: Colors.white,
          elevation: 4,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 24),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.add_box_outlined,
                size: 32,
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
                // TODO: Navigate to all orders
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

  Widget _buildOrderList() {
    return Column(
      children: _recentOrders.map((order) {
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.grey[300]!),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            children: [
              // Mã đơn
              Expanded(
                flex: 2,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Mã đơn',
                      style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      order['OrderNo'] ?? 'N/A',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              // Trạng thái
              Expanded(
                flex: 2,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Trạng thái',
                      style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _getStatusText(order['Status']),
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: _getStatusTextColor(order['Status']),
                      ),
                    ),
                  ],
                ),
              ),
              // Ngày tạo
              Expanded(
                flex: 3,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      'Ngày tạo',
                      style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _formatDate(order['CreatedAt']),
                      style: const TextStyle(fontSize: 13),
                      textAlign: TextAlign.right,
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  String _getStatusText(dynamic status) {
    if (status == null) return 'N/A';
    // Map với OrderStatus enum trong backend
    switch (status.toString()) {
      case '0':
      case 'Pending':
        return 'Chờ duyệt';
      case '1':
      case 'Approved':
        return 'Đã duyệt';
      case '2':
      case 'Completed':
        return 'Hoàn tất';
      case '3':
      case 'InTransit':
        return 'Đang giao';
      case '4':
      case 'Cancelled':
        return 'Đã hủy';
      default:
        return status.toString();
    }
  }

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
      case 'Completed':
        return Colors.green;
      case '3':
      case 'InTransit':
        return Colors.blue;
      case '4':
      case 'Cancelled':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  String _formatDate(dynamic dateStr) {
    if (dateStr == null) return 'N/A';
    try {
      final date = DateTime.parse(dateStr.toString());
      return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year} ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
    } catch (e) {
      return dateStr.toString();
    }
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          children: [
            Icon(Icons.inventory_2_outlined, size: 80, color: Colors.grey[400]),
            const SizedBox(height: 20),
            Text(
              'Chưa có đơn hàng nào',
              style: TextStyle(
                fontSize: 18,
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              'Tạo đơn hàng đầu tiên của bạn ngay!',
              style: TextStyle(fontSize: 14, color: Colors.grey[500]),
            ),
          ],
        ),
      ),
    );
  }

  void _navigateToCreateOrder(BuildContext context) {
    Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => const CreateOrderScreen()));
  }

  Future<void> _refreshOrders() async {
    await _loadOrders();
  }
}
