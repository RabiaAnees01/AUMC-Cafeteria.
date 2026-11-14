import 'package:flutter/material.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Student Profile & Favorites', style: TextStyle(color: Colors.white)),
        backgroundColor: const Color(0xFF059669),
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {},
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const SizedBox(height: 10),
            const CircleAvatar(
              radius: 45,
              backgroundColor: Color(0xFFF5EFE6),
              child: Icon(Icons.person, size: 50, color: Color(0xFF4B3621)),
            ),
            const SizedBox(height: 12),
            const Text(
              'Rabia Anees',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFF111827)),
            ),
            const SizedBox(height: 4),
            const Text(
              'Roll No: 243746\nBS Software Engineering',
              textAlign: TextAlign.center,
              style: TextStyle(color: Color(0xFF6B7280), height: 1.3),
            ),
            const SizedBox(height: 25),
            const Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Saved Favorite Meals (Offline SQLite)',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF374151)),
              ),
            ),
            const SizedBox(height: 10),
            Expanded(
              child: ListView(
                children: [
                  Card(
                    elevation: 1,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    child: ListTile(
                      leading: ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Container(width: 50, height: 50, color: const Color(0xFFF5EFE6), child: const Icon(Icons.fastfood, color: Color(0xFF059669))),
                      ),
                      title: const Text('Chicken Biryani', style: TextStyle(fontWeight: FontWeight.bold)),
                      subtitle: const Text('Rs. 250'),
                      trailing: ElevatedButton(
                        style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF059669), minimumSize: const Size(80, 36)),
                        onPressed: () {},
                        child: const Text('Order Now', style: TextStyle(color: Colors.white, fontSize: 12)),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Card(
                    elevation: 1,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    child: ListTile(
                      leading: ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Container(width: 50, height: 50, color: const Color(0xFFF5EFE6), child: const Icon(Icons.fastfood, color: Color(0xFF059669))),
                      ),
                      title: const Text('Zinger Burger', style: TextStyle(fontWeight: FontWeight.bold)),
                      subtitle: const Text('Rs. 250'),
                      trailing: ElevatedButton(
                        style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF059669), minimumSize: const Size(80, 36)),
                        onPressed: () {},
                        child: const Text('Order Now', style: TextStyle(color: Colors.white, fontSize: 12)),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Colors.red),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: () => Navigator.pushReplacementNamed(context, '/login'),
                icon: const Icon(Icons.logout, color: Colors.red),
                label: const Text('Logout', style: TextStyle(color: Colors.red, fontSize: 16, fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}