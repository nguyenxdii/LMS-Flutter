import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/driver_shipment_model.dart';
import '../providers/auth_provider.dart';
import '../services/api_service.dart';
import 'driver_shipment_detail_screen.dart';

class DriverOrdersScreen extends StatefulWidget {
  const DriverOrdersScreen({super.key});

  @override
  State<DriverOrdersScreen> createState() => _DriverOrdersScreenState();
}

class _DriverOrdersScreenState extends State<DriverOrdersScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final ApiService _apiService = ApiService();

  bool _isLoading = true;
  List<ShipmentRow> _allShipments = []; // Active only
  List<ShipmentRow> _historyShipments = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
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

      setState(() {
        _allShipments = active;
        _historyShipments = history;
        _isLoading = false;
      });
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          color: Colors.blue,
          child: TabBar(
            controller: _tabController,
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white70,
            indicatorColor: Colors.white,
            tabs: const [
              Tab(text: "Mới"),
              Tab(text: "Đang chạy"),
              Tab(text: "Lịch sử"),
            ],
          ),
        ),
        Expanded(
          child: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : TabBarView(
                  controller: _tabController,
                  children: [
                    _buildShipmentList(_getNewShipments()),
                    _buildShipmentList(_getInProgressShipments()),
                    _buildShipmentList(_historyShipments),
                  ],
                ),
        ),
      ],
    );
  }

  List<ShipmentRow> _getNewShipments() {
    return _allShipments
        .where((s) => s.status == 'Assigned' || s.status == 'Pending')
        .toList();
  }

  List<ShipmentRow> _getInProgressShipments() {
    return _allShipments
        .where(
          (s) =>
              s.status == 'OnRoute' ||
              s.status == 'AtWarehouse' ||
              s.status == 'ArrivedDestination',
        )
        .toList();
  }

  Widget _buildShipmentList(List<ShipmentRow> list) {
    if (list.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.inbox, size: 48, color: Colors.grey[300]),
            const SizedBox(height: 12),
            Text(
              "Không có chuyến hàng nào",
              style: TextStyle(color: Colors.grey[500]),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadData,
      child: ListView.separated(
        padding: const EdgeInsets.all(12),
        itemCount: list.length,
        separatorBuilder: (ctx, i) => const SizedBox(height: 12),
        itemBuilder: (ctx, i) {
          final s = list[i];
          return _buildShipmentItem(s);
        },
      ),
    );
  }

  Widget _buildShipmentItem(ShipmentRow s) {
    Color statusColor = Colors.grey;
    if (s.status == 'Assigned') statusColor = Colors.blue;
    if (s.status == 'OnRoute') statusColor = Colors.orange;
    if (s.status == 'Delivered') statusColor = Colors.green;

    return Card(
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
}
