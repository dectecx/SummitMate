import 'package:flutter/material.dart';
import '../models/page_content.dart';
import 'peak_card.dart';

/// 分類資料頁面視圖
class CategoryPageView extends StatelessWidget {
  /// 分類資料
  final CategoryData category;

  const CategoryPageView({super.key, required this.category});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.95),
        borderRadius: BorderRadius.circular(24),
        boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 8, offset: Offset(0, 4))],
      ),
      child: Column(
        children: [
          // Header
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(color: category.color.withValues(alpha: 0.1), shape: BoxShape.circle),
                child: Icon(Icons.terrain, color: category.color, size: 32),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      category.title,
                      style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, letterSpacing: 0.5),
                    ),
                    Text(category.subtitle, style: TextStyle(fontSize: 13, color: Colors.grey[700])),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // List
          Expanded(
            child: ListView.separated(
              itemCount: category.peaks.length,
              separatorBuilder: (ctx, i) => const SizedBox(height: 16),
              itemBuilder: (ctx, i) => PeakCard(peak: category.peaks[i], themeColor: category.color),
            ),
          ),
        ],
      ),
    );
  }
}
