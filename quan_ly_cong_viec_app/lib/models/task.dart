class Task {
  final int id;
  final String title;
  final String? note;
  final String dueDate;
  final String? dueTime; // <-- THÊM TRƯỜNG MỚI
  bool isCompleted;

  Task({
    required this.id,
    required this.title,
    this.note,
    required this.dueDate,
    this.dueTime, // <-- CẬP NHẬT CONSTRUCTOR
    required this.isCompleted,
  });

  factory Task.fromJson(Map<String, dynamic> json) {
    return Task(
      id: json['id'],
      title: json['title'],
      note: json['note'],
      dueDate: json['due_date'],
      dueTime: json['due_time'], // <-- LẤY DỮ LIỆU TỪ JSON
      // API trả về 0 hoặc 1 cho boolean, cần chuyển đổi
      isCompleted: json['is_completed'] is bool
          ? json['is_completed']
          : json['is_completed'] == 1,
    );
  }
}