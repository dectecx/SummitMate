import 'package:flutter/material.dart';

/// 電話訊號資訊卡片
///
/// 顯示步道各段的電話訊號狀況
class SignalInfoCard extends StatelessWidget {
  const SignalInfoCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ExpansionTile(
        leading: const Icon(Icons.signal_cellular_alt),
        title: const Text('電話訊號資訊', style: TextStyle(fontWeight: FontWeight.bold)),
        children: const [
          Padding(
            padding: EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _SignalInfoRow(location: '起點 ~ 3.3K', signal: '有訊號'),
                _SignalInfoRow(location: '3.3K ~ 向陽山屋', signal: '無訊號'),
                _SignalInfoRow(location: '黑水塘稜線', signal: '中華/遠傳 1~2 格'),
                _SignalInfoRow(location: '向陽山屋 ~ 10K', signal: '無訊號'),
                _SignalInfoRow(location: '10K', signal: '遠傳微弱 (風大易失溫)'),
                _SignalInfoRow(location: '10.5K', signal: '遠傳 2 格穩定'),
                _SignalInfoRow(location: '嘉明湖本湖', signal: '中華/遠傳 (視雲況)'),
                SizedBox(height: 8),
                Text('💡 建議使用遠傳門號以獲得較多通訊點', style: TextStyle(fontSize: 12, fontStyle: FontStyle.italic)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// 訊號資訊行
class _SignalInfoRow extends StatelessWidget {
  final String location;
  final String signal;

  const _SignalInfoRow({required this.location, required this.signal});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          const Icon(Icons.location_on, size: 16, color: Colors.grey),
          const SizedBox(width: 8),
          Expanded(
            child: Text(location, style: const TextStyle(fontWeight: FontWeight.w500)),
          ),
          _buildSignalChip(signal),
        ],
      ),
    );
  }

  Widget _buildSignalChip(String signal) {
    Color color;
    if (signal.contains('無訊號')) {
      color = Colors.red;
    } else if (signal.contains('微弱')) {
      color = Colors.orange;
    } else {
      color = Colors.green;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Text(
        signal,
        style: TextStyle(fontSize: 12, color: color, fontWeight: FontWeight.w500),
      ),
    );
  }
}
