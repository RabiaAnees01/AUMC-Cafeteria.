import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../core/app_routes.dart';
import '../core/models/user_model.dart';
import '../core/services/app_services.dart';
import '../core/app_theme.dart';
import '../core/widgets/common.dart';

class AppDrawer extends StatelessWidget {
  const AppDrawer({super.key});
  @override Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    return Drawer(child: SafeArea(child: FutureBuilder<UserModel?>(
      future: uid == null ? Future.value(null) : AppServices.instance.loadProfile(uid),
      builder: (context, s) {
        final p = s.data;
        return Column(children: [
          Container(width: double.infinity, padding: const EdgeInsets.all(20),
            color: AppColors.navy, child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const CircleAvatar(radius: 28, child: Icon(Icons.person)),
              const SizedBox(height: 10),
              Text(p?.fullName ?? 'AUMC User', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              Text('Roll No: ${p?.rollNumber ?? 'N/A'}', style: const TextStyle(color: Colors.white70)),
              const SizedBox(height: 8), const StatusBadge('Offline Ready'),
            ])),
          _link(context, Icons.restaurant_menu, 'Menu Catalog', AppRoutes.menu),
          _link(context, Icons.shopping_cart, 'Checkout Cart', AppRoutes.checkout),
          _link(context, Icons.track_changes, 'Live Tracking', AppRoutes.liveTrack),
          _link(context, Icons.storage, 'Offline Database', AppRoutes.offlineDb),
          if (p?.role == UserRole.vendor) _link(context, Icons.kitchen, 'Vendor Dashboard', AppRoutes.vendor),
          if (p?.role == UserRole.admin) _link(context, Icons.admin_panel_settings, 'Admin Portal', AppRoutes.admin),
          const Spacer(),
          ListTile(leading: const Icon(Icons.logout, color: AppColors.red), title: const Text('Logout'),
            onTap: () async { await AppServices.instance.signOut(); if (context.mounted) Navigator.pushNamedAndRemoveUntil(context, AppRoutes.login, (_) => false); }),
        ]);
      },
    )));
  }
  Widget _link(BuildContext c, IconData icon, String label, String route) =>
    ListTile(leading: Icon(icon), title: Text(label), onTap: () { Navigator.pop(c); Navigator.pushNamed(c, route); });
}

