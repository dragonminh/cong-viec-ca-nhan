import 'package:flutter/material.dart';
import 'package:quan_ly_cong_viec_app/models/user.dart';

// Lớp này sẽ quản lý và cung cấp thông tin người dùng cho toàn bộ ứng dụng
class AuthProvider with ChangeNotifier {
  User? _currentUser;

  User? get user => _currentUser;

  // Hàm này được gọi khi người dùng đăng nhập thành công
  // hoặc khi thông tin người dùng được cập nhật
  void setUser(User user) {
    _currentUser = user;
    // Thông báo cho tất cả các widget đang "lắng nghe" rằng dữ liệu đã thay đổi
    notifyListeners();
  }

  // Hàm này để xóa thông tin người dùng khi đăng xuất
  void clearUser() {
    _currentUser = null;
    notifyListeners();
  }
}