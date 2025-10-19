import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:quan_ly_cong_viec_app/api/api_service.dart';
import 'package:quan_ly_cong_viec_app/models/task.dart';

class AddTaskScreen extends StatefulWidget {
  // Thêm 2 tham số tùy chọn vào constructor
  final DateTime? initialDate; // Dùng khi thêm mới từ lịch
  final Task? taskToEdit; // Dùng khi sửa một công việc đã có

  const AddTaskScreen({super.key, this.initialDate, this.taskToEdit});

  @override
  State<AddTaskScreen> createState() => _AddTaskScreenState();
}

class _AddTaskScreenState extends State<AddTaskScreen> {
  final _titleController = TextEditingController();
  final _noteController = TextEditingController();
  DateTime? _selectedDate;
  bool _isLoading = false;

  // Biến để xác định đang ở chế độ "Sửa" hay không
  bool get _isEditing => widget.taskToEdit != null;

  @override
  void initState() {
    super.initState();
    // Nếu là chế độ "Sửa", điền thông tin của công việc vào form
    if (_isEditing) {
      final task = widget.taskToEdit!;
      _titleController.text = task.title;
      _noteController.text = task.note ?? '';
      _selectedDate = DateFormat('yyyy-MM-dd').parse(task.dueDate);
    } else {
      // Nếu là chế độ "Thêm", lấy ngày từ màn hình chính
      _selectedDate = widget.initialDate;
    }
  }

  Future<void> _presentDatePicker() async {
    final now = DateTime.now();
    final firstDate = _isEditing ? DateTime(now.year - 5) : now;
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? now,
      firstDate: firstDate,
      lastDate: DateTime(now.year + 5),
    );
    if (pickedDate != null) {
      setState(() {
        _selectedDate = pickedDate;
      });
    }
  }

  // Hàm này bây giờ xử lý cả "Lưu" và "Cập nhật"
  void _submitTask() async {
    if (_titleController.text.trim().isEmpty || _selectedDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng nhập tiêu đề và chọn ngày.')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      if (_isEditing) {
        // Gọi API cập nhật
        await ApiService.updateTask(
          widget.taskToEdit!.id,
          _titleController.text,
          _noteController.text.isEmpty ? null : _noteController.text,
          _selectedDate!,
        );
      } else {
        // Gọi API tạo mới
        await ApiService.createTask(
          _titleController.text,
          _noteController.text.isEmpty ? null : _noteController.text,
          _selectedDate!,
        );
      }

      if (!mounted) return;
      // Gửi tín hiệu 'true' để màn hình chính biết cần làm mới
      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Thao tác thất bại: $e')));
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        // Thay đổi tiêu đề tùy theo chế độ
        title: Text(_isEditing ? 'Sửa công việc' : 'Thêm công việc mới'),
        actions: [
          if (_isLoading)
            const Padding(
              padding: EdgeInsets.only(right: 16.0),
              child: Center(
                child: CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 2.0,
                ),
              ),
            )
          else
            IconButton(icon: const Icon(Icons.save), onPressed: _submitTask),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: _titleController,
              decoration: const InputDecoration(labelText: 'Tiêu đề'),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _noteController,
              decoration: const InputDecoration(
                labelText: 'Ghi chú (tùy chọn)',
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: Text(
                    _selectedDate == null
                        ? 'Chưa chọn ngày'
                        : 'Ngày: ${DateFormat('dd/MM/yyyy').format(_selectedDate!)}',
                  ),
                ),
                TextButton(
                  onPressed: _presentDatePicker,
                  child: const Text('Thay đổi'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
