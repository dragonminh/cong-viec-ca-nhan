import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:quan_ly_cong_viec_app/providers/theme_provider.dart';
import 'package:quan_ly_cong_viec_app/api/secure_storage_service.dart';
import 'package:quan_ly_cong_viec_app/screens/login_screen.dart';
import 'package:quan_ly_cong_viec_app/models/user.dart';
import 'package:quan_ly_cong_viec_app/providers/auth_provider.dart';
import 'package:quan_ly_cong_viec_app/screens/edit_profile_screen.dart';
import 'package:quan_ly_cong_viec_app/services/notification_service.dart';
// ĐÃ XÓA import '...flutter_gen...'

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  String _themeModeToString(ThemeMode themeMode) {
    switch (themeMode) {
      case ThemeMode.light:
        return 'Sáng';
      case ThemeMode.dark:
        return 'Tối';
      case ThemeMode.system:
        return 'Theo hệ thống';
    }
  }

  void _showThemeDialog(BuildContext context, ThemeProvider themeProvider) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Chọn giao diện'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              RadioListTile<ThemeMode>(
                title: const Text('Sáng'),
                value: ThemeMode.light,
                groupValue: themeProvider.themeMode,
                onChanged: (newMode) {
                  if (newMode != null) {
                    themeProvider.setTheme(newMode);
                    Navigator.of(context).pop();
                  }
                },
              ),
              RadioListTile<ThemeMode>(
                title: const Text('Tối'),
                value: ThemeMode.dark,
                groupValue: themeProvider.themeMode,
                onChanged: (newMode) {
                  if (newMode != null) {
                    themeProvider.setTheme(newMode);
                    Navigator.of(context).pop();
                  }
                },
              ),
              RadioListTile<ThemeMode>(
                title: const Text('Theo hệ thống'),
                value: ThemeMode.system,
                groupValue: themeProvider.themeMode,
                onChanged: (newMode) {
                  if (newMode != null) {
                    themeProvider.setTheme(newMode);
                    Navigator.of(context).pop();
                  }
                },
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final authProvider = Provider.of<AuthProvider>(context);
    final currentUser = authProvider.user;

    // ĐÃ XÓA 'final localizations = ...'

    return Scaffold(
      // ĐÃ SỬA LẠI AppBar
      appBar: AppBar(title: const Text('Cài đặt')), 
      body: ListView(
        children: [
          ListTile(
            leading: const Icon(Icons.brightness_6),
            title: const Text('Giao diện'), // Dùng chữ cứng
            subtitle: Text(_themeModeToString(themeProvider.themeMode)),
            onTap: () {
              _showThemeDialog(context, themeProvider);
            },
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.language),
            title: const Text('Ngôn ngữ'), // Dùng chữ cứng
            subtitle: const Text('Tiếng Việt'),
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text(
                    'Chức năng đổi ngôn ngữ sẽ được phát triển sau.',
                  ),
                ),
              );
            },
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.person_outline),
            title: const Text('Thông tin tài khoản'), // Dùng chữ cứng
            subtitle: Text(currentUser != null
                ? 'Thay đổi ${currentUser.name}, ${currentUser.email}'
                : 'Không có thông tin'),
            onTap: () async {
              if (currentUser == null) {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                    content: Text('Không thể tải thông tin người dùng.')));
                return;
              }
              final updatedUser = await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) =>
                      EditProfileScreen(currentUser: currentUser),
                ),
              );

              // Sửa lỗi: Đảm bảo authProvider được truy cập đúng cách
              if (updatedUser != null && updatedUser is User && context.mounted) {
                Provider.of<AuthProvider>(context, listen: false).setUser(updatedUser);
              }
            },
          ),
          const Divider(),
          ListTile(
            leading:
                const Icon(Icons.notification_add_outlined, color: Colors.blue),
            title: const Text('Gửi thông báo thử nghiệm'), // Dùng chữ cứng
            onTap: () {
              NotificationService.showTestNotification();
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                  content: Text(
                      'Đã gửi yêu cầu thông báo! Hãy kiểm tra thanh trạng thái.')));
            },
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.logout, color: Colors.red),
            title: const Text( // Dùng chữ cứng
              'Đăng xuất',
              style: TextStyle(color: Colors.red),
            ),
            onTap: () async {
              // Sửa lỗi: Đảm bảo authProvider được truy cập đúng cách
              Provider.of<AuthProvider>(context, listen: false).clearUser();
              await SecureStorageService.deleteToken();

              if (context.mounted) {
                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(builder: (context) => const LoginScreen()),
                  (Route<dynamic> route) => false,
                );
              }
            },
          ),
        ],
      ),
    );
  }
}