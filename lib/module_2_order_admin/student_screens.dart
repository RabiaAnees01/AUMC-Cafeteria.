import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'dart:convert';
import '../../module_3_tracking_vendor_sqlite/sqlite_helper.dart';
import '../core/app_routes.dart';
import '../core/app_theme.dart';
import '../core/models/food_item_model.dart';
import '../core/models/order_model.dart';
import '../core/services/app_services.dart';
import '../core/services/cart_provider.dart';
import '../core/widgets/common.dart';
import '../module_1_auth_nav/custom_drawer.dart';

class MenuCatalogScreen extends StatefulWidget {
  const MenuCatalogScreen({super.key});
  @override State<MenuCatalogScreen> createState() => _MenuCatalogScreenState();
}
class _MenuCatalogScreenState extends State<MenuCatalogScreen> {
  String category = 'All', search = '';
  @override Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('AUMC Cafeteria'), actions: [
      IconButton(onPressed: () => Navigator.pushNamed(context, AppRoutes.checkout),
        icon: const Icon(Icons.shopping_cart_outlined)),
    ]),
    drawer: const AppDrawer(),
    body: Column(children: [
      Container(color: AppColors.navy, padding: const EdgeInsets.fromLTRB(16, 0, 16, 18), child: Column(children: [
        Align(alignment: Alignment.centerLeft, child: Text('Salam, ${FirebaseAuth.instance.currentUser?.displayName ?? 'Student'}',
          style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold))),
        const SizedBox(height: 12),
        TextField(onChanged: (v) => setState(() => search = v.toLowerCase()),
          decoration: const InputDecoration(hintText: 'Search food...', prefixIcon: Icon(Icons.search), fillColor: Colors.white)),
      ])),
      FutureBuilder<List<Map<String, dynamic>>>(future: AppServices.instance.loadDeals(), builder: (context, s) {
        final deal = s.data?.first;
        return Container(margin: const EdgeInsets.all(12), padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(color: AppColors.amber, borderRadius: BorderRadius.circular(16)),
          child: Row(children: [const Icon(Icons.local_offer, size: 32),
            const SizedBox(width: 10), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(deal?['title']?.toString() ?? 'Lecture Break Deal', style: const TextStyle(fontWeight: FontWeight.bold)),
              Text(deal?['description']?.toString() ?? 'Special cafeteria offer'),
            ])),
          ]));
      }),
      SingleChildScrollView(scrollDirection: Axis.horizontal, padding: const EdgeInsets.symmetric(horizontal: 10),
        child: Row(children: ['All', 'Fast Food', 'Desi/Meals', 'Beverages'].map((c) => Padding(
          padding: const EdgeInsets.only(right: 6), child: ChoiceChip(label: Text(c), selected: category == c,
            onSelected: (_) => setState(() => category = c)))).toList())),
      Expanded(child: StreamBuilder<List<FoodItemModel>>(
        stream: AppServices.instance.watchFood(),
        builder: (context, s) {
          if (s.hasError) return const Center(child: Text('Could not load menu. Check Firebase rules.'));
          if (!s.hasData) return const Center(child: CircularProgressIndicator());
          final items = s.data!.where((f) => (category == 'All' || f.category == category) &&
            f.name.toLowerCase().contains(search)).toList();
          if (items.isEmpty) return const Center(child: Text('No food items found. Add menu items in Firebase.'));
          return GridView.builder(padding: const EdgeInsets.all(10), gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2, childAspectRatio: .72, crossAxisSpacing: 8, mainAxisSpacing: 8),
            itemCount: items.length, itemBuilder: (context, i) => _FoodCard(food: items[i]));
        },
      )),
    ]),
    bottomNavigationBar: BottomNavigationBar(currentIndex: 0, onTap: (i) {
      if (i == 1) Navigator.pushNamed(context, AppRoutes.checkout);
      if (i == 2) Navigator.pushNamed(context, AppRoutes.offlineDb);
    }, items: const [
      BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
      BottomNavigationBarItem(icon: Icon(Icons.shopping_cart), label: 'Cart'),
      BottomNavigationBarItem(icon: Icon(Icons.storage), label: 'Offline'),
      BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
    ]),
  );
}
class _FoodCard extends StatelessWidget {
  final FoodItemModel food;
  const _FoodCard({required this.food});
  @override Widget build(BuildContext context) => Card(clipBehavior: Clip.antiAlias, child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
    Expanded(child: food.imageUrl.isEmpty
      ? Container(color: const Color(0xFFE8EEF5), child: const Center(child: Icon(Icons.fastfood, size: 48, color: AppColors.navy)))
      : Image.network(food.imageUrl, width: double.infinity, fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => const Center(child: Icon(Icons.fastfood, size: 42)))),
    Padding(padding: const EdgeInsets.all(8), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(food.name, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.bold)),
      Text('Rs. ${food.price.toStringAsFixed(0)}'),
      Row(children: [StatusBadge(food.inStock ? 'In Stock' : 'Out of Stock', color: food.inStock ? AppColors.green : AppColors.red),
        const Spacer(),
        IconButton(tooltip: 'Save favorite', onPressed: () async {
          await SqliteHelper.instance.addFavorite(food.id, food.name, jsonEncode(food.toMap()));
          if (context.mounted) showMessage(context, 'Saved to offline favorites');
        }, icon: const Icon(Icons.favorite_border, color: AppColors.red)),
        IconButton(onPressed: food.inStock ? () {
          Navigator.pushNamed(context, AppRoutes.foodDetails, arguments: food);
        } : null, icon: const Icon(Icons.add_circle, color: AppColors.amber))]),
    ])),
  ]));
}

