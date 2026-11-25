import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../core/app_theme.dart';
import '../core/app_routes.dart';
import '../core/models/user_model.dart';
import '../core/services/app_services.dart';
import '../core/widgets/common.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});
  @override State<SplashScreen> createState() => _SplashScreenState();
}
class _SplashScreenState extends State<SplashScreen> {
  @override void initState() { super.initState(); _go(); }
  Future<void> _go() async {
    await Future.delayed(const Duration(milliseconds: 900));
    final user = FirebaseAuth.instance.currentUser;
    if (!mounted) return;
    if (user == null) { Navigator.pushReplacementNamed(context, AppRoutes.login); return; }
    try {
      final p = await AppServices.instance.loadProfile(user.uid);
      if (!mounted) return;
      final route = p?.role == UserRole.vendor ? AppRoutes.vendor :
        p?.role == UserRole.admin ? AppRoutes.admin : AppRoutes.menu;
      Navigator.pushReplacementNamed(context, route);
    } catch (_) {
      if (mounted) Navigator.pushReplacementNamed(context, AppRoutes.login);
    }
  }
  @override Widget build(BuildContext context) => const Scaffold(
    backgroundColor: AppColors.navy,
    body: Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
      Icon(Icons.restaurant_menu, color: AppColors.amber, size: 72),
      SizedBox(height: 18),
      Text('AUMC Cafeteria', style: TextStyle(color: Colors.white, fontSize: 30, fontWeight: FontWeight.bold)),
      Text('Air University Multan Campus', style: TextStyle(color: Colors.white70)),
      SizedBox(height: 35), CircularProgressIndicator(color: AppColors.amber),
      SizedBox(height: 12), Text('Checking Firebase Session...', style: TextStyle(color: Colors.white70)),
    ])),
  );
}

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});
  @override State<LoginScreen> createState() => _LoginScreenState();
}
class _LoginScreenState extends State<LoginScreen> {
  final email = TextEditingController(), password = TextEditingController();
  bool busy = false, show = false;
  UserRole role = UserRole.student;
  Future<void> submit() async {
    if (email.text.trim().isEmpty || password.text.isEmpty) { showMessage(context, 'Enter email and password'); return; }
    setState(() => busy = true);
    try {
      final p = await AppServices.instance.signIn(email.text, password.text);
      if (!mounted) return;
      if (p.role != role && p.role != UserRole.admin) {
        await AppServices.instance.signOut();
        throw Exception('Selected role does not match this account.');
      }
      final route = p.role == UserRole.admin ? AppRoutes.admin :
        p.role == UserRole.vendor ? AppRoutes.vendor : AppRoutes.menu;
      Navigator.pushNamedAndRemoveUntil(context, route, (_) => false);
    } on FirebaseAuthException catch (e) { showMessage(context, e.message ?? 'Login failed'); }
      catch (e) { showMessage(context, e.toString().replaceFirst('Exception: ', '')); }
    finally { if (mounted) setState(() => busy = false); }
  }
  @override Widget build(BuildContext context) => Scaffold(
    backgroundColor: AppColors.navy,
    body: Center(child: SingleChildScrollView(padding: const EdgeInsets.all(24), child: Card(
      child: Padding(padding: const EdgeInsets.all(22), child: Column(mainAxisSize: MainAxisSize.min, children: [
        const Icon(Icons.restaurant, size: 46, color: AppColors.amber),
        const Text('Welcome to AUMC Cafeteria', style: TextStyle(fontSize: 21, fontWeight: FontWeight.bold)),
        const SizedBox(height: 18),
        SegmentedButton<UserRole>(segments: const [
          ButtonSegment(value: UserRole.student, label: Text('Student')),
          ButtonSegment(value: UserRole.vendor, label: Text('Vendor Staff')),
        ], selected: {role}, onSelectionChanged: (s) => setState(() => role = s.first)),
        const SizedBox(height: 16),
        TextField(controller: email, keyboardType: TextInputType.emailAddress, decoration: const InputDecoration(labelText: 'University Email', prefixIcon: Icon(Icons.email_outlined))),
        const SizedBox(height: 12),
        TextField(controller: password, obscureText: !show, decoration: InputDecoration(labelText: 'Password', prefixIcon: const Icon(Icons.lock_outline), suffixIcon: IconButton(icon: Icon(show ? Icons.visibility_off : Icons.visibility), onPressed: () => setState(() => show = !show))),
          onSubmitted: (_) => submit()),
        const SizedBox(height: 18),
        PrimaryButton(busy ? 'Signing in...' : 'Sign In with Firebase', onPressed: busy ? null : submit),
        TextButton(onPressed: () => Navigator.pushNamed(context, AppRoutes.signup), child: const Text('Create Account')),
        const Text('Admin accounts are provisioned separately.', style: TextStyle(color: AppColors.muted, fontSize: 11)),
      ])),
    ))),
  );
}

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});
  @override State<SignupScreen> createState() => _SignupScreenState();
}
class _SignupScreenState extends State<SignupScreen> {
  final name = TextEditingController(), roll = TextEditingController(),
    email = TextEditingController(), password = TextEditingController();
  UserRole role = UserRole.student;
  bool busy = false;
  Future<void> submit() async {
    if ([name.text, email.text, password.text].any((e) => e.trim().isEmpty) ||
        (role == UserRole.student && roll.text.trim().isEmpty)) {
      showMessage(context, 'Please complete all required fields'); return;
    }
    if (password.text.length < 6) { showMessage(context, 'Password must contain at least 6 characters'); return; }
    setState(() => busy = true);
    try {
      final p = await AppServices.instance.signUp(name: name.text, email: email.text,
        password: password.text, rollNumber: roll.text, role: role);
      if (!mounted) return;
      Navigator.pushNamedAndRemoveUntil(context,
        p.role == UserRole.vendor ? AppRoutes.vendor : AppRoutes.menu, (_) => false);
    } on FirebaseAuthException catch (e) { showMessage(context, e.message ?? 'Registration failed'); }
      catch (e) { showMessage(context, e.toString().replaceFirst('Exception: ', '')); }
    finally { if (mounted) setState(() => busy = false); }
  }
  @override Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Create Account')),
    body: SingleChildScrollView(padding: const EdgeInsets.all(20), child: Card(child: Padding(
      padding: const EdgeInsets.all(18), child: Column(children: [
        TextField(controller: name, decoration: const InputDecoration(labelText: 'Full Name')),
        const SizedBox(height: 12),
        TextField(controller: roll, decoration: const InputDecoration(labelText: 'University Roll No (students)')),
        const SizedBox(height: 12),
        TextField(controller: email, keyboardType: TextInputType.emailAddress, decoration: const InputDecoration(labelText: 'AU Email')),
        const SizedBox(height: 12),
        TextField(controller: password, obscureText: true, decoration: const InputDecoration(labelText: 'Password')),
        const SizedBox(height: 16),
        SegmentedButton<UserRole>(segments: const [
          ButtonSegment(value: UserRole.student, label: Text('Student')),
          ButtonSegment(value: UserRole.vendor, label: Text('Vendor')),
        ], selected: {role}, onSelectionChanged: (s) => setState(() => role = s.first)),
        const SizedBox(height: 18),
        PrimaryButton(busy ? 'Registering...' : 'Register Account', onPressed: busy ? null : submit),
      ]),
    ))),
  );
}

