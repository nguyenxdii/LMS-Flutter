import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/driver_shipment_model.dart';
import '../../providers/auth_provider.dart';
import '../../services/api_service.dart';

import 'driver_shipment_detail_screen.dart';

class DriverDashboardScreen extends StatefulWidget {
  final Function(int) onNavigateToTab;

  const DriverDashboardScreen({super.key, required this.onNavigateToTab});

  @override
  DriverDashboardScreenState createState() => DriverDashboardScreenState();
}

class DriverDashboardScreenState extends State<DriverDashboardScreen> {
  final ApiService _apiService = ApiService();
  bool _isLoading = true;
  DriverDashboardStats? _stats;
  ShipmentRow? _currentShipment;

  // phương thức công khai để refresh từ parent
  void refresh() => _loadData();

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final driverId = Provider.of<AuthProvider>(
      context,
      listen: false,
    ).user?.driverId;
    if (driverId == null) return;

    setState(() => _isLoading = true);

    try {
      // 1. lấy thống kê
      final stats = await _apiService.getDriverDashboardStats(driverId);

      // 2. lấy danh sách chuyến để tìm chuyến "đang chạy"
      final shipments = await _apiService.getDriverShipments(driverId);
      // Ưu tiên: OnRoute > AtWarehouse > ArrivedDestination > Assigned
      final current = shipments.firstWhere(
        (s) =>
            ['OnRoute', 'AtWarehouse', 'ArrivedDestination'].contains(s.status),
        orElse: () => ShipmentRow(
          id: 0,
          shipmentNo: '',
          orderNo: '',
          route: '',
          status: '',
          stops: 0,
          customerName: '',
          originWarehouse: '',
          destinationWarehouse: '',
        ), // placeholder
      );

      setState(() {
        _stats = stats;
        _currentShipment = current.id != 0 ? current : null;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return RefreshIndicator(
      onRefresh: _loadData,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildStatsRow(),
            const SizedBox(height: 24),
            const Text(
              'Hoạt động hiện tại',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            if (_currentShipment != null)
              _buildCurrentShipmentCard()
            else
              _buildEmptyState(),
          ],
        ),
      ),
    );
  }

  Widget _buildStatsRow() {
    return Row(
      children: [
        Expanded(
          child: _buildStatCard(
            'Chuyến mới',
            _stats?.assigned ?? 0,
            Colors.blue,
            Icons.new_releases,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _buildStatCard(
            'Đang chạy',
            _stats?.inProgress ?? 0,
            Colors.orange,
            Icons.local_shipping,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _buildStatCard(
            'Hoàn thành',
            _stats?.completed ?? 0,
            Colors.green,
            Icons.check_circle,
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard(String title, int count, Color color, IconData icon) {
    return SizedBox(
      height: 110, // chiều cao cố định để tránh tràn
      child: Card(
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12.0, horizontal: 4.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: color, size: 24),
              const SizedBox(height: 4),
              Text(
                count.toString(),
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
              Text(
                title,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.grey, fontSize: 11),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCurrentShipmentCard() {
    final s = _currentShipment!;
    return Card(
      elevation: 4,
      shadowColor: Colors.blue.withAlpha(26), // màu bóng
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.blue.shade200, width: 1.5),
      ),
      // click vào card có hiệu ứng
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) =>
                  DriverShipmentDetailScreen(shipmentId: s.id),
            ),
          ).then((_) => _loadData()); // load lại dữ liệu khi quay lại
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.blue.withAlpha(26),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.navigation,
                      color: Colors.blue,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          s.shipmentNo,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          s.route,
                          style: TextStyle(color: Colors.grey[700]),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  // badge trạng thái
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.orange.withAlpha(26),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      s.statusText,
                      style: const TextStyle(
                        color: Colors.orange,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),

              const Divider(height: 24),

              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '${s.stops} điểm dừng',
                    style: const TextStyle(color: Colors.grey),
                  ),
                  const Row(
                    children: [
                      Text(
                        'Tiếp tục',
                        style: TextStyle(
                          color: Colors.blue,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Icon(Icons.arrow_forward, size: 16, color: Colors.blue),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.grey.shade100,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Icon(Icons.commute, size: 48, color: Colors.grey.shade400),
            const SizedBox(height: 12),
            Text(
              'Chưa có chuyến đang chạy',
              style: TextStyle(color: Colors.grey.shade600),
            ),
            const SizedBox(height: 12),
            // gọi callback hoặc push trực tiếp màn hình
            ElevatedButton(
              onPressed: () => widget.onNavigateToTab(1),
              child: const Text('Xem danh sách chuyến'),
            ),
          ],
        ),
      ),
    );
  }
}
