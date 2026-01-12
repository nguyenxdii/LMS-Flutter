import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/driver_shipment_model.dart';
import '../../providers/auth_provider.dart';
import '../../services/api_service.dart';
import 'driver_shipment_detail_screen.dart';

/// Màn hình hiển thị tất cả chuyến hàng (shipments) của tài xế
class DriverAllOrdersScreen extends StatefulWidget {
  const DriverAllOrdersScreen({super.key});

  @override
  State<DriverAllOrdersScreen> createState() => _DriverAllOrdersScreenState();
}

class _DriverAllOrdersScreenState extends State<DriverAllOrdersScreen> {
  final ApiService _apiService = ApiService();
  List<ShipmentRow> _allShipments = [];
  List<ShipmentRow> _historyShipments = [];
  bool _isLoading = true;

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

    if (driverId == null) {
      setState(() => _isLoading = false);
      return;
    }

    setState(() => _isLoading = true);

    try {
      final active = await _apiService.getDriverShipments(driverId);
      final history = await _apiService.getDriverHistory(driverId);

      if (mounted) {
        setState(() {
          _allShipments = active;
          _historyShipments = history;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  List<ShipmentRow> get _combinedShipments {
    // kết hợp active và history để có tất cả
    return [..._allShipments, ..._historyShipments];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 242, 249, 255),
      appBar: AppBar(
        title: const Text('Tất Cả Chuyến Hàng'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadData,
              child: _combinedShipments.isEmpty
                  ? _buildEmptyState()
                  : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: _combinedShipments.length,
                      itemBuilder: (context, index) =>
                          _buildShipmentCard(_combinedShipments[index]),
                    ),
            ),
    );
  }

  Widget _buildShipmentCard(ShipmentRow s) {
    Color statusColor = Colors.grey;
    if (s.status == 'Assigned') statusColor = Colors.blue;
    if (s.status == 'OnRoute') statusColor = Colors.orange;
    if (s.status == 'Delivered') statusColor = Colors.green;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) =>
                  DriverShipmentDetailScreen(shipmentId: s.id),
            ),
          ).then((_) => _loadData());
        },
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    s.shipmentNo,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: statusColor.withAlpha(26),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      s.statusText,
                      style: TextStyle(
                        color: statusColor,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  const Icon(Icons.map, size: 16, color: Colors.grey),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      s.route,
                      style: const TextStyle(fontWeight: FontWeight.w500),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  const Icon(Icons.person, size: 16, color: Colors.grey),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      s.customerName,
                      style: TextStyle(color: Colors.grey[700]),
                    ),
                  ),
                ],
              ),
              const Divider(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    "Đơn gốc: ${s.orderNo}",
                    style: TextStyle(color: Colors.grey[600], fontSize: 13),
                  ),
                  Text(
                    "${s.stops} điểm dừng",
                    style: TextStyle(color: Colors.grey[600], fontSize: 13),
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
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.local_shipping_outlined,
              size: 80,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 20),
            Text(
              'Chưa có chuyến hàng nào',
              style: TextStyle(
                fontSize: 18,
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
