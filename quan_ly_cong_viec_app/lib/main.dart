import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:quan_ly_cong_viec_app/providers/auth_provider.dart';
import 'package:quan_ly_cong_viec_app/providers/theme_provider.dart';
import 'package:quan_ly_cong_viec_app/screens/auth_check_screen.dart';
// THÊM VÀO: Import Dịch vụ Thông báo
import 'package:quan_ly_cong_viec_app/services/notification_service.dart';

void main() async {
  // Đảm bảo các plugin đã được khởi tạo trước khi chạy app
  WidgetsFlutterBinding.ensureInitialized();

  // Khởi tạo định dạng ngày tháng cho Tiếng Việt
  await initializeDateFormatting('vi_VN', null);

  // THÊM VÀO: Khởi tạo Dịch vụ Thông báo
  await NotificationService.initializeNotifications();

  runApp(
    // Sử dụng MultiProvider để cung cấp nhiều trạng thái cho ứng dụng
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ChangeNotifierProvider(create: (_) => AuthProvider()),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    // Lắng nghe thay đổi theme từ ThemeProvider
    final themeProvider = Provider.of<ThemeProvider>(context);

    return MaterialApp(
      title: 'Quản lý công việc',
      themeMode: themeProvider.themeMode,
      theme: ThemeData.light(useMaterial3: true),
      darkTheme: ThemeData.dark(useMaterial3: true),
      debugShowCheckedModeBanner: false,
      home: const AuthCheckScreen(),
    );
  }
}

