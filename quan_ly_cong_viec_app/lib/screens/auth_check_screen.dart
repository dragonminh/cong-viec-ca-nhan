import 'package:flutter/material.dart';
import 'package:quan_ly_cong_viec_app/api/secure_storage_service.dart';
import 'package:quan_ly_cong_viec_app/screens/home_screen.dart';
import 'package:quan_ly_cong_viec_app/screens/login_screen.dart';

class AuthCheckScreen extends StatefulWidget {
  // ===== SỬA LẠI DÒNG NÀY =====
  // Thêm "const" và sử dụng "super.key" theo chuẩn mới.
  const AuthCheckScreen({super.key});

  @override
  State<AuthCheckScreen> createState() => _AuthCheckScreenState();
}

class _AuthCheckScreenState extends State<AuthCheckScreen> {
  @override
  void initState() {
    super.initState();
    _checkAuthStatus();
  }

  Future<void> _checkAuthStatus() async {
    final token = await SecureStorageService.readToken();
    await Future.delayed(const Duration(seconds: 1));

    if (!mounted) return;

    if (token != null) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (context) => const HomeScreen()),
      );
    } else {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (context) => const LoginScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(body: Center(child: CircularProgressIndicator()));
  }
}
