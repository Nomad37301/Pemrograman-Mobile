import 'package:flutter/material.dart';
import '../../data/services/auth_service.dart';
import 'login_page.dart';
import 'home_page.dart';

/// Splash screen yang mengecek status token.
/// Jika token ada → HomePage, jika tidak → LoginPage
class CheckAuthPage extends StatefulWidget {
  const CheckAuthPage({super.key});

  @override
  State<CheckAuthPage> createState() => _CheckAuthPageState();
}

class _CheckAuthPageState extends State<CheckAuthPage> {
  @override
  void initState() {
    super.initState();
    _checkToken();
  }

  Future<void> _checkToken() async {
    final authService = AuthService();
    final token = await authService.getToken();

    await Future.delayed(const Duration(milliseconds: 800));

    if (!mounted) return;

    if (token != null) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const HomePage()),
      );
    } else {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const LoginPage()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: CircularProgressIndicator(),
      ),
    );
  }
}
