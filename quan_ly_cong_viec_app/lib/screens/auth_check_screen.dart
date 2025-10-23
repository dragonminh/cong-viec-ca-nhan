// file: lib/screens/auth_check_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:quan_ly_cong_viec_app/api/secure_storage_service.dart';
import 'package:quan_ly_cong_viec_app/providers/auth_provider.dart';
import 'package:quan_ly_cong_viec_app/screens/home_screen.dart'; // <-- Sẽ tạo sau
import 'package:quan_ly_cong_viec_app/screens/login_screen.dart'; // <-- Sẽ tạo sau
import 'package:quan_ly_cong_viec_app/api/api_service.dart'; // <-- Cần để gọi API
import 'package:quan_ly_cong_viec_app/models/user.dart'; // <-- Import model User

class AuthCheckScreen extends StatefulWidget {
  const AuthCheckScreen({super.key});

  @override
  State<AuthCheckScreen> createState() => _AuthCheckScreenState();
}

class _AuthCheckScreenState extends State<AuthCheckScreen> {
  @override
  void initState() {
    super.initState();
    _checkAuthentication();
  }

  Future<void> _checkAuthentication() async {
    // Đợi 1 chút để màn hình build xong
    await Future.delayed(const Duration(milliseconds: 50));

    final token = await SecureStorageService.readToken();
    
    if (token == null) {
      // Không có token, chuyển đến màn hình Đăng nhập
      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => const LoginScreen()), // Sẽ lỗi vì chưa tạo LoginScreen
        );
      }
      return;
    }

    // Có token, thử lấy thông tin user để xác thực
    try {
      // Vì ApiService là static, ta không cần khai báo
      // Nhưng ta cần một hàm để lấy user, hãy thêm nó vào ApiService
      
      // Giả sử chúng ta chưa có hàm getUser, ta sẽ tạm thời chuyển đến HomeScreen
      // và sẽ cập nhật logic này sau.
      // TỐT HƠN: chúng ta sẽ thêm hàm getUser vào ApiService

      // --- Tạm thời bỏ qua phần xác thực user, đi thẳng tới home ---
      // (Chúng ta sẽ làm việc này ở bước sau, khi làm LoginScreen)

       if (mounted) {
         Navigator.of(context).pushReplacement(
           MaterialPageRoute(builder: (context) => const LoginScreen()), // Tạm thời vẫn về Login
         );
       }
      
    } catch (e) {
      // Token có thể đã hết hạn, xóa token cũ và về màn hình Login
      await SecureStorageService.deleteToken();
      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => const LoginScreen()),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Màn hình loading tạm thời
    return const Scaffold(
      body: Center(
        child: CircularProgressIndicator(),
      ),
    );
  }
}