class FoodDetailsScreen extends StatefulWidget {
  const FoodDetailsScreen({super.key});
  @override State<FoodDetailsScreen> createState() => _FoodDetailsScreenState();
}
class _FoodDetailsScreenState extends State<FoodDetailsScreen> {
  String spice = 'Regular';
  final Set<String> selected = {};
  int quantity = 1;
  @override Widget build(BuildContext context) {
    final food = ModalRoute.of(context)?.settings.arguments as FoodItemModel?;
    if (food == null) return const Scaffold(body: Center(child: Text('Food item not selected. Open from menu.')));
    final addons = food.addons.where((a) => selected.contains(a.id)).toList();
    final total = (food.price + addons.fold<double>(0, (s, a) => s + a.price)) * quantity;
    return Scaffold(appBar: AppBar(title: const Text('Food Details')), body: ListView(padding: const EdgeInsets.all(16), children: [
      ClipRRect(borderRadius: BorderRadius.circular(18), child: SizedBox(height: 220, child: food.imageUrl.isEmpty
        ? Container(color: Colors.blueGrey.shade100, child: const Icon(Icons.fastfood, size: 80))
        : Image.network(food.imageUrl, fit: BoxFit.cover, errorBuilder: (_, __, ___) => const Icon(Icons.fastfood, size: 80)))),
      const SizedBox(height: 14), Text(food.name, style: const TextStyle(fontSize: 23, fontWeight: FontWeight.bold)),
      Text('Rs. ${food.price.toStringAsFixed(0)}', style: const TextStyle(fontSize: 20)),
      Text(food.description),
      const SizedBox(height: 16), const Text('Spice Level', style: TextStyle(fontWeight: FontWeight.bold)),
      RadioListTile<String>(value: 'Regular', groupValue: spice, onChanged: (v) => setState(() => spice = v!), title: const Text('Regular'), dense: true),
      RadioListTile<String>(value: 'Extra Spicy', groupValue: spice, onChanged: (v) => setState(() => spice = v!), title: const Text('Extra Spicy'), dense: true),
      const Text('Add-ons', style: TextStyle(fontWeight: FontWeight.bold)),
      ...food.addons.map((a) => CheckboxListTile(value: selected.contains(a.id),
        onChanged: (v) => setState(() => v == true ? selected.add(a.id) : selected.remove(a.id)),
        title: Text('${a.name}  +Rs. ${a.price.toStringAsFixed(0)}'), dense: true)),
      Row(children: [const Text('Quantity'), const Spacer(),
        IconButton(onPressed: quantity > 1 ? () => setState(() => quantity--) : null, icon: const Icon(Icons.remove_circle_outline)),
        Text('$quantity'), IconButton(onPressed: () => setState(() => quantity++), icon: const Icon(Icons.add_circle_outline))]),
      PrimaryButton('Add to Cart - Rs. ${total.toStringAsFixed(0)}', onPressed: () {
        context.read<CartProvider>().add(food, quantity: quantity, spice: spice, addons: addons);
        showMessage(context, 'Added to cart');
        Navigator.pushNamed(context, AppRoutes.checkout);
      }),
    ]));
  }
}

