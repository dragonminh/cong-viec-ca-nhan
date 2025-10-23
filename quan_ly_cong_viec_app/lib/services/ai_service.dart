import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:quan_ly_cong_viec_app/models/task.dart';

// ⬇️ QUAN TRỌNG: DÁN API KEY CỦA BẠN VÀO ĐÂY ⬇️
const String _apiKey = "AIzaSyAdWWMvco7y_sTaTCcpyBnsUCkvGhHIgdo";

class AiService {
  // Khởi tạo model AI
  static final _model = GenerativeModel(
    model: 'gemini-2.5-flash', // Dùng model gemini-pro
    apiKey: _apiKey,
  );

  /// Hỏi Gemini xem công việc nào quan trọng nhất
  static Future<String> getTaskPrioritySuggestion(List<Task> tasks) async {
    // Nếu không có công việc nào thì trả về luôn
    if (tasks.isEmpty) {
      return "Bạn không có công việc nào trong ngày này để AI sắp xếp.";
    }

    try {
      // 1. Chuyển danh sách Task thành một chuỗi văn bản đơn giản
      // Ví dụ: "- làm bài tập (Hết hạn: 2025-10-22 lúc 08:49)"
      final taskListString = tasks
          .where((task) => !task.isCompleted) // Chỉ lấy việc chưa làm
          .map((task) {
        return "- ${task.title} (Hết hạn: ${task.dueDate} lúc ${task.dueTime ?? 'cả ngày'})";
      }).join('\n'); // Nối các công việc bằng dấu xuống dòng

      if (taskListString.isEmpty) {
         return "Tất cả công việc trong ngày đã hoàn thành! 🎉";
      }

      // 2. Tạo câu lệnh (prompt) cho AI
      final prompt =
          'Tôi là một sinh viên, hôm nay tôi có danh sách các công việc sau:\n$taskListString\n\nDựa trên tiêu đề và thời gian hết hạn, hãy cho tôi một lời khuyên ngắn gọn (không quá 3 câu) rằng tôi nên ưu tiên làm công việc nào trước nhất? Hãy trả lời thật thân thiện và động viên.';

      // 3. Gửi yêu cầu đến Gemini và chờ kết quả
      final response = await _model.generateContent([Content.text(prompt)]);

      // 4. Trả về văn bản gợi ý
      return response.text ?? "Không thể nhận được gợi ý từ AI.";

    } catch (e) {
      // Xử lý nếu có lỗi (ví dụ: API Key sai, không có mạng...)
      return "Lỗi khi kết nối đến AI: $e";
    }
  }
}