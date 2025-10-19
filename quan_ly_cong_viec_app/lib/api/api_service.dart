import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:quan_ly_cong_viec_app/api/secure_storage_service.dart';
import 'package:quan_ly_cong_viec_app/models/task.dart';

class ApiService {
  // Hãy đảm bảo địa chỉ IP này vẫn đúng với máy tính của bạn
  static const String _baseUrl = 'http://192.168.1.112:8000/api';

  // --- CÁC HÀM XÁC THỰC ---
  static Future<Map<String, dynamic>> register(
    String name,
    String email,
    String password,
    String passwordConfirmation,
  ) async {
    final url = Uri.parse('$_baseUrl/register');
    final response = await http.post(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
      body: jsonEncode({
        'name': name,
        'email': email,
        'password': password,
        'password_confirmation': passwordConfirmation,
      }),
    );
    return jsonDecode(response.body);
  }

  static Future<Map<String, dynamic>> login(
    String email,
    String password,
  ) async {
    final url = Uri.parse('$_baseUrl/login');
    final response = await http.post(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
      body: jsonEncode({'email': email, 'password': password}),
    );
    return jsonDecode(response.body);
  }

  // --- CÁC HÀM QUẢN LÝ CÔNG VIỆC ---
  static Future<List<dynamic>> getTasks() async {
    final token = await SecureStorageService.readToken();
    if (token == null) throw Exception('Chưa đăng nhập');
    final url = Uri.parse('$_baseUrl/tasks');
    final response = await http.get(
      url,
      headers: {'Accept': 'application/json', 'Authorization': 'Bearer $token'},
    );
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Lỗi khi tải danh sách công việc');
    }
  }

  static Future<Map<String, dynamic>> createTask(
    String title,
    String? note,
    DateTime dueDate,
  ) async {
    final token = await SecureStorageService.readToken();
    if (token == null) throw Exception('Chưa đăng nhập');
    final formattedDate = DateFormat('yyyy-MM-dd').format(dueDate);
    final url = Uri.parse('$_baseUrl/tasks');
    final response = await http.post(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({
        'title': title,
        'note': note,
        'due_date': formattedDate,
      }),
    );
    if (response.statusCode == 201) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Lỗi khi tạo công việc mới');
    }
  }

  static Future<Map<String, dynamic>> updateTask(
    int taskId,
    String title,
    String? note,
    DateTime dueDate,
  ) async {
    final token = await SecureStorageService.readToken();
    if (token == null) throw Exception('Chưa đăng nhập');
    final formattedDate = DateFormat('yyyy-MM-dd').format(dueDate);
    final url = Uri.parse('$_baseUrl/tasks/$taskId');
    final response = await http.put(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({
        'title': title,
        'note': note,
        'due_date': formattedDate,
      }),
    );
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Lỗi khi cập nhật công việc');
    }
  }

  static Future<Map<String, dynamic>> updateTaskStatus(
    int taskId,
    bool isCompleted,
  ) async {
    final token = await SecureStorageService.readToken();
    if (token == null) throw Exception('Chưa đăng nhập');
    final url = Uri.parse('$_baseUrl/tasks/$taskId');
    final response = await http.put(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({'is_completed': isCompleted}),
    );
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Lỗi khi cập nhật trạng thái công việc');
    }
  }

  static Future<void> deleteTask(int taskId) async {
    final token = await SecureStorageService.readToken();
    if (token == null) throw Exception('Chưa đăng nhập');
    final url = Uri.parse('$_baseUrl/tasks/$taskId');
    final response = await http.delete(
      url,
      headers: {'Accept': 'application/json', 'Authorization': 'Bearer $token'},
    );
    if (response.statusCode != 204) {
      throw Exception('Lỗi khi xóa công việc');
    }
  }

  // --- HÀM CẬP NHẬT THÔNG TIN CÁ NHÂN ---
  static Future<Map<String, dynamic>> updateProfile(String name, String email) async {
    final token = await SecureStorageService.readToken();
    if (token == null) throw Exception('Chưa đăng nhập');

    final url = Uri.parse('$_baseUrl/user/profile');
    final response = await http.put(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({
        'name': name,
        'email': email,
      }),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      final errors = jsonDecode(response.body);
      // Ném ra lỗi cụ thể hơn từ server
      throw Exception(errors['message'] ?? 'Cập nhật thất bại');
    }
  }
}
