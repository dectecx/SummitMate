import 'package:equatable/equatable.dart';

/// 山岳收藏功能的狀態基類
abstract class MountainFavoritesState extends Equatable {
  const MountainFavoritesState();

  @override
  List<Object> get props => [];
}

/// 初始狀態
class MountainFavoritesInitial extends MountainFavoritesState {}

/// 載入中
class MountainFavoritesLoading extends MountainFavoritesState {}

/// 載入完成 (包含目前的收藏 ID 清單)
class MountainFavoritesLoaded extends MountainFavoritesState {
  /// 收藏的山岳 ID 列表
  final List<String> favoriteIds;

  const MountainFavoritesLoaded(this.favoriteIds);

  @override
  List<Object> get props => [favoriteIds];

  /// 檢查特定 ID 是否在收藏中
  bool isFavorite(String id) => favoriteIds.contains(id);
}

/// 發生錯誤
class MountainFavoritesError extends MountainFavoritesState {
  final String message;

  const MountainFavoritesError(this.message);

  @override
  List<Object> get props => [message];
}
