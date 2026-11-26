import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../core/app_theme.dart';
import '../core/app_routes.dart';
import '../core/models/food_item_model.dart';
import '../core/services/app_services.dart';
import '../core/widgets/common.dart';

class AdminPortalScreen extends StatefulWidget {
  const AdminPortalScreen({super.key});
  @override State<AdminPortalScreen> createState() => _AdminPortalScreenState();
}
class _AdminPortalScreenState extends State<AdminPortalScreen> {
  int tab = 0;
  @override Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('AUMC Admin Portal'), actions: [
      IconButton(onPressed: () => showMessage(context, 'Review cafeteria alerts and audit records below.'), icon: const Icon(Icons.notifications)),
    ]),
    body: IndexedStack(index: tab, children: const [
      _AdminMonitor(), _MenuAudit(), _Guidelines(), _AdminProfile(),
    ]),
    bottomNavigationBar: BottomNavigationBar(currentIndex: tab, onTap: (v) => setState(() => tab = v),
      items: const [
        BottomNavigationBarItem(icon: Icon(Icons.dashboard), label: 'Monitor'),
        BottomNavigationBarItem(icon: Icon(Icons.receipt_long), label: 'Audit'),
        BottomNavigationBarItem(icon: Icon(Icons.rule), label: 'Guidelines'),
        BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
      ]),
  );
}

class _AdminMonitor extends StatelessWidget {
  const _AdminMonitor();
  @override Widget build(BuildContext context) => ListView(padding: const EdgeInsets.all(14), children: [
    const Text('Admin Monitor', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
    StreamBuilder<List<FoodItemModel>>(stream: AppServices.instance.watchFood(), builder: (c, s) {
      final foods = s.data ?? [];
      final flags = foods.where((f) => f.price > 450).length;
      return GridView.count(shrinkWrap: true, physics: const NeverScrollableScrollPhysics(), crossAxisCount: 2, childAspectRatio: 1.8,
        children: [
          _metric('Active Vendors', '—', Icons.store),
          _metric('Live Items', '${foods.length}', Icons.fastfood),
          _metric('Overpriced Alerts', '$flags', Icons.warning),
          _metric('Flagged Items', '$flags', Icons.flag),
        ]);
    }),
    Card(child: Padding(padding: const EdgeInsets.all(16), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const Text("Today's Sales", style: TextStyle(fontWeight: FontWeight.bold)),
      const Text('Sales are calculated from live orders once payment verification is integrated.'),
      const SizedBox(height: 14),
      const Icon(Icons.bar_chart, size: 80, color: AppColors.navy),
    ]))),
    PrimaryButton('Review Menu & Price Audit', onPressed: () => showMessage(context, 'Open the Audit tab below.')),
  ]);
  Widget _metric(String title, String value, IconData icon) => Card(child: Padding(padding: const EdgeInsets.all(10), child: Column(
    crossAxisAlignment: CrossAxisAlignment.start, mainAxisAlignment: MainAxisAlignment.center,
    children: [Icon(icon, color: AppColors.navy), Text(value, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)), Text(title, style: const TextStyle(fontSize: 12))],
  )));
}

class _MenuAudit extends StatelessWidget {
  const _MenuAudit();
  @override Widget build(BuildContext context) => StreamBuilder<List<FoodItemModel>>(
    stream: AppServices.instance.watchFood(), builder: (context, s) {
      if (!s.hasData) return const Center(child: CircularProgressIndicator());
      if (s.data!.isEmpty) return const Center(child: Text('No menu items found.'));
      return ListView(padding: const EdgeInsets.all(12), children: [
        const Text('Menu & Price Audit', style: TextStyle(fontSize: 21, fontWeight: FontWeight.bold)),
        ...s.data!.map((f) => Card(child: Padding(padding: const EdgeInsets.all(12), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('${f.name} - Rs. ${f.price.toStringAsFixed(0)}', style: const TextStyle(fontWeight: FontWeight.bold)),
          StatusBadge(f.price > 450 ? 'Overpriced Alert' : 'Fair Price', color: f.price > 450 ? AppColors.amber : AppColors.green),
          const SizedBox(height: 8),
          TextField(controller: TextEditingController(), decoration: const InputDecoration(labelText: 'Audit Comment')),
          const SizedBox(height: 8),
          Row(children: [
            Expanded(child: OutlinedButton(onPressed: () async {
              await AppServices.instance.auditAction(foodId: f.id, action: 'warning', comment: 'Please review listed price.');
              if (context.mounted) showMessage(context, 'Audit note recorded');
            }, child: const Text('Send Note'))),
            const SizedBox(width: 8),
            Expanded(child: ElevatedButton(style: ElevatedButton.styleFrom(backgroundColor: AppColors.red, foregroundColor: Colors.white),
              onPressed: () async {
                await AppServices.instance.auditAction(foodId: f.id, action: 'remove', comment: 'Removed by admin');
                if (context.mounted) showMessage(context, 'Item marked unavailable');
              }, child: const Text('Remove Item'))),
          ]),
        ])))),
      ]);
    });
}

class _Guidelines extends StatelessWidget {
  const _Guidelines();
  @override Widget build(BuildContext context) => StreamBuilder<DatabaseEventPlaceholder>(
    stream: const Stream.empty(), builder: (context, _) => ListView(padding: const EdgeInsets.all(16), children: const [
      Text('Cafeteria Guidelines', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
      _GuidelineCard('Official University Rate List', 'Active'),
      _GuidelineCard('Prohibited & Illegal Items Policy', 'Active'),
      _GuidelineCard('Kitchen Hygiene Standards', 'Active'),
      _GuidelineCard('Removed Items Log', 'Review audit logs in Firebase'),
    ]),
  );
}
class DatabaseEventPlaceholder {}
class _GuidelineCard extends StatelessWidget {
  final String title, subtitle;
  const _GuidelineCard(this.title, this.subtitle);
  @override Widget build(BuildContext context) => Card(child: ListTile(
    title: Text(title), subtitle: Text(subtitle), trailing: const StatusBadge('Active'),
  ));
}

class _AdminProfile extends StatelessWidget {
  const _AdminProfile();
  @override Widget build(BuildContext context) => ListView(padding: const EdgeInsets.all(16), children: [
    const CircleAvatar(radius: 35, child: Icon(Icons.admin_panel_settings, size: 36)),
    const Center(child: Text('Cafeteria Oversight Committee', style: TextStyle(fontWeight: FontWeight.bold))),
    const SizedBox(height: 16),
    SwitchListTile(value: true, onChanged: (_) {}, title: const Text('Auto-Flag Overpriced Items (>20%)')),
    SwitchListTile(value: true, onChanged: (_) {}, title: const Text('Instant Vendor Remark Alerts')),
    SwitchListTile(value: true, onChanged: (_) {}, title: const Text('Daily Compliance Summary')),
    PrimaryButton('Sign Out', onPressed: () async {
      await AppServices.instance.signOut();
      if (context.mounted) Navigator.pushNamedAndRemoveUntil(context, AppRoutes.login, (_) => false);
    }),
  ]);
}
