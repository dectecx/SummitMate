import 'package:flutter/material.dart';
import 'package:seo_renderer/seo_renderer.dart';
import '../../screens/map/map_screen.dart';
import '../zoomable_image.dart';

class TrailOverviewCard extends StatefulWidget {
  final Key? expandedElevationKey;
  final Key? expandedTimeMapKey;

  const TrailOverviewCard({super.key, this.expandedElevationKey, this.expandedTimeMapKey});

  @override
  State<TrailOverviewCard> createState() => _TrailOverviewCardState();
}

class _TrailOverviewCardState extends State<TrailOverviewCard> {
  bool _isElevationExpanded = false;
  bool _isTimeMapExpanded = false;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('步道概況', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            Row(
              children: [
                _buildStatItem(context, Icons.straighten, '全長', '13 km'),
                _buildStatItem(
                  context,
                  Icons.landscape,
                  '海拔 (點擊展開高度圖)',
                  '2320~3603m',
                  onTap: () => setState(() {
                    _isElevationExpanded = !_isElevationExpanded;
                    if (_isElevationExpanded) _isTimeMapExpanded = false;
                  }),
                  highlight: _isElevationExpanded,
                ),
                _buildStatItem(
                  context,
                  Icons.timer,
                  '路程時間',
                  '點擊查看參考圖',
                  onTap: () => setState(() {
                    _isTimeMapExpanded = !_isTimeMapExpanded;
                    if (_isTimeMapExpanded) _isElevationExpanded = false;
                  }),
                  highlight: _isTimeMapExpanded,
                ),
              ],
            ),

            // 高度圖 (可縮合)
            AnimatedCrossFade(
              firstChild: const SizedBox(height: 0, width: double.infinity),
              secondChild: Padding(
                key: widget.expandedElevationKey,
                padding: const EdgeInsets.only(top: 16),
                child: const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '📏 高度變化圖',
                      style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey),
                    ),
                    SizedBox(height: 8),
                    ZoomableImage(assetPath: 'assets/images/elevation_profile.png', borderRadius: 8, title: '高度變化圖'),
                  ],
                ),
              ),
              crossFadeState: _isElevationExpanded ? CrossFadeState.showSecond : CrossFadeState.showFirst,
              duration: const Duration(milliseconds: 300),
            ),

            // 路程時間圖 (可縮合)
            AnimatedCrossFade(
              firstChild: const SizedBox(height: 0, width: double.infinity),
              secondChild: Padding(
                key: widget.expandedTimeMapKey,
                padding: const EdgeInsets.only(top: 16),
                child: const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '⏱️ 路程時間參考',
                      style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey),
                    ),
                    SizedBox(height: 8),
                    ZoomableImage(assetPath: 'assets/images/trail_time_map.png', borderRadius: 8, title: '路程時間參考'),
                  ],
                ),
              ),
              crossFadeState: _isTimeMapExpanded ? CrossFadeState.showSecond : CrossFadeState.showFirst,
              duration: const Duration(milliseconds: 300),
            ),

            const SizedBox(height: 16),
            const TextRenderer(
              child: Text(
                '嘉明湖國家步道為中央山脈南二段的一部分，穿越台灣鐵杉林、高山深谷與箭竹草原，以高山寒原與藍寶石般的嘉明湖聞名。',
                style: TextStyle(height: 1.5),
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const MapScreen())),
                icon: const Icon(Icons.map),
                label: const Text('查看步道導覽地圖'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(
    BuildContext context,
    IconData icon,
    String label,
    String value, {
    VoidCallback? onTap,
    bool highlight = false,
  }) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
          decoration: highlight
              ? BoxDecoration(
                  color: Theme.of(context).colorScheme.primaryContainer.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.5)),
                )
              : null,
          child: Row(
            children: [
              Icon(icon, size: 20, color: highlight ? Theme.of(context).colorScheme.primary : Colors.grey),
              const SizedBox(width: 8),
              Flexible(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: TextStyle(
                        fontSize: 12,
                        color: highlight ? Theme.of(context).colorScheme.primary : Colors.grey,
                      ),
                    ),
                    Text(
                      value,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: highlight ? Theme.of(context).colorScheme.primary : null,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
