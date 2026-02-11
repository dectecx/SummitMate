import 'package:flutter/material.dart';

/// 資訊簡介頁面視圖
///
/// 顯示指南說明、新手建議與未收錄路線說明
class InfoPageView extends StatelessWidget {
  const InfoPageView({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.95),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.1), blurRadius: 10, spreadRadius: 2)],
      ),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '指南簡介',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.teal.shade800),
            ),
            const SizedBox(height: 16),
            const Text(
              '這份清單專為「平常有運動習慣的新手」設計。我們精選了風景絕美、日出震撼的路線，並排除了部分雖熱門但不適合初次體驗日出的百岳。',
              style: TextStyle(fontSize: 16, height: 1.6, color: Colors.black87),
            ),
            const Divider(height: 48, thickness: 2),

            Text(
              '給新手的「第一座」建議',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.teal.shade800),
            ),
            const SizedBox(height: 16),
            _buildSuggestionItem('📷 輕鬆拍美照', '合歡北峰', Colors.amber),
            _buildSuggestionItem('🏠 體驗住山屋', '奇萊南華', Colors.orange),
            _buildSuggestionItem('💪 挑戰體能極限', '北大武山', Colors.redAccent),
            _buildSuggestionItem('⛺ 享受野營感', '屏風山', Colors.green),

            const Divider(height: 48, thickness: 2),

            Text(
              '未收錄的熱門百岳？',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.teal.shade800),
            ),
            const SizedBox(height: 8),
            const Text('以下路線雖熱門，但在此指南中未被列入首選：', style: TextStyle(fontSize: 14, color: Colors.grey)),
            const SizedBox(height: 16),
            _buildExcludedItem('合歡主/東峰', '視野略遜北峰，建議順路撿，不需專程看日出。'),
            _buildExcludedItem('合歡西峰', '路程太遠，俗稱「七上八下」，新手容易走到懷疑人生。'),
            _buildExcludedItem('品田山', 'V型斷崖對懼高症新手不友善，摸黑風險高。'),
            _buildExcludedItem('畢祿/羊頭', '多在樹林中行走，展望較少，單攻極累。'),

            const SizedBox(height: 60),
          ],
        ),
      ),
    );
  }

  /// 建構建議項目列 (打勾圖示)
  Widget _buildSuggestionItem(String label, String peak, Color color) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Icon(Icons.check_circle, color: color),
          const SizedBox(width: 12),
          Text(label, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
          const Spacer(),
          Text(
            '➝ $peak',
            style: TextStyle(fontWeight: FontWeight.bold, color: color, fontSize: 16),
          ),
        ],
      ),
    );
  }

  /// 建構未收錄路線說明列 (驚嘆號圖示)
  Widget _buildExcludedItem(String name, String reason) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.info_outline, size: 20, color: Colors.grey.shade600),
          const SizedBox(width: 12),
          Expanded(
            child: RichText(
              text: TextSpan(
                style: const TextStyle(color: Colors.black87, height: 1.4),
                children: [
                  TextSpan(
                    text: '$name：',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  TextSpan(text: reason),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
