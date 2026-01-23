import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:summitmate/core/core.dart';
import 'package:summitmate/data/models/mountain_location.dart';

/// 外部資訊連結卡片
///
/// 提供各種相關外部連結
class ExternalLinksCard extends StatelessWidget {
  final MountainLocation? location;

  const ExternalLinksCard({super.key, this.location});

  Future<void> _launchUrl(String url) async {
    if (url.isEmpty) return;
    final uri = Uri.parse(url);
    try {
      await launchUrl(uri, mode: LaunchMode.platformDefault);
    } catch (e) {
      debugPrint('無法開啟連結: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    // 預設使用嘉明湖資料
    final target = location ?? MountainData.jiamingLake;

    return Card(
      child: ExpansionTile(
        leading: const Icon(Icons.link),
        title: Text('相關連結 - ${target.name}', style: const TextStyle(fontWeight: FontWeight.bold)),
        children: [
          ...target.links.map(
            (link) => Column(
              children: [
                _buildLinkTile(
                  icon: _getLinkIcon(link.type),
                  iconColor: _getLinkColor(link.type),
                  title: link.title,
                  url: link.url,
                  trailing: link.type == LinkType.gpx ? Icons.download : Icons.open_in_new,
                ),
                const Divider(height: 1),
              ],
            ),
          ),
          _buildLinkTile(
            icon: Icons.cloud,
            iconColor: Colors.blue,
            title: 'Windy 天氣預報',
            url: '${ExternalLinks.windyUrl}${target.windyParams}',
          ),
          const Divider(height: 1),
          _buildLinkTile(
            icon: Icons.wb_sunny,
            iconColor: Colors.orange,
            title: '中央氣象署 (${target.name})',
            url: '${ExternalLinks.cwaUrl}?PID=${target.cwaPid}',
          ),
        ],
      ),
    );
  }

  IconData _getLinkIcon(LinkType type) {
    switch (type) {
      case LinkType.trail:
        return Icons.public;
      case LinkType.permit:
        return Icons.article_outlined;
      case LinkType.cabin:
        return Icons.home_work;
      case LinkType.gpx:
        return Icons.map;
      case LinkType.gearPdf:
        return Icons.description;
      case LinkType.accommodation:
        return Icons.hotel;
      case LinkType.other:
        return Icons.link;
    }
  }

  Color _getLinkColor(LinkType type) {
    switch (type) {
      case LinkType.trail:
        return Colors.indigo;
      case LinkType.permit:
        return Colors.green;
      case LinkType.cabin:
        return Colors.brown;
      case LinkType.gpx:
        return Colors.green;
      case LinkType.gearPdf:
        return Colors.blueGrey;
      case LinkType.accommodation:
        return Colors.purple;
      case LinkType.other:
        return Colors.grey;
    }
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
