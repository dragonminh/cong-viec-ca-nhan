class Task {
  final int id;
  final String title;
  final String? note;
  final String dueDate;
  bool isCompleted;

  Task({
    required this.id,
    required this.title,
    this.note,
    required this.dueDate,
    required this.isCompleted,
  });

  // Hàm factory này dùng để chuyển đổi JSON (dữ liệu từ API)
  // thành một đối tượng Task.
  factory Task.fromJson(Map<String, dynamic> json) {
    return Task(
      id: json['id'],
      title: json['title'],
      note: json['note'],
      dueDate: json['due_date'],
      // API trả về 0 hoặc 1 cho boolean, cần chuyển đổi
      isCompleted: json['is_completed'] == 1,
    );
  }
}
