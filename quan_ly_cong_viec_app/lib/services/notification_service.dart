import 'package:awesome_notifications/awesome_notifications.dart';
import 'package:flutter/material.dart';

class NotificationService {
  // Phương thức khởi tạo
  static Future<void> initializeNotifications() async {
    await AwesomeNotifications().initialize(
      // null để dùng icon mặc định của app
      // Nếu bạn có file icon tên là 'app_icon.png' trong 'android/app/src/main/res/drawable',
      // bạn có thể dùng 'resource://drawable/app_icon'
      null,
      [
        NotificationChannel(
          channelGroupKey: 'basic_channel_group',
          channelKey: 'basic_channel',
          channelName: 'Thông báo cơ bản',
          channelDescription: 'Kênh thông báo cho các nhắc nhở công việc',
          defaultColor: Colors.teal,
          ledColor: Colors.white,
          importance: NotificationImportance.High,
          channelShowBadge: true,
          onlyAlertOnce: true,
          playSound: true,
          criticalAlerts: true,
        )
      ],
      channelGroups: [
        NotificationChannelGroup(
          channelGroupKey: 'basic_channel_group',
          channelGroupName: 'Nhóm cơ bản',
        )
      ],
      debug: true, // Bật debug để dễ dàng kiểm tra lỗi
    );

    // Yêu cầu quyền hiển thị thông báo từ người dùng
    final isAllowed = await AwesomeNotifications().isNotificationAllowed();
    if (!isAllowed) {
      await AwesomeNotifications().requestPermissionToSendNotifications();
    }
  }

  // Phương thức để tạo một thông báo ngay lập tức (dùng để test)
  static Future<void> showTestNotification() async {
    await AwesomeNotifications().createNotification(
      content: NotificationContent(
        id: -1, // -1 có nghĩa là id sẽ được tạo ngẫu nhiên
        channelKey: 'basic_channel',
        title: 'Đây là thông báo thử nghiệm! 🔔',
        body: 'Nếu bạn thấy được thông báo này, nghĩa là mọi thứ đã hoạt động.',
        notificationLayout: NotificationLayout.Default,
      ),
    );
  }

  // --- SAU NÀY BẠN SẼ THÊM CÁC HÀM LÊN LỊCH THÔNG BÁO TẠI ĐÂY ---

}

