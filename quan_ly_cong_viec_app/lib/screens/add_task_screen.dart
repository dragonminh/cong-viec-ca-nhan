import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:quan_ly_cong_viec_app/api/api_service.dart';
import 'package:quan_ly_cong_viec_app/models/task.dart';
import 'package:quan_ly_cong_viec_app/services/notification_service.dart';

class AddTaskScreen extends StatefulWidget {
  final DateTime? initialDate;
  final Task? taskToEdit;

  const AddTaskScreen({super.key, this.initialDate, this.taskToEdit});

  @override
  State<AddTaskScreen> createState() => _AddTaskScreenState();
}

class _AddTaskScreenState extends State<AddTaskScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _noteController = TextEditingController();
  late DateTime _selectedDate;
  TimeOfDay? _selectedTime;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    if (widget.taskToEdit != null) {
      // Chế độ sửa
      _titleController.text = widget.taskToEdit!.title;
      _noteController.text = widget.taskToEdit!.note ?? '';
      _selectedDate = DateFormat('yyyy-MM-dd').parse(widget.taskToEdit!.dueDate);
      if (widget.taskToEdit!.dueTime != null) {
        final timeParts = widget.taskToEdit!.dueTime!.split(':');
        _selectedTime = TimeOfDay(
            hour: int.parse(timeParts[0]), minute: int.parse(timeParts[1]));
      }
    } else {
      // Chế độ thêm mới
      _selectedDate = widget.initialDate ?? DateTime.now();
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _selectTime() async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: _selectedTime ?? TimeOfDay.now(),
    );
    if (picked != null && picked != _selectedTime) {
      setState(() {
        _selectedTime = picked;
      });
    }
  }

  Future<void> _saveTask() async {
    if (_formKey.currentState!.validate()) {
      setState(() { _isLoading = true; });

      try {
        final String? formattedTime = _selectedTime != null
            ? '${_selectedTime!.hour.toString().padLeft(2, '0')}:${_selectedTime!.minute.toString().padLeft(2, '0')}'
            : null;

        Map<String, dynamic> response;
        if (widget.taskToEdit == null) {
          // Thêm công việc mới
          response = await ApiService.createTask(
            _titleController.text,
            _noteController.text,
            _selectedDate,
            formattedTime,
          );
        } else {
          // Cập nhật công việc
          response = await ApiService.updateTask(
            widget.taskToEdit!.id,
            {
              'title': _titleController.text,
              'note': _noteController.text,
              'due_date': DateFormat('yyyy-MM-dd').format(_selectedDate),
              'due_time': formattedTime,
            },
          );
        }

        final savedTask = Task.fromJson(response);
        await NotificationService.scheduleNotificationForTask(savedTask);

        if (mounted) {
          Navigator.of(context).pop(true); // Trả về true để báo thành công
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Thao tác thất bại: $e')),
          );
        }
      } finally {
        if (mounted) {
          setState(() { _isLoading = false; });
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.taskToEdit == null ? 'Thêm công việc' : 'Sửa công việc'),
        actions: [
          IconButton(
            icon: const Icon(Icons.save),
            onPressed: _isLoading ? null : _saveTask,
          )
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16.0),
          children: [
            TextFormField(
              controller: _titleController,
              decoration: const InputDecoration(labelText: 'Tiêu đề công việc'),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Vui lòng nhập tiêu đề';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _noteController,
              decoration: const InputDecoration(labelText: 'Ghi chú (tùy chọn)'),
            ),
            const SizedBox(height: 16),
            ListTile(
              leading: const Icon(Icons.calendar_today),
              title: const Text('Ngày hết hạn'),
              subtitle: Text(DateFormat('dd/MM/yyyy').format(_selectedDate)),
              trailing: const Icon(Icons.chevron_right),
              onTap: () async {
                final DateTime? picked = await showDatePicker(
                  context: context,
                  initialDate: _selectedDate,
                  firstDate: DateTime(2020),
                  lastDate: DateTime(2030),
                );
                if (picked != null && picked != _selectedDate) {
                  setState(() {
                    _selectedDate = picked;
                  });
                }
              },
            ),
            ListTile(
              leading: const Icon(Icons.access_time),
              title: const Text('Giờ nhắc nhở'),
              subtitle: Text(_selectedTime != null ? _selectedTime!.format(context) : 'Chưa đặt (sẽ không thông báo)'),
              trailing: const Icon(Icons.chevron_right),
              onTap: _selectTime,
            ),
          ],
        ),
      ),
    );
  }
}

