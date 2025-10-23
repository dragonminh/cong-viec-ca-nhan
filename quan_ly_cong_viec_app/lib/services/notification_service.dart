import 'package:awesome_notifications/awesome_notifications.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:quan_ly_cong_viec_app/models/task.dart';

class NotificationService {
  static Future<void> initializeNotifications() async {
    await AwesomeNotifications().initialize(
     'resource://mipmap/ic_launcher', // icon cho thông báo
      [
        NotificationChannel(
          channelGroupKey: 'basic_channel_group',
          channelKey: 'basic_channel',
          channelName: 'Nhắc nhở công việc',
          channelDescription: 'Kênh thông báo cho các công việc và nhắc nhở',
          defaultColor: Colors.teal,
          ledColor: Colors.white,
          importance: NotificationImportance.High,
          channelShowBadge: true,
        )
      ],
      channelGroups: [
        NotificationChannelGroup(
          channelGroupKey: 'basic_channel_group',
          channelGroupName: 'Nhóm cơ bản',
        )
      ],
      debug: true,
    );

    bool isAllowed = await AwesomeNotifications().isNotificationAllowed();
    if (!isAllowed) {
      await AwesomeNotifications().requestPermissionToSendNotifications();
    }
  }

  static Future<void> showTestNotification() async {
    AwesomeNotifications().createNotification(
      content: NotificationContent(
        id: -1, // Dùng ID âm để tránh trùng lặp
        channelKey: 'basic_channel',
        title: 'Đây là thông báo thử nghiệm! 🔔',
        body: 'Nếu bạn thấy được thông báo này, nghĩa là mọi thứ đã hoạt động.',
      ),
    );
  }

  /// Lên lịch thông báo cho một công việc cụ thể
  static Future<void> scheduleNotificationForTask(Task task) async {
    // Không lên lịch nếu không có giờ cụ thể hoặc công việc đã hoàn thành
    if (task.dueTime == null || task.isCompleted) {
      // Nếu có thông báo cũ, hãy hủy nó đi
      await cancelScheduledNotification(task.id);
      return;
    }

    try {
      // Ghép ngày và giờ thành một đối tượng DateTime hoàn chỉnh
      final scheduleDateTime =
        DateFormat("yyyy-MM-dd HH:mm").parse('${task.dueDate} ${task.dueTime!}');

      // Chỉ lên lịch nếu thời gian là trong tương lai
      if (scheduleDateTime.isAfter(DateTime.now())) {
        await AwesomeNotifications().createNotification(
          content: NotificationContent(
            id: task.id, // ID của thông báo = ID của công việc
            channelKey: 'basic_channel',
            title: '⏰ Nhắc nhở: ${task.title}',
            body: task.note != null && task.note!.isNotEmpty
                ? task.note!
                : 'Đã đến giờ thực hiện công việc của bạn.',
            notificationLayout: NotificationLayout.Default,
            payload: {'taskId': task.id.toString()}, // Gửi kèm dữ liệu
          ),
          schedule: NotificationCalendar.fromDate(
            date: scheduleDateTime,
            preciseAlarm: true, // Đảm bảo đúng giờ trên Android
            allowWhileIdle: true, // Cho phép hiện khi máy ở chế độ chờ
          ),
        );
        debugPrint('✅ Đã lên lịch thông báo cho công việc #${task.id} lúc $scheduleDateTime');
      }
    } catch (e) {
      debugPrint('❌ Lỗi khi lên lịch thông báo: $e');
    }
  }

  /// Hủy một thông báo đã được lên lịch
  static Future<void> cancelScheduledNotification(int taskId) async {
    await AwesomeNotifications().cancel(taskId);
    debugPrint('🚫 Đã hủy lịch thông báo cho công việc #${taskId}');
  }
}