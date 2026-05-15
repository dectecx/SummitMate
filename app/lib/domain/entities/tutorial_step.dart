import 'package:equatable/equatable.dart';

/// 教學章節
enum TutorialChapter {
  itinerary, // 行程管理
  gear, // 裝備清單
  collaboration, // 協作功能（留言/投票/同步）
  groupEvent, // 揪團功能
  cloud, // 雲端同步與帳號
}

extension TutorialChapterExtension on TutorialChapter {
  String get displayName {
    switch (this) {
      case TutorialChapter.itinerary:
        return '行程管理';
      case TutorialChapter.gear:
        return '裝備清單';
      case TutorialChapter.collaboration:
        return '協作功能';
      case TutorialChapter.groupEvent:
        return '揪團活動';
      case TutorialChapter.cloud:
        return '雲端同步';
    }
  }

  String get emoji {
    switch (this) {
      case TutorialChapter.itinerary:
        return '📅';
      case TutorialChapter.gear:
        return '🎒';
      case TutorialChapter.collaboration:
        return '💬';
      case TutorialChapter.groupEvent:
        return '👥';
      case TutorialChapter.cloud:
        return '☁️';
    }
  }
}

/// 教學模式
enum TutorialMode {
  quickTour, // 快速導覽（5 張卡片，初次登入）
  fullTutorial, // 完整教學（全部章節）
  chapterOnly, // 單一章節
}

/// 單一教學步驟的資料模型
class TutorialStep extends Equatable {
  final String id;
  final TutorialChapter chapter;
  final String title;
  final String description;
  final String emoji;

  /// 若有 mock 資料的說明提示
  final String? mockDataHint;

  const TutorialStep({
    required this.id,
    required this.chapter,
    required this.title,
    required this.description,
    required this.emoji,
    this.mockDataHint,
  });

  @override
  List<Object?> get props => [id, chapter, title, description, emoji, mockDataHint];
}

/// 快速導覽卡片資料模型（用於初次登入的 5 張卡片）
class QuickTourCard extends Equatable {
  final String title;
  final String description;
  final String emoji;
  final String? subtitle;

  const QuickTourCard({required this.title, required this.description, required this.emoji, this.subtitle});

  @override
  List<Object?> get props => [title, description, emoji, subtitle];
}
