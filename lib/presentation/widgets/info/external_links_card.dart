import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:summitmate/core/core.dart';

/// 外部資訊連結卡片
///
/// 提供各種相關外部連結
class ExternalLinksCard extends StatelessWidget {
  const ExternalLinksCard({super.key});

  Future<void> _launchUrl(String url) async {
    final uri = Uri.parse(url);
    try {
      await launchUrl(uri, mode: LaunchMode.platformDefault);
    } catch (e) {
      debugPrint('無法開啟連結: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ExpansionTile(
        leading: const Icon(Icons.link),
        title: const Text('相關連結', style: TextStyle(fontWeight: FontWeight.bold)),
        children: [
          _buildLinkTile(
            icon: Icons.article_outlined,
            iconColor: Colors.green,
            title: '申請入山證',
            url: ExternalLinks.permitUrl,
          ),
          const Divider(height: 1),
          _buildLinkTile(icon: Icons.home_work, iconColor: Colors.brown, title: '山屋預約申請', url: ExternalLinks.cabinUrl),
          const Divider(height: 1),
          _buildLinkTile(
            icon: Icons.public,
            iconColor: Colors.indigo,
            title: '台灣山林悠遊網 (官網)',
            url: ExternalLinks.trailPageUrl,
          ),
          const Divider(height: 1),
          _buildLinkTile(
            icon: Icons.map,
            iconColor: Colors.green,
            title: 'GPX 軌跡檔下載 (健行筆記)',
            url: ExternalLinks.gpxUrl,
            trailing: Icons.download,
          ),
          const Divider(height: 1),
          _buildLinkTile(icon: Icons.cloud, iconColor: Colors.blue, title: 'Windy 天氣預報', url: ExternalLinks.windyUrl),
          const Divider(height: 1),
          _buildLinkTile(
            icon: Icons.wb_sunny,
            iconColor: Colors.orange,
            title: '中央氣象署 (三叉山)',
            url: ExternalLinks.cwaUrl,
          ),
          const Divider(height: 1),
          _buildLinkTile(
            icon: Icons.hotel,
            iconColor: Colors.purple,
            title: '鋤禾日好-站前館 (住宿)',
            url: ExternalLinks.accommodationUrl,
          ),
        ],
      ),
    );
  }

  Widget _buildLinkTile({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String url,
    IconData trailing = Icons.open_in_new,
  }) {
    return ListTile(
      leading: Icon(icon, color: iconColor),
      title: Text(title),
      trailing: Icon(trailing, size: 18),
      onTap: () => _launchUrl(url),
    );
  }
}
