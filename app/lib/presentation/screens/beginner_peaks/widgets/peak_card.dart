import 'package:flutter/material.dart';
import '../models/peak_data.dart';

/// 單座山岳的詳細資訊卡片 (可展開)
class PeakCard extends StatelessWidget {
  /// 山岳資料
  final PeakData peak;

  /// 主題色 (對應分類顏色)
  final Color themeColor;

  const PeakCard({super.key, required this.peak, required this.themeColor});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      color: Colors.grey.shade50,
      child: ExpansionTile(
        tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: CircleAvatar(
          backgroundColor: themeColor,
          foregroundColor: Colors.white,
          child: Text(peak.name.substring(0, 1), style: const TextStyle(fontWeight: FontWeight.bold)),
        ),
        title: Text(peak.displayName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 4.0),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildMiniTag(Icons.schedule, peak.days),
              const SizedBox(width: 8),
              _buildMiniTag(Icons.place, peak.location),
            ],
          ),
        ),
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
            child: Column(
              children: [
                const Divider(),
                // Ratings Section
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8.0),
                  child: Row(
                    children: [
                      Expanded(child: _buildRatingColumn('推薦指數', peak.recommendation, Colors.amber, Icons.star)),
                      Container(width: 1, height: 30, color: Colors.grey.shade300),
                      Expanded(
                        child: _buildRatingColumn('體力難度', peak.difficulty, Colors.redAccent.shade200, Icons.hiking),
                      ),
                    ],
                  ),
                ),

                // Tags
                Container(
                  margin: const EdgeInsets.symmetric(vertical: 12),
                  width: double.infinity,
                  child: Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    alignment: WrapAlignment.center,
                    children: [
                      _buildPillTag('H${peak.height}m', Colors.blueGrey),
                      _buildPillTag('往返${peak.distance}', Colors.green),
                      _buildPillTag('爬升${peak.climb}', Colors.orange),
                    ],
                  ),
                ),

                // Details Table
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey.shade200),
                  ),
                  child: Column(
                    children: [
                      _buildDetailRow('入園申請', peak.permit),
                      const SizedBox(height: 8),
                      _buildDetailRow('住宿資訊', peak.accommodation),
                      const SizedBox(height: 8),
                      _buildDetailRow('體能需求', peak.limit),
                    ],
                  ),
                ),

                const SizedBox(height: 12),
                // Sunrise Feature
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.amber.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.wb_sunny, size: 20, color: Colors.amber),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          peak.feature,
                          style: const TextStyle(fontSize: 14, height: 1.4, color: Colors.black87),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// 建構迷你標籤 (用於卡片副標題)
  Widget _buildMiniTag(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, size: 12, color: Colors.grey),
        const SizedBox(width: 2),
        Text(text, style: const TextStyle(fontSize: 12, color: Colors.grey)),
      ],
    );
  }

  /// 建構評分欄位 (推薦指數、體力難度)
  Widget _buildRatingColumn(String label, int value, Color color, IconData icon) {
    return Column(
      children: [
        Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
        const SizedBox(height: 4),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(
            5,
            (index) => Icon(
              index < value ? icon : (icon == Icons.star ? Icons.star_border : Icons.drag_handle),
              color: index < value ? color : Colors.grey.shade300,
              size: 18,
            ),
          ),
        ),
      ],
    );
  }

  /// 建構膠囊型標籤 (高度、距離、爬升)
  Widget _buildPillTag(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Text(
        text,
        style: TextStyle(fontSize: 12, color: color, fontWeight: FontWeight.bold),
      ),
    );
  }

  /// 建構詳細資訊列 (入園申請、住宿等)
  Widget _buildDetailRow(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 70,
          child: Text(label, style: const TextStyle(color: Colors.grey, fontSize: 13)),
        ),
        Expanded(
          child: Text(value, style: const TextStyle(fontSize: 13, color: Colors.black87)),
        ),
      ],
    );
  }
}