class CartCheckoutScreen extends StatefulWidget {
  const CartCheckoutScreen({super.key});
  @override State<CartCheckoutScreen> createState() => _CartCheckoutScreenState();
}
class _CartCheckoutScreenState extends State<CartCheckoutScreen> {
  final formKey = GlobalKey<FormState>();
  final roll = TextEditingController(), note = TextEditingController();
  String slot = '11:30 AM Lecture Break';
  bool wallet = false, busy = false;
  final slots = const ['11:30 AM Lecture Break', '01:00 PM Lunch Break', '03:00 PM Afternoon Break'];
  Future<void> place() async {
    final cart = context.read<CartProvider>();
    if (cart.items.isEmpty) { showMessage(context, 'Your cart is empty'); return; }
    if (!formKey.currentState!.validate()) return;
    setState(() => busy = true);
    try {
      final uid = FirebaseAuth.instance.currentUser!.uid;
      final id = AppServices.instance.db.ref('orders').push().key!;
      final token = 'AUMC-${roll.text.trim()}-${id.substring(0, 5).toUpperCase()}';
      final order = OrderModel(orderId: id, userId: uid, rollNumber: roll.text.trim(),
        items: cart.items, totalAmount: cart.total, pickupSlot: slot,
        specialNote: note.text.trim(), paymentMethod: wallet ? 'Mobile Wallet / Pay at Pickup' : 'Pay at Pickup',
        qrToken: token, createdAt: DateTime.now().millisecondsSinceEpoch);
      await showDialog(context: context, builder: (d) => AlertDialog(
        title: const Text('Confirm Pre-Order?'),
        content: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Roll Number: ${roll.text}'), Text('Pickup Slot: $slot'),
          Text('Total Amount: Rs. ${cart.total.toStringAsFixed(0)}'),
        ]),
        actions: [TextButton(onPressed: () => Navigator.pop(d, false), child: const Text('Cancel')),
          ElevatedButton(onPressed: () => Navigator.pop(d, true), child: const Text('Confirm Order'))],
      )).then((ok) async {
        if (ok != true) return;
        await AppServices.instance.createOrder(order);
        await SqliteHelper.instance.saveOrder(id, jsonEncode(order.toMap()), order.createdAt);
        cart.clear();
        if (!mounted) return;
        showMessage(context, 'Order #${id.substring(0, 7)} placed!');
        Navigator.pushNamed(context, AppRoutes.liveTrack, arguments: id);
      });
    } catch (e) { if (mounted) showMessage(context, 'Order failed: $e'); }
    finally { if (mounted) setState(() => busy = false); }
  }
  @override Widget build(BuildContext context) {
    final cart = context.watch<CartProvider>();
    return Scaffold(appBar: AppBar(title: const Text('Cart & Pre-Order Form')),
      body: Form(key: formKey, child: ListView(padding: const EdgeInsets.all(16), children: [
        if (cart.items.isEmpty) const Padding(padding: EdgeInsets.all(24), child: Center(child: Text('Your cart is empty'))),
        ...cart.items.map((item) => Card(child: ListTile(
          title: Text(item.name), subtitle: Text('Rs. ${item.unitPrice.toStringAsFixed(0)} each'),
          trailing: Row(mainAxisSize: MainAxisSize.min, children: [
            IconButton(onPressed: () => cart.changeQuantity(item, -1), icon: const Icon(Icons.remove_circle_outline)),
            Text('${item.quantity}'),
            IconButton(onPressed: () => cart.changeQuantity(item, 1), icon: const Icon(Icons.add_circle_outline)),
          ]),
        ))),
        const SizedBox(height: 12),
        TextFormField(controller: roll, decoration: const InputDecoration(labelText: 'Student Roll Number'),
          validator: (v) => v == null || v.trim().isEmpty ? 'Enter roll number' : null),
        const SizedBox(height: 12),
        DropdownButtonFormField<String>(value: slot, decoration: const InputDecoration(labelText: 'Pickup Break Slot'),
          items: slots.map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(),
          onChanged: (v) => setState(() => slot = v!)),
        const SizedBox(height: 12),
        TextFormField(controller: note, maxLines: 2, decoration: const InputDecoration(labelText: 'Special Kitchen Note')),
        SwitchListTile(title: const Text('Mobile Wallet / Pay at Pickup'), value: wallet, onChanged: (v) => setState(() => wallet = v)),
        const SizedBox(height: 12),
        Text('Total: Rs. ${cart.total.toStringAsFixed(0)}', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
        PrimaryButton(busy ? 'Placing Order...' : 'Place Pre-Order & Generate QR', onPressed: busy ? null : place),
      ])),
    );
  }
}
