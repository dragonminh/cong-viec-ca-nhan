import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:quan_ly_cong_viec_app/api/secure_storage_service.dart';

class ApiService {
  // IP này bạn đã tự cập nhật, tôi giữ nguyên
  static const String _baseUrl = 'http://192.168.1.17:8000/api';

  // --- HÀM XÁC THỰC ---

  static Future<Map<String, dynamic>> register(String name, String email,
      String password, String passwordConfirmation) async {
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

    final responseBody = jsonDecode(response.body);

    // SỬA LỖI: Kiểm tra statusCode
    if (response.statusCode == 201) {
      return responseBody;
    } else {
      // Ném ra lỗi để màn hình có thể bắt và hiển thị
      String errorMessage = responseBody['message'] ?? 'Đăng ký thất bại';
      if (responseBody.containsKey('errors')) {
        try {
          errorMessage = responseBody['errors'].values.first[0];
        } catch (e) {/* Bỏ qua nếu cấu trúc lỗi khác */}
      }
      throw Exception(errorMessage);
    }
  }

  static Future<Map<String, dynamic>> login(
      String email, String password) async {
    final url = Uri.parse('$_baseUrl/login');
    final response = await http.post(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
      body: jsonEncode({'email': email, 'password': password}),
    );

    final responseBody = jsonDecode(response.body);

    // SỬA LỖI: Kiểm tra statusCode
    if (response.statusCode == 200) {
      return responseBody;
    } else {
      // Ném ra lỗi để màn hình có thể bắt và hiển thị
      String errorMessage = responseBody['message'] ?? 'Đăng nhập thất bại';
      if (responseBody.containsKey('errors')) {
        try {
          errorMessage = responseBody['errors'].values.first[0];
        } catch (e) {/* Bỏ qua nếu cấu trúc lỗi khác */}
      }
      throw Exception(errorMessage);
    }
  }

  static Future<Map<String, dynamic>> getUser() async {
    final token = await SecureStorageService.readToken();
    if (token == null) throw Exception('Chưa đăng nhập');

    final url = Uri.parse('$_baseUrl/user');
    final response = await http.get(
      url,
      headers: {
        'Accept': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception(
          'Lỗi khi lấy thông tin người dùng (Token có thể hết hạn)');
    }
  }

  static Future<Map<String, dynamic>> updateProfile(
      String name, String email) async {
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
      throw Exception(errors['message'] ?? 'Cập nhật thất bại');
    }
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

    // SỬA LỖI: Kiểm tra statusCode
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      final responseBody = jsonDecode(response.body);
      throw Exception(
          responseBody['message'] ?? 'Lỗi khi tải danh sách công việc');
    }
  }

  static Future<Map<String, dynamic>> createTask(
    String title,
    String? note,
    DateTime dueDate,
    String? dueTime,
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
        'due_time': dueTime,
      }),
    );

    final responseBody = jsonDecode(response.body);

    // SỬA LỖI: Kiểm tra statusCode
    if (response.statusCode == 201) {
      return responseBody;
    } else {
      String errorMessage = responseBody['message'] ?? 'Lỗi khi tạo công việc';
      if (responseBody.containsKey('errors')) {
        try {
          errorMessage = responseBody['errors'].values.first[0];
        } catch (e) {/* Bỏ qua nếu cấu trúc lỗi khác */}
      }
      throw Exception(errorMessage);
    }
  }

  static Future<Map<String, dynamic>> updateTask(
      int taskId, Map<String, dynamic> data) async {
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
      body: jsonEncode(data),
    );

    final responseBody = jsonDecode(response.body);

    // SỬA LỖI: Kiểm tra statusCode
    if (response.statusCode == 200) {
      return responseBody;
    } else {
      String errorMessage =
          responseBody['message'] ?? 'Lỗi khi cập nhật công việc';
      if (responseBody.containsKey('errors')) {
        try {
          errorMessage = responseBody['errors'].values.first[0];
        } catch (e) {/* Bỏ qua nếu cấu trúc lỗi khác */}
      }
      throw Exception(errorMessage);
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

    // Mã 204 No Content là thành công
    if (response.statusCode != 204) {
      throw Exception('Lỗi khi xóa công việc');
    }
  }
}
