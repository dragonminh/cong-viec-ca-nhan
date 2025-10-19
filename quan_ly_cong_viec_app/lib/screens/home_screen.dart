import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:table_calendar/table_calendar.dart'; // Thư viện lịch
import 'package:quan_ly_cong_viec_app/api/api_service.dart';
import 'package:quan_ly_cong_viec_app/api/secure_storage_service.dart';
import 'package:quan_ly_cong_viec_app/models/task.dart';
import 'package:quan_ly_cong_viec_app/screens/login_screen.dart';
import 'package:quan_ly_cong_viec_app/screens/add_task_screen.dart';
import 'package:quan_ly_cong_viec_app/screens/settings_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  // --- BIẾN TRẠNG THÁI ---
  List<Task> _allTasks = []; // Chứa TẤT CẢ công việc của người dùng
  bool _isLoading = true;

  // Các biến mới để quản lý lịch
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;

  @override
  void initState() {
    super.initState();
    _selectedDay = _focusedDay; // Mặc định chọn ngày hôm nay
    _fetchTasks();
  }

  // --- CÁC HÀM XỬ LÝ LOGIC ---

  // Tải tất cả công việc từ server
  Future<void> _fetchTasks() async {
    if (mounted)
      setState(() {
        _isLoading = true;
      });
    try {
      final data = await ApiService.getTasks();
      final tasks = data.map((taskJson) => Task.fromJson(taskJson)).toList();
      if (mounted) {
        setState(() {
          _allTasks = tasks;
          _isLoading = false;
        });
      }
    } catch (e) {
      // (Xử lý lỗi không đổi)
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Không thể tải công việc: $e')));
      }
    }
  }

  // Lọc và trả về danh sách công việc cho một ngày cụ thể
  List<Task> _getTasksForDay(DateTime day) {
    return _allTasks.where((task) {
      // So sánh ngày của công việc với ngày được chọn trên lịch
      try {
        final taskDate = DateFormat('yyyy-MM-dd').parse(task.dueDate);
        return isSameDay(taskDate, day);
      } catch (e) {
        return false;
      }
    }).toList();
  }

  // Chuyển đến màn hình Thêm công việc, gửi kèm ngày đã chọn trên lịch
  void _navigateToAddTaskScreen() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AddTaskScreen(initialDate: _selectedDay),
      ),
    );
    // Nếu thêm thành công, tải lại toàn bộ danh sách
    if (result == true) {
      _fetchTasks();
    }
  }

  void _logout(BuildContext context) async {
    await SecureStorageService.deleteToken();
    if (!mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (context) => const LoginScreen()),
      (Route<dynamic> route) => false,
    );
  }

  Future<void> _toggleTaskStatus(Task task, bool? newValue) async {
    if (newValue == null) return;
    final originalStatus = task.isCompleted;
    setState(() {
      task.isCompleted = newValue;
    });
    try {
      await ApiService.updateTaskStatus(task.id, newValue);
    } catch (e) {
      setState(() {
        task.isCompleted = originalStatus;
      });
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Cập nhật thất bại: $e')));
    }
  }

  Future<void> _deleteTask(Task task) async {
    final originalTasks = List<Task>.from(_allTasks);
    setState(() {
      _allTasks.removeWhere((t) => t.id == task.id);
    });
    try {
      await ApiService.deleteTask(task.id);
    } catch (e) {
      setState(() {
        _allTasks = originalTasks;
      });
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Xóa thất bại: $e')));
    }
  }

  // --- HÀM XÂY DỰNG GIAO DIỆN ---
  @override
  Widget build(BuildContext context) {
    // Lấy danh sách công việc cho ngày đang được chọn
    final selectedDayTasks = _selectedDay != null
        ? _getTasksForDay(_selectedDay!)
        : [];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Lịch công việc'),
        actions: [
          // Nút để quay về ngày hôm nay
          IconButton(
            tooltip: 'Về hôm nay',
            icon: const Icon(Icons.today),
            onPressed: () {
              setState(() {
                _focusedDay = DateTime.now();
                _selectedDay = _focusedDay;
              });
            },
          ),
          IconButton(
            tooltip: 'Đăng xuất',
            icon: const Icon(Icons.logout),
            onPressed: () => _logout(context),
          ),
        ],
      ),
      body: Column(
        children: [
          // ===== PHẦN LỊCH =====
          TableCalendar(
            locale: 'vi_VN',
            firstDay: DateTime.utc(2020, 1, 1),
            lastDay: DateTime.utc(2030, 12, 31),
            focusedDay: _focusedDay,
            headerStyle: const HeaderStyle(
              formatButtonVisible: false,
              titleCentered: true,
            ),
            selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
            onDaySelected: (selectedDay, focusedDay) {
              setState(() {
                _selectedDay = selectedDay;
                _focusedDay = focusedDay;
              });
            },
            onPageChanged: (focusedDay) {
              _focusedDay = focusedDay;
            },
            // Thêm dấu chấm dưới những ngày có công việc
            eventLoader: _getTasksForDay,
          ),
          const Divider(height: 1),

          // ===== PHẦN DANH SÁCH CÔNG VIỆC CỦA NGÀY ĐÃ CHỌN =====
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : ListView.builder(
                    itemCount: selectedDayTasks.length,
                    itemBuilder: (context, index) {
                      final task = selectedDayTasks[index];
                      return Dismissible(
                        key: ValueKey(task.id),
                        direction: DismissDirection.endToStart,
                        onDismissed: (direction) => _deleteTask(task),
                        background: Container(
                          color: Colors.red,
                          alignment: Alignment.centerRight,
                          padding: const EdgeInsets.only(right: 20.0),
                          child: const Icon(Icons.delete, color: Colors.white),
                        ),
                        child: ListTile(
                          // ===== THÊM HÀNH ĐỘNG SỬA KHI NHẤN VÀO ĐÂY =====
                          onTap: () async {
                            final result = await Navigator.push(
                              context,
                              MaterialPageRoute(
                                // Gửi công việc hiện tại sang màn hình sửa
                                builder: (context) =>
                                    AddTaskScreen(taskToEdit: task),
                              ),
                            );
                            // Nếu sửa thành công, làm mới danh sách
                            if (result == true) {
                              _fetchTasks();
                            }
                          },
                          // ===============================================
                          leading: Checkbox(
                            value: task.isCompleted,
                            onChanged: (value) =>
                                _toggleTaskStatus(task, value),
                          ),
                          title: Text(
                            task.title,
                            style: TextStyle(
                              decoration: task.isCompleted
                                  ? TextDecoration.lineThrough
                                  : TextDecoration.none,
                            ),
                          ),
                          subtitle: task.note != null && task.note!.isNotEmpty
                              ? Text(task.note!)
                              : null,
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),

      // ===== PHẦN THANH ĐIỀU HƯỚNG DƯỚI CÙNG (GIỮ NGUYÊN) =====
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      floatingActionButton: FloatingActionButton(
        onPressed: _navigateToAddTaskScreen,
        shape: const CircleBorder(),
        child: const Icon(Icons.add),
      ),
      bottomNavigationBar: BottomAppBar(
        shape: const CircularNotchedRectangle(),
        notchMargin: 8.0,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            IconButton(
              icon: const Icon(Icons.calendar_month),
              onPressed: () {}, // Đang ở trang lịch
            ),
            IconButton(
              icon: const Icon(Icons.settings_outlined),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const SettingsScreen(),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
