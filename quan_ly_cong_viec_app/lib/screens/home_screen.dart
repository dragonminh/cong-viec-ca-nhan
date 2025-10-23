import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:quan_ly_cong_viec_app/api/api_service.dart';
import 'package:quan_ly_cong_viec_app/api/secure_storage_service.dart';
import 'package:quan_ly_cong_viec_app/models/task.dart';
import 'package:quan_ly_cong_viec_app/screens/login_screen.dart';
import 'package:quan_ly_cong_viec_app/screens/add_task_screen.dart';
import 'package:quan_ly_cong_viec_app/screens/settings_screen.dart';
import 'package:quan_ly_cong_viec_app/services/notification_service.dart';

// Imports cho AI
import 'package:quan_ly_cong_viec_app/services/ai_service.dart';
import 'dart:async'; // Dùng để xử lý bất đồng bộ

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<Task> _allTasks = [];
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  bool _isLoading = true;
  bool _isAiLoading = false; // Biến trạng thái cho nút AI

  @override
  void initState() {
    super.initState();
    _selectedDay = _focusedDay;
    _fetchTasks();
  }

  // --- HÀM LẤY DỮ LIỆU ---
  Future<void> _fetchTasks() async {
    // ... (code hàm này giữ nguyên) ...
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
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Không thể tải công việc: $e')));
      }
    }
  }

  // --- HÀM LỌC VÀ SẮP XẾP TASK CHO NGÀY ---
  List<Task> _getTasksForDay(DateTime day) {
    // ... (code hàm này giữ nguyên, đã có sắp xếp theo giờ) ...
     // 1. Lọc tất cả công việc của ngày được chọn
    final tasksForDay = _allTasks.where((task) {
      try {
        final taskDate = DateFormat('yyyy-MM-dd').parse(task.dueDate);
        // SỬA LỖI: Cần import table_calendar để dùng isSameDay
        return isSameDay(taskDate, day);
      } catch (e) {
        return false;
      }
    }).toList();

    // 2. Sắp xếp danh sách vừa lọc
    tasksForDay.sort((a, b) {
      // Ưu tiên 1: Công việc đã hoàn thành luôn ở dưới cùng
      if (a.isCompleted && !b.isCompleted) return 1;
      if (!a.isCompleted && b.isCompleted) return -1;

      // Ưu tiên 2: Sắp xếp theo giờ
      if (a.dueTime == null && b.dueTime == null) {
        return 0; // Cả hai đều không có giờ
      }
      if (a.dueTime == null) {
        // SỬA LOGIC: Công việc không có giờ nên ở cuối cùng trong ngày (hoặc đầu tùy yêu cầu)
        // Hiện tại: để ở cuối cùng những việc chưa hoàn thành
        return 1;
      }
      if (b.dueTime == null) {
        return -1;
      }

      // Cả hai đều có giờ, so sánh chuỗi (ví dụ: "08:49" so với "11:29")
      return a.dueTime!.compareTo(b.dueTime!);
    });

    return tasksForDay;
  }

  // --- HÀM ĐIỀU HƯỚNG ---
  void _navigateToAddTaskScreen({Task? taskToEdit}) async {
    // ... (code hàm này giữ nguyên) ...
     final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AddTaskScreen(
          // Truyền ngày đang chọn vào màn hình thêm/sửa
          initialDate: _selectedDay ?? DateTime.now(),
          taskToEdit: taskToEdit,
        ),
      ),
    );
    // Nếu màn hình thêm/sửa trả về true (có thay đổi), tải lại danh sách
    if (result == true && mounted) {
      _fetchTasks();
    }
  }

  void _logout(BuildContext context) async {
    // ... (code hàm này giữ nguyên) ...
    await SecureStorageService.deleteToken();
    if (!mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (context) => const LoginScreen()),
      (Route<dynamic> route) => false,
    );
  }

  // --- HÀM XỬ LÝ TASK ---
  Future<void> _toggleTaskStatus(Task task, bool? newValue) async {
    // ... (code hàm này giữ nguyên) ...
    if (newValue == null) return;

    // Lưu trạng thái cũ để rollback nếu lỗi
    final originalStatus = task.isCompleted;
    // Cập nhật giao diện ngay lập tức
    setState(() {
      task.isCompleted = newValue;
      // Sắp xếp lại danh sách ngay sau khi tick (đẩy task hoàn thành xuống cuối)
      // Điều này cần hàm _getTasksForDay chạy lại, sẽ thực hiện qua _fetchTasks hoặc setState toàn màn hình
    });

    try {
      // Gọi API để cập nhật backend
      final response =
          await ApiService.updateTask(task.id, {'is_completed': newValue});
      // Cập nhật task với dữ liệu mới nhất từ server (nếu cần)
      final updatedTaskFromServer = Task.fromJson(response);

      // Lên lịch hoặc hủy thông báo dựa trên trạng thái mới
      await NotificationService.scheduleNotificationForTask(updatedTaskFromServer);

      // Cập nhật lại task trong list _allTasks (quan trọng)
      final index = _allTasks.indexWhere((t) => t.id == task.id);
      if (index != -1) {
          // Cập nhật state một lần nữa để chắc chắn dữ liệu khớp server
           setState(() {
             _allTasks[index] = updatedTaskFromServer;
           });
      }

    } catch (e) {
      // Nếu có lỗi, rollback trạng thái trên giao diện
      setState(() {
        task.isCompleted = originalStatus;
      });
      // Hiển thị thông báo lỗi
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Cập nhật thất bại: $e')));
    }
  }

  Future<void> _deleteTask(Task task) async {
    // ... (code hàm này giữ nguyên) ...
      // Hủy thông báo đã lên lịch trước khi xóa task
    await NotificationService.cancelScheduledNotification(task.id);

    // Lưu lại danh sách cũ để rollback nếu lỗi
    final originalTasks = List<Task>.from(_allTasks);
    // Xóa task khỏi giao diện ngay lập tức
    setState(() {
      _allTasks.removeWhere((t) => t.id == task.id);
    });
    try {
      // Gọi API để xóa task khỏi backend
      await ApiService.deleteTask(task.id);
      // Hiển thị thông báo xóa thành công (tùy chọn)
      if (mounted) {
           ScaffoldMessenger.of(context).showSnackBar(
               SnackBar(content: Text('Đã xóa công việc "${task.title}"'))
           );
      }
    } catch (e) {
      // Nếu có lỗi, rollback giao diện
      setState(() {
        _allTasks = originalTasks;
      });
      // Hiển thị thông báo lỗi
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Xóa thất bại: $e')));
    }
  }

  // --- HÀM GỌI AI ---
  Future<void> _showAiSuggestion() async {
    // ... (code hàm này giữ nguyên) ...
     // 1. Kiểm tra nếu chưa chọn ngày hoặc AI đang tải thì không làm gì
    if (_selectedDay == null || _isAiLoading) return;

    // 2. Cập nhật trạng thái loading và hiển thị spinner cho nút AI
    setState(() {
      _isAiLoading = true; // Bắt đầu loading
    });

    // 3. Lấy danh sách công việc của ngày đang chọn
    final tasksForSelectedDay = _getTasksForDay(_selectedDay!);

    // 4. Hiển thị hộp thoại "Đang tải..."
    showDialog(
      context: context,
      barrierDismissible: false, // Không cho tắt bằng cách bấm ra ngoài
      builder: (context) => const AlertDialog(
        content: Row(
          children: [
            CircularProgressIndicator(),
            SizedBox(width: 20),
            Text("Đang hỏi AI..."),
          ],
        ),
      ),
    );

    // 5. Gọi AI Service và chờ kết quả
    String suggestion;
    try {
      suggestion =
          await AiService.getTaskPrioritySuggestion(tasksForSelectedDay);
    } catch (e) {
      suggestion = "Gặp lỗi: $e\n\nVui lòng kiểm tra lại API Key và kết nối mạng.";
    }

    // 6. Tắt hộp thoại "Đang tải"
    // Dùng Future.delayed nhỏ để đảm bảo dialog loading tắt hẳn trước khi dialog kết quả hiện ra
    await Future.delayed(const Duration(milliseconds: 100));
    if (mounted) Navigator.of(context).pop(); // Tắt dialog loading

    // 7. Cập nhật trạng thái loading của AI về false
    setState(() {
      _isAiLoading = false; // Kết thúc loading
    });

    // 8. Hiển thị kết quả gợi ý từ AI trong một dialog mới
    if (mounted) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Row(
            children: [
              Icon(Icons.auto_awesome, color: Colors.blue), // Icon AI
              SizedBox(width: 10),
              Text("Gợi ý từ AI"), // Tiêu đề dialog
            ],
          ),
          content: SingleChildScrollView(child: Text(suggestion)), // Nội dung gợi ý (cho phép cuộn nếu dài)
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(), // Nút đóng dialog
              child: const Text("OK"),
            ),
          ],
        ),
      );
    }
  }

  // --- HÀM BUILD GIAO DIỆN CHÍNH ---
  @override
  Widget build(BuildContext context) {
    // Lấy danh sách task cho ngày đã chọn để hiển thị trong ListView
    final selectedDayTasks =
        _selectedDay != null ? _getTasksForDay(_selectedDay!) : [];

    return Scaffold(
      // --- AppBar ---
      appBar: AppBar(
        // ... (code AppBar giữ nguyên) ...
        title: const Text('Lịch công việc'),
        actions: [
          // Nút quay về ngày hôm nay
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
          // Nút đăng xuất
          IconButton(
            tooltip: 'Đăng xuất',
            icon: const Icon(Icons.logout),
            onPressed: () => _logout(context),
          ),
        ],
      ),

      // --- Body (Lịch và danh sách công việc) ---
      body: Column(
        children: [
          // Widget Lịch (TableCalendar)
          TableCalendar(
             // ... (code TableCalendar giữ nguyên) ...
            locale: 'vi_VN', // Hiển thị tiếng Việt
            firstDay: DateTime.utc(2020, 1, 1), // Ngày bắt đầu của lịch
            lastDay: DateTime.utc(2030, 12, 31), // Ngày kết thúc của lịch
            focusedDay: _focusedDay, // Ngày đang được focus (thường là tháng hiện tại)
            headerStyle: const HeaderStyle(
              formatButtonVisible: false, // Ẩn nút đổi định dạng (tuần/tháng)
              titleCentered: true, // Căn giữa tiêu đề tháng/năm
            ),
            selectedDayPredicate: (day) => isSameDay(_selectedDay, day), // Hàm kiểm tra ngày nào đang được chọn
            onDaySelected: (selectedDay, focusedDay) {
              // Khi người dùng chọn một ngày mới
              setState(() {
                _selectedDay = selectedDay; // Cập nhật ngày được chọn
                _focusedDay = focusedDay; // Cập nhật cả ngày focus để lịch hiển thị đúng tháng
              });
            },
            onPageChanged: (focusedDay) {
              // Khi người dùng vuốt sang tháng khác
               setState(() { // Cập nhật _focusedDay để header hiển thị đúng tháng/năm
                  _focusedDay = focusedDay;
               });
            },
            eventLoader: _getTasksForDay, // Hàm cung cấp danh sách sự kiện (tasks) cho mỗi ngày để hiển thị dấu chấm
            // Tùy chỉnh giao diện Calendar (nếu cần)
            calendarStyle: CalendarStyle(
              // markerDecoration: BoxDecoration(...) // Tùy chỉnh dấu chấm sự kiện
              todayDecoration: BoxDecoration( // Trang trí ngày hôm nay
                color: Theme.of(context).colorScheme.secondaryContainer.withOpacity(0.5),
                shape: BoxShape.circle,
              ),
              selectedDecoration: BoxDecoration( // Trang trí ngày được chọn
                color: Theme.of(context).primaryColor,
                shape: BoxShape.circle,
              ),
            ),
             calendarBuilders: CalendarBuilders(
               markerBuilder: (context, date, events) {
                 if (events.isNotEmpty) {
                   // Đếm số task chưa hoàn thành
                   final incompleteTasks = (events as List<Task>).where((task) => !task.isCompleted).length;
                   if (incompleteTasks > 0) {
                     return Positioned(
                       right: 1,
                       bottom: 1,
                       child: Container(
                         padding: const EdgeInsets.all(2),
                         decoration: BoxDecoration(
                           shape: BoxShape.circle,
                           color: Colors.redAccent, // Màu đỏ cho task chưa hoàn thành
                         ),
                         constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
                         child: Text(
                           '$incompleteTasks', // Hiển thị số lượng
                           style: const TextStyle(
                             color: Colors.white,
                             fontSize: 10,
                           ),
                           textAlign: TextAlign.center,
                         ),
                       ),
                     );
                   }
                 }
                 return null; // Không hiển thị gì nếu không có task hoặc tất cả đã hoàn thành
               },
             ),
          ),
          const Divider(height: 1), // Đường kẻ ngang phân cách lịch và danh sách
          // Danh sách công việc
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator()) // Hiển thị loading khi đang tải
                : selectedDayTasks.isEmpty // Kiểm tra nếu ngày đó không có công việc
                    ? const Center(child: Text('Không có công việc nào cho ngày này.')) // Thông báo nếu không có việc
                    : ListView.builder( // Hiển thị danh sách nếu có công việc
                        // ... (code ListView.builder giữ nguyên) ...
                         itemCount: selectedDayTasks.length, // Số lượng công việc
                        itemBuilder: (context, index) {
                          final task = selectedDayTasks[index]; // Lấy công việc tại vị trí index
                          // Widget cho phép vuốt để xóa
                          return Dismissible(
                            key: ValueKey(task.id), // Key để Flutter nhận diện từng item
                            direction: DismissDirection.endToStart, // Chỉ cho phép vuốt từ phải sang trái
                            onDismissed: (direction) => _deleteTask(task), // Gọi hàm xóa khi vuốt xong
                            background: Container( // Nền màu đỏ hiển thị khi vuốt
                              color: Colors.red,
                              alignment: Alignment.centerRight,
                              padding: const EdgeInsets.only(right: 20.0),
                              child: const Icon(Icons.delete, color: Colors.white), // Icon thùng rác
                            ),
                            // Nội dung chính của mỗi dòng công việc (ListTile)
                            child: ListTile(
                                onTap: () => _navigateToAddTaskScreen(taskToEdit: task), // Nhấn vào để sửa công việc
                                leading: Checkbox( // Checkbox để đánh dấu hoàn thành
                                  value: task.isCompleted,
                                  onChanged: (value) => _toggleTaskStatus(task, value), // Gọi hàm cập nhật trạng thái
                                ),
                                title: Text( // Tiêu đề công việc
                                  task.title,
                                  style: TextStyle(
                                    // Gạch ngang chữ nếu công việc đã hoàn thành
                                    decoration: task.isCompleted
                                        ? TextDecoration.lineThrough
                                        : TextDecoration.none,
                                    // Làm mờ chữ nếu công việc đã hoàn thành
                                    color: task.isCompleted ? Colors.grey : null,
                                  ),
                                ),
                                subtitle: Column( // Hiển thị ghi chú và thời gian ở dưới tiêu đề
                                  crossAxisAlignment: CrossAxisAlignment.start, // Căn lề trái
                                  children: [
                                    // Chỉ hiển thị Text ghi chú nếu ghi chú không rỗng
                                    if (task.note != null && task.note!.isNotEmpty)
                                      Padding( // Thêm khoảng đệm cho ghi chú
                                        padding: const EdgeInsets.only(top: 4.0),
                                        child: Text(task.note!),
                                      ),
                                    // Chỉ hiển thị Text thời gian nếu thời gian được đặt
                                    if (task.dueTime != null)
                                      Padding( // Thêm khoảng đệm cho thời gian
                                        padding: const EdgeInsets.only(top: 4.0),
                                        child: Text(
                                          'Nhắc lúc: ${task.dueTime!.substring(0, 5)}', // Chỉ lấy HH:mm
                                          style: TextStyle(
                                              color: Theme.of(context).primaryColor, // Màu chính của theme
                                              fontWeight: FontWeight.bold),
                                        ),
                                      )
                                  ],
                                )),
                          );
                        },
                      ),
          ),
        ],
      ),

      // --- Nút thêm công việc (Floating Action Button) ---
      floatingActionButton: FloatingActionButton(
        // ... (code FAB giữ nguyên) ...
         shape: const CircleBorder(), // Đảm bảo nút luôn tròn
        onPressed: _navigateToAddTaskScreen, // Gọi hàm điều hướng khi nhấn
        tooltip: 'Thêm công việc mới', // Chú thích khi nhấn giữ
        child: const Icon(Icons.add), // Icon dấu cộng
      ),

      // --- Vị trí của nút + ---
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,

      // --- Thanh công cụ dưới cùng (Bottom App Bar) ---
      // ***** PHẦN SỬA ĐỔI CHÍNH NẰM Ở ĐÂY *****
      bottomNavigationBar: BottomAppBar(
        shape: const CircularNotchedRectangle(), // Hình dạng lõm
        notchMargin: 8.0, // Khoảng cách lõm
        height: 60.0, // Chiều cao thanh bar
        child: Row(
          // mainAxisAlignment: MainAxisAlignment.spaceBetween, // Không dùng spaceBetween nữa
          children: <Widget>[
            // --- Nút Lịch (Bên trái) ---
            Padding(
              padding: const EdgeInsets.only(left: 16.0), // Đẩy nút Lịch ra xa lề trái
              child: IconButton(
                icon: const Icon(Icons.calendar_month),
                tooltip: 'Lịch',
                onPressed: () {
                  setState(() {
                    _focusedDay = DateTime.now();
                    _selectedDay = _focusedDay;
                  });
                },
              ),
            ),

            
            const Spacer(),

            // --- Nút AI (Ngay bên phải nút +) ---
            _isAiLoading
                ? Container( // Spinner loading
                    width: 48, height: 48, padding: const EdgeInsets.all(12.0),
                    child: CircularProgressIndicator(strokeWidth: 2, color: Theme.of(context).primaryColor),
                  )
                : IconButton( // Icon AI
                    icon: Icon(Icons.auto_awesome, color: Theme.of(context).primaryColor),
                    tooltip: 'AI gợi ý ưu tiên',
                    onPressed: _showAiSuggestion,
                  ),

            // --- Nút Cài đặt (Bên phải cùng) ---
            Padding(
              padding: const EdgeInsets.only(right: 16.0), // Đẩy nút Cài đặt ra xa lề phải
              child: IconButton(
                icon: const Icon(Icons.settings_outlined),
                tooltip: 'Cài đặt',
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const SettingsScreen()),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
} 