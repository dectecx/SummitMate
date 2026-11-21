import 'package:material_ui/material_ui.dart';

/// 使用者頭像元件
///
/// 支援以下三種情境：
/// 1. 網路圖片 URL (`http://` 或 `https://`)：載入網路圖片，錯誤時降級顯示 fallbackText。
/// 2. Emoji 或自訂文字（例如 `🐻`、`🦊`）：以適當字體大小置中顯示。
/// 3. 空值 / 空字串：顯示 fallbackText 的首字或預設圖示。
class UserAvatar extends StatelessWidget {
  final String? avatar;
  final String fallbackText;
  final double radius;
  final Color? backgroundColor;
  final Color? foregroundColor;

  const UserAvatar({
    super.key,
    required this.avatar,
    this.fallbackText = '',
    this.radius = 20,
    this.backgroundColor,
    this.foregroundColor,
  });

  bool get _isNetworkUrl {
    if (avatar == null) return false;
    final trimmed = avatar!.trim();
    return trimmed.startsWith('http://') || trimmed.startsWith('https://');
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bgColor = backgroundColor ?? theme.colorScheme.primaryContainer;
    final fgColor = foregroundColor ?? theme.colorScheme.onPrimaryContainer;

    if (_isNetworkUrl) {
      return CircleAvatar(
        radius: radius,
        backgroundColor: bgColor,
        foregroundColor: fgColor,
        backgroundImage: NetworkImage(avatar!.trim()),
        onBackgroundImageError: (_, _) {},
        child: Text(
          fallbackText.isNotEmpty ? fallbackText[0] : '',
          style: TextStyle(fontSize: radius * 0.9, fontWeight: FontWeight.bold),
        ),
      );
    }

    final trimmedAvatar = avatar?.trim() ?? '';
    final displayText = trimmedAvatar.isNotEmpty ? trimmedAvatar : (fallbackText.isNotEmpty ? fallbackText[0] : '');

    return CircleAvatar(
      radius: radius,
      backgroundColor: bgColor,
      foregroundColor: fgColor,
      child: Text(
        displayText,
        style: TextStyle(
          fontSize: _isEmoji(displayText) ? radius * 1.1 : radius * 0.9,
          fontWeight: _isEmoji(displayText) ? FontWeight.normal : FontWeight.bold,
        ),
      ),
    );
  }

  bool _isEmoji(String text) {
    if (text.isEmpty) return false;
    final runes = text.runes;
    if (runes.isEmpty) return false;
    final first = runes.first;
    // 常用 Unicode Emoji 區間判斷
    return (first >= 0x1F300 && first <= 0x1FAFF) ||
        (first >= 0x2600 && first <= 0x27BF) ||
        (first >= 0xFE00 && first <= 0xFE0F);
  }
}
