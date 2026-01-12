import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../models/driver_shipment_model.dart';
import '../../providers/auth_provider.dart';
import '../../services/api_service.dart';

class DriverShipmentDetailScreen extends StatefulWidget {
  final int shipmentId;

  const DriverShipmentDetailScreen({super.key, required this.shipmentId});

  @override
  State<DriverShipmentDetailScreen> createState() =>
      _DriverShipmentDetailScreenState();
}

class _DriverShipmentDetailScreenState
    extends State<DriverShipmentDetailScreen> {
  final ApiService _apiService = ApiService();
  final DateFormat _dateFormat = DateFormat('HH:mm dd/MM');

  bool _isLoading = true;
  ShipmentDetail? _detail;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadDetail();
  }

  Future<void> _loadDetail() async {
    final driverId = Provider.of<AuthProvider>(
      context,
      listen: false,
    ).user?.driverId;
    if (driverId == null) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final detail = await _apiService.getShipmentDetail(
        widget.shipmentId,
        driverId,
      );
      if (detail != null) {
        setState(() {
          _detail = detail;
          _isLoading = false;
        });
      } else {
        setState(() {
          _errorMessage = 'Không tìm thấy thông tin chuyến hàng.';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Lỗi kết nối: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _updateStatus(String action, {String? note}) async {
    final driverId = Provider.of<AuthProvider>(
      context,
      listen: false,
    ).user?.driverId;
    if (driverId == null) return;

    // hiển loading
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => const Center(child: CircularProgressIndicator()),
    );

    final success = await _apiService.updateShipmentStatus(
      shipmentId: widget.shipmentId,
      driverId: driverId,
      action: action,
      note: note,
    );

    if (!mounted) return;
    Navigator.pop(context); // ẩn loading

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Cập nhật thành công'),
          backgroundColor: Colors.green,
        ),
      );
      _loadDetail(); // tải lại UI
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Cập nhật thất bại. Vui lòng thử lại.'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _showNoteDialog() {
    final noteController = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Ghi chú cho Admin"),
        content: TextField(
          controller: noteController,
          decoration: const InputDecoration(
            hintText: "Nhập vấn đề gặp phải (vd: kẹt xe, sự cố...)",
            border: OutlineInputBorder(),
          ),
          maxLines: 3,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text("Hủy"),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              if (noteController.text.trim().isNotEmpty) {
                _updateStatus('note', note: noteController.text.trim());
              }
            },
            child: const Text("Gửi ghi chú"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 242, 249, 255),
      appBar: AppBar(
        title: Text(_detail?.header.shipmentNo ?? 'Chi tiết chuyến'),
        centerTitle: true,
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null
          ? RefreshIndicator(
              onRefresh: _loadDetail,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                child: SizedBox(
                  height: MediaQuery.of(context).size.height - 100,
                  child: Center(child: Text(_errorMessage!)),
                ),
              ),
            )
          : RefreshIndicator(
              onRefresh: _loadDetail,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildHeaderButtons(), // nút ghi chú
                    const SizedBox(height: 16),
                    _buildHeaderCard(),
                    const SizedBox(height: 24),
                    const Text(
                      'Lộ trình vận chuyển',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    _buildTimeline(),
                    const SizedBox(height: 24),
                    _buildMainActionButtons(), // nút thao tác chính
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildHeaderButtons() {
    // nút ghi chú: chỉ khi đang vận chuyển (OnRoute)
    bool canNote = _detail?.header.status == 'OnRoute';

    if (!canNote) return const SizedBox.shrink();

    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: _showNoteDialog,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.amber[700],
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 12),
        ),
        child: const Text("GHI CHÚ (Sự cố / Tình trạng)"),
      ),
    );
  }

  Widget _buildHeaderCard() {
    final h = _detail!.header;
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            _buildInfoRow(Icons.receipt, 'Mã đơn hàng', h.orderNo),
            const Divider(),
            _buildInfoRow(Icons.person, 'Khách hàng', h.customerName),
            const Divider(),
            // bố cục đặc biệt cho tuyến đường
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.map, size: 20, color: Colors.grey),
                  const SizedBox(width: 12),
                  const SizedBox(
                    width: 100,
                    child: Text(
                      'Tuyến đường',
                      style: TextStyle(color: Colors.grey),
                    ),
                  ),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: _buildRouteWidgets(h.route),
                    ),
                  ),
                ],
              ),
            ),
            const Divider(),
            _buildInfoRow(
              Icons.info_outline,
              'Trạng thái',
              _mapShipmentStatus(h.status),
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildRouteWidgets(String route) {
    // "Kho A → Kho B"
    if (!route.contains('→')) {
      return [Text(route, style: const TextStyle(fontWeight: FontWeight.bold))];
    }
    final parts = route.split('→').map((e) => e.trim()).toList();
    if (parts.length < 2) {
      return [Text(route, style: const TextStyle(fontWeight: FontWeight.bold))];
    }

    return [
      Text(parts[0], style: const TextStyle(fontWeight: FontWeight.bold)),
      const Padding(
        padding: EdgeInsets.symmetric(vertical: 4.0),
        child: Icon(Icons.arrow_downward, size: 16, color: Colors.blue),
      ),
      Text(parts[1], style: const TextStyle(fontWeight: FontWeight.bold)),
    ];
  }

  String _mapShipmentStatus(String status) {
    switch (status) {
      case 'Pending':
        return 'Chờ nhận';
      case 'Assigned':
        return 'Đã nhận';
      case 'OnRoute':
        return 'Đang chạy';
      case 'AtWarehouse':
        return 'Tại kho';
      case 'ArrivedDestination':
        return 'Đến đích';
      case 'Delivered':
        return 'Hoàn thành';
      default:
        return status;
    }
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: Colors.grey),
          const SizedBox(width: 12),
          SizedBox(
            width: 100,
            child: Text(label, style: const TextStyle(color: Colors.grey)),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTimeline() {
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: _detail!.stops.length,
      itemBuilder: (context, index) {
        return _buildTimelineItem(
          _detail!.stops[index],
          index == _detail!.stops.length - 1,
        );
      },
    );
  }

  Widget _buildTimelineItem(RouteStopLite stop, bool isLast) {
    Color statusColor = Colors.grey;
    bool isActive = stop.seq == _detail!.header.currentStopSeq;

    if (stop.stopStatus == 'Departed') {
      statusColor = Colors.green;
    } else if (stop.stopStatus == 'Arrived') {
      statusColor = isActive ? Colors.blue : Colors.green[300]!;
    } else if (isActive) {
      statusColor = Colors.orange;
    }

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 50,
            child: Column(
              children: [
                Text(
                  _dateFormat.format(stop.plannedETA ?? DateTime.now()),
                  style: const TextStyle(fontSize: 10, color: Colors.grey),
                ),
                const SizedBox(height: 4),
                Container(
                  width: 16,
                  height: 16,
                  decoration: BoxDecoration(
                    color: statusColor,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: isActive
                          ? Colors.blue.withValues(alpha: 0.3)
                          : Colors.transparent,
                      width: 4,
                    ),
                  ),
                ),
                if (!isLast)
                  Expanded(child: Container(width: 2, color: Colors.grey[300])),
              ],
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 24),
              child: Card(
                elevation: isActive ? 3 : 1,
                color: isActive ? Colors.blue[50] : Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              stop.stopName,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          Text(
                            stop.statusText,
                            style: TextStyle(
                              fontSize: 12,
                              fontStyle: FontStyle.italic,
                              color: statusColor,
                            ),
                          ),
                        ],
                      ),
                      if (stop.note != null &&
                          stop.note!.isNotEmpty &&
                          isActive)
                        Padding(
                          padding: const EdgeInsets.only(top: 8.0),
                          child: Text(
                            "Ghi chú: ${stop.note}",
                            style: const TextStyle(color: Colors.red),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMainActionButtons() {
    final status = _detail!.header.status;
    final stops = _detail!.stops;
    final currentSeq = _detail!.header.currentStopSeq;

    // tìm tên điểm dừng hiện tại/tiếp theo cho nút rõ ràng hơn
    String currentStopName = "";
    String nextStopName = "";

    if (currentSeq != null) {
      final cur = stops.firstWhere(
        (s) => s.seq == currentSeq,
        orElse: () => stops.first,
      );
      currentStopName = cur.stopName;

      final nextSeq = currentSeq + 1;
      if (nextSeq <= stops.map((e) => e.seq).reduce((a, b) => a > b ? a : b)) {
        final next = stops.firstWhere(
          (s) => s.seq == nextSeq,
          orElse: () => stops.last,
        );
        nextStopName = next.stopName;
      }
    }

    // 1. Pending -> nút "NHẬN CHUYẾN"
    if (status == 'Pending') {
      return SizedBox(
        width: double.infinity,
        height: 50,
        child: ElevatedButton(
          onPressed: () => _updateStatus('receive'),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.blue,
            foregroundColor: Colors.white,
          ),
          child: const Text('NHẬN CHUYẾN'),
        ),
      );
    }

    // 2. Assigned -> "RỜI KHO [BẮt đầu]"
    if (status == 'Assigned') {
      return SizedBox(
        width: double.infinity,
        height: 50,
        child: ElevatedButton(
          onPressed: () => _updateStatus('depart'),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.blue[700],
            foregroundColor: Colors.white,
          ),
          child: Text('XÁC NHẬN RỜI KHO: $currentStopName'),
        ),
      );
    }

    // 3. OnRoute -> "ĐẾN KHO [Tiếp theo]"
    if (status == 'OnRoute') {
      return SizedBox(
        width: double.infinity,
        height: 50,
        child: ElevatedButton(
          onPressed: () => _updateStatus('arrive'),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.orange[800],
            foregroundColor: Colors.white,
          ),
          child: Text('ĐÃ ĐẾN: $nextStopName'),
        ),
      );
    }

    // 4. AtWarehouse -> "RỜI KHO [Hiện tại]"
    if (status == 'AtWarehouse') {
      return SizedBox(
        width: double.infinity,
        height: 50,
        child: ElevatedButton(
          onPressed: () => _updateStatus('depart'),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.blue,
            foregroundColor: Colors.white,
          ),
          child: Text('XÁC NHẬN RỜI: $currentStopName'),
        ),
      );
    }

    // 5. ArrivedDestination -> "HOÀN THÀNH"
    if (status == 'ArrivedDestination') {
      return SizedBox(
        width: double.infinity,
        height: 50,
        child: ElevatedButton(
          onPressed: () => _updateStatus('complete'),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.green,
            foregroundColor: Colors.white,
          ),
          child: const Text('XÁC NHẬN HOÀN THÀNH CHUYẾN'),
        ),
      );
    }

    if (status == 'Delivered') {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(12),
        margin: const EdgeInsets.only(top: 8),
        decoration: BoxDecoration(
          color: Colors.green[50], // nền xanh nhạt
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.green.withValues(alpha: 0.5)),
        ),
        child: const Center(
          child: Text(
            "CHUYẾN HÀNG ĐÃ HOÀN THÀNH",
            style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold),
          ),
        ),
      );
    }

    return const SizedBox.shrink();
  }
}
