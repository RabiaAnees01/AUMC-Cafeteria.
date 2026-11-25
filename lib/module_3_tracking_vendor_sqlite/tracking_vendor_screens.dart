import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../core/app_theme.dart';
import '../core/app_routes.dart';
import '../core/models/order_model.dart';
import '../core/models/food_item_model.dart';
import '../core/services/app_services.dart';
import '../core/widgets/common.dart';
import 'sqlite_helper.dart';

class LiveTrackingScreen extends StatelessWidget {
  const LiveTrackingScreen({super.key});
  @override Widget build(BuildContext context) {
    final id = ModalRoute.of(context)?.settings.arguments as String?;
    if (id == null) return const Scaffold(body: Center(child: Text('Open tracking from a placed order.')));
    return Scaffold(appBar: AppBar(title: const Text('Live Order Tracking')),
      body: StreamBuilder<OrderModel?>(stream: AppServices.instance.watchOrder(id), builder: (context, s) {
        if (s.hasError) return const Center(child: Text('Tracking unavailable. Check connection.'));
        if (!s.hasData) return const Center(child: CircularProgressIndicator());
        final order = s.data;
        if (order == null) return const Center(child: Text('Order not found.'));
        final step = order.status.index;
        return ListView(padding: const EdgeInsets.all(18), children: [
          Card(child: Padding(padding: const EdgeInsets.all(16), child: Column(children: [
            Text('Order ID: ${order.orderId}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
            const SizedBox(height: 20),
            Row(children: List.generate(3, (i) => Expanded(child: Column(children: [
              CircleAvatar(backgroundColor: i <= step ? AppColors.green : Colors.grey.shade300,
                child: Icon(i <= step ? Icons.check : Icons.circle, color: Colors.white)),
              const SizedBox(height: 6),
              Text(['Received', 'Preparing', 'Ready'][i], style: const TextStyle(fontSize: 11)),
            ])))),
          ]))),
          Card(color: AppColors.navy, child: Padding(padding: const EdgeInsets.all(18), child: Column(children: [
            const Text('Fraud-Free Pickup Token', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            const Text('Digital QR Code', style: TextStyle(color: Colors.white70)),
            const SizedBox(height: 12),
            QrImageView(data: order.qrToken, size: 190, backgroundColor: Colors.white),
            const SizedBox(height: 8),
            Text(order.qrToken, style: const TextStyle(color: Colors.white)),
          ]))),
          Text('Pickup: ${order.pickupSlot}'),
          Text('Total: Rs. ${order.totalAmount.toStringAsFixed(0)}'),
        ]);
      }),
    );
  }
}

class OfflineStorageScreen extends StatefulWidget {
  const OfflineStorageScreen({super.key});
  @override State<OfflineStorageScreen> createState() => _OfflineStorageScreenState();
}
class _OfflineStorageScreenState extends State<OfflineStorageScreen> {
  int tab = 0;
  @override Widget build(BuildContext context) => Scaffold(appBar: AppBar(title: const Text('Offline Storage & Campus')),
    body: Column(children: [
      const Padding(padding: EdgeInsets.all(12), child: StatusBadge('Offline Ready')),
      SegmentedButton<int>(segments: const [
        ButtonSegment(value: 0, label: Text('Recent Orders')),
        ButtonSegment(value: 1, label: Text('Favorites')),
      ], selected: {tab}, onSelectionChanged: (v) => setState(() => tab = v.first)),
      Expanded(child: FutureBuilder<List<Map<String, Object?>>>(future: tab == 0 ?
        SqliteHelper.instance.recentOrders() : SqliteHelper.instance.favorites(),
        builder: (context, s) {
          if (!s.hasData) return const Center(child: CircularProgressIndicator());
          if (s.data!.isEmpty) return const Center(child: Text('No locally saved records yet.'));
          return ListView(children: s.data!.map((r) => ListTile(
            title: Text('${r['name'] ?? r['id']}'),
            subtitle: Text('${r['created_at'] ?? ''}'),
            trailing: tab == 0 ? const Text('1-Tap Reorder') : const Icon(Icons.favorite),
          )).toList());
        })),
      const Divider(),
      const ListTile(leading: Icon(Icons.location_on), title: Text('Main Canteen Express Counter'), subtitle: Text('AUMC Main Canteen')),
      const ListTile(leading: Icon(Icons.location_on), title: Text('CS Block Kiosk'), subtitle: Text('Computer Science Block')),
    ]),
  );
}

class VendorDashboardScreen extends StatelessWidget {
  const VendorDashboardScreen({super.key});
  @override Widget build(BuildContext context) => Scaffold(appBar: AppBar(title: const Text('AUMC Kitchen Dashboard')),
    body: StreamBuilder<List<OrderModel>>(stream: AppServices.instance.watchOrders(), builder: (context, s) {
      if (!s.hasData) return const Center(child: CircularProgressIndicator());
      final orders = s.data!;
      final active = orders.where((o) => o.status != OrderStatus.ready).toList();
      return ListView(padding: const EdgeInsets.all(14), children: [
        const StatusBadge('Role Guard: Vendor Only'),
        Row(children: [
          _metric('Queue', '${active.length}'),
          _metric('Preparing', '${orders.where((o) => o.status == OrderStatus.preparing).length}'),
          _metric('Today Sales', 'Rs. ${orders.fold<double>(0, (a, o) => a + o.totalAmount).toStringAsFixed(0)}'),
        ]),
        const Text('Incoming Student Order Tickets', style: TextStyle(fontSize: 19, fontWeight: FontWeight.bold)),
        ...active.map((o) => Card(child: Padding(padding: const EdgeInsets.all(12), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Order #${o.orderId}', style: const TextStyle(fontWeight: FontWeight.bold)),
          Text('Roll No: ${o.rollNumber} • ${o.pickupSlot}'),
          ...o.items.map((i) => Text('${i.quantity} × ${i.name}')),
          const SizedBox(height: 8),
          Row(children: [
            Expanded(child: OutlinedButton(onPressed: o.status == OrderStatus.received ?
              () => AppServices.instance.updateOrderStatus(o.orderId, OrderStatus.preparing) : null,
              child: const Text('Start Preparing'))),
            const SizedBox(width: 8),
            Expanded(child: ElevatedButton(onPressed: () =>
              AppServices.instance.updateOrderStatus(o.orderId, OrderStatus.ready),
              child: const Text('Mark Ready for Pickup'))),
          ]),
        ])))),
        const SizedBox(height: 12),
        const Text('Live Menu Stock Control', style: TextStyle(fontSize: 19, fontWeight: FontWeight.bold)),
        StreamBuilder<List<FoodItemModel>>(stream: AppServices.instance.watchFood(), builder: (context, fs) {
          if (!fs.hasData) return const LinearProgressIndicator();
          return Column(children: fs.data!.map((f) => SwitchListTile(
            title: Text(f.name), subtitle: Text('Stock quantity: ${f.stockQuantity}'),
            value: f.isAvailable, onChanged: (v) => AppServices.instance.updateStock(f.id, v),
          )).toList());
        }),
      ]);
    }),
  );
  Widget _metric(String label, String value) => Expanded(child: Card(child: Padding(
    padding: const EdgeInsets.all(10), child: Column(children: [
      Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
      Text(label, style: const TextStyle(fontSize: 11)),
    ]),
  )));
}
