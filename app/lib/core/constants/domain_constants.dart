/// 留言分類
class MessageCategory {
  static const String important = 'Important'; // 重要公告
  static const String chat = 'Chat'; // 討論/閒聊
  static const String gear = 'Gear'; // 裝備

  static const List<String> all = [important, chat, gear];
}

/// 裝備分類
class GearCategory {
  static const String sleep = 'Sleep';
  static const String cook = 'Cook';
  static const String wear = 'Wear';
  static const String other = 'Other';

  static const List<String> all = [sleep, cook, wear, other];
}
