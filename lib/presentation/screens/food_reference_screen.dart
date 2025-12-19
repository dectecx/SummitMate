import 'package:flutter/material.dart';
import 'package:photo_view/photo_view.dart';
import 'package:url_launcher/url_launcher.dart';

class FoodReferenceScreen extends StatelessWidget {
  const FoodReferenceScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('乾燥飯比較參考')),
      body: Column(
        children: [
          Expanded(
            flex: 6, // Image takes more space
            child: PhotoView(
              imageProvider: const AssetImage('assets/images/dried_rice_comparison.png'),
              backgroundDecoration: BoxDecoration(color: Theme.of(context).scaffoldBackgroundColor),
              minScale: PhotoViewComputedScale.contained,
              maxScale: PhotoViewComputedScale.covered * 2,
            ),
          ),
          Expanded(
            flex: 4,
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('重點整理', style: Theme.of(context).textTheme.titleLarge),
                  const SizedBox(height: 8),
                  _buildBrandInfo(context, '佐竹 (Satake)', '最好吃但價格高 (200元)', isBest: true),
                  _buildBrandInfo(context, '尾西 (Onisi)', '米飯Q彈，悶煮久 (190元)'),
                  _buildBrandInfo(context, '輕快風', 'CP值高，口感普通 (80-105元)'),
                  _buildBrandInfo(context, '輕旅人', '最便宜，調味淡 (80元)'),
                  const SizedBox(height: 16),
                  const Text('💡 建議新手可先嘗試佐竹或尾西，追求輕量與預算可選輕快風。', style: TextStyle(color: Colors.grey)),
                  const SizedBox(height: 24),
                  InkWell(
                    onTap: () => launchUrl(Uri.parse('https://www.instagram.com/p/COZu-kXHEG9/?img_index=3')),
                    child: const Text(
                      '圖片來源: Instagram @gingerbreadtzu',
                      style: TextStyle(color: Colors.blue, decoration: TextDecoration.underline, fontSize: 12),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBrandInfo(BuildContext context, String title, String desc, {bool isBest = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(isBest ? Icons.star : Icons.circle, size: 16, color: isBest ? Colors.amber : Colors.grey),
          const SizedBox(width: 8),
          Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(width: 8),
          Expanded(child: Text(desc)),
        ],
      ),
    );
  }
}